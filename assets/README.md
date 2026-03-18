# Assets for NexusVPN Installers

This directory contains visual assets for the installers.

## Windows (Inno Setup)

### Required files:
- `icon.ico` - Application icon (256x256, 128x128, 64x64, 32x32, 16x16)
- `installer-wizard.bmp` - Wizard sidebar image (164×314 pixels)
- `installer-small.bmp` - Wizard header image (55×55 pixels)

### Creating icons:
1. Create PNG logo in Figma/Photoshop
2. Convert to ICO: https://convertio.co/png-ico/
3. Place in this folder

### Creating wizard images:
- **installer-wizard.bmp**: 164×314, 24-bit color, BMP format
- **installer-small.bmp**: 55×55, 24-bit color, BMP format
- Use dark blue/purple gradient matching the app theme

## macOS

### Required files:
- `icon.icns` - macOS app icon (1024×1024, with all smaller sizes)
- `dmg-background.png` - DMG background (800×400 or 1000×500)

### Creating icons:
```bash
# Convert PNG to ICNS
mkdir MyIcon.iconset
sips -z 16 16     icon.png --out MyIcon.iconset/icon_16x16.png
sips -z 32 32     icon.png --out MyIcon.iconset/icon_16x16@2x.png
sips -z 32 32     icon.png --out MyIcon.iconset/icon_32x32.png
sips -z 64 64     icon.png --out MyIcon.iconset/icon_32x32@2x.png
sips -z 128 128   icon.png --out MyIcon.iconset/icon_128x128.png
sips -z 256 256   icon.png --out MyIcon.iconset/icon_128x128@2x.png
sips -z 256 256   icon.png --out MyIcon.iconset/icon_256x256.png
sips -z 512 512   icon.png --out MyIcon.iconset/icon_256x256@2x.png
sips -z 512 512   icon.png --out MyIcon.iconset/icon_512x512.png
sips -z 1024 1024 icon.png --out MyIcon.iconset/icon_512x512@2x.png
iconutil -c icns MyIcon.iconset
```

### DMG background:
- Create in Figma: 800×400 pixels
- Show: App icon + arrow → Applications folder icon
- Use dark theme (matches the app)

## Brand Variants

You can create separate assets for each brand:
- `icon-nebula.ico`
- `icon-pepewatafa.ico`

Then reference them in the build scripts.

## Default Placeholder

If no assets provided, installers will use default Windows/macOS icons.
