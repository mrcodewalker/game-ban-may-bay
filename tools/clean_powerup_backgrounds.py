import os
import glob
from PIL import Image
import numpy as np
from collections import deque
from scipy.ndimage import binary_dilation

def clean_powerup_backgrounds():
    target_dir = 'extracted_assets/AI/cut_assets/power-up/trimmed_powerups'
    files = glob.glob(os.path.join(target_dir, '*.png'))
    
    if not files:
        print("No PNG files found in:", target_dir)
        return
        
    for f in sorted(files):
        img = Image.open(f).convert('RGBA')
        arr = np.array(img).astype(int)
        h, w, c = arr.shape
        
        bg_mask = np.zeros((h, w), dtype=bool)
        queue = deque()
        
        for x in range(w):
            queue.append((0, x))
            queue.append((h - 1, x))
        for y in range(h):
            queue.append((y, 0))
            queue.append((y, w - 1))
            
        for y, x in queue:
            bg_mask[y, x] = True
            
        bg_ref = arr[0, 0, :3]
        directions = [(-1, 0), (1, 0), (0, -1), (0, 1)]
        
        while queue:
            cy, cx = queue.popleft()
            curr_rgb = arr[cy, cx, :3]
            
            for dy, dx in directions:
                ny, nx = cy + dy, cx + dx
                if 0 <= ny < h and 0 <= nx < w and not bg_mask[ny, nx]:
                    n_rgb = arr[ny, nx, :3]
                    dist_ref = np.abs(n_rgb - bg_ref).max()
                    dist_curr = np.abs(n_rgb - curr_rgb).max()
                    
                    if n_rgb.min() > 180 and (dist_ref < 60 or dist_curr < 35):
                        bg_mask[ny, nx] = True
                        queue.append((ny, nx))
                        
        res_arr = np.array(img)
        res_arr[bg_mask, 3] = 0
        
        border_mask = binary_dilation(bg_mask, iterations=1) & ~bg_mask
        res_arr[border_mask, 3] = (res_arr[border_mask, 3] * 0.4).astype(np.uint8)
        
        res_img = Image.fromarray(res_arr)
        bbox = res_img.split()[3].getbbox()
        if bbox:
            res_img = res_img.crop(bbox)
            
        res_img.save(f)
        print(f"Cleaned transparent PNG {os.path.basename(f)}: size {res_img.size}")

if __name__ == '__main__':
    clean_powerup_backgrounds()
