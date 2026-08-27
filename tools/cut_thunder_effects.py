import os
from PIL import Image

def cut_thunder_effects():
    src_path = 'extracted_assets/AI/cut_assets/bullets/thunder.png'
    out_dir = 'extracted_assets/AI/cut_assets/bullets/thunder_frames'
    os.makedirs(out_dir, exist_ok=True)
    
    if not os.path.exists(src_path):
        print("Source image not found:", src_path)
        return
        
    img = Image.open(src_path)
    # Only frames 1 through 7 (sequence from launch to full release)
    c_ranges = [
        (20, 50),   # Frame 1
        (80, 114),  # Frame 2
        (139, 180), # Frame 3
        (202, 245), # Frame 4
        (263, 311), # Frame 5
        (332, 396), # Frame 6
        (411, 485)  # Frame 7 (Peak release beam)
    ]

    for idx, (c1, c2) in enumerate(c_ranges):
        crop_box = (c1, 586, c2, 970)
        cropped = img.crop(crop_box)
        
        # Auto-crop padding around non-transparent pixels
        alpha = cropped.split()[3]
        bbox = alpha.getbbox()
        if bbox:
            cropped = cropped.crop(bbox)
            
        save_path = os.path.join(out_dir, f'thunder_frame_{idx+1:02d}.png')
        cropped.save(save_path)
        print(f'Saved {save_path}: size {cropped.size}')

    # Remove unwanted error frames (8 to 11)
    for i in range(8, 12):
        unwanted = os.path.join(out_dir, f'thunder_frame_{i:02d}.png')
        if os.path.exists(unwanted):
            os.remove(unwanted)
            print(f'Removed unwanted frame {unwanted}')

if __name__ == '__main__':
    cut_thunder_effects()
