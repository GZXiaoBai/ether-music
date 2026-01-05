---
description: Build Windows Release and Installer
---
# Build Windows Installer

This workflow guides you through building the release version of the Release and creating the Windows Installer.

## Prerequisites
1.  **Flutter SDK** installed and valid `flutter doctor`.
2.  **Inno Setup Compiler** installed (Standard installation).

## Steps

### 1. Build Flutter Release
Run the following command to build the release executable:

```bash
flutter build windows --release
```

// turbo
### 2. Compile Installer
Open `installer/setup.iss` with Inno Setup Compiler.
Click "Compile" (or press Ctrl+F9).

### 3. Verify
The output installer will be located in `installer_output/`.
The filename will be `EtherMusic_Setup_v2.1.3.exe`.

## Installer Features
- **Standard Install**: Upgrades existing installation, preserving user data (playlists, settings).
- **Clean Install**: Select "全新安装" checkbox during installation to wipe all user data and start fresh.
- **Uninstall**: Standard uninstaller included.
