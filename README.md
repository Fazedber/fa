# NexusVPN

[![Build](https://github.com/yourusername/nexusvpn/actions/workflows/build.yml/badge.svg)](https://github.com/yourusername/nexusvpn/actions)
[![Go Version](https://img.shields.io/badge/Go-1.22-blue)](https://go.dev)
[![License](https://img.shields.io/badge/License-MIT-green)](LICENSE)

**Cross-platform VPN client** с поддержкой протоколов **VLESS** и **Hysteria2**. 

Использует Go Core в качестве VPN-движка и нативные UI (WinUI 3, SwiftUI, Jetpack Compose) для каждой платформы.

![Architecture](docs/architecture.png)

## 🚀 Быстрый старт

### Скачать готовую сборку

| Платформа | Статус | Скачать |
|-----------|--------|---------|
| Windows 10/11 | ✅ Готово | [NexusVPN-Windows.zip](../../releases) |
| Android 8+ | ✅ Готово | [NexusVPN-Android.zip](../../releases) |
| macOS 14+ | 🚧 В разработке | - |

📖 [Подробная инструкция по установке](INSTALL.md)

---

## ✨ Возможности

- **🔒 Протоколы**: VLESS (XTLS/Reality), Hysteria2 (QUIC)
- **🛡️ Kill Switch**: Автоматическая блокировка трафика при обрыве VPN
- **⚡ Быстрый переподключение**: Seamless roaming при смене WiFi↔LTE
- **🔐 Безопасность**: Zero-Log Architecture, шифрование токенов
- **📊 Статистика**: Real-time трафик (upload/download)

---

## 🏗️ Архитектура

```
┌─────────────────────────────────────────┐
│  UI (WinUI 3 / SwiftUI / Jetpack)       │
│  - Нативный интерфейс                   │
│  - State Machine Streaming              │
└──────────────┬──────────────────────────┘
               │ gRPC (localhost)
┌──────────────▼──────────────────────────┐
│  Go Core (Service)                      │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│  │   API   │ │   App   │ │ Engine  │   │
│  │ (gRPC)  │ │(Orche-  │ │(sing-   │   │
│  │         │ │strator) │ │ box)    │   │
│  └─────────┘ └─────────┘ └─────────┘   │
│  ┌─────────┐ ┌─────────┐ ┌─────────┐   │
│  │  State  │ │ Routing │ │ Storage │   │
│  │ Machine │ │ Policy  │ │(SQLite) │   │
│  └─────────┘ └─────────┘ └─────────┘   │
└─────────────────────────────────────────┘
```

---

## 📦 Установка

### Windows

```powershell
# 1. Скачайте и распакуйте NexusVPN-Windows.zip
# 2. Запустите от имени Администратора:
.\install.bat

# 3. Запустите UI
.\UI\Nebula.exe
```

### Android

```bash
# 1. Включите "Установка из неизвестных источников"
# 2. Установите APK
adb install app-nebula-debug.apk
```

---

## 🔨 Сборка из исходников

### Требования

- **Go** 1.22+
- **Windows**: .NET SDK 8.0+
- **Android**: Android SDK, JDK 17, gomobile
- **macOS**: Xcode 15+

### Скрипты сборки

```bash
# Windows
cd scripts
.\build-windows.ps1 -Brand Nebula

# Android
cd scripts
./build-android.sh

# macOS
cd scripts
./build-macos.sh
```

### Ручная сборка

```bash
# Go Core
cd core
go mod tidy
go build -o nexus-core ./cmd/desktop

# Windows UI
cd apps/windows/NexusVPN
dotnet publish -c Release

# Android UI
cd apps/android
./gradlew assembleDebug
```

---

## 🧪 Тестирование

```bash
cd core

# Unit тесты
go test ./...

# С проверкой гонок
go test -race ./...

# Бенчмарки
go test -bench=. ./...
```

---

## 📁 Структура проекта

```
nexusvpn/
├── core/                    # Go Core (VPN engine)
│   ├── api/                 # gRPC API, Mobile bindings
│   ├── app/                 # Orchestrator, State Machine
│   ├── cmd/desktop/         # Desktop entry point
│   ├── config/              # VLESS/Hysteria2 parsers
│   ├── engine/              # sing-box adapter
│   ├── logging/             # Log redaction (privacy)
│   ├── proto/api/           # Generated protobuf
│   ├── routing/             # Split-tunnel rules
│   ├── state/               # Connection state enum
│   └── storage/             # SQLite persistence
│
├── apps/
│   ├── android/             # Kotlin + Jetpack Compose
│   │   └── app/src/main/...
│   ├── macos/               # Swift + SwiftUI
│   │   ├── NexusVPN/        # Main app
│   │   └── NexusVPNExtension/ # PacketTunnel
│   └── windows/             # C# + WinUI 3
│       └── NexusVPN/        # Main app
│
├── proto/                   # Protobuf contracts
├── scripts/                 # Build scripts
└── docs/                    # Documentation
```

---

## 🔐 Безопасность

### Privacy Features

- **Log Redaction**: IP и UUID автоматически скрываются в логах
- **Local Token Storage**: Токены хранятся в защищённом хранилище
- **No Telemetry**: Никакой отправки данных на сторонние серверы

### Kill Switch

```json
{
  "route": {
    "strict_route": true  // Блокирует трафик при падении VPN
  }
}
```

---

## 🛠️ Технологии

| Компонент | Технология |
|-----------|------------|
| VPN Engine | [sing-box](https://github.com/SagerNet/sing-box) v1.8.8 |
| Протоколы | VLESS, Hysteria2 |
| IPC | gRPC + Protocol Buffers |
| Database | SQLite (modernc.org/sqlite) |
| UI Frameworks | WinUI 3, SwiftUI, Jetpack Compose |

---

## 📝 Лицензия

MIT License - см. [LICENSE](LICENSE)

---

## 🤝 Contributing

1. Fork the project
2. Create your feature branch (`git checkout -b feature/amazing`)
3. Commit changes (`git commit -m 'Add amazing feature'`)
4. Push to branch (`git push origin feature/amazing`)
5. Open a Pull Request

---

## ⚠️ Disclaimer

Это образовательный проект. Используйте на свой страх и риск. 
Автор не несёт ответственности за возможные нарушения законодательства в вашей стране.

---

<p align="center">Made with ❤️ for privacy</p>
