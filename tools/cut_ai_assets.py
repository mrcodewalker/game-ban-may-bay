# -*- coding: utf-8 -*-
"""
BFS Asset Extraction Tool for Sky Force Remake.
Uses BFS Flood-Fill from outer edges to trace, separate background pixels,
and extract tight bounding boxes for each object sprite cleanly.
"""

import os
import json
import cv2
import numpy as np
from PIL import Image

ROOT_DIR = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
AI_DIR = os.path.join(ROOT_DIR, "extracted_assets", "AI")
OUT_DIR = os.path.join(AI_DIR, "cut_assets")

PADDING = 4

# Metadata configuration for each AI asset sheet
ASSET_CONFIGS = [
    {
        "filename": "may-bay-storage.png",
        "category": "player_jets",
        "prefix": "player_jet",
        "rows": 2,
        "cols": 6,
        "bg_type": "rgba"
    },
    {
        "filename": "pet-jet.png",
        "category": "pet_jets",
        "prefix": "pet_jet",
        "rows": 2,
        "cols": 6,
        "bg_type": "white"
    },
    {
        "filename": "enemy.png",
        "category": "enemies",
        "prefix": "enemy",
        "rows": 2,
        "cols": 6,
        "bg_type": "white"
    },
    {
        "filename": "tower.png",
        "category": "towers",
        "prefix": "tower",
        "rows": 2,
        "cols": 6,
        "bg_type": "white"
    },
    {
        "filename": "bullet.png",
        "category": "bullets",
        "prefix": "bullet",
        "rows": 2,
        "cols": 6,
        "bg_type": "white"
    },
    {
        "filename": "power-up.png",
        "category": "powerups",
        "prefix": "powerup",
        "rows": 2,
        "cols": 6,
        "bg_type": "rgba"
    },
    {
        "filename": "cong-chua.png",
        "category": "princess",
        "prefix": "princess",
        "rows": 2,
        "cols": 6,
        "bg_type": "rgba"
    },
    {
        "filename": "effect.png",
        "category": "effects",
        "prefix": "effect",
        "rows": 3,
        "cols": 4,
        "bg_type": "dark"
    },
    {
        "filename": "vung-nhieu-bat-loi.png",
        "category": "debuff_zones",
        "prefix": "debuff_zone",
        "rows": 2,
        "cols": 3,
        "bg_type": "white"
    }
]


def remove_white_background_bfs(crop_rgba, thresh=220):
    """
    BFS Flood-Fill from cell borders inwards to isolate object pixels from connected background.
    """
    arr = np.array(crop_rgba).copy()
    h, w = arr.shape[:2]
    
    r, g, b, a = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2], arr[:, :, 3]
    whiteness = np.minimum(np.minimum(r, g), b)
    
    bg_mask = (whiteness > thresh).astype(np.uint8)
    flood_mask = np.zeros((h + 2, w + 2), np.uint8)
    
    # BFS Seeds from outer edges
    for x in range(w):
        if bg_mask[0, x] == 1:
            cv2.floodFill(bg_mask, flood_mask, (x, 0), 2)
        if bg_mask[h - 1, x] == 1:
            cv2.floodFill(bg_mask, flood_mask, (x, h - 1), 2)
    for y in range(h):
        if bg_mask[y, 0] == 1:
            cv2.floodFill(bg_mask, flood_mask, (0, y), 2)
        if bg_mask[y, w - 1] == 1:
            cv2.floodFill(bg_mask, flood_mask, (w - 1, y), 2)
            
    connected_bg = (bg_mask == 2)
    arr[connected_bg, 3] = 0  # Set alpha = 0 for BFS-filled background
    
    # Soft edge feathering around objects
    kernel = np.ones((3, 3), np.uint8)
    bg_dilated = cv2.dilate(connected_bg.astype(np.uint8), kernel, iterations=1)
    edge_pixels = (bg_dilated == 1) & (~connected_bg) & (whiteness > thresh - 30)
    arr[edge_pixels, 3] = np.clip((255 - whiteness[edge_pixels]) * 3.0, 0, 255).astype(np.uint8)
    
    return Image.fromarray(arr, mode="RGBA")


def remove_dark_background_bfs(crop_rgba, thresh=30):
    """
    BFS Flood-Fill for dark/black backgrounds in visual effect sheets.
    """
    arr = np.array(crop_rgba).copy()
    h, w = arr.shape[:2]
    
    r, g, b, a = arr[:, :, 0], arr[:, :, 1], arr[:, :, 2], arr[:, :, 3]
    lum = 0.299 * r + 0.587 * g + 0.114 * b
    
    dark_mask = (lum < thresh).astype(np.uint8)
    flood_mask = np.zeros((h + 2, w + 2), np.uint8)
    
    for x in range(w):
        if dark_mask[0, x] == 1:
            cv2.floodFill(dark_mask, flood_mask, (x, 0), 2)
        if dark_mask[h - 1, x] == 1:
            cv2.floodFill(dark_mask, flood_mask, (x, h - 1), 2)
    for y in range(h):
        if dark_mask[y, 0] == 1:
            cv2.floodFill(dark_mask, flood_mask, (0, y), 2)
        if dark_mask[y, w - 1] == 1:
            cv2.floodFill(dark_mask, flood_mask, (w - 1, y), 2)
            
    connected_bg = (dark_mask == 2)
    arr[connected_bg, 3] = 0
    
    non_bg = ~connected_bg
    arr[non_bg, 3] = np.clip(lum[non_bg] * 2.5, 0, 255).astype(np.uint8)
    
    return Image.fromarray(arr, mode="RGBA")


def trim_tight_bfs(cell_img, padding=PADDING):
    """
    Find tight bounding box around object alpha mask and trim empty transparent space.
    """
    arr = np.array(cell_img)
    alpha = arr[:, :, 3]
    
    non_zero = np.where(alpha > 15)
    if len(non_zero[0]) == 0 or len(non_zero[1]) == 0:
        return None
        
    y_min, y_max = non_zero[0].min(), non_zero[0].max()
    x_min, x_max = non_zero[1].min(), non_zero[1].max()
    
    h, w = cell_img.height, cell_img.width
    y1 = max(0, y_min - padding)
    y2 = min(h, y_max + padding + 1)
    x1 = max(0, x_min - padding)
    x2 = min(w, x_max + padding + 1)
    
    return cell_img.crop((x1, y1, x2, y2))


def process_sheet(config, manifest_data):
    filename = config["filename"]
    category = config["category"]
    prefix = config["prefix"]
    rows = config["rows"]
    cols = config["cols"]
    bg_type = config["bg_type"]
    
    src_path = os.path.join(AI_DIR, filename)
    if not os.path.exists(src_path):
        print(f"[WARN] File not found: {src_path}")
        return
        
    category_dir = os.path.join(OUT_DIR, category)
    os.makedirs(category_dir, exist_ok=True)
    
    img = Image.open(src_path).convert("RGBA")
    w, h = img.size
    cell_w = w / cols
    cell_h = h / rows
    
    print(f"\nBFS Processing '{filename}' -> Category '{category}' ({cols}x{rows} grid)...")
    manifest_data[category] = []
    
    count = 0
    for r in range(rows):
        for c in range(cols):
            x1 = int(c * cell_w)
            y1 = int(r * cell_h)
            x2 = int((c + 1) * cell_w)
            y2 = int((r + 1) * cell_h)
            
            cell = img.crop((x1, y1, x2, y2))
            
            if bg_type == "white":
                cell = remove_white_background_bfs(cell)
            elif bg_type == "dark":
                cell = remove_dark_background_bfs(cell)
                
            trimmed = trim_tight_bfs(cell)
            if trimmed is None:
                print(f"  [SKIP] Cell ({r},{c}) empty")
                continue
                
            count += 1
            out_name = f"{prefix}_{count:02d}.png"
            out_path = os.path.join(category_dir, out_name)
            trimmed.save(out_path, "PNG")
            
            rel_path = f"extracted_assets/AI/cut_assets/{category}/{out_name}"
            manifest_data[category].append({
                "name": out_name,
                "path": rel_path,
                "width": trimmed.width,
                "height": trimmed.height,
                "row": r,
                "col": c
            })
            print(f"  [OK] Saved {out_name:22s} size={trimmed.width}x{trimmed.height}")

    print(f"Total extracted for '{category}': {count} sprites.")


def main():
    os.makedirs(OUT_DIR, exist_ok=True)
    manifest_data = {}
    
    for cfg in ASSET_CONFIGS:
        process_sheet(cfg, manifest_data)
        
    manifest_path = os.path.join(OUT_DIR, "manifest.json")
    with open(manifest_path, "w", encoding="utf-8") as f:
        json.dump(manifest_data, f, indent=2)
        
    print(f"\nSuccessfully extracted all AI assets using BFS! Manifest saved to: {manifest_path}")


if __name__ == "__main__":
    main()
