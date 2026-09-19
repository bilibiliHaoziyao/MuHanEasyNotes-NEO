//! MuHanEasyNotes NEO — Rust core library
//!
//! 核心模块：数据模型、SQLite 存储、备份/恢复、WebDAV 同步、AES-GCM 加密

pub mod api;
pub mod backup;
pub mod crypto;
pub mod db;
pub mod errors;
pub mod models;
pub mod platform;
pub mod sync;

pub use errors::CoreError;
pub use models::*;

/// 数据库当前版本
pub const DB_VERSION: i32 = 2;
