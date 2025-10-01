#!/usr/bin/env python3
"""
Convert SVG logo to Android splash screen PNG files with correct densities
"""

import os
import subprocess
import sys
from pathlib import Path

# Android density multipliers
DENSITIES = {
    'mdpi': 1,      # 160dpi - baseline (48x48)
    'hdpi': 1.5,    # 240dpi (72x72)
    'xhdpi': 2,     # 320dpi (96x96)
    'xxhdpi': 3,    # 480dpi (144x144)
    'xxxhdpi': 4,   # 640dpi (192x192)
}

BASE_SIZE = 96  # Base size for splash icon

def check_inkscape():
    """Check if Inkscape is available"""
    try:
        subprocess.run(['inkscape', '--version'], capture_output=True, check=True)
        return True
    except (subprocess.CalledProcessError, FileNotFoundError):
        return False

def convert_svg_to_png(svg_path, output_path, size):
    """Convert SVG to PNG using Inkscape"""
    cmd = [
        'inkscape',
        '--export-type=png',
        f'--export-filename={output_path}',
        f'--export-width={size}',
        f'--export-height={size}',
        '--export-background=ffffff',  # White background
        '--export-background-opacity=0',  # Transparent
        str(svg_path)
    ]
    
    try:
        result = subprocess.run(cmd, capture_output=True, text=True, check=True)
        print(f"✅ Created: {output_path} ({size}x{size})")
        return True
    except subprocess.CalledProcessError as e:
        print(f"❌ Error creating {output_path}: {e.stderr}")
        return False

def main():
    # Paths
    svg_path = Path('assets/images/logo.svg')
    android_res = Path('android/app/src/main/res')
    
    if not svg_path.exists():
        print(f"❌ SVG file not found: {svg_path}")
        return False
    
    if not android_res.exists():
        print(f"❌ Android res directory not found: {android_res}")
        return False
    
    if not check_inkscape():
        print("❌ Inkscape not found. Please install Inkscape:")
        print("   Windows: winget install Inkscape.Inkscape")
        print("   Mac: brew install inkscape")
        print("   Linux: sudo apt install inkscape")
        return False
    
    print("🚀 Converting SVG logo to Android splash screens...")
    
    success_count = 0
    total_count = 0
    
    # Generate splash.png for each density
    for density, multiplier in DENSITIES.items():
        drawable_dir = android_res / f'drawable-{density}'
        drawable_dir.mkdir(exist_ok=True)
        
        size = int(BASE_SIZE * multiplier)
        output_path = drawable_dir / 'splash.png'
        
        total_count += 1
        if convert_svg_to_png(svg_path, output_path, size):
            success_count += 1
    
    # Also create a base drawable version
    drawable_dir = android_res / 'drawable'
    drawable_dir.mkdir(exist_ok=True)
    output_path = drawable_dir / 'splash.png'
    
    total_count += 1
    if convert_svg_to_png(svg_path, output_path, BASE_SIZE):
        success_count += 1
    
    print(f"\n📊 Results: {success_count}/{total_count} files created successfully")
    
    if success_count == total_count:
        print("✅ All Android splash screens updated with your logo!")
        print("🔄 Run 'flutter clean && flutter build apk' to see changes")
        return True
    else:
        print("⚠️  Some files failed to generate")
        return False

if __name__ == '__main__':
    success = main()
    sys.exit(0 if success else 1)