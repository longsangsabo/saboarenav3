#!/usr/bin/env python3
"""
Generate store graphics for Google Play Store and App Store
"""
from PIL import Image, ImageDraw, ImageFont
import os

def create_feature_graphic():
    """Create Google Play Store feature graphic (1024x500)"""
    width, height = 1024, 500
    image = Image.new('RGB', (width, height), '#4285F4')  # Google Blue background
    draw = ImageDraw.Draw(image)
    
    # Gradient background
    for y in range(height):
        alpha = y / height
        color_r = int(66 + (33 - 66) * alpha)   # 66 -> 33
        color_g = int(133 + (150 - 133) * alpha) # 133 -> 150  
        color_b = int(244 + (243 - 244) * alpha) # 244 -> 243
        draw.rectangle([0, y, width, y+1], fill=(color_r, color_g, color_b))
    
    # Load app icon or create placeholder
    try:
        icon = Image.open('assets/images/app_icon.png')
        icon = icon.resize((200, 200), Image.Resampling.LANCZOS)
        image.paste(icon, (50, 150), icon if icon.mode == 'RGBA' else None)
    except:
        # Create placeholder icon
        draw.ellipse([50, 150, 250, 350], fill='white', outline='#1976D2', width=4)
        try:
            font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 40)
        except:
            font = ImageFont.load_default()
        draw.text((120, 220), "SA", fill='#1976D2', font=font)
    
    # Add app name and tagline
    try:
        title_font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 72)
        subtitle_font = ImageFont.truetype("C:/Windows/Fonts/arial.ttf", 32)
    except:
        title_font = ImageFont.load_default()
        subtitle_font = ImageFont.load_default()
    
    # App name
    draw.text((300, 150), "Sabo Arena", fill='white', font=title_font)
    
    # Tagline
    draw.text((300, 250), "Your Ultimate Sports Arena", fill='white', font=subtitle_font)
    draw.text((300, 300), "Management Platform", fill='white', font=subtitle_font)
    
    return image

def create_phone_screenshots():
    """Create mock phone screenshots (1080x1920)"""
    screenshots = []
    
    # Screenshot 1: Home/Arena List
    img1 = Image.new('RGB', (1080, 1920), '#f5f5f5')
    draw1 = ImageDraw.Draw(img1)
    
    # Status bar
    draw1.rectangle([0, 0, 1080, 100], fill='#4285F4')
    draw1.text((50, 35), "9:41", fill='white', font=ImageFont.load_default())
    draw1.text((950, 35), "100%", fill='white', font=ImageFont.load_default())
    
    # Header
    draw1.rectangle([0, 100, 1080, 200], fill='white')
    draw1.text((50, 135), "Sabo Arena", fill='#333', font=ImageFont.load_default())
    
    # Arena cards (mockup)
    for i, (name, location) in enumerate([
        ("Arena Sports Center", "123 Main St"),
        ("Elite Football Club", "456 Oak Ave"),
        ("Victory Stadium", "789 Park Rd")
    ]):
        y_pos = 250 + i * 200
        draw1.rectangle([50, y_pos, 1030, y_pos + 150], fill='white', outline='#ddd', width=2)
        draw1.text((70, y_pos + 20), name, fill='#333', font=ImageFont.load_default())
        draw1.text((70, y_pos + 60), location, fill='#666', font=ImageFont.load_default())
        draw1.text((70, y_pos + 100), "⭐ 4.5 • Available Now", fill='#4285F4', font=ImageFont.load_default())
    
    screenshots.append(img1)
    
    # Screenshot 2: Arena Details
    img2 = Image.new('RGB', (1080, 1920), '#f5f5f5')
    draw2 = ImageDraw.Draw(img2)
    
    # Status bar
    draw2.rectangle([0, 0, 1080, 100], fill='#4285F4')
    draw2.text((50, 35), "9:41", fill='white', font=ImageFont.load_default())
    
    # Hero image placeholder
    draw2.rectangle([0, 100, 1080, 600], fill='#4285F4')
    draw2.text((400, 320), "Arena Image", fill='white', font=ImageFont.load_default())
    
    # Details
    draw2.rectangle([0, 600, 1080, 1920], fill='white')
    draw2.text((50, 650), "Arena Sports Center", fill='#333', font=ImageFont.load_default())
    draw2.text((50, 700), "⭐⭐⭐⭐⭐ 4.8 (124 reviews)", fill='#666', font=ImageFont.load_default())
    draw2.text((50, 750), "📍 123 Main Street, City", fill='#666', font=ImageFont.load_default())
    draw2.text((50, 800), "⏰ Open 6:00 AM - 11:00 PM", fill='#666', font=ImageFont.load_default())
    
    # Booking button
    draw2.rectangle([50, 1500, 1030, 1600], fill='#4285F4')
    draw2.text((480, 1535), "Book Now", fill='white', font=ImageFont.load_default())
    
    screenshots.append(img2)
    
    # Screenshot 3: QR Scanner
    img3 = Image.new('RGBA', (1080, 1920), (0, 0, 0, 255))
    draw3 = ImageDraw.Draw(img3)
    
    # Status bar
    draw3.rectangle([0, 0, 1080, 100], fill=(0, 0, 0, 128))  # Semi-transparent black
    draw3.text((50, 35), "9:41", fill='white', font=ImageFont.load_default())
    
    # QR Scanner frame
    frame_size = 400
    frame_x = (1080 - frame_size) // 2
    frame_y = (1920 - frame_size) // 2
    
    # Scanner overlay
    draw3.rectangle([frame_x, frame_y, frame_x + frame_size, frame_y + frame_size], 
                   outline='#4285F4', width=8)
    
    # Corner brackets
    bracket_size = 50
    for corner in [(frame_x, frame_y), (frame_x + frame_size - bracket_size, frame_y),
                   (frame_x, frame_y + frame_size - bracket_size), 
                   (frame_x + frame_size - bracket_size, frame_y + frame_size - bracket_size)]:
        draw3.rectangle([corner[0], corner[1], corner[0] + bracket_size, corner[1] + 20], 
                       fill='#4285F4')
        draw3.rectangle([corner[0], corner[1], corner[0] + 20, corner[1] + bracket_size], 
                       fill='#4285F4')
    
    # Instructions
    draw3.text((300, frame_y + frame_size + 100), "Scan QR Code to Check In", 
              fill='white', font=ImageFont.load_default())
    
    screenshots.append(img3)
    
    return screenshots

def resize_app_icon_for_stores():
    """Create different sizes of app icon for stores"""
    try:
        original = Image.open('assets/images/app_icon.png')
    except:
        print("App icon not found, creating placeholder...")
        original = Image.new('RGB', (1024, 1024), '#4285F4')
        draw = ImageDraw.Draw(original)
        draw.ellipse([200, 200, 824, 824], fill='white', outline='#1976D2', width=8)
        draw.text((450, 450), "SA", fill='#1976D2', font=ImageFont.load_default())
    
    sizes = {
        'play_store_icon_512.png': (512, 512),
        'app_store_icon_1024.png': (1024, 1024),
    }
    
    icons = {}
    for filename, size in sizes.items():
        resized = original.resize(size, Image.Resampling.LANCZOS)
        icons[filename] = resized
    
    return icons

def main():
    # Create store_graphics directory
    os.makedirs('store_graphics', exist_ok=True)
    
    print("Creating store graphics...")
    
    # Create feature graphic for Google Play
    print("1. Creating feature graphic (1024x500)...")
    feature_graphic = create_feature_graphic()
    feature_graphic.save('store_graphics/feature_graphic_1024x500.png')
    
    # Create phone screenshots
    print("2. Creating phone screenshots (1080x1920)...")
    screenshots = create_phone_screenshots()
    for i, screenshot in enumerate(screenshots, 1):
        screenshot.save(f'store_graphics/phone_screenshot_{i}_1080x1920.png')
    
    # Create app icons in different sizes
    print("3. Creating app icons for stores...")
    icons = resize_app_icon_for_stores()
    for filename, icon in icons.items():
        icon.save(f'store_graphics/{filename}')
    
    print("\n✅ Store graphics created successfully!")
    print("\nFiles created:")
    print("📁 store_graphics/")
    print("  📄 feature_graphic_1024x500.png (Google Play feature graphic)")
    print("  📄 phone_screenshot_1_1080x1920.png (Arena list)")
    print("  📄 phone_screenshot_2_1080x1920.png (Arena details)")
    print("  📄 phone_screenshot_3_1080x1920.png (QR scanner)")
    print("  📄 play_store_icon_512.png (Google Play icon)")
    print("  📄 app_store_icon_1024.png (App Store icon)")
    
    print("\n📋 Next steps:")
    print("1. Review generated graphics and customize as needed")
    print("2. Take actual screenshots from your running app for better quality")
    print("3. Upload these graphics to Google Play Console and App Store Connect")
    print("4. Consider hiring a designer for professional graphics")

if __name__ == "__main__":
    main()