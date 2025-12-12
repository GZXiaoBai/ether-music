# 🎵 Ether 以太音乐

一款集美学与功能于一体的开源音乐播放器，基于 Flutter 构建，支持 Windows、macOS 和 Android 平台。

![Flutter](https://img.shields.io/badge/Flutter-3.38.4-blue?logo=flutter)
![License](https://img.shields.io/badge/License-MIT-green)
![Platform](https://img.shields.io/badge/Platform-Windows%20%7C%20macOS%20%7C%20Android-lightgrey)

## ✨ 特性

### 🎨 设计语言
- **Glassmorphism 2.0** - 新拟态 + 毛玻璃效果
- **动态取色** - 播放器背景根据专辑封面主色调实时渐变
- **流畅动画** - 60fps/120fps 丝滑过渡效果
- **深色/浅色主题** - 自适应切换

### 🎵 播放功能
- 支持 MP3, FLAC, AAC, OGG 格式
- 无缝切歌 (Gapless Playback)
- 播放队列管理
- 多种播放模式（顺序/循环/单曲/随机）

### 📝 歌词系统
- LRC 格式解析
- 逐行滚动同步
- 翻译歌词支持

### 🔍 音乐发现
- 多源搜索（基于 NeteaseCloudMusicApiEnhanced）
- 热门搜索
- 推荐歌单
- 新歌推荐
- 排行榜

## 🚀 快速开始

### 环境要求

- Flutter 3.10+
- Dart 3.0+
- Node.js 18+ (用于 API 服务)

### 1. 克隆项目

```bash
git clone https://github.com/your-username/ether-music.git
cd ether-music
```

### 2. 安装依赖

```bash
flutter pub get
```

### 3. 启动 API 服务

Ether 使用 [NeteaseCloudMusicApiEnhanced](https://github.com/NeteaseCloudMusicApiEnhanced/api-enhanced) 作为数据源，支持多音源解锁。

#### 本地运行（推荐，启用多音源解锁）

```bash
# 克隆 API 项目
git clone https://github.com/NeteaseCloudMusicApiEnhanced/api-enhanced.git /tmp/netease-api
cd /tmp/netease-api
npm install

# 启动服务（启用多音源解锁）
ENABLE_GENERAL_UNBLOCK=true \
ENABLE_FLAC=true \
SELECT_MAX_BR=true \
UNBLOCK_SOURCE=pyncmd,qq,bodian,migu,kugou,kuwo \
FOLLOW_SOURCE_ORDER=true \
node app.js
```

#### 或使用项目提供的启动脚本

```bash
# 首次需要先安装 API
git clone https://github.com/NeteaseCloudMusicApiEnhanced/api-enhanced.git /tmp/netease-api
cd /tmp/netease-api && npm install

# 使用脚本启动
./scripts/start_api.sh
```

#### 环境变量说明

| 变量名                   | 默认值                             | 说明                         |
| ------------------------ | ---------------------------------- | ---------------------------- |
| `ENABLE_GENERAL_UNBLOCK` | `true`                             | 启用全局解灰（VIP 歌曲解锁） |
| `ENABLE_FLAC`            | `true`                             | 启用无损音质                 |
| `SELECT_MAX_BR`          | `false`                            | 选择最高码率                 |
| `UNBLOCK_SOURCE`         | `pyncmd,qq,bodian,migu,kugou,kuwo` | 音源优先级列表               |
| `FOLLOW_SOURCE_ORDER`    | `true`                             | 按顺序匹配音源               |

#### Docker 方式

```bash
docker run -p 3000:3000 \
  -e ENABLE_GENERAL_UNBLOCK=true \
  -e ENABLE_FLAC=true \
  -e UNBLOCK_SOURCE=pyncmd,qq,bodian,migu,kugou,kuwo \
  moefurina/ncm-api:latest
```

### 4. 运行应用

```bash
# macOS
flutter run -d macos

# Windows
flutter run -d windows

# Android
flutter run -d android

# 或者同时选择设备
flutter run
```

## 📁 项目结构

```
lib/
├── api/                 # API 适配层
│   ├── client.dart      # HTTP 客户端封装
│   ├── endpoints.dart   # API 端点定义
│   ├── models/          # 数据模型
│   └── music_service.dart
├── components/          # 可复用 UI 组件
│   ├── main_layout.dart # 主布局
│   ├── player_bar.dart  # 迷你播放栏
│   └── song_card.dart   # 歌曲卡片
├── core/                # 核心逻辑
│   ├── audio_engine.dart    # 播放器引擎
│   ├── color_extractor.dart # 动态取色
│   └── lyrics_parser.dart   # 歌词解析
├── pages/               # 页面
│   ├── home/            # 首页
│   ├── search/          # 搜索
│   ├── player/          # 全屏播放器
│   └── library/         # 音乐库
├── state/               # 状态管理
│   ├── app_state.dart
│   └── player_state.dart
├── theme/               # 主题系统
│   ├── app_theme.dart
│   └── glassmorphism.dart
├── utils/               # 工具函数
│   └── router.dart      # 路由配置
└── main.dart            # 入口文件
```

## 🛠️ 技术栈

| 类别     | 技术                       |
| -------- | -------------------------- |
| 框架     | Flutter 3.x                |
| 状态管理 | Riverpod                   |
| 路由     | go_router                  |
| 音频播放 | just_audio + audio_service |
| 网络请求 | dio                        |
| 动态取色 | palette_generator          |
| 图片缓存 | cached_network_image       |
| 动画     | flutter_animate            |

## 📝 开发计划

- [x] 项目初始化与基础架构
- [x] 主题系统（Glassmorphism 风格）
- [x] API 客户端与数据模型
- [x] 音频播放引擎
- [x] 歌词解析器
- [x] 动态取色算法
- [x] 首页与推荐
- [x] 搜索功能
- [x] 全屏播放器
- [ ] 本地音乐扫描
- [ ] 歌单管理
- [ ] 用户登录
- [ ] 下载功能
- [ ] 桌面端快捷键
- [ ] Android 后台播放

## 📄 许可证

本项目采用 MIT 许可证 - 查看 [LICENSE](LICENSE) 文件了解详情。

## 🙏 致谢

- [NeteaseCloudMusicApiEnhanced](https://github.com/NeteaseCloudMusicApiEnhanced/api-enhanced) - 提供音乐 API 服务
- [just_audio](https://pub.dev/packages/just_audio) - 强大的音频播放库
- [Flutter](https://flutter.dev) - 优秀的跨平台框架

---

**Made with ❤️ and Flutter**
