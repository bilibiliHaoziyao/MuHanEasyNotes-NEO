//! 备份与恢复

use crate::db::Database;
use crate::errors::Result;
use crate::models::*;
use serde::{Deserialize, Serialize};
use std::fs;
use std::path::{Path, PathBuf};

/// 备份文件格式
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct BackupFile {
    pub app: String,
    pub version: String,
    pub exported_at: String,
    pub notes: Vec<Note>,
    pub attachments: Vec<Attachment>,
    pub settings: AppSettings,
}

impl BackupFile {
    pub fn new(
        notes: Vec<Note>,
        attachments: Vec<Attachment>,
        settings: AppSettings,
    ) -> Self {
        Self {
            app: "MuHanEasyNotes NEO".to_string(),
            version: "2.0.0".to_string(),
            exported_at: chrono::Utc::now().to_rfc3339(),
            notes,
            attachments,
            settings,
        }
    }
}

/// 旧版备份格式（兼容 v1.x 手动选择迁移）
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LegacyBackupFile {
    pub app: Option<String>,
    pub notes: Vec<LegacyNote>,
    #[serde(default)]
    pub attachments: Vec<LegacyAttachment>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LegacyNote {
    pub id: Option<String>,
    pub title: Option<String>,
    pub content: Option<String>,
    pub color: Option<String>,
    pub pinned: Option<bool>,
    pub created_at: Option<String>,
    pub updated_at: Option<String>,
    pub deleted_at: Option<String>,
}

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct LegacyAttachment {
    pub id: Option<String>,
    pub note_id: Option<String>,
    pub file_path: Option<String>,
    pub mime_type: Option<String>,
    pub file_size: Option<i64>,
    pub created_at: Option<String>,
}

impl Database {
    /// 导出为 JSON 备份文件
    pub fn export_backup<P: AsRef<Path>>(&self, path: P) -> Result<BackupFile> {
        let notes = self.get_all_notes()?;
        let mut attachments = Vec::new();
        for n in &notes {
            attachments.extend(self.get_attachments(&n.id)?);
        }
        let settings = self.load_app_settings()?;
        let backup = BackupFile::new(notes, attachments, settings);
        let json = serde_json::to_string_pretty(&backup)?;
        fs::write(path, json)?;
        Ok(backup)
    }

    /// 从 JSON 文件导入（自动识别新旧格式）
    pub fn import_backup<P: AsRef<Path>>(&self, path: P) -> Result<BackupFile> {
        let content = fs::read_to_string(path)?;

        // 先尝试新版格式
        if let Ok(backup) = serde_json::from_str::<BackupFile>(&content) {
            self.apply_backup(&backup)?;
            return Ok(backup);
        }

        // 再尝试旧版格式
        let legacy: LegacyBackupFile = serde_json::from_str(&content).map_err(|e| {
            crate::errors::CoreError::Migration(format!(
                "无法解析备份文件，既不是新版也不是旧版格式: {}",
                e
            ))
        })?;
        let notes = legacy
            .notes
            .into_iter()
            .map(|ln| convert_legacy_note(ln))
            .collect();
        let attachments = legacy
            .attachments
            .into_iter()
            .map(|la| convert_legacy_attachment(la))
            .collect();
        let backup = BackupFile::new(notes, attachments, AppSettings::default());
        self.apply_backup(&backup)?;
        Ok(backup)
    }

    /// 预览备份文件内容（不写入数据库）
    pub fn preview_backup<P: AsRef<Path>>(path: P) -> Result<BackupFile> {
        let content = fs::read_to_string(path)?;
        if let Ok(backup) = serde_json::from_str::<BackupFile>(&content) {
            return Ok(backup);
        }
        let legacy: LegacyBackupFile = serde_json::from_str(&content).map_err(|e| {
            crate::errors::CoreError::Migration(format!("无法解析备份文件: {}", e))
        })?;
        let notes = legacy
            .notes
            .into_iter()
            .map(|ln| convert_legacy_note(ln))
            .collect();
        let attachments = legacy
            .attachments
            .into_iter()
            .map(|la| convert_legacy_attachment(la))
            .collect();
        Ok(BackupFile::new(notes, attachments, AppSettings::default()))
    }

    fn apply_backup(&self, backup: &BackupFile) -> Result<()> {
        self.batch_insert_notes(&backup.notes)?;
        for att in &backup.attachments {
            let _ = self.add_attachment(att); // 附件插入失败不影响笔记
        }
        // 不覆盖现有设置，除非全新
        let existing_count = self.count_notes(true)?;
        if existing_count as usize == backup.notes.len() {
            let _ = self.save_app_settings(&backup.settings);
        }
        Ok(())
    }
}

fn convert_legacy_note(ln: LegacyNote) -> Note {
    let id = ln.id.unwrap_or_else(|| uuid::Uuid::new_v4().to_string());
    let title = ln.title.unwrap_or_default();
    let content = ln.content.unwrap_or_default();
    let color = ln
        .color
        .as_deref()
        .map(str_to_color)
        .unwrap_or_default();
    let pinned = ln.pinned.unwrap_or(false);

    let parse_dt = |s: Option<String>| -> chrono::DateTime<chrono::Utc> {
        s.and_then(|s| chrono::DateTime::parse_from_rfc3339(&s).ok())
            .map(|dt| dt.with_timezone(&chrono::Utc))
            .unwrap_or_else(chrono::Utc::now)
    };

    let created_at = parse_dt(ln.created_at);
    let updated_at = parse_dt(ln.updated_at);
    let deleted_at = ln
        .deleted_at
        .and_then(|s| chrono::DateTime::parse_from_rfc3339(&s).ok())
        .map(|dt| dt.with_timezone(&chrono::Utc));

    Note {
        id,
        title: if title.is_empty() {
            Note::auto_title(&content)
        } else {
            title
        },
        content,
        color,
        pinned,
        created_at,
        updated_at,
        deleted_at,
    }
}

fn convert_legacy_attachment(la: LegacyAttachment) -> Attachment {
    Attachment {
        id: la.id.unwrap_or_else(|| uuid::Uuid::new_v4().to_string()),
        note_id: la.note_id.unwrap_or_default(),
        file_path: la.file_path.unwrap_or_default(),
        mime_type: la.mime_type.unwrap_or_else(|| "application/octet-stream".to_string()),
        file_size: la.file_size.unwrap_or(0),
        created_at: chrono::Utc::now(),
    }
}

fn str_to_color(s: &str) -> NoteColor {
    match s {
        "red" => NoteColor::Red,
        "orange" => NoteColor::Orange,
        "yellow" => NoteColor::Yellow,
        "green" => NoteColor::Green,
        "blue" => NoteColor::Blue,
        "purple" => NoteColor::Purple,
        _ => NoteColor::Gray,
    }
}

/// 递归扫描旧版备份目录中的 .json 文件
pub fn find_legacy_backups(dir: &Path) -> Result<Vec<PathBuf>> {
    let mut results = Vec::new();
    if !dir.exists() {
        return Ok(results);
    }
    for entry in walkdir::WalkDir::new(dir).max_depth(3) {
        let entry = match entry {
            Ok(e) => e,
            Err(_) => continue,
        };
        if entry.file_type().is_file()
            && entry.path().extension().map(|e| e == "json").unwrap_or(false)
        {
            results.push(entry.path().to_path_buf());
        }
    }
    Ok(results)
}

/// 检测旧版默认备份路径（各平台常见位置）
pub fn get_legacy_search_paths() -> Vec<PathBuf> {
    let mut paths = Vec::new();

    if let Some(home) = std::env::var_os("HOME") {
        let home = PathBuf::from(home);
        // Android 旧版可能的备份位置（用户手动导出后放到桌面/Download）
        paths.push(home.join("Desktop"));
        paths.push(home.join("Downloads"));
        paths.push(home.join("Documents"));
        paths.push(home.join(".muhan"));
        paths.push(home.join(".MuHanEasyNotes"));
    }

    // Linux XDG
    if let Some(xdg) = std::env::var_os("XDG_DATA_HOME") {
        paths.push(PathBuf::from(xdg).join("MuHanEasyNotes"));
    }

    // macOS 特定
    if cfg!(target_os = "macos") {
        if let Some(home) = std::env::var_os("HOME") {
            let home = PathBuf::from(home);
            paths.push(home.join("Library").join("Application Support").join("MuHanEasyNotes"));
        }
    }

    // Windows 特定
    if cfg!(target_os = "windows") {
        if let Some(appdata) = std::env::var_os("APPDATA") {
            paths.push(PathBuf::from(appdata).join("MuHanEasyNotes"));
        }
    }

    paths
}

/// 模块级自由函数：预览备份文件（不依赖 Database 实例）
pub fn preview_backup<P: AsRef<Path>>(path: P) -> Result<BackupFile> {
    let content = std::fs::read_to_string(path.as_ref())?;
    if let Ok(backup) = serde_json::from_str::<BackupFile>(&content) {
        return Ok(backup);
    }
    let legacy: LegacyBackupFile = serde_json::from_str(&content).map_err(|e| {
        crate::errors::CoreError::Migration(format!("无法解析备份文件: {}", e))
    })?;
    let notes = legacy
        .notes
        .into_iter()
        .map(|ln| convert_legacy_note(ln))
        .collect();
    let attachments = legacy
        .attachments
        .into_iter()
        .map(|la| convert_legacy_attachment(la))
        .collect();
    Ok(BackupFile::new(notes, attachments, AppSettings::default()))
}
