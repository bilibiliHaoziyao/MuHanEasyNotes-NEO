use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};
use uuid::Uuid;

use super::color::NoteColor;

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Note {
    pub id: String,
    pub title: String,
    pub content: String,
    pub color: NoteColor,
    pub pinned: bool,
    pub created_at: DateTime<Utc>,
    pub updated_at: DateTime<Utc>,
    pub deleted_at: Option<DateTime<Utc>>,
}

impl Note {
    pub fn new(title: String, content: String) -> Self {
        let now = Utc::now();
        let title = if title.is_empty() {
            Self::auto_title(&content)
        } else {
            title
        };
        Self {
            id: Uuid::new_v4().to_string(),
            title,
            content,
            color: NoteColor::default(),
            pinned: false,
            created_at: now,
            updated_at: now,
            deleted_at: None,
        }
    }

    /// 智能标题：取正文第一句话（到 \n 或 。或 . 或 ，或 , 或 15 字符）
    pub fn auto_title(content: &str) -> String {
        let trimmed = content.trim();
        if trimmed.is_empty() {
            return "无标题".to_string();
        }
        let chars: Vec<char> = trimmed.chars().collect();
        let mut end = chars.len();
        for (i, &c) in chars.iter().enumerate() {
            if i >= 15 {
                end = 15;
                break;
            }
            if matches!(c, '\n' | '。' | '.' | '，' | ',' | '！' | '!' | '？' | '?' | '；' | ';') {
                end = i;
                break;
            }
        }
        chars[..end]
            .iter()
            .collect::<String>()
            .trim()
            .to_string()
    }

    pub fn soft_delete(&mut self) {
        self.deleted_at = Some(Utc::now());
        self.updated_at = Utc::now();
    }

    pub fn restore(&mut self) {
        self.deleted_at = None;
        self.updated_at = Utc::now();
    }
}

/// 笔记筛选条件
#[derive(Debug, Clone, Default)]
pub struct NoteFilter {
    pub query: Option<String>,
    pub include_deleted: bool,
    pub pinned_only: bool,
    pub color: Option<NoteColor>,
}

/// 笔记排序
#[derive(Debug, Clone, Copy, PartialEq, Eq)]
pub enum NoteSort {
    UpdatedDesc,
    UpdatedAsc,
    CreatedDesc,
    CreatedAsc,
    TitleAsc,
    TitleDesc,
}

impl Default for NoteSort {
    fn default() -> Self {
        NoteSort::UpdatedDesc
    }
}
