# 慕寒易笔记 · MuHanEasyNotes NEO

> 一款 **跨平台** 的轻量本地笔记应用，基于 **Flutter + Rust** 全新重写。  
> 为桌面与 Web 而生，离线优先，开源 MIT。

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.24%2B-blue?logo=flutter)
![Rust](https://img.shields.io/badge/Rust-1.75%2B-orange?logo=rust)
![Platforms](https://img.shields.io/badge/Platforms-Windows%20%7C%20macOS%20%7C%20Linux%20%7C%20Web-2ea44f)
![License](https://img.shields.io/badge/License-MIT-yellow)
![Version](https://img.shields.io/badge/Version-2.0.0-purple)

**[下载安装](https://github.com/bilibiliHaoziyao/MuHanEasyNotes-NEO/releases)** · **[报告问题](https://github.com/bilibiliHaoziyao/MuHanEasyNotes-NEO/issues)** · **[讨论](https://github.com/bilibiliHaoziyao/MuHanEasyNotes-NEO/discussions)**

</div>

---

## ✨ 特性

| 特性 | 说明 |
|------|------|
| 🖥️ **四平台原生 UI** | Windows Fluent Design、macOS HIG 三栏、Linux GTK 混合、Web 响应式 PWA |
| 🦀 **Rust 核心层** | SQLite 存储、AES-GCM 加密、WebDAV 同步，高性能零 GC 开销 |
| 🔄 **迁移向导** | 首次启动自动检测旧版数据，5 步完成迁移到 v2 |
| 🔐 **本地密码锁** | 可选密码保护，自动锁定超时 |
| ☁️ **WebDAV 同步** | 支持 Nextcloud / 坚果云 / OwnCloud / 百度网盘 |
| 🏷️ **7 种主题色** | 小米便签风格：红橙黄绿蓝紫灰 |
| 📌 **置顶 / 回收站** | 置顶优先展示，软删除可恢复 |
| 💡 **智能标题** | 未填写时自动取正文第一句话 |
| ⚡ **自动保存** | 防抖 1.2s，编辑即保存 |
| 🔍 **全文搜索** | 按标题和内容搜索 |
| 📦 **JSON 备份** | 导入导出兼容 v1.x 旧格式 |
| 🎨 **深浅色模式** | 跟随系统或手动切换 |

> ⚠️ **语音输入已移除**：v2 不再支持语音功能。旧版 Android Wear OS 请通过 JSON 备份文件迁移。

---

## 📦 下载

### 稳定版 v2.0.0

| 平台 | 文件 | 安装方式 |
|------|------|---------|
| Windows | [.exe](https://github.com/bilibiliHaoziyao/MuHanEasyNotes-NEO/releases/download/v2.0.0/muhan_easy_notes_neo_windows.exe) | 直接运行 |
| macOS | [.dmg](https://github.com/bilibiliHaoziyao/MuHanEasyNotes-NEO/releases/download/v2.0.0/muhan_easy_notes_neo_macos.dmg) | 拖入 Applications |
| Linux | [.tar.gz](https://github.com/bilibiliHaoziyao/MuHanEasyNotes-NEO/releases/download/v2.0.0/muhan_easy_notes_neo_linux_x64.tar.gz) | 解压运行 |
| Web | [.zip](https://github.com/bilibiliHaoziyao/MuHanEasyNotes-NEO/releases/download/v2.0.0/muhan_easy_notes_neo_web.zip) | 解压后静态托管 |
| Android | [.apk](https://github.com/bilibiliHaoziyao/MuHanEasyNotes-NEO/releases/download/v2.0.0/muhan_easy_notes_neo.apk) | 安装到设备 |

> 所有资产也可以在 **[GitHub Releases](https://github.com/bilibiliHaoziyao/MuHanEasyNotes-NEO/releases/tag/v2.0.0)** 下载。

---

## 🏗️ 技术栈

```
┌─────────────────────────────────────────────┐
│  Flutter 3.24+  (UI / 平台适配)             │
│  ├── windows_fluent.dart                    │
│  ├── macos_hig.dart                         │
│  ├── linux_gtk.dart                         │
│  └── web_pwa.dart                           │
├─────────────────────────────────────────────┤
│  flutter_rust_bridge 2.10  (FFI 桥接)       │
├─────────────────────────────────────────────┤
│  Rust 1.75+  (核心业务逻辑)                 │
│  ├── rusqlite (bundled SQLite)              │
│  ├── aes-gcm + sha2 (加密)                   │
│  ├── reqwest (WebDAV HTTP)                   │
│  ├── serde_json (序列化)                     │
│  └── uuid (ID 生成)                          │
└─────────────────────────────────────────────┘
```

## 🗂️ 项目结构

```
muhan_easy_notes_neo/
├── crates/muhan_core/          # Rust 核心库
│   └── src/
│       ├── api.rs              # flutter_rust_bridge 暴露的 API
│       ├── db/                 # SQLite 数据访问
│       ├── models/             # Note / Settings / Color
│       ├── backup/             # JSON 导入导出 + v1 迁移
│       ├── sync/               # WebDAV 客户端
│       ├── crypto/             # AES-256-GCM
│       └── platform/           # 跨平台路径
├── lib/                        # Flutter UI
│   ├── main.dart               # 入口 + 平台分发
│   ├── core/                   # Theme / Providers / Bridge
│   ├── platforms/              # Windows / macOS / Linux / Web UI
│   └── ui/
│       ├── shared/             # 共享组件
│       └── wizard/             # 迁移向导
├── android/                    # Android 平台
├── windows/                    # Windows 平台
├── macos/                      # macOS 平台
├── linux/                      # Linux 平台
├── web/                        # Web 平台
├── legacy/android/             # v1.x Kotlin 旧代码（归档）
└── .github/workflows/          # CI + Release
```

---

## 🛠️ 开发

### 前置条件

| 工具 | 版本 |
|------|------|
| Flutter | ≥ 3.24 |
| Rust | ≥ 1.75 |
| Android SDK | 35 (for APK) |

### 构建

```bash
# 1. 克隆
git clone https://github.com/bilibiliHaoziyao/MuHanEasyNotes-NEO.git
cd MuHanEasyNotes-NEO

# 2. 安装 Flutter 依赖
flutter pub get

# 3. 构建（任选平台）
flutter build windows --release
flutter build macos --release
flutter build linux --release
flutter build web --release
flutter build apk --release

# 4. Rust 单元测试
cd crates/muhan_core && cargo test && cd ../..
```

### 本地运行

```bash
flutter run -d windows
flutter run -d macos
flutter run -d linux
flutter run -d chrome     # Web
flutter run -d android
```

### flutter_rust_bridge 代码生成

当修改 `crates/muhan_core/src/api.rs` 后：

```bash
dart run flutter_rust_bridge_codegen generate
```

---

## 🔄 从 v1.x 迁移

1. **旧版导出**：在旧版慕寒轻松记 v1.x 中，使用「备份」功能导出 JSON
2. **安装新版**：安装慕寒易笔记 v2.0.0
3. **运行向导**：首次启动自动弹出迁移向导
   - 选择 **自动检测** 或 **手动选择文件**
   - 预览待迁移笔记
   - 点击 **开始迁移**
4. **完成**：数据导入完成，旧文件不删除

> 迁移过程中随时可以取消，不会破坏现有数据。

---

## 🧪 CI / CD

GitHub Actions 自动处理：

| Workflow | 触发条件 | 产物 |
|----------|---------|------|
| **CI** | push / PR → `main` | `cargo test` + `flutter analyze` + `flutter test` |
| **Release** | push tag `v*` | Windows exe, macOS dmg, Linux tar.gz, Web zip, Android apk |

---

## 🤝 贡献

欢迎贡献！请：

1. Fork 本仓库
2. 创建特性分支 (`git checkout -b feat/amazing-feature`)
3. 提交修改 (`git commit -m 'feat: add amazing feature'`)
4. 推送分支 (`git push origin feat/amazing-feature`)
5. 创建 Pull Request

---

## 📜 许可证

本项目基于 **MIT License** 开源。详见 [LICENSE](./LICENSE)。

```
Copyright (c) 2026 MuHan

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED.
```

---

## 🙏 致谢

- [Flutter](https://flutter.dev/) — 跨平台 UI 框架
- [flutter_rust_bridge](https://pub.dev/packages/flutter_rust_bridge) — Dart ↔ Rust FFI
- [rusqlite](https://crates.io/crates/rusqlite) — 纯 Rust SQLite
- [AES-GCM](https://crates.io/crates/aes-gcm) — 加密

---

<p align="center">
  <a href="https://github.com/bilibiliHaoziyao/MuHanEasyNotes-NEO"><strong>⭐ 如果这个项目对你有帮助，请点个 Star！</strong></a>
</p>
