//! SQLite 数据库存储层

use rusqlite::{params, Connection, OptionalExtension};
use chrono::Utc;
use std::path::Path;

use crate::errors::{CoreError, Result};
use crate::models::*;

pub struct Database {
    conn: Connection,
}

impl Database {
    pub fn open<P: AsRef<Path>>(path: P) -> Result<Self> {
        let conn = Connection::open(path)?;
        conn.pragma_update(None, "journal_mode", "WAL")?;
        conn.pragma_update(None, "foreign_keys", "ON")?;

        let db = Self { conn };
        db.migrate()?;
        Ok(db)
    }

    pub fn open_in_memory() -> Result<Self> {
        let conn = Connection::open_in_memory()?;
        let db = Self { conn };
        db.migrate()?;
        Ok(db)
    }

    fn migrate(&self) -> Result<()> {
        let version: i32 = self
            .conn
            .query_row("PRAGMA user_version", [], |r| r.get(0))
            .unwrap_or(0);

        if version < 1 {
            self.conn.execute_batch(
                r#"
                CREATE TABLE IF NOT EXISTS notes (
                    id TEXT PRIMARY KEY,
                    title TEXT NOT NULL,
                    content TEXT NOT NULL,
                    color TEXT NOT NULL DEFAULT 'yellow',
                    pinned INTEGER NOT NULL DEFAULT 0,
                    created_at TEXT NOT NULL,
                    updated_at TEXT NOT NULL,
                    deleted_at TEXT
                );
                CREATE INDEX IF NOT EXISTS idx_notes_pinned ON notes(pinned);
                CREATE INDEX IF NOT EXISTS idx_notes_updated ON notes(updated_at);
                CREATE INDEX IF NOT EXISTS idx_notes_deleted ON notes(deleted_at);

                CREATE TABLE IF NOT EXISTS attachments (
                    id TEXT PRIMARY KEY,
                    note_id TEXT NOT NULL,
                    file_path TEXT NOT NULL,
                    mime_type TEXT NOT NULL,
                    file_size INTEGER NOT NULL,
                    created_at TEXT NOT NULL,
                    FOREIGN KEY (note_id) REFERENCES notes(id) ON DELETE CASCADE
                );

                CREATE TABLE IF NOT EXISTS settings (
                    key TEXT PRIMARY KEY,
                    value TEXT NOT NULL
                );
                "#,
            )?;
            self.conn.pragma_update(None, "user_version", 1)?;
        }

        if version < 2 {
            // v2 改动：无（预留未来迁移）
            self.conn.pragma_update(None, "user_version", 2)?;
        }

        Ok(())
    }

    // ===== Notes =====

    pub fn create_note(&self, note: &Note) -> Result<()> {
        self.conn.execute(
            "INSERT INTO notes (id, title, content, color, pinned, created_at, updated_at, deleted_at) \
             VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)",
            params![
                note.id,
                note.title,
                note.content,
                note.color.as_str(),
                note.pinned as i32,
                note.created_at.to_rfc3339(),
                note.updated_at.to_rfc3339(),
                note.deleted_at.map(|d| d.to_rfc3339()),
            ],
        )?;
        Ok(())
    }

    pub fn get_note(&self, id: &str) -> Result<Option<Note>> {
        let note = self
            .conn
            .query_row(
                "SELECT * FROM notes WHERE id = ?1",
                params![id],
                |row| Self::row_to_note(row),
            )
            .optional()?;
        Ok(note)
    }

    pub fn update_note(&self, note: &Note) -> Result<()> {
        self.conn.execute(
            "UPDATE notes SET title=?2, content=?3, color=?4, pinned=?5, \
             updated_at=?6, deleted_at=?7 WHERE id=?1",
            params![
                note.id,
                note.title,
                note.content,
                note.color.as_str(),
                note.pinned as i32,
                note.updated_at.to_rfc3339(),
                note.deleted_at.map(|d| d.to_rfc3339()),
            ],
        )?;
        Ok(())
    }

    pub fn soft_delete_note(&self, id: &str) -> Result<()> {
        let now = Utc::now().to_rfc3339();
        self.conn.execute(
            "UPDATE notes SET deleted_at=?2, updated_at=?2 WHERE id=?1",
            params![id, now],
        )?;
        Ok(())
    }

    pub fn restore_note(&self, id: &str) -> Result<()> {
        let now = Utc::now().to_rfc3339();
        self.conn.execute(
            "UPDATE notes SET deleted_at=NULL, updated_at=?2 WHERE id=?1",
            params![id, now],
        )?;
        Ok(())
    }

    pub fn permanent_delete_note(&self, id: &str) -> Result<()> {
        self.conn
            .execute("DELETE FROM attachments WHERE note_id=?1", params![id])?;
        self.conn.execute("DELETE FROM notes WHERE id=?1", params![id])?;
        Ok(())
    }

    pub fn list_notes(&self, filter: &NoteFilter, sort: NoteSort) -> Result<Vec<Note>> {
        let where_clause = if filter.include_deleted {
            "WHERE 1=1".to_string()
        } else {
            "WHERE deleted_at IS NULL".to_string()
        };

        let mut conditions = Vec::new();
        if let Some(ref q) = filter.query {
            let q = format!("%{}%", q);
            conditions.push(format!("(title LIKE ? OR content LIKE ?)"));
        }
        if filter.pinned_only {
            conditions.push("pinned = 1".to_string());
        }
        if let Some(c) = filter.color {
            conditions.push(format!("color = '{}'", c.as_str()));
        }

        let mut sql = format!("SELECT * FROM notes {} ", where_clause);
        if !conditions.is_empty() {
            sql.push_str("AND ");
            sql.push_str(&conditions.join(" AND "));
        }

        let order = match sort {
            NoteSort::UpdatedDesc => "ORDER BY pinned DESC, updated_at DESC",
            NoteSort::UpdatedAsc => "ORDER BY pinned DESC, updated_at ASC",
            NoteSort::CreatedDesc => "ORDER BY pinned DESC, created_at DESC",
            NoteSort::CreatedAsc => "ORDER BY pinned DESC, created_at ASC",
            NoteSort::TitleAsc => "ORDER BY pinned DESC, title ASC",
            NoteSort::TitleDesc => "ORDER BY pinned DESC, title DESC",
        };
        sql.push_str(order);

        let mut stmt = self.conn.prepare(&sql)?;
        let search_param = filter.query.as_ref().map(|q| format!("%{}%", q));
        let notes: Vec<Note> = match search_param {
            Some(ref q) => stmt
                .query_map(params![q, q], |r| Self::row_to_note(r))?
                .filter_map(|r| r.ok())
                .collect(),
            None => stmt
                .query_map([], |r| Self::row_to_note(r))?
                .filter_map(|r| r.ok())
                .collect(),
        };
        Ok(notes)
    }

    pub fn count_notes(&self, include_deleted: bool) -> Result<i64> {
        let sql = if include_deleted {
            "SELECT COUNT(*) FROM notes"
        } else {
            "SELECT COUNT(*) FROM notes WHERE deleted_at IS NULL"
        };
        let count = self.conn.query_row(sql, [], |r| r.get(0))?;
        Ok(count)
    }

    /// 批量插入（迁移用）
    pub fn batch_insert_notes(&self, notes: &[Note]) -> Result<()> {
        let tx = self.conn.unchecked_transaction()?;
        for note in notes {
            tx.execute(
                "INSERT OR IGNORE INTO notes (id, title, content, color, pinned, created_at, updated_at, deleted_at) \
                 VALUES (?1, ?2, ?3, ?4, ?5, ?6, ?7, ?8)",
                params![
                    note.id,
                    note.title,
                    note.content,
                    note.color.as_str(),
                    note.pinned as i32,
                    note.created_at.to_rfc3339(),
                    note.updated_at.to_rfc3339(),
                    note.deleted_at.map(|d| d.to_rfc3339()),
                ],
            )?;
        }
        tx.commit()?;
        Ok(())
    }

    /// 获取所有笔记（备份用）
    pub fn get_all_notes(&self) -> Result<Vec<Note>> {
        let mut stmt = self.conn.prepare("SELECT * FROM notes ORDER BY updated_at DESC")?;
        let notes = stmt
            .query_map([], |r| Self::row_to_note(r))?
            .filter_map(|r| r.ok())
            .collect();
        Ok(notes)
    }

    fn row_to_note(row: &rusqlite::Row) -> rusqlite::Result<Note> {
        let color_str: String = row.get("color")?;
        let color = match color_str.as_str() {
            "red" => NoteColor::Red,
            "orange" => NoteColor::Orange,
            "yellow" => NoteColor::Yellow,
            "green" => NoteColor::Green,
            "blue" => NoteColor::Blue,
            "purple" => NoteColor::Purple,
            _ => NoteColor::Gray,
        };

        let created_at_str: String = row.get("created_at")?;
        let updated_at_str: String = row.get("updated_at")?;
        let deleted_at_str: Option<String> = row.get("deleted_at")?;

        let created_at = chrono::DateTime::parse_from_rfc3339(&created_at_str)
            .unwrap_or_else(|_| chrono::Utc::now().into())
            .with_timezone(&Utc);
        let updated_at = chrono::DateTime::parse_from_rfc3339(&updated_at_str)
            .unwrap_or_else(|_| chrono::Utc::now().into())
            .with_timezone(&Utc);
        let deleted_at = deleted_at_str.and_then(|s| {
            chrono::DateTime::parse_from_rfc3339(&s)
                .ok()
                .map(|dt| dt.with_timezone(&Utc))
        });

        Ok(Note {
            id: row.get("id")?,
            title: row.get("title")?,
            content: row.get("content")?,
            color,
            pinned: row.get::<_, i32>("pinned")? != 0,
            created_at,
            updated_at,
            deleted_at,
        })
    }

    // ===== Attachments =====

    pub fn add_attachment(&self, att: &Attachment) -> Result<()> {
        self.conn.execute(
            "INSERT INTO attachments (id, note_id, file_path, mime_type, file_size, created_at) \
             VALUES (?1, ?2, ?3, ?4, ?5, ?6)",
            params![
                att.id,
                att.note_id,
                att.file_path,
                att.mime_type,
                att.file_size,
                att.created_at.to_rfc3339(),
            ],
        )?;
        Ok(())
    }

    pub fn get_attachments(&self, note_id: &str) -> Result<Vec<Attachment>> {
        let mut stmt = self
            .conn
            .prepare("SELECT * FROM attachments WHERE note_id=?1 ORDER BY created_at")?;
        let atts = stmt
            .query_map(params![note_id], |row| {
                let created_at_str: String = row.get("created_at")?;
                Ok(Attachment {
                    id: row.get("id")?,
                    note_id: row.get("note_id")?,
                    file_path: row.get("file_path")?,
                    mime_type: row.get("mime_type")?,
                    file_size: row.get("file_size")?,
                    created_at: chrono::DateTime::parse_from_rfc3339(&created_at_str)
                        .unwrap()
                        .with_timezone(&Utc),
                })
            })?
            .filter_map(|r| r.ok())
            .collect();
        Ok(atts)
    }

    pub fn delete_attachment(&self, id: &str) -> Result<()> {
        self.conn
            .execute("DELETE FROM attachments WHERE id=?1", params![id])?;
        Ok(())
    }

    // ===== Settings =====

    pub fn get_setting(&self, key: &str) -> Result<Option<String>> {
        let val = self
            .conn
            .query_row(
                "SELECT value FROM settings WHERE key=?1",
                params![key],
                |r| r.get::<_, String>(0),
            )
            .optional()?;
        Ok(val)
    }

    pub fn set_setting(&self, key: &str, value: &str) -> Result<()> {
        self.conn.execute(
            "INSERT OR REPLACE INTO settings (key, value) VALUES (?1, ?2)",
            params![key, value],
        )?;
        Ok(())
    }

    pub fn load_app_settings(&self) -> Result<AppSettings> {
        let def = AppSettings::default();
        Ok(AppSettings {
            ui_scale: self
                .get_setting("ui_scale")?
                .and_then(|v| v.parse().ok())
                .unwrap_or(def.ui_scale),
            font_scale: self
                .get_setting("font_scale")?
                .and_then(|v| v.parse().ok())
                .unwrap_or(def.font_scale),
            autosave_debounce_ms: self
                .get_setting("autosave_debounce_ms")?
                .and_then(|v| v.parse().ok())
                .unwrap_or(def.autosave_debounce_ms),
            dark_mode: self
                .get_setting("dark_mode")?
                .and_then(|v| v.parse().ok()),
            password_hash: self.get_setting("password_hash")?,
            auto_lock_seconds: self
                .get_setting("auto_lock_seconds")?
                .and_then(|v| v.parse().ok())
                .unwrap_or(def.auto_lock_seconds),
            webdav_url: self.get_setting("webdav_url")?,
            webdav_username: self.get_setting("webdav_username")?,
            webdav_password: self.get_setting("webdav_password")?,
            webdav_sync_enabled: self
                .get_setting("webdav_sync_enabled")?
                .and_then(|v| v.parse().ok())
                .unwrap_or(false),
            language: self
                .get_setting("language")?
                .unwrap_or_else(|| def.language),
        })
    }

    pub fn save_app_settings(&self, s: &AppSettings) -> Result<()> {
        let tx = self.conn.unchecked_transaction()?;
        tx.execute(
            "INSERT OR REPLACE INTO settings (key, value) VALUES (?1, ?2)",
            params!["ui_scale", s.ui_scale.to_string()],
        )?;
        tx.execute(
            "INSERT OR REPLACE INTO settings (key, value) VALUES (?1, ?2)",
            params!["font_scale", s.font_scale.to_string()],
        )?;
        tx.execute(
            "INSERT OR REPLACE INTO settings (key, value) VALUES (?1, ?2)",
            params![
                "autosave_debounce_ms",
                s.autosave_debounce_ms.to_string()
            ],
        )?;
        if let Some(dm) = s.dark_mode {
            tx.execute(
                "INSERT OR REPLACE INTO settings (key, value) VALUES (?1, ?2)",
                params!["dark_mode", dm.to_string()],
            )?;
        }
        if let Some(ref pwd) = s.password_hash {
            tx.execute(
                "INSERT OR REPLACE INTO settings (key, value) VALUES (?1, ?2)",
                params!["password_hash", pwd],
            )?;
        }
        tx.execute(
            "INSERT OR REPLACE INTO settings (key, value) VALUES (?1, ?2)",
            params!["auto_lock_seconds", s.auto_lock_seconds.to_string()],
        )?;
        if let Some(ref u) = s.webdav_url {
            tx.execute(
                "INSERT OR REPLACE INTO settings (key, value) VALUES (?1, ?2)",
                params!["webdav_url", u],
            )?;
        }
        if let Some(ref u) = s.webdav_username {
            tx.execute(
                "INSERT OR REPLACE INTO settings (key, value) VALUES (?1, ?2)",
                params!["webdav_username", u],
            )?;
        }
        if let Some(ref p) = s.webdav_password {
            tx.execute(
                "INSERT OR REPLACE INTO settings (key, value) VALUES (?1, ?2)",
                params!["webdav_password", p],
            )?;
        }
        tx.execute(
            "INSERT OR REPLACE INTO settings (key, value) VALUES (?1, ?2)",
            params!["webdav_sync_enabled", s.webdav_sync_enabled.to_string()],
        )?;
        tx.execute(
            "INSERT OR REPLACE INTO settings (key, value) VALUES (?1, ?2)",
            params!["language", s.language.as_str()],
        )?;
        tx.commit()?;
        Ok(())
    }
}

