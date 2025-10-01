#!/usr/bin/env python3
"""
Create Android splash screens using wand (ImageMagick Python binding)
"""

import os
import sys
from pathlib import Path

def install_wand():
    """Install Wand if not available"""
    try:
        from wand.image import Image as WandImage
        return True
    except ImportError:
        print("Installing Wand (ImageMagick Python binding)...")
        import subprocess
        try:
            subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'Wand'])
            from wand.image import Image as WandImage
            return True
        except Exception as e:
            print(f"❌ Failed to install Wand: {e}")
            return False

def create_png_from_svg(svg_path, output_path, size):
    """Convert SVG to PNG using Wand"""
    try:
        from wand.image import Image as WandImage
        from wand.color import Color
        
        with WandImage() as img:
            img.read(filename=str(svg_path))
            img.format = 'png'
            img.resize(size, size)
            img.background_color = Color('transparent')
            img.save(filename=str(output_path))
        
        print(f"✅ Created: {output_path} ({size}x{size})")
        return True
    except Exception as e:
        print(f"❌ Error creating {output_path}: {e}")
        return False

def main():
    if not install_wand():
        print("❌ Cannot install required dependencies")
        print("📝 Please manually convert your SVG logo to PNG files:")
        print("   Use an online converter like https://convertio.co/svg-png/")
        return False
    
    # Paths
    svg_path = Path('assets/images/logo.svg')
    android_res = Path('android/app/src/main/res')
    
    if not svg_path.exists():
        print(f"❌ SVG file not found: {svg_path}")
        return False
    
    print("🚀 Converting SVG to Android splash PNGs...")
    
    # Android density multipliers and sizes
    densities = {
        'mdpi': 96,      # 160dpi - baseline
        'hdpi': 144,     # 240dpi  
        'xhdpi': 192,    # 320dpi
        'xxhdpi': 288,   # 480dpi
        'xxxhdpi': 384,  # 640dpi
    }
    
    success_count = 0
    total_count = len(densities) + 1  # +1 for base drawable
    
    # Generate for each density
    for density, size in densities.items():
        drawable_dir = android_res / f'drawable-{density}'
        output_path = drawable_dir / 'splash.png'
        
        if create_png_from_svg(svg_path, output_path, size):
            success_count += 1
    
    # Base drawable
    drawable_dir = android_res / 'drawable'
    output_path = drawable_dir / 'splash.png'
    if create_png_from_svg(svg_path, output_path, 96):
        success_count += 1
    
    print(f"\n📊 Results: {success_count}/{total_count} files created")
    
    if success_count == total_count:
        print("✅ All Android splash screens updated!")
        print("🔄 Run 'flutter clean && flutter run' to see changes")
        return True
    else:
        print("⚠️  Some files failed to generate")
        return False

if __name__ == '__main__':
    main()