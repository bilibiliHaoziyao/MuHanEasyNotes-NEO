//! WebDAV 同步模块

use crate::backup::BackupFile;
use crate::errors::{CoreError, Result};
use chrono::Utc;
use percent_encoding::{utf8_percent_encode, NON_ALPHANUMERIC};
use reqwest::header::{HeaderMap, HeaderValue};
use serde::{Deserialize, Serialize};
use std::path::Path;
use url::Url;

#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct WebDavConfig {
    pub url: String,
    pub username: String,
    pub password: String,
    #[serde(default)]
    pub remote_path: String,
}

impl WebDavConfig {
    pub fn normalize_url(&self) -> Result<String> {
        let mut url = Url::parse(&self.url)
            .map_err(|e| CoreError::WebDav(format!("无效的 URL: {}", e)))?;
        let path = url.path().trim_end_matches('/').to_string();
        if !path.is_empty() {
            url.set_path(&(path.to_string() + "/"));
        }
        Ok(url.to_string())
    }
}

#[derive(Debug)]
pub struct WebDavClient {
    client: reqwest::Client,
    config: WebDavConfig,
}

impl WebDavClient {
    pub fn new(config: WebDavConfig) -> Result<Self> {
        let mut headers = HeaderMap::new();
        headers.insert("Accept", HeaderValue::from_static("application/xml, text/xml"));
        let client = reqwest::Client::builder()
            .default_headers(headers)
            .timeout(std::time::Duration::from_secs(30))
            .build()?;
        Ok(Self { client, config })
    }

    fn auth_header(&self) -> String {
        let auth = format!("{}:{}", self.config.username, self.config.password);
        format!(
            "Basic {}",
            base64::Engine::encode(&base64::engine::general_purpose::STANDARD, auth.as_bytes())
        )
    }

    fn build_url(&self, path: &str) -> Result<String> {
        let base = self.config.normalize_url()?;
        let mut full = Url::parse(&base).unwrap();
        let remote = self.config.remote_path.trim_start_matches('/');
        let encoded_path: String = utf8_percent_encode(
            &format!("{}/{}", remote, path.trim_start_matches('/')),
            NON_ALPHANUMERIC,
        )
        .collect();
        full.set_path(&format!(
            "{}/{}",
            full.path().trim_end_matches('/'),
            encoded_path.trim_start_matches('/')
        ));
        Ok(full.to_string())
    }

    fn propfind_request(&self, url: &str, depth: u8) -> reqwest::RequestBuilder {
        let method = reqwest::Method::from_bytes(b"PROPFIND").unwrap();
        self.client
            .request(method, url)
            .header("Authorization", self.auth_header())
            .header("Depth", depth.to_string())
    }

    fn mkcol_request(&self, url: &str) -> reqwest::RequestBuilder {
        let method = reqwest::Method::from_bytes(b"MKCOL").unwrap();
        self.client
            .request(method, url)
            .header("Authorization", self.auth_header())
    }

    /// 测试连接
    pub async fn test_connection(&self) -> Result<()> {
        let url = self.build_url("")?;
        let resp = self
            .propfind_request(&url, 0)
            .send()
            .await
            .map_err(|e| CoreError::WebDav(format!("连接失败: {}", e)))?;

        let status = resp.status();
        if !status.is_success() {
            return Err(CoreError::WebDav(format!(
                "连接失败 HTTP {}: {}",
                status,
                resp.text().await.unwrap_or_default()
            )));
        }
        Ok(())
    }

    /// 上传备份 JSON
    pub async fn upload_backup<P: AsRef<Path>>(&self, local_path: P) -> Result<String> {
        let file_name = local_path
            .as_ref()
            .file_name()
            .and_then(|s| s.to_str())
            .ok_or_else(|| CoreError::InvalidInput("无效的文件路径".to_string()))?;

        let content = tokio::fs::read(local_path.as_ref())
            .await
            .map_err(|e| CoreError::Io(e))?;

        let remote_path = format!("backups/{}", file_name);
        let url = self.build_url(&remote_path)?;

        // 确保 backups 目录存在
        let _ = self.mkdir("backups").await;

        let resp = self
            .client
            .put(&url)
            .header("Authorization", self.auth_header())
            .header("Content-Type", "application/json")
            .body(content)
            .send()
            .await
            .map_err(|e| CoreError::WebDav(format!("上传失败: {}", e)))?;

        if !resp.status().is_success() {
            return Err(CoreError::WebDav(format!(
                "上传失败 HTTP {}",
                resp.status()
            )));
        }
        Ok(remote_path)
    }

    /// 下载备份 JSON
    pub async fn download_backup(&self, remote_path: &str) -> Result<BackupFile> {
        let url = self.build_url(remote_path)?;
        let resp = self
            .client
            .get(&url)
            .header("Authorization", self.auth_header())
            .send()
            .await
            .map_err(|e| CoreError::WebDav(format!("下载失败: {}", e)))?;

        if !resp.status().is_success() {
            return Err(CoreError::WebDav(format!(
                "下载失败 HTTP {}",
                resp.status()
            )));
        }

        let body = resp.text().await.map_err(|e: reqwest::Error| CoreError::WebDav(e.to_string()))?;
        let backup: BackupFile =
            serde_json::from_str(&body).map_err(|e| CoreError::WebDav(format!("解析失败: {}", e)))?;
        Ok(backup)
    }

    /// 列出远程备份文件
    pub async fn list_backups(&self) -> Result<Vec<String>> {
        let url = self.build_url("backups/")?;
        let resp = self
            .propfind_request(&url, 1)
            .send()
            .await
            .map_err(|e| CoreError::WebDav(format!("列出失败: {}", e)))?;

        let body = resp.text().await.map_err(|e: reqwest::Error| CoreError::WebDav(e.to_string()))?;
        Ok(parse_propfind_response(&body))
    }

    async fn mkdir(&self, name: &str) -> Result<()> {
        let url = self.build_url(&format!("{}/", name))?;
        let resp = self
            .mkcol_request(&url)
            .send()
            .await
            .map_err(|e| CoreError::WebDav(format!("创建目录失败: {}", e)))?;
        // 201 Created 或 405 已存在都算成功
        let status = resp.status().as_u16();
        if status == 201 || status == 405 {
            Ok(())
        } else {
            Err(CoreError::WebDav(format!(
                "创建目录失败 HTTP {}",
                resp.status()
            )))
        }
    }
}

fn parse_propfind_response(xml: &str) -> Vec<String> {
    let mut results = Vec::new();
    // 简单解析：找所有 href 中的路径
    for cap in regex::Regex::new(r"<href>([^<]+)</href>")
        .unwrap()
        .captures_iter(xml)
    {
        if let Some(path) = cap.get(1) {
            let p = path.as_str();
            if p.ends_with(".json") {
                results.push(p.to_string());
            }
        }
    }
    results
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_config_normalize() {
        let cfg = WebDavConfig {
            url: "https://dav.example.com:5005/remote.php/dav/files/user".to_string(),
            username: "u".into(),
            password: "p".into(),
            remote_path: "MuHan".into(),
        };
        let url = cfg.normalize_url().unwrap();
        assert!(url.ends_with('/'));
    }
}
