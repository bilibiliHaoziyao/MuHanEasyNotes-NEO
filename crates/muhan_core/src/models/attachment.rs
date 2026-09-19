use chrono::{DateTime, Utc};
use serde::{Deserialize, Serialize};

#[derive(Debug, Clone, PartialEq, Serialize, Deserialize)]
pub struct Attachment {
    pub id: String,
    pub note_id: String,
    pub file_path: String,
    pub mime_type: String,
    pub file_size: i64,
    pub created_at: DateTime<Utc>,
}
