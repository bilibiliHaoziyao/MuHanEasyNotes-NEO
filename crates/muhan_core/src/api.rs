//! flutter_rust_bridge 桥接 API
//!
//! 暴露给 Flutter/Dart 端的类型安全 API。
//! 使用 flutter_rust_bridge_codegen generate 生成对应的 Dart 绑定。

use flutter_rust_bridge::frb;
use std::sync::Arc;
use tokio::sync::Mutex;

use crate::backup::{self, BackupFile};
use crate::crypto;
use crate::db::Database;
use crate::models::*;
use crate::platform;
use crate::sync::WebDavConfig;

/// 应用版本常量
#[frb(sync)]
pub fn app_version() -> String {
    "2.0.0".to_string()
}

/// 全局数据库实例（懒加载）
static DB: std::sync::OnceLock<Arc<Mutex<Option<Database>>>> = std::sync::OnceLock::new();

fn get_db_arc() -> &'static Arc<Mutex<Option<Database>>> {
    DB.get_or_init(|| Arc::new(Mutex::new(None)))
}

async fn ensure_db() -> Result<(), String> {
    let arc = get_db_arc();
    let mut guard = arc.lock().await;
    if guard.is_none() {
        platform::ensure_dirs().map_err(|e| e.to_string())?;
        let path = platform::database_path();
        let db = Database::open(&path).map_err(|e| e.to_string())?;
        *guard = Some(db);
    }
    Ok(())
}

async fn with_db<F, R>(f: F) -> Result<R, String>
where
    F: FnOnce(&Database) -> Result<R, String> + Send + 'static,
    R: Send + 'static,
{
    ensure_db().await?;
    let arc = get_db_arc().clone();
    let guard = arc.lock().await;
    let db = guard.as_ref().ok_or("数据库未初始化".to_string())?;
    f(db)
}

// ===== Note API =====

#[frb]
pub async fn note_create(title: String, content: String, color: Option<String>) -> Result<Note, String> {
    with_db(move |db| {
        let c = color
            .as_deref()
            .map(color_from_str)
            .unwrap_or_default();
        let mut note = Note::new(title, content);
        note.color = c;
        db.create_note(&note)
            .map(|_| note)
            .map_err(|e| e.to_string())
    })
    .await
}

#[frb]
pub async fn note_get(id: String) -> Result<Option<Note>, String> {
    with_db(move |db| db.get_note(&id).map_err(|e| e.to_string())).await
}

#[frb]
pub async fn note_update(
    id: String,
    title: String,
    content: String,
    color: Option<String>,
    pinned: bool,
) -> Result<Note, String> {
    with_db(move |db| {
        let existing = db
            .get_note(&id)
            .map_err(|e| e.to_string())?
            .ok_or_else(|| "笔记不存在".to_string())?;
        let color = color
            .as_deref()
            .map(color_from_str)
            .unwrap_or(existing.color);
        let updated = Note {
            title: if title.is_empty() {
                Note::auto_title(&content)
            } else {
                title
            },
            content,
            color,
            pinned,
            updated_at: chrono::Utc::now(),
            ..existing
        };
        db.update_note(&updated)
            .map(|_| updated)
            .map_err(|e| e.to_string())
    })
    .await
}

#[frb]
pub async fn note_delete(id: String, permanent: bool) -> Result<(), String> {
    with_db(move |db| {
        if permanent {
            db.permanent_delete_note(&id)
        } else {
            db.soft_delete_note(&id)
        }
        .map_err(|e| e.to_string())
    })
    .await
}

#[frb]
pub async fn note_restore(id: String) -> Result<(), String> {
    with_db(move |db| db.restore_note(&id).map_err(|e| e.to_string())).await
}

#[frb]
pub async fn note_list(
    query: Option<String>,
    include_deleted: bool,
    pinned_only: bool,
    sort: Option<String>,
) -> Result<Vec<Note>, String> {
    with_db(move |db| {
        let filter = NoteFilter {
            query,
            include_deleted,
            pinned_only,
            color: None,
        };
        let sort = sort.as_deref().map(sort_from_str).unwrap_or_default();
        db.list_notes(&filter, sort).map_err(|e| e.to_string())
    })
    .await
}

#[frb]
pub async fn note_count(include_deleted: bool) -> Result<i64, String> {
    with_db(move |db| db.count_notes(include_deleted).map_err(|e| e.to_string())).await
}

#[frb]
pub async fn note_auto_title(content: String) -> String {
    Note::auto_title(&content)
}

// ===== Backup API =====

#[frb]
pub async fn backup_export(path: String) -> Result<BackupFile, String> {
    ensure_db().await?;
    let arc = get_db_arc().clone();
    let guard = arc.lock().await;
    let db = guard.as_ref().ok_or("数据库未初始化".to_string())?;
    db.export_backup(&path).map_err(|e| e.to_string())
}

#[frb]
pub async fn backup_import(path: String) -> Result<BackupFile, String> {
    ensure_db().await?;
    let arc = get_db_arc().clone();
    let guard = arc.lock().await;
    let db = guard.as_ref().ok_or("数据库未初始化".to_string())?;
    db.import_backup(&path).map_err(|e| e.to_string())
}

#[frb(sync)]
pub fn backup_preview(path: String) -> Result<BackupFile, String> {
    backup::preview_backup(&path).map_err(|e| e.to_string())
}

#[frb(sync)]
pub fn find_legacy_backup_files() -> Result<Vec<String>, String> {
    let mut results = Vec::new();
    for dir in backup::get_legacy_search_paths() {
        if let Ok(files) = backup::find_legacy_backups(&dir) {
            for f in files {
                results.push(f.to_string_lossy().to_string());
            }
        }
    }
    // 去重并取最多 20 个
    results.sort();
    results.dedup();
    results.truncate(20);
    Ok(results)
}

// ===== Settings API =====

#[frb]
pub async fn settings_load() -> Result<AppSettings, String> {
    with_db(|db| db.load_app_settings().map_err(|e| e.to_string())).await
}

#[frb]
pub async fn settings_save(settings: AppSettings) -> Result<(), String> {
    with_db(move |db| db.save_app_settings(&settings).map_err(|e| e.to_string())).await
}

// ===== Crypto API =====

#[frb(sync)]
pub fn crypto_encrypt(password: String, plaintext: Vec<u8>) -> Result<Vec<u8>, String> {
    crypto::encrypt(&password, &plaintext).map_err(|e| e.to_string())
}

#[frb(sync)]
pub fn crypto_decrypt(password: String, data: Vec<u8>) -> Result<Vec<u8>, String> {
    crypto::decrypt(&password, &data).map_err(|e| e.to_string())
}

#[frb(sync)]
pub fn crypto_hash_password(password: String) -> String {
    crypto::hash_password(&password)
}

#[frb(sync)]
pub fn crypto_verify_password(password: String, hash: String) -> bool {
    crypto::verify_password(&password, &hash)
}

// ===== WebDAV API =====

#[frb]
pub async fn webdav_test(
    url: String,
    username: String,
    password: String,
) -> Result<(), String> {
    let config = WebDavConfig {
        url,
        username,
        password,
        remote_path: String::new(),
    };
    let client = crate::sync::WebDavClient::new(config).map_err(|e| e.to_string())?;
    client.test_connection().await.map_err(|e| e.to_string())
}

#[frb]
pub async fn webdav_upload_backup(
    url: String,
    username: String,
    password: String,
    local_path: String,
) -> Result<String, String> {
    let config = WebDavConfig {
        url,
        username,
        password,
        remote_path: String::new(),
    };
    let client = crate::sync::WebDavClient::new(config).map_err(|e| e.to_string())?;
    client
        .upload_backup(&local_path)
        .await
        .map_err(|e| e.to_string())
}

// ===== Platform =====

#[frb(sync)]
pub fn platform_app_data_dir() -> String {
    platform::app_data_dir().to_string_lossy().to_string()
}

#[frb(sync)]
pub fn platform_database_path() -> String {
    platform::database_path().to_string_lossy().to_string()
}

#[frb(sync)]
pub fn platform_color_names() -> Vec<String> {
    NoteColor::all().into_iter().map(|c| c.as_str().to_string()).collect()
}

#[frb(sync)]
pub fn platform_auto_title(content: String) -> String {
    Note::auto_title(&content)
}

// ===== Helpers =====

fn color_from_str(s: &str) -> NoteColor {
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

fn sort_from_str(s: &str) -> NoteSort {
    match s {
        "updated_asc" => NoteSort::UpdatedAsc,
        "created_desc" => NoteSort::CreatedDesc,
        "created_asc" => NoteSort::CreatedAsc,
        "title_asc" => NoteSort::TitleAsc,
        "title_desc" => NoteSort::TitleDesc,
        _ => NoteSort::UpdatedDesc,
    }
}

/// 确保 Rust 库被正确初始化（Dart 端启动时调用）
#[frb(sync)]
pub fn initialize() -> bool {
    // 触发 flutter_rust_bridge 初始化
    true
}
