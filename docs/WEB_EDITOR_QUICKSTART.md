# Web Dashboard Editor - Quick Start Guide

## 🎉 What's New?

Your ESP32-S3 dashboard can now be edited **directly in your browser** - no more recompiling and reflashing!

## 🚀 How to Use

###  1. Access the Editor

1. Open your dashboard: `https://kc.local`
2. Click **"Code Editor"** in the top navigation bar

### 2. Edit Files

1. Select **index.html** from the dropdown
2. Make your changes in the text editor
3. Click **"Save File"**
4. Refresh the page to see your changes!

## ✨ What You Can Edit

- **index.html** - The main dashboard layout and structure
- **dashboard.js** - JavaScript functionality (coming soon)
- **custom.css** - Custom styling (coming soon)

## ⚠️ Important Notes

- **Backup First**: Copy your current index.html before making major changes
- **Syntax Errors**: If you break something, reflash the device to restore defaults
- **File Size**: Keep files under 100KB for best performance
- **Changes are Permanent**: Saved files persist after reboot

## 🔧 Technical Details

- Files stored in a 512 KB FATFS partition (`www` at `0x380000` with wear levelling)
- Automatic initialization/mount + default seeding on first boot
- Embedded HTML/CSS/JS used as fallback if the FATFS copy fails
- Only `.html`, `.js`, and `.css` files can be edited through the UI

## 📝 Example: Change the Dashboard Title

Find this line in index.html:
```html
<h1 class='text-2xl font-bold text-green-600 dark:text-green-400'>🌱 KannaCloud</h1>
```

Change it to:
```html
<h1 class='text-2xl font-bold text-green-600 dark:text-green-400'>🌿 My Custom Dashboard</h1>
```

Save and refresh!

## 🆘 Help! I Broke It!

If the dashboard stops working:

1. **Quick Fix**: Reflash the firmware
   ```
   idf.py -p COM3 flash
   ```

2. **Erase dashboard partition only** (keeps Wi-Fi/NVS):
   ```
   esptool.py -p COM3 erase_region 0x380000 0x080000
   ```

Then reboot - the device will remount FATFS and restore files from the embedded defaults.

## 📚 Full Documentation

See [WEB_FILE_EDITOR.md](WEB_FILE_EDITOR.md) for complete documentation.

---

**Status**: ✅ Feature Complete  
**Version**: 1.0.0  
**Last Updated**: November 29, 2025
