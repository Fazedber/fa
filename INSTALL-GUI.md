# 📦 Графические установщики NexusVPN

## Быстрый старт

### Windows

#### Требования
- Windows 10/11 (64-bit)
- Права Администратора

#### Установка
1. Скачайте `NebulaVPN-1.0.0-Setup.exe` из [Releases](../../releases)
2. Двойной клик по файлу
3. Следуйте инструкциям установщика:
   - Выберите язык
   - Примите лицензию
   - Выберите папку установки
   - Дождитесь завершения
   - Нажмите "Finish" (автоматически запустит приложение)

#### Скриншоты процесса
```
┌─────────────────────────────────┐
│  Welcome to Nebula VPN Setup   │
│                                 │
│  [Next >]  [Cancel]            │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│  Select Destination Location   │
│  C:\Program Files\NebulaVPN    │
│                                 │
│  [Browse...]  [Next >]         │
└─────────────────────────────────┘

┌─────────────────────────────────┐
│  Installing...                 │
│  ████████████░░░░  75%         │
│                                 │
│  Installing service...         │
└─────────────────────────────────┘
```

#### Удаление
1. Пуск → Параметры → Приложения
2. Найдите "Nebula VPN"
3. Нажмите "Удалить"

Или через Панель управления:
```powershell
# Командная строка (Admin)
sc stop NebulaVPN
sc delete NebulaVPN
rmdir /S "%ProgramFiles%\NebulaVPN"
```

---

### macOS

#### Требования
- macOS 14+ (Sonoma)
- Apple Silicon или Intel

#### Установка
1. Скачайте `NebulaVPN-1.0.0-macOS.dmg` из [Releases](../../releases)
2. Двойной клик по DMG файлу
3. В окне установщика перетащите `NexusVPN.app` в папку `Applications`:

```
┌─────────────────────────────────────────────┐
│                                             │
│    [NexusVPN.app] ──────→ [Applications]   │
│          ⬇                                   │
│      Drag to install                        │
│                                             │
└─────────────────────────────────────────────┘
```

4. Откройте `Applications` и запустите `NexusVPN`
5. **Важно**: При первом запуске появится предупреждение
   - Нажмите `Отмена`
   - Откройте `Системные настройки` → `Конфиденциальность и безопасность`
   - Нажмите `Всё равно открыть`

#### Предоставление разрешений
При первом подключении VPN:
1. Появится запрос на установку "System Extension"
2. Откройте `Системные настройки` → `Конфиденциальность и безопасность`
3. Нажмите `Разрешить` рядом с сообщением о расширении
4. Перезапустите приложение

#### Удаление
```bash
# Полное удаление
sudo rm -rf /Applications/NexusVPN.app
sudo rm -rf ~/Library/Application\ Support/NexusVPN
sudo rm -rf ~/Library/Preferences/com.nexusvpn.app.plist
```

---

### Android

#### Требования
- Android 8.0+ (API 26+)
- 50 MB свободного места

#### Установка
1. Скачайте `app-nebula-debug.apk`
2. Разрешите установку из неизвестных источников:
   - **Android 8-10**: Настройки → Безопасность → Неизвестные источники
   - **Android 11+**: При установке появится запрос → Разрешить
3. Откройте APK файл
4. Нажмите "Установить"
5. Предоставьте разрешение VPN при первом запуске

#### Удаление
1. Настройки → Приложения
2. Найдите "Nebula VPN"
3. Нажмите "Удалить"

---

## Решение проблем

### Windows

#### "Windows protected your PC"
**Причина**: Приложение не подписано сертификатом

**Решение**:
1. Нажмите "More info"
2. Нажмите "Run anyway"

#### "Service failed to start"
**Причина**: Антивирус блокирует установку службы

**Решение**:
```powershell
# Проверьте статус службы
sc query NebulaVPN

# Запустите вручную
sc start NebulaVPN

# Или переустановите
& "C:\Program Files\NebulaVPN\install.bat"
```

### macOS

#### "App is damaged and can't be opened"
**Причина**: Gatekeeper блокирует неподписанное приложение

**Решение**:
```bash
# Удалите quarantine атрибут
xattr -cr /Applications/NexusVPN.app
```

#### "System Extension blocked"
**Причина**: macOS не разрешил расширение

**Решение**:
1. Системные настройки → Конфиденциальность и безопасность
2. Нажмите "Разрешить" рядом с сообщением о NexusVPN
3. Перезапустите компьютер

### Android

#### "App not installed"
**Причина**: Конфликт версий или недостаточно места

**Решение**:
1. Удалите старую версию
2. Очистите кэш
3. Попробуйте установить снова

---

## Верификация установки

### Windows
```powershell
# Служба должна быть запущена
Get-Service NebulaVPN

# Порт должен быть открыт
Test-NetConnection -ComputerName localhost -Port 50051

# Процесс должен существовать
Get-Process nexus-core
```

### macOS
```bash
# Расширение должно быть загружено
systemextensionsctl list

# Процесс должен существовать
pgrep -l nexus-core
```

### Android
```bash
# Через adb
adb shell ps | grep nexus
adb shell netstat | grep 50051
```

---

## Альтернативные методы установки

### Windows (Chocolatey)
```powershell
# Скоро будет доступно
choco install nexusvpn
```

### macOS (Homebrew)
```bash
# Скоро будет доступно
brew install --cask nexusvpn
```

### Android (F-Droid)
Скоро в репозитории F-Droid

---

## Получить помощь

- **GitHub Issues**: [Сообщить о проблеме](../../issues)
- **Telegram**: [@nexusvpn_support](https://t.me/nexusvpn_support)
- **Email**: support@nexusvpn.app
