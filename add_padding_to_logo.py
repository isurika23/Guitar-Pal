"""
Add transparent padding around the Guitar-Pal logo for proper app icon display.
This ensures the full guitar pick shape is visible in the app launcher.
"""

from PIL import Image
import os

def add_padding_to_logo():
    # Paths
    input_path = os.path.join('mobile_app', 'assets', 'images', 'logo-2287665_1280.png')
    output_path = os.path.join('mobile_app', 'assets', 'images', 'logo_padded.png')
    
    print(f"Opening: {input_path}")
    
    # Open the original image
    logo = Image.open(input_path)
    print(f"Original size: {logo.size}")
    
    # Create new image with padding
    # Original: 1280x1088
    # New: 2000x2000 (adds much more padding for full visibility)
    new_size = 2000
    new_image = Image.new('RGBA', (new_size, new_size), (0, 0, 0, 0))  # Transparent background
    
    # Calculate position to center the logo
    offset_x = (new_size - logo.width) // 2
    offset_y = (new_size - logo.height) // 2
    offset = (offset_x, offset_y)
    
    print(f"New size: {new_size}x{new_size}")
    print(f"Padding: {offset_x}px on each side")
    
    # Paste the logo in the center
    new_image.paste(logo, offset, logo if logo.mode == 'RGBA' else None)
    
    # Save the result
    new_image.save(output_path, 'PNG')
    
    print(f"\n✅ Success! Padded logo created:")
    print(f"   {output_path}")
    print(f"\nNext steps:")
    print(f"1. Update pubspec.yaml to use 'assets/images/logo_padded.png'")
    print(f"2. Run: cd mobile_app && flutter pub run flutter_launcher_icons")
    print(f"3. Uninstall and reinstall the app to see the new icon")

if __name__ == '__main__':
    try:
        add_padding_to_logo()
    except ImportError:
        print("Error: PIL/Pillow is not installed.")
        print("Install it with: pip install Pillow")
    except FileNotFoundError as e:
        print(f"Error: {e}")
        print("Make sure you run this script from the Guitar-Pal directory")
    except Exception as e:
        print(f"Error: {e}")
