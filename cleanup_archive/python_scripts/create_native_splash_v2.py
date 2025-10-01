#!/usr/bin/env python3
"""
Convert SVG logo to Android splash screen PNG files using Python libraries
"""

import os
import sys
from pathlib import Path

try:
    from PIL import Image
    import cairosvg
except ImportError:
    print("❌ Required libraries not found. Installing...")
    import subprocess
    subprocess.check_call([sys.executable, '-m', 'pip', 'install', 'pillow', 'cairosvg'])
    from PIL import Image
    import cairosvg

# Android density multipliers
DENSITIES = {
    'mdpi': 1,      # 160dpi - baseline
    'hdpi': 1.5,    # 240dpi
    'xhdpi': 2,     # 320dpi
    'xxhdpi': 3,    # 480dpi
    'xxxhdpi': 4,   # 640dpi
}

BASE_SIZE = 96  # Base size for splash icon

def convert_svg_to_png(svg_path, output_path, size):
    """Convert SVG to PNG using cairosvg and Pillow"""
    try:
        # Convert SVG to PNG bytes
        png_bytes = cairosvg.svg2png(
            url=str(svg_path),
            output_width=size,
            output_height=size,
            background_color='white'
        )
        
        # Create PIL Image and save
        with Image.open(io.BytesIO(png_bytes)) as img:
            # Convert to RGBA for transparency
            img = img.convert('RGBA')
            
            # Make white background transparent
            data = img.getdata()
            new_data = []
            for item in data:
                # If pixel is close to white, make it transparent
                if item[0] > 240 and item[1] > 240 and item[2] > 240:
                    new_data.append((255, 255, 255, 0))  # Transparent
                else:
                    new_data.append(item)
            
            img.putdata(new_data)
            img.save(output_path, 'PNG')
        
        print(f"✅ Created: {output_path} ({size}x{size})")
        return True
    except Exception as e:
        print(f"❌ Error creating {output_path}: {e}")
        return False

def main():
    # Add required import
    import io
    
    # Paths
    svg_path = Path('assets/images/logo.svg')
    android_res = Path('android/app/src/main/res')
    
    if not svg_path.exists():
        print(f"❌ SVG file not found: {svg_path}")
        return False
    
    if not android_res.exists():
        print(f"❌ Android res directory not found: {android_res}")
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