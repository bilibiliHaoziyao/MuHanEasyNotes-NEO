//! AES-GCM 本地加密

use aes_gcm::{
    aead::{Aead, KeyInit},
    Aes256Gcm, Nonce,
};
use rand::RngCore;

use crate::errors::{CoreError, Result};

const SALT_LEN: usize = 16;
const NONCE_LEN: usize = 12;

/// 用密码派生 AES-256 key（简化版：SHA-256 直接截取；生产环境用 Argon2）
fn derive_key(password: &str) -> [u8; 32] {
    use sha2::{Digest, Sha256};
    let mut hasher = Sha256::new();
    hasher.update(password.as_bytes());
    hasher.finalize().into()
}

/// 加密数据：salt(16) + nonce(12) + ciphertext
pub fn encrypt(password: &str, plaintext: &[u8]) -> Result<Vec<u8>> {
    let key = derive_key(password);
    let cipher = Aes256Gcm::new_from_slice(&key).map_err(|e| CoreError::Crypto(e.to_string()))?;

    let mut salt = [0u8; SALT_LEN];
    let mut nonce_bytes = [0u8; NONCE_LEN];
    rand::thread_rng().fill_bytes(&mut salt);
    rand::thread_rng().fill_bytes(&mut nonce_bytes);

    let nonce = Nonce::from_slice(&nonce_bytes);
    let ciphertext = cipher
        .encrypt(nonce, plaintext)
        .map_err(|e| CoreError::Crypto(format!("加密失败: {}", e)))?;

    let mut result = Vec::with_capacity(SALT_LEN + NONCE_LEN + ciphertext.len());
    result.extend_from_slice(&salt);
    result.extend_from_slice(&nonce_bytes);
    result.extend_from_slice(&ciphertext);
    Ok(result)
}

/// 解密数据
pub fn decrypt(password: &str, data: &[u8]) -> Result<Vec<u8>> {
    if data.len() < SALT_LEN + NONCE_LEN + 1 {
        return Err(CoreError::Crypto("数据过短".to_string()));
    }

    let key = derive_key(password);
    let cipher = Aes256Gcm::new_from_slice(&key).map_err(|e| CoreError::Crypto(e.to_string()))?;

    let nonce_bytes = &data[SALT_LEN..SALT_LEN + NONCE_LEN];
    let ciphertext = &data[SALT_LEN + NONCE_LEN..];

    let nonce = Nonce::from_slice(nonce_bytes);
    cipher
        .decrypt(nonce, ciphertext)
        .map_err(|e| CoreError::Crypto(format!("解密失败: {}", e)))
}

/// 简化的密码哈希（用于设置存储）
pub fn hash_password(password: &str) -> String {
    use sha2::{Digest, Sha256};
    let mut hasher = Sha256::new();
    hasher.update(b"MuHanSalt::");
    hasher.update(password.as_bytes());
    let hash = hasher.finalize();
    base64::Engine::encode(&base64::engine::general_purpose::STANDARD, hash.as_slice())
}

pub fn verify_password(password: &str, hash: &str) -> bool {
    hash_password(password) == hash
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_encrypt_decrypt_roundtrip() {
        let plain = b"Hello, MuHan Easy Notes!";
        let key = "my-secret-password";
        let encrypted = encrypt(key, plain).unwrap();
        assert_ne!(encrypted.as_slice(), plain.as_slice());
        let decrypted = decrypt(key, &encrypted).unwrap();
        assert_eq!(decrypted.as_slice(), plain.as_slice());
    }

    #[test]
    fn test_wrong_password_fails() {
        let plain = b"secret data";
        let encrypted = encrypt("correct", plain).unwrap();
        let result = decrypt("wrong", &encrypted);
        assert!(result.is_err());
    }

    #[test]
    fn test_password_hash() {
        let h = hash_password("test123");
        assert!(verify_password("test123", &h));
        assert!(!verify_password("wrong", &h));
    }
}
