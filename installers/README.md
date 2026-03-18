# 📦 NexusVPN Installers

Здесь находятся установщики для всех платформ.

## 📂 Структура

```
installers/
├── 📂 windows/          # Windows установщики (.exe)
├── 📂 macos/            # macOS установщики (.dmg)
├── 📂 android/          # Android установщики (.apk)
└── 📄 README.md         # Этот файл
```

## 🚀 Быстрый старт

Выбери свою платформу и следуй инструкции:

| Платформа | Папка | Готовый файл |
|-----------|-------|--------------|
| Windows | `windows/` | `NebulaVPN-Setup.exe` |
| macOS | `macos/` | `NebulaVPN-macOS.dmg` |
| Android | `android/` | `app-nebula.apk` |

---

## 🪟 Windows

### Где взять установщик?
**Файл:** `windows/NebulaVPN-Setup.exe`

### Как установить?
1. Открой папку `windows/`
2. Запусти `NebulaVPN-Setup.exe`
3. Следуй инструкциям мастера
4. Готово!

### Если файла нет - как собрать?
```powershell
# 1. Установи Inno Setup: https://jrsoftware.org/isdl.php
# 2. Запусти PowerShell от Администратора
# 3. Выполни:
cd windows
.\build-installer-windows.ps1

# 4. Готовый файл появится в:
# ..\dist\windows\NebulaVPN-*-Setup.exe
```

Подробнее: [windows/README.md](windows/README.md)

---

## 🍎 macOS

### Где взять установщик?
**Файл:** `macos/NebulaVPN-macOS.dmg`

### Как установить?
1. Открой папку `macos/`
2. Открой `NebulaVPN-macOS.dmg`
3. Перетащи `NexusVPN.app` в `Applications`
4. Готово!

### Если файла нет - как собрать?
```bash
# 1. Нужен macOS с Xcode
# 2. Выполни:
cd macos
./build-installer-macos.sh

# 3. Готовый файл появится в:
# ../dist/macos/NebulaVPN-*-macOS.dmg
```

Подробнее: [macos/README.md](macos/README.md)

---

## 🤖 Android

### Где взять установщик?
**Файл:** `android/app-nebula.apk`

### Как установить?
1. Передай файл `app-nebula.apk` на телефон
2. Открой файл на телефоне
3. Разреши установку из неизвестных источников
4. Нажми "Установить"
5. Готово!

### Если файла нет - как собрать?
```bash
# 1. Установи Android Studio и Go
# 2. Выполни:
cd android
./build-android.sh

# 3. Готовый файл появится в:
# ../dist/android/nebula/app-nebula-debug.apk
```

Подробнее: [android/README.md](android/README.md)

---

## ❓ Проблемы?

Если что-то не работает:
1. Проверь [INSTALL-GUI.md](../INSTALL-GUI.md) - там подробные инструкции
2. Создай Issue на GitHub

---

## 🔨 Для разработчиков

Все скрипты сборки находятся в папках:
- `windows/build-*.ps1` - PowerShell скрипты
- `macos/build-*.sh` - Bash скрипты
- `android/build-*.sh` - Bash скрипты

Чтобы собрать ВСЕ установщики сразу:
```bash
cd ..
./scripts/build-all-installers.sh
```
