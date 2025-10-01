#!/usr/bin/env python3
"""
Simple script to create app icons and splash screen images for Flutter app
"""
from PIL import Image, ImageDraw, ImageFont

def create_app_icon():
    """Create a simple app icon (1024x1024)"""
    # Create a 1024x1024 image with gradient background
    size = 1024
    image = Image.new('RGB', (size, size), '#4285F4')  # Google Blue
    draw = ImageDraw.Draw(image)
    
    # Create gradient effect
    for i in range(size):
        alpha = i / size
        color_r = int(66 + (33 - 66) * alpha)   # 66 -> 33
        color_g = int(133 + (150 - 133) * alpha) # 133 -> 150  
        color_b = int(244 + (243 - 244) * alpha) # 244 -> 243
        draw.rectangle([0, i, size, i+1], fill=(color_r, color_g, color_b))
    
    # Add a circle in the center
    circle_radius = size // 4
    circle_center = (size // 2, size // 2)
    draw.ellipse([
        circle_center[0] - circle_radius,
        circle_center[1] - circle_radius,
        circle_center[0] + circle_radius,
        circle_center[1] + circle_radius
    ], fill='white', outline='#1976D2', width=8)
    
    # Add "SA" text (Sabo Arena)
    try:
        # Try to use a system font
        font = ImageFont.truetype("arial.ttf", 120)
    except:
        try:
            font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 120)
        except:
            font = ImageFont.load_default()
    
    text = "SA"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_height = bbox[3] - bbox[1]
    text_x = (size - text_width) // 2
    text_y = (size - text_height) // 2 - 20
    
    draw.text((text_x, text_y), text, fill='#1976D2', font=font)
    
    return image

def create_splash_logo():
    """Create a simple splash screen logo (512x512)"""
    size = 512
    image = Image.new('RGBA', (size, size), (255, 255, 255, 0))  # Transparent background
    draw = ImageDraw.Draw(image)
    
    # Create a circle with app colors
    circle_radius = size // 3
    circle_center = (size // 2, size // 2)
    draw.ellipse([
        circle_center[0] - circle_radius,
        circle_center[1] - circle_radius,
        circle_center[0] + circle_radius,
        circle_center[1] + circle_radius
    ], fill='#4285F4', outline='#1976D2', width=6)
    
    # Add "Sabo Arena" text
    try:
        font = ImageFont.truetype("arial.ttf", 48)
    except:
        try:
            font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 48)
        except:
            font = ImageFont.load_default()
    
    text = "Sabo Arena"
    bbox = draw.textbbox((0, 0), text, font=font)
    text_width = bbox[2] - bbox[0]
    text_x = (size - text_width) // 2
    text_y = circle_center[1] + circle_radius + 20
    
    draw.text((text_x, text_y), text, fill='#1976D2', font=font)
    
    return image

def main():
    # Create directories if they don't exist
    import os
    os.makedirs('assets/images', exist_ok=True)
    
    # Create and save app icon
    print("Creating app icon...")
    app_icon = create_app_icon()
    app_icon.save('assets/images/app_icon.png')
    print("✓ App icon saved to assets/images/app_icon.png")
    
    # Create and save splash logo
    print("Creating splash logo...")
    splash_logo = create_splash_logo()
    splash_logo.save('assets/images/splash_logo.png')
    print("✓ Splash logo saved to assets/images/splash_logo.png")
    
    print("\nNext steps:")
    print("1. Run: flutter pub get")
    print("2. Run: dart run flutter_launcher_icons")
    print("3. Run: dart run flutter_native_splash:create")

if __name__ == "__main__":
    main()