//! 平台相关路径解析

use std::path::PathBuf;

/// 应用数据目录（各平台标准位置）
pub fn app_data_dir() -> PathBuf {
    let dir = if cfg!(target_os = "windows") {
        std::env::var_os("APPDATA")
            .map(PathBuf::from)
            .unwrap_or_else(|| PathBuf::from("."))
    } else if cfg!(target_os = "macos") {
        std::env::var_os("HOME")
            .map(PathBuf::from)
            .map(|h| h.join("Library").join("Application Support"))
            .unwrap_or_else(|| PathBuf::from("."))
    } else if cfg!(target_os = "web") {
        PathBuf::from("/tmp/muhan_notes")
    } else {
        // Linux / other
        std::env::var_os("XDG_DATA_HOME")
            .map(PathBuf::from)
            .unwrap_or_else(|| {
                std::env::var_os("HOME")
                    .map(|h| PathBuf::from(h).join(".local").join("share"))
                    .unwrap_or_else(|| PathBuf::from("."))
            })
    };
    dir.join("MuHanEasyNotes")
}

pub fn database_path() -> PathBuf {
    app_data_dir().join("notes.db")
}

pub fn attachments_dir() -> PathBuf {
    app_data_dir().join("attachments")
}

pub fn backups_dir() -> PathBuf {
    app_data_dir().join("backups")
}

pub fn ensure_dirs() -> std::io::Result<()> {
    let dirs = [app_data_dir(), attachments_dir(), backups_dir()];
    for d in &dirs {
        std::fs::create_dir_all(d)?;
    }
    Ok(())
}
