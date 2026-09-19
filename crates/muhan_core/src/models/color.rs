use serde::{Deserialize, Serialize};
use std::fmt;

/// 7 种小米便签风格主题色
#[derive(Debug, Clone, Copy, PartialEq, Eq, Hash, Serialize, Deserialize)]
#[serde(rename_all = "snake_case")]
pub enum NoteColor {
    Red,
    Orange,
    Yellow,
    Green,
    Blue,
    Purple,
    Gray,
}

impl NoteColor {
    pub fn as_str(&self) -> &'static str {
        match self {
            NoteColor::Red => "red",
            NoteColor::Orange => "orange",
            NoteColor::Yellow => "yellow",
            NoteColor::Green => "green",
            NoteColor::Blue => "blue",
            NoteColor::Purple => "purple",
            NoteColor::Gray => "gray",
        }
    }

    pub fn all() -> Vec<NoteColor> {
        use NoteColor::*;
        vec![Red, Orange, Yellow, Green, Blue, Purple, Gray]
    }
}

impl fmt::Display for NoteColor {
    fn fmt(&self, f: &mut fmt::Formatter<'_>) -> fmt::Result {
        write!(f, "{}", self.as_str())
    }
}

impl Default for NoteColor {
    fn default() -> Self {
        NoteColor::Yellow
    }
}
