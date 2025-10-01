#!/usr/bin/env python3
"""
Simple script to copy and resize logo for Android splash screens
Since we can't easily convert SVG, let's create a simple approach
"""

import shutil
from pathlib import Path

def main():
    print("🚀 Setting up Android native splash screens...")
    
    # Paths
    logo_svg = Path('assets/images/logo.svg')
    android_res = Path('android/app/src/main/res')
    
    if not logo_svg.exists():
        print(f"❌ Logo SVG not found: {logo_svg}")
        return False
    
    if not android_res.exists():
        print(f"❌ Android res directory not found: {android_res}")
        return False
    
    # Create a simple instruction
    print("📝 Manual steps needed:")
    print("1. Open your logo.svg in an image editor (GIMP, Photoshop, online converter)")
    print("2. Export as PNG with these sizes:")
    
    densities = {
        'mdpi': 96,      # 160dpi - baseline
        'hdpi': 144,     # 240dpi  
        'xhdpi': 192,    # 320dpi
        'xxhdpi': 288,   # 480dpi
        'xxxhdpi': 384,  # 640dpi
    }
    
    print("\n📐 Required PNG sizes:")
    for density, size in densities.items():
        print(f"   - drawable-{density}/splash.png: {size}x{size} pixels")
    
    # Check current splash files
    print("\n📂 Current splash files to replace:")
    for density in densities.keys():
        splash_file = android_res / f'drawable-{density}' / 'splash.png'
        if splash_file.exists():
            print(f"   ✅ Found: {splash_file}")
        else:
            print(f"   ❌ Missing: {splash_file}")
    
    print("\n💡 Alternative: I can create a simple workaround...")
    return True

if __name__ == '__main__':
    main()