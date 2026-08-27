import os
import shutil
from PIL import Image
import numpy as np

def cut_powerup_trim():
    src_path = 'extracted_assets/AI/cut_assets/power-up/need-trim.png'
    out_dir = 'extracted_assets/AI/cut_assets/power-up/trimmed_powerups'
    
    if not os.path.exists(src_path):
        print("Source image not found:", src_path)
        return
        
    # Clear previous output directory completely
    if os.path.exists(out_dir):
        shutil.rmtree(out_dir)
    os.makedirs(out_dir, exist_ok=True)
    
    img = Image.open(src_path).convert('RGBA')
    arr = np.array(img)
    
    # Remove light grey/white background color (r > 215, g > 215, b > 215)
    r, g, b = arr[:,:,0], arr[:,:,1], arr[:,:,2]
    bg_mask = (r > 215) & (g > 215) & (b > 215)
    arr[bg_mask, 3] = 0
    
    clean_img = Image.fromarray(arr)
    
    # 9 distinct individual item bounding regions
    boxes = [
        (25, 260, 376, 535),    # Item 1
        (393, 260, 553, 535),   # Item 2
        (591, 260, 721, 535),   # Item 3
        (733, 260, 911, 535),   # Item 4
        (921, 260, 1074, 535),  # Item 5
        (1081, 260, 1448, 535), # Item 6
        (1448, 260, 1806, 535), # Item 7
        (1816, 260, 1955, 535), # Item 8
        (1966, 260, 2147, 535)  # Item 9
    ]

    for idx, box in enumerate(boxes):
        cropped = clean_img.crop(box)
        alpha = cropped.split()[3]
        bbox = alpha.getbbox()
        if bbox:
            cropped = cropped.crop(bbox)
            
        out_file = os.path.join(out_dir, f'powerup_{idx+1:02d}.png')
        cropped.save(out_file)
        print(f'Cut file {out_file}: size {cropped.size}')

if __name__ == '__main__':
    cut_powerup_trim()
