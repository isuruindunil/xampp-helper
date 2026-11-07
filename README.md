# XAMPP Helper for macOS

A native, lightweight macOS desktop application designed to easily **Start**, **Stop**, **Restart**, and **Monitor** your local XAMPP services (Apache, MySQL, and ProFTPD).

---

## ✨ Features

- **📊 Live Status Dashboard**: Real-time status indicators (Running, Stopped, Transitioning) for all services with automatic background polling.
- **🚀 Global Controls**: One-click **Start All**, **Stop All**, and **Restart All** services.
- **🎛️ Individual Service Controls**: Start, stop, or reload **Apache**, **MySQL**, and **ProFTPD** independently.
- **⚡ 1-Click Passwordless Sudo Helper**: Avoid entering Touch ID or your admin password every time you start/stop services. Configures a safe, scoped rule in `/etc/sudoers.d/xampp-helper` validated with `visudo`.
- **🔗 Quick Shortcuts**:
  - Open `http://localhost` in default browser
  - Open `http://localhost/phpmyadmin` in default browser
  - Reveal `htdocs` web root directory in Finder
  - Reveal XAMPP root (`/Applications/XAMPP`) in Finder
  - Open and edit `httpd.conf`, `php.ini`, `my.cnf`, and `proftpd.conf`
  - Open XAMPP logs folder
- **📜 Integrated Log Viewer**:
  - Live console output for all executed XAMPP commands and exit codes
  - Live tail of Apache `error_log`
  - Live tail of Apache `access_log`
  - Live tail of `php_error_log`
  - Search/filter, copy to clipboard, and reveal in Finder
- **🎨 Modern macOS Native UI**: Built with Swift 6 and SwiftUI, supporting Dark Mode, Light Mode, and macOS Human Interface Guidelines.

---

## 🚀 Getting Started

### 1. Launch Pre-built App
The standalone `.app` bundle is pre-built in the `dist` directory:

```bash
open "dist/XAMPP Helper.app"
```

To install it into your macOS Applications folder:
```bash
cp -R "dist/XAMPP Helper.app" /Applications/
```

### 2. Run Directly from Source (Developer Mode)
You can launch the app directly using the Swift Package Manager:

```bash
swift run
```

Or open the project in Xcode:
```bash
open Package.swift
```

### 3. Rebuild App Bundle
To rebuild the standalone `.app` bundle and Retina icon:

```bash
./Scripts/build_app.sh
```

---

## 🔒 Passwordless Sudo Setup (Recommended)

macOS requires root permissions to manage Apache (port 80) and ProFTPD (port 21). Without passwordless sudo, macOS prompts for your Touch ID or password on every action.

### Automated Setup (via App)
1. Open **XAMPP Helper**.
2. Click **Configure Now** on the top banner or go to **Settings** → **Passwordless Sudo Configuration**.
3. Click **Enable Passwordless Sudo**.
4. Authenticate once with Touch ID / Password.
5. All future Start/Stop/Restart clicks are instant and silent!

### Manual Setup (Optional)
If you prefer configuring it manually via terminal:

```bash
echo "$USER ALL=(ALL) NOPASSWD: /Applications/XAMPP/xamppfiles/xampp" | sudo tee /etc/sudoers.d/xampp-helper
sudo chmod 0440 /etc/sudoers.d/xampp-helper
```

To remove it at any time:
```bash
sudo rm -f /etc/sudoers.d/xampp-helper
```

---

## 📁 Project Architecture

```
XamppHelper/
├── Package.swift                    # Swift Package definition
├── dist/
│   └── XAMPP Helper.app             # Standalone signed macOS application
├── Sources/
│   └── XamppHelper/
│       ├── App/
│       │   ├── XamppHelperApp.swift # Main SwiftUI App entry point
│       │   └── AppDelegate.swift    # macOS AppKit lifecycle
│       ├── Models/
│       │   ├── ServiceType.swift    # Apache, MySQL, ProFTPD enums & ports
│       │   ├── ServiceStatus.swift  # Running, stopped, transitioning states
│       │   └── LogEntry.swift       # Timestamped log records
│       ├── Services/
│       │   ├── CommandExecutor.swift# Process & elevated AppleScript runner
│       │   ├── XamppManager.swift   # Central ObservableObject controller
│       │   ├── SudoHelper.swift     # Sudoers rule installer & checker
│       │   └── LogWatcher.swift     # Log file tailer
│       ├── Views/
│       │   ├── ContentView.swift    # Root NavigationSplitView
│       │   ├── AppSidebar.swift     # Navigation sidebar
│       │   ├── Dashboard/
│       │   │   ├── DashboardView.swift
│       │   │   ├── ServiceCardView.swift
│       │   │   └── QuickLinksView.swift
│       │   ├── Logs/
│       │   │   └── LogsView.swift
│       │   ├── Settings/
│       │   │   └── SettingsView.swift
│       │   └── Components/
│       │       └── StatusBadge.swift
│       └── Utilities/
│           └── PathConfig.swift     # XAMPP directories & URL paths
├── Tests/
│   └── XamppHelperTests/            # Comprehensive unit tests
├── Scripts/
│   ├── build_app.sh                 # Release build & .app bundle packager
│   └── generate_icon.swift          # CoreGraphics Retina icon generator
└── Resources/
    ├── Info.plist                   # App bundle configuration
    └── AppIcon.icns                 # High-resolution application icon
```

---

## 🧪 Testing

Run automated tests:

```bash
swift test
```

---

## 💻 Requirements

- **macOS**: 14.0 (Sonoma) or later
- **XAMPP**: Traditional macOS XAMPP (`/Applications/XAMPP`)
- **Architecture**: Apple Silicon (arm64) and Intel (x86_64)

---

## 👤 Author

**Isuru Indunil**
- Email: [hello@isuruindunil.me](mailto:hello@isuruindunil.me)
- Website: [https://isuruindunil.me](https://isuruindunil.me)

---

## 📄 License

Copyright © 2026 Isuru Indunil. All rights reserved.

