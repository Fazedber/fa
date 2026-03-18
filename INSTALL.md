# Установка NexusVPN

## Готовые сборки (Releases)

Скачайте последнюю версию из [Releases](../../releases):

| Платформа | Файл | Размер |
|-----------|------|--------|
| Windows | `NexusVPN-Windows.zip` | ~15 MB |
| Android | `NexusVPN-Android.zip` | ~25 MB |
| macOS | `NexusVPN-macOS.dmg` | ~20 MB |

---

## Windows

### Требования
- Windows 10/11 (64-bit)
- Права Администратора

### Установка

1. Скачайте `NexusVPN-Windows.zip` и распакуйте
2. Запустите `install.bat` от имени Администратора:
   ```powershell
   # PowerShell (Administrator)
   .\install.bat
   ```
3. Сервис будет установлен и запущен автоматически
4. Запустите UI: `UI\Nebula.exe` или `UI\PepeWatafa.exe`

### Удаление
```powershell
.\uninstall.bat
```

---

## Android

### Требования
- Android 8.0+ (API 26+)
- Разрешение "Установка из неизвестных источников"

### Установка

1. Скачайте APK для вашего бренда:
   - `app-nebula-debug.apk` или `app-pepewatafa-debug.apk`

2. Установите через adb:
   ```bash
   adb install app-nebula-debug.apk
   ```

3. Или скопируйте на телефон и установите через файловый менеджер

### Примечание
Для Android 10+ может потребоваться разрешение на VPN в настройках.

---

## macOS

### Требования
- macOS 14.2+ (Sonoma)
- Apple Silicon или Intel

### Установка

1. Скачайте `NexusVPN-macOS.dmg`
2. Откройте DMG и перетащите `NexusVPN.app` в `Applications`
3. **Важно**: Первый запуск требует одобрения в:
   ```
   System Settings → Privacy & Security → Open Anyway
   ```

### Разрешения
При первом подключении macOS попросит разрешить:
- VPN Configuration (NetworkExtension)
- System Extension

---

## Сборка из исходников

### Windows
```powershell
# Требуется: Go 1.22+, .NET SDK 8.0
cd scripts
.\build-windows.ps1 -Brand Nebula
```

### Android
```bash
# Требуется: Go 1.22+, Android SDK, gomobile
cd scripts
export ANDROID_SDK_ROOT=/path/to/android-sdk
./build-android.sh
```

### macOS
```bash
# Требуется: Go 1.22+, Xcode 15+, gomobile
cd scripts
./build-macos.sh
```

---

## Проверка установки

### Windows
```powershell
# Проверка сервиса
sc query Nebula

# Проверка порта
netstat -an | findstr 50051
```

### Android
```bash
# Проверка через adb
adb shell ps | grep nexus
adb logcat -s "VPN" "GoLog"
```

### macOS
```bash
# Проверка расширения
systemextensionsctl list

# Логи
log stream --predicate 'process == "NexusVPN"'
```

---

## Устранение неполадок

### "Cannot connect to core service"
- Windows: Проверьте что сервис запущен: `sc start Nebula`
- Проверьте порт 50051: `netstat -ano | findstr 50051`

### "Permission denied" на Android
- Проверьте разрешение VPN в Settings → Apps → NexusVPN

### "System Extension blocked" на macOS
- System Settings → Privacy & Security → Разрешить расширение

---

## Разработка

### Структура проекта
```
nexusvpn/
├── core/           # Go core (VPN engine)
├── apps/
│   ├── android/    # Kotlin/Jetpack Compose
│   ├── windows/    # C#/WinUI 3
│   └── macos/      # Swift/SwiftUI
└── proto/          # gRPC contracts
```

### Локальная разработка
```bash
# Запуск core
cd core
go run ./cmd/desktop

# Тесты
go test ./...
```

---

## Лицензия
MIT License - см. [LICENSE](LICENSE)
