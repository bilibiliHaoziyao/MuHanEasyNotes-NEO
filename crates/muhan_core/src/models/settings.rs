use serde::{Deserialize, Serialize};

/// 应用设置
#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct AppSettings {
    /// 界面缩放
    pub ui_scale: f64,
    /// 字体缩放
    pub font_scale: f64,
    /// 编辑时自动保存防抖（毫秒）
    pub autosave_debounce_ms: u64,
    /// 是否启用深色模式
    pub dark_mode: Option<bool>,
    /// 密码保护（已哈希）
    pub password_hash: Option<String>,
    /// 自动锁定超时（秒）
    pub auto_lock_seconds: u64,
    /// WebDAV 配置
    pub webdav_url: Option<String>,
    pub webdav_username: Option<String>,
    pub webdav_password: Option<String>,
    pub webdav_sync_enabled: bool,
    /// 语言
    pub language: String,
}

impl Default for AppSettings {
    fn default() -> Self {
        Self {
            ui_scale: 1.0,
            font_scale: 1.0,
            autosave_debounce_ms: 1200,
            dark_mode: None,
            password_hash: None,
            auto_lock_seconds: 300,
            webdav_url: None,
            webdav_username: None,
            webdav_password: None,
            webdav_sync_enabled: false,
            language: "zh_CN".to_string(),
        }
    }
}
