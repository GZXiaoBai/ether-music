# Changelog

## [2.1.4] - 2026-01-05

### 🚀 CI/CD & Installer
- **Windows Installer**: Introduced Inno Setup script to generate `.exe` installer.
- **Auto Build**: Configured GitHub Actions to automatically build and release Windows installer on new tags.
- **Install Options**: Installer now supports "Fresh Install" (data wipe) separately from "Upgrade".

### ✨ Improvements
- **Settings**: Added "Check for Updates" button in Settings > About.
- **UI**: Added dynamic version display in Settings.



## [2.1.3] - 2026-01-05

### ✨ New Features
- **Auto Update**: Added automatic update checking on startup and a manual check button in Settings.
- **Android UI Optimization**: Refactored the player page for Android devices featuring a new vertical layout and gesture-supported lyrics view.

### 🐛 Bug Fixes
- **Windows Fonts**: Fixed blurry text rendering on Windows by enforcing "Microsoft YaHei" as the fallback font.
