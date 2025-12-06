# Web File Editor - User Guide

## 🎨 Overview

The ESP32-S3 dashboard now includes a **built-in code editor** that allows you to edit HTML, JavaScript, and CSS files directly from your browser - no need to reflash the device!

## ✨ Features

- **In-Browser Editing**: Edit dashboard files using a simple text editor
- **Live Updates**: Changes take effect immediately after saving
- **File Management**: View all web files and their sizes
- **Safety Features**: File type restrictions and confirmation prompts
- **Persistent Storage**: Files stored in a FATFS flash partition with wear levelling (survives reboots)

## 🚀 Quick Start

### 1. Access the Code Editor

1. Open your dashboard: `https://kc.local`
2. Click **"Code Editor"** in the navigation bar
3. The editor interface will load

### 2. Edit a File

1. **Select a file** from the dropdown menu (e.g., `index.html`)
2. The file content will load in the text editor
3. **Make your changes** in the editor
4. Click **"Save File"** to persist changes
5. Refresh the page to see your updates

### 3. Preview Changes

- For `index.html`: Click **"Preview Changes"** to reload the dashboard
- For other files: Save and manually refresh

## 📁 Available Files

The following files are editable:

- **`index.html`** - Main dashboard HTML structure
- **`dashboard.js`** - JavaScript functionality (if separated)
- **Custom CSS files** - Styling modifications

## 🔧 Technical Details

### FATFS Partition

- **Location**: 0x380000 (3.5MB offset)
- **Size**: 512KB (0x080000 bytes)
- **File System**: FATFS on top of the ESP-IDF wear-levelling driver
- **Max File Size**: 200KB per file

### API Endpoints

The editor uses these HTTPS API endpoints:

```
GET  /api/webfiles           - List all files
GET  /api/webfiles/<filename> - Get file content
PUT  /api/webfiles/<filename> - Save file content
POST /api/webfiles/reset      - Format + reseed dashboard defaults
```

### Reseeding the Filesystem

If the FATFS copy of the dashboard becomes corrupted or you flash new firmware that updates the embedded assets, run the reset endpoint to format `/www` and restore the built-in `index.html`, `dashboard.css`, and `dashboard.js`:

```powershell
curl.exe -k -X POST https://kc.local/api/webfiles/reset
```

A `{"success":true,"message":"filesystem reset"}` response confirms the reseed finished. **This erases any edits stored on the device**, so download custom files first via `/api/webfiles/*` if you need to keep them.

### First Boot Initialization

On the first boot after flashing:
1. The ESP32 mounts the FATFS partition (formatting if needed)
2. If `index.html`/CSS/JS files are missing or empty, it copies the embedded versions
3. Future requests are served directly from FATFS
4. Embedded fallback is used if the filesystem read fails

## ⚠️ Important Safety Notes

### File Type Restrictions

- Only `.html`, `.js`, and `.css` files can be edited
- Path traversal (`../`) is blocked for security
- Maximum file size: 200KB

### Backup Recommendations

**Before making major changes:**

1. Copy the current `index.html` content to a local file
2. Test changes incrementally
3. Keep the original file as backup

### Syntax Errors

**If you break the dashboard:**

1. The embedded fallback will still work for `index.html`
2. Use the serial monitor to check for JavaScript errors
3. Reflash the firmware to restore original files
4. Or manually fix via the editor

### Memory Considerations

- Large files may cause memory issues
- Keep files under 100KB when possible
- The editor loads entire files into RAM

## 🛠️ Troubleshooting

### "FATFS not mounted" Error

**Cause**: FATFS partition failed to mount or format

**Solutions**:
1. Erase flash: `idf.py -p COM3 erase-flash`
2. Reflash firmware: `idf.py -p COM3 flash`
3. Check partition table in `config/partitions.csv`

### File Won't Save

**Possible causes**:
- File too large (>200KB)
- FATFS partition nearly full
- Invalid filename

**Check FATFS usage** in serial logs:
```
FATFS: total=512 KB, free=XX KB
```

### Dashboard Broken After Edit

**Quick fix**:
1. Clear browser cache (Ctrl+F5)
2. Check browser console for JavaScript errors (F12)
3. Revert file using "Reset" button (if content still loaded)

**If editor is inaccessible**:
1. Reflash the device: `idf.py -p COM3 flash`
2. The embedded version will be restored

### `Invalid or unexpected token` in `dashboard.js`

**Cause**: Older firmware versions copied the embedded JavaScript with the linker-added `\0` byte, so FATFS stored an extra NUL at the end of `dashboard.js`. Browsers bail out when they encounter `0x00` in a script, causing functions such as `showEditor()` or `showDashboard()` to be undefined.

**Fix**:
1. Flash firmware dated Dec 2 2025 or newer (the copy routine now trims the terminator).
2. Run `POST /api/webfiles/reset` to wipe `/www` and reseed clean copies.
3. Reload the dashboard (Ctrl+F5). The device files now match the repository byte-for-byte, and the syntax error disappears.

### Can't Access Editor

**Symptoms**: "Code Editor" link doesn't work

**Solutions**:
1. Ensure you're running the latest firmware
2. Check that HTTPS server is running
3. Verify the partition table includes `www` partition

## 📝 Example: Changing the Dashboard Title

### Step-by-Step

1. Navigate to **Code Editor**
2. Select **index.html** from dropdown
3. Find this line:
   ```html
   <h1 class='text-2xl font-bold text-green-600 dark:text-green-400'>🌱 KannaCloud</h1>
   ```
4. Change to:
   ```html
   <h1 class='text-2xl font-bold text-green-600 dark:text-green-400'>🌿 My Custom Dashboard</h1>
   ```
5. Click **"Save File"**
6. Click **"Preview Changes"** or refresh the page

## 🔄 Resetting to Factory Defaults

### Method 1: Reflash Firmware

```bash
cd c:\Code\esp32_S3
idf.py -p COM3 flash
```

This will:
- Overwrite the embedded HTML
- On next boot, copy embedded version to FATFS
- Restore all original files

### Method 2: Manual FATFS Erase

```bash
esptool.py -p COM3 erase_region 0x380000 0x080000
```

Then reboot the device - it will remount FATFS and restore the embedded files.

## 🎯 Advanced Usage

### Adding New Files

Currently not supported via the editor. To add new files:

1. Add file to `main/web/` folder
2. Rebuild and flash firmware
3. File will be available after first boot

### Custom JavaScript Modules

You can separate JavaScript into multiple files:

1. Create `main/web/custom.js`
2. Add to `index.html`:
   ```html
   <script src='/api/webfiles/custom.js'></script>
   ```
3. Flash firmware to initialize

### Styling Modifications

Create custom CSS files:

1. Create `main/web/custom.css`
2. Link in `index.html` `<head>`:
   ```html
   <link rel='stylesheet' href='/api/webfiles/custom.css'>
   ```

## 📊 Partition Table Reference

```csv
# Name,      Type, SubType,  Offset,  Size
nvs,         data, nvs,      0x9000,   0x6000    # WiFi credentials
nvs_key,     data, nvs_keys, 0xF000,   0x1000    # Encryption keys
otadata,     data, ota,      0x10000,  0x2000    # OTA data slots
phy_init,    data, phy,      0x12000,  0x1000    # PHY calibration
nvs_certs,   data, nvs,      0x13000,  0xD000    # HTTPS certificates
ota_0,       app,  ota_0,    0x20000,  0x1B0000  # Primary firmware slot
ota_1,       app,  ota_1,    0x1D0000, 0x1B0000  # Secondary firmware slot
www,         data, fat,      0x380000, 0x080000  # Web files (FATFS)
```

## 🆘 Getting Help

If you encounter issues:

1. Check serial monitor for errors: `idf.py -p COM3 monitor`
2. Look for `HTTP_SERVER` or FATFS log messages
3. Verify FATFS is mounted: should see `FATFS: total=... free=...`
4. Check GitHub issues or create a new one

## 📚 Related Documentation

- [FATFS Documentation](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/storage/fatfs.html)
- [ESP-IDF Partition Tables](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-guides/partition-tables.html)
- [HTTP Server API](https://docs.espressif.com/projects/esp-idf/en/latest/esp32/api-reference/protocols/esp_http_server.html)

---

**Last Updated**: November 29, 2025  
**Feature Version**: 1.0.0
