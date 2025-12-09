#!/usr/bin/env python3
"""
Upload web files to the ESP32 FATFS dashboard partition
This helper rebuilds/flashes the firmware so the bundled HTML/CSS/JS
are copied into the FATFS volume on first boot.
"""

import os
import sys
import subprocess

def main():
    print("=" * 60)
    print("ESP32 Web Files Upload Script")
    print("=" * 60)
    print()
    
    # Parse arguments
    if len(sys.argv) < 3:
        print("Usage: python upload_web_files.py --target <c6|s3> --port <PORT>")
        print("Example: python upload_web_files.py --target s3 --port COM3")
        print()
        sys.exit(1)
    
    # Parse command line arguments
    target = None
    port = None
    i = 1
    while i < len(sys.argv):
        if sys.argv[i] == '--target' and i + 1 < len(sys.argv):
            target = sys.argv[i + 1]
            i += 2
        elif sys.argv[i] == '--port' and i + 1 < len(sys.argv):
            port = sys.argv[i + 1]
            i += 2
        else:
            i += 1
    
    if not target or not port:
        print("❌ Error: Both --target and --port are required")
        print("Example: python upload_web_files.py --target s3 --port COM3")
        sys.exit(1)
    
    if target not in ['c6', 's3']:
        print("❌ Error: Target must be 'c6' or 's3'")
        sys.exit(1)
    
    # Check if web files exist
    web_dir = os.path.join("main", "web")
    if not os.path.exists(web_dir):
        print(f"❌ Error: Web directory not found: {web_dir}")
        sys.exit(1)
    
    # List web files
    web_files = []
    for filename in os.listdir(web_dir):
        if filename.endswith(('.html', '.js', '.css')):
            filepath = os.path.join(web_dir, filename)
            size = os.path.getsize(filepath)
            web_files.append((filename, filepath, size))
    
    if not web_files:
        print("❌ No web files found in main/web/")
        sys.exit(1)
    
    print("Found web files:")
    total_size = 0
    for filename, filepath, size in web_files:
        print(f"  • {filename:20s} {size:8d} bytes ({size/1024:.1f} KB)")
        total_size += size
    print(f"\nTotal size: {total_size} bytes ({total_size/1024:.1f} KB)")
    print()
    
    # Check if partition size is sufficient (1MB = 1048576 bytes)
    partition_size = 1048576  # 1MB
    if total_size > partition_size * 0.9:  # Use 90% threshold
        print(f"⚠️  Warning: Files use {total_size/partition_size*100:.1f}% of partition")
    
    print("=" * 60)
    print(f"Uploading to ESP32-{target.upper()} on {port}...")
    print("=" * 60)
    print()
    
    # Note: C6 doesn't have a dashboard, only S3 does
    if target == 'c6':
        print("⚠️  Note: ESP32-C6 is cloud-only and doesn't have the dashboard")
        print("    Web files are only used by ESP32-S3")
        print()
        response = input("Continue anyway? (y/n): ")
        if response.lower() != 'y':
            print("Upload cancelled")
            sys.exit(0)
    
    # Step 1: Build the project using PowerShell script
    print("Step 1: Building project...")
    result = subprocess.run(
        ["powershell.exe", "-ExecutionPolicy", "Bypass", "-File", "./build.ps1", 
         "-Target", target, "-Action", "build"],
        capture_output=True,
        text=True
    )
    if result.returncode != 0:
        print("❌ Build failed!")
        print(result.stdout)
        print(result.stderr)
        sys.exit(1)
    print("✓ Build successful")
    print()
    
    # Step 2: Flash the project
    print("Step 2: Flashing firmware...")
    result = subprocess.run(
        ["powershell.exe", "-ExecutionPolicy", "Bypass", "-File", "./build.ps1",
         "-Target", target, "-Action", "flash", "-Port", port],
        capture_output=True,
        text=True
    )
    if result.returncode != 0:
        print("❌ Flash failed!")
        print(result.stdout)
        print(result.stderr)
        sys.exit(1)
    print("✓ Flash successful")
    print()
    
    print("=" * 60)
    print("✓ Upload complete!")
    print("=" * 60)
    print()
    print("The ESP32 will:")
    print("  1. Boot and mount the FATFS partition (wear-levelled flash)")
    print("  2. Copy embedded dashboard assets into FATFS on first boot")
    print("  3. Serve future requests directly from FATFS")
    print()
    print("You can now edit files via the dashboard:")
    print("  • Navigate to https://kc.local")
    print("  • Click 'Code Editor' in the navigation")
    print("  • Select a file, edit, and save")
    print()
    print("Manual flashing of a standalone FATFS image isn't required; rebooting after a")
    print("build/flash or uploading through the dashboard editor keeps the volume in sync.")
    print()

if __name__ == "__main__":
    main()
