"""
Sprite cutter cho game bắn máy bay
Nguồn: enemy.png và sky-force-needed-trim.png (grid 12x8, cell 128x128)

ENEMY.PNG layout (row, col) -> tên sprite:
  Row 0 (col 3-11): Phần trên của các tàu lớn / boss parts / đường đạn enemy nhỏ  
  Row 1 (col 0-11): Ship enemy - các máy bay địch (animation frames / các loại khác nhau)
  Row 2 (col 0-11): Mix - đạn, parts
  Row 3 (col 0-11): Ship enemy tiếp
  Row 4 (col 0-11): Buff items (màu rực rỡ - đỏ cam hồng tím cyan xanh)
  Row 5 (col 0-11): Buff items frame 2
  Row 6 (col 0-11): Tank enemy / xe tăng
  Row 7 (col 0-11): Tank enemy / ground units

SKY-FORCE-NEEDED-TRIM.PNG layout:
  Row 0 (col 0-4): Tàu nhỏ màu xanh dương (fairy/tinh linh companion)
  Row 0 (col 5-8): Tàu nhỏ màu xanh lá (fairy khác)
  Row 0 (col 9-11): Ship enemy đỏ nhỏ
  Row 1-2 (col 0-11): Các loại ship enemy / boss
  Row 3-4 (col 0-11): Mix bosses, castle parts, princess
  Row 5-7 (col 0-11): Đạn enemy, shield, explosion, khiên
"""

from PIL import Image
import numpy as np
import os
import shutil

SRC_ENEMY = "extracted_assets/AI/enemy.png"
SRC_SKY = "extracted_assets/AI/sky-force-needed-trim.png"
OUT_DIR = "extracted_assets/sprites"

CELL_W = 128
CELL_H = 128


def crop_cell(img, row, col, padding=2):
    """Cắt 1 cell từ grid, tự động trim vùng trống xung quanh."""
    x = col * CELL_W
    y = row * CELL_H
    cell = img.crop((x, y, x + CELL_W, y + CELL_H))
    arr = np.array(cell)
    alpha = arr[:, :, 3]
    if alpha.max() < 10:
        return None
    rows_with = np.where(alpha.max(axis=1) > 10)[0]
    cols_with = np.where(alpha.max(axis=0) > 10)[0]
    top = max(0, rows_with.min() - padding)
    bot = min(CELL_H, rows_with.max() + padding + 1)
    lft = max(0, cols_with.min() - padding)
    rgt = min(CELL_W, cols_with.max() + padding + 1)
    return cell.crop((lft, top, rgt, bot))


def crop_multi_cell(img, row, col_start, col_end, row_end=None, padding=2):
    """Cắt nhiều cell liên tiếp thành 1 sprite lớn (cho boss/castle)."""
    re = row if row_end is None else row_end
    x = col_start * CELL_W
    y = row * CELL_H
    xe = (col_end + 1) * CELL_W
    ye = (re + 1) * CELL_H
    region = img.crop((x, y, xe, ye))
    arr = np.array(region)
    alpha = arr[:, :, 3]
    if alpha.max() < 10:
        return None
    rows_with = np.where(alpha.max(axis=1) > 10)[0]
    cols_with = np.where(alpha.max(axis=0) > 10)[0]
    top = max(0, rows_with.min() - padding)
    bot = min(ye - y, rows_with.max() + padding + 1)
    lft = max(0, cols_with.min() - padding)
    rgt = min(xe - x, cols_with.max() + padding + 1)
    return region.crop((lft, top, rgt, bot))


def save(sprite, name):
    if sprite is None:
        print(f"  [SKIP] {name} - empty cell")
        return
    path = os.path.join(OUT_DIR, f"{name}.png")
    sprite.save(path)
    print(f"  [OK] {name}.png  {sprite.size}")


def clear_sprites_dir():
    if os.path.exists(OUT_DIR):
        for f in os.listdir(OUT_DIR):
            fp = os.path.join(OUT_DIR, f)
            if os.path.isfile(fp):
                os.remove(fp)
    else:
        os.makedirs(OUT_DIR)
    print(f"Cleared {OUT_DIR}")


def main():
    clear_sprites_dir()

    enemy = Image.open(SRC_ENEMY)
    sky = Image.open(SRC_SKY)

    print("\n=== ENEMY.PNG - Máy bay địch (row 1) ===")
    # Row 1: 12 loại máy bay địch khác nhau
    enemy_jet_names = [
        "enemy_jet_1_small",
        "enemy_jet_2_small_b",
        "enemy_jet_3_medium",
        "enemy_jet_4_medium_b",
        "enemy_jet_5_medium_c",
        "enemy_jet_6_medium_d",
        "enemy_jet_7_large",
        "enemy_jet_8_large_b",
        "enemy_jet_9_huge",
        "enemy_jet_10_huge_b",
        "enemy_jet_11_boss_a",
        "enemy_jet_12_boss_b",
    ]
    for col, name in enumerate(enemy_jet_names):
        save(crop_cell(enemy, 1, col), name)

    print("\n=== ENEMY.PNG - Ship enemy (row 3) ===")
    enemy_ship_names = [
        "enemy_ship_1",
        "enemy_ship_2",
        "enemy_ship_3",
        "enemy_ship_4",
        "enemy_ship_5",
        "enemy_ship_6",
        "enemy_ship_7",
        "enemy_ship_8",
        "enemy_ship_9",
        "enemy_ship_10",
        "enemy_ship_11",
        "enemy_ship_12",
    ]
    for col, name in enumerate(enemy_ship_names):
        save(crop_cell(enemy, 3, col), name)

    print("\n=== ENEMY.PNG - Tank địch (row 6) ===")
    tank_names_r6 = [
        "enemy_tank_1_small",
        "enemy_tank_2_small_b",
        "enemy_tank_3_medium",
        "enemy_tank_4_medium_b",
        "enemy_tank_5_large",
        "enemy_tank_6_large_b",
        "enemy_tank_7_huge",
        "enemy_tank_8_huge_b",
        "enemy_tank_9_boss_a",
        "enemy_tank_10_boss_b",
        "enemy_tank_11_boss_c",
        "enemy_tank_12_boss_d",
    ]
    for col, name in enumerate(tank_names_r6):
        save(crop_cell(enemy, 6, col), name)

    print("\n=== ENEMY.PNG - Tank/Ground địch (row 7) ===")
    tank_names_r7 = [
        "enemy_ground_1",
        "enemy_ground_2",
        "enemy_ground_3",
        "enemy_ground_4",
        "enemy_ground_5",
        "enemy_ground_6",
        "enemy_ground_7",
        "enemy_ground_8",
        "enemy_ground_9",
        "enemy_ground_10",
        "enemy_ground_11",
        "enemy_ground_12",
    ]
    for col, name in enumerate(tank_names_r7):
        save(crop_cell(enemy, 7, col), name)

    print("\n=== ENEMY.PNG - Đạn địch (row 0, các cell có nội dung) ===")
    bullet_r0 = {
        3: "enemy_bullet_small_a",
        4: "enemy_bullet_small_b",
        5: "enemy_bullet_bar_a",
        6: "enemy_bullet_bar_b",
        7: "enemy_bullet_orb_a",
        8: "enemy_bullet_orb_b",
        9: "enemy_bullet_orb_c",
        10: "enemy_bullet_large_a",
        11: "enemy_bullet_large_b",
    }
    for col, name in bullet_r0.items():
        save(crop_cell(enemy, 0, col), name)

    print("\n=== ENEMY.PNG - Parts/misc (row 2) ===")
    misc_r2 = {
        1: "enemy_part_wing_a",
        3: "enemy_part_body_a",
        5: "enemy_part_body_b",
        6: "enemy_part_body_c",
        7: "enemy_part_body_d",
        8: "enemy_part_hull_a",
        9: "enemy_part_hull_b",
        10: "enemy_part_hull_c",
        11: "enemy_part_hull_d",
    }
    for col, name in misc_r2.items():
        save(crop_cell(enemy, 2, col), name)

    print("\n=== ENEMY.PNG - Buff items (row 4) ===")
    # Màu phân tích: đỏ, cam, đỏ hồng, hồng, tím, tím nhạt, cyan, xanh lá, xanh lá, nâu, tím tối, tím
    buff_r4 = [
        "buff_bomb",           # [4,0] đỏ cam
        "buff_heart",          # [4,1] cam
        "buff_shield",         # [4,2] đỏ
        "buff_star",           # [4,3] hồng
        "buff_weapon_capsule", # [4,4] tím hồng
        "buff_wings",          # [4,5] tím nhạt
        "buff_magnet",         # [4,6] cyan
        "buff_gem",            # [4,7] xanh lá
        "buff_coin",           # [4,8] xanh lá nhạt
        "buff_crate_brown",    # [4,9] nâu
        "buff_crate_dark",     # [4,10] tím tối
        "buff_crate_purple",   # [4,11] tím
    ]
    for col, name in enumerate(buff_r4):
        save(crop_cell(enemy, 4, col), name)

    print("\n=== ENEMY.PNG - Buff items frame 2 (row 5) ===")
    buff_r5 = [
        "buff_bomb_b",
        "buff_heart_b",
        "buff_shield_b",
        "buff_star_b",
        "buff_weapon_capsule_b",
        "buff_wings_b",
        "buff_magnet_b",
        "buff_gem_b",
        "buff_coin_b",
        "buff_crate_brown_b",
        "buff_crate_red",
        "buff_crate_blue",
    ]
    for col, name in enumerate(buff_r5):
        save(crop_cell(enemy, 5, col), name)

    # ===== SKY-FORCE-NEEDED-TRIM.PNG =====
    print("\n=== SKY-FORCE - Tàu nhỏ xanh dương (tinh linh fairy - row 0 col 0-4) ===")
    # Tàu nhỏ từ sky-force → tinh linh companion
    fairy_blue = [
        "fairy_blue_a",
        "fairy_blue_b",
        "fairy_blue_c",
        "fairy_blue_d",
        "fairy_blue_e",
    ]
    for col, name in enumerate(fairy_blue):
        save(crop_cell(sky, 0, col), name)

    print("\n=== SKY-FORCE - Tàu nhỏ xanh lá (tinh linh - row 0 col 5-8) ===")
    fairy_green = {
        5: "fairy_green_a",
        6: "fairy_green_b",
        7: "fairy_green_c",
        8: "fairy_green_d",
    }
    for col, name in fairy_green.items():
        save(crop_cell(sky, 0, col), name)

    print("\n=== SKY-FORCE - Ship địch đỏ nhỏ (row 0 col 9-11) ===")
    sky_enemy_r0 = {
        9: "sky_enemy_red_small_a",
        10: "sky_enemy_red_small_b",
        11: "sky_enemy_red_small_c",
    }
    for col, name in sky_enemy_r0.items():
        save(crop_cell(sky, 0, col), name)

    print("\n=== SKY-FORCE - Ship địch (row 1) ===")
    sky_ship_r1 = [
        "sky_enemy_ship_1",
        "sky_enemy_ship_2",
        "sky_enemy_ship_3",
        "sky_enemy_ship_4",
        "sky_enemy_ship_5",
        "sky_enemy_ship_6",
        "sky_enemy_ship_7",
        "sky_enemy_ship_8",
        "sky_enemy_ship_9",
        "sky_enemy_ship_10",
        "sky_enemy_ship_11",
        "sky_enemy_ship_12",
    ]
    for col, name in enumerate(sky_ship_r1):
        save(crop_cell(sky, 1, col), name)

    print("\n=== SKY-FORCE - Ship địch / boss (row 2) ===")
    sky_ship_r2 = [
        "sky_enemy_medium_a",
        "sky_enemy_medium_b",
        "sky_enemy_medium_c",
        "sky_enemy_medium_d",
        "sky_enemy_medium_e",
        "sky_enemy_heavy_a",
        "sky_enemy_heavy_b",
        "sky_enemy_heavy_c",
        "sky_enemy_heavy_d",
        "sky_enemy_heavy_e",
        "sky_enemy_heavy_f",
        "sky_enemy_heavy_g",
    ]
    for col, name in enumerate(sky_ship_r2):
        save(crop_cell(sky, 2, col), name)

    print("\n=== SKY-FORCE - Boss / castle / princess (row 3) ===")
    # [3,0] xanh dương → lâu đài/castle hoặc boss đặc biệt
    # [3,1] cam → boss
    # [3,4] đỏ → boss
    # [3,7] cam đậm → boss rocket
    # [3,8] hồng → princess cage?
    sky_r3 = {
        0: "sky_castle_a",
        1: "sky_boss_orange",
        2: "sky_boss_grey_a",
        3: "sky_boss_grey_b",
        4: "sky_boss_red",
        5: "sky_boss_blue",
        6: "sky_boss_dark_blue",
        7: "sky_boss_rocket",
        8: "sky_princess_cage",
        9: "sky_boss_gold",
        10: "sky_enemy_fortess_a",
        11: "sky_enemy_fortress_b",
    }
    for col, name in sky_r3.items():
        save(crop_cell(sky, 3, col), name)

    print("\n=== SKY-FORCE - Mix bosses / shields (row 4) ===")
    sky_r4 = {
        0: "sky_castle_b",
        1: "sky_boss_orange_b",
        2: "sky_boss_grey_c",
        3: "sky_boss_grey_d",
        4: "sky_boss_fire",
        5: "sky_buff_shield_blue",
        6: "sky_boss_purple",
        7: "sky_boss_tan",
        8: "sky_enemy_dark",
        9: "sky_enemy_olive",
        10: "sky_enemy_dark_b",
        11: "sky_enemy_dark_c",
    }
    for col, name in sky_r4.items():
        save(crop_cell(sky, 4, col), name)

    print("\n=== SKY-FORCE - Đạn địch / shield / khiên (row 5) ===")
    sky_r5 = [
        "sky_enemy_bullet_red_a",
        "sky_enemy_bullet_red_b",
        "sky_enemy_bullet_orange_a",
        "sky_enemy_bullet_orange_b",
        "sky_enemy_bullet_orange_c",
        "sky_enemy_bullet_dark_a",
        "sky_enemy_bullet_fire_a",
        "sky_enemy_bullet_fire_b",
        "sky_shield_small",
        "sky_shield_medium_a",
        "sky_shield_medium_b",
        "sky_shield_large",
    ]
    for col, name in enumerate(sky_r5):
        save(crop_cell(sky, 5, col), name)

    print("\n=== SKY-FORCE - Đạn/explosion địch (row 6) ===")
    sky_r6 = [
        "sky_enemy_bullet_brown_a",
        "sky_enemy_bullet_brown_b",
        "sky_enemy_bullet_grey_a",
        "sky_enemy_bullet_pink_a",
        "sky_enemy_bullet_pink_b",
        "sky_enemy_bullet_dark_b",
        "sky_enemy_bullet_purple_a",
        "sky_enemy_bullet_tan",
        "sky_bullet_bar_grey",
        "sky_enemy_bullet_teal",
        "sky_enemy_bullet_green_a",
        "sky_enemy_bullet_green_b",
    ]
    for col, name in enumerate(sky_r6):
        save(crop_cell(sky, 6, col), name)

    print("\n=== SKY-FORCE - Bullets / explosions (row 7) ===")
    sky_r7 = [
        "sky_bullet_rocket_a",
        "sky_bullet_rocket_b",
        "sky_bullet_rocket_c",
        "sky_bullet_small_a",
        "sky_bullet_fire",
        "sky_bullet_dark",
        "sky_bullet_flat",
        "sky_bullet_green_a",
        "sky_bullet_grey_a",
        "sky_bullet_green_b",
        "sky_shield_blue",
        "sky_shield_teal",
    ]
    for col, name in enumerate(sky_r7):
        save(crop_cell(sky, 7, col), name)

    print("\n=== DONE ===")
    total = len([f for f in os.listdir(OUT_DIR) if f.endswith('.png')])
    print(f"Tổng: {total} sprites trong {OUT_DIR}")


if __name__ == "__main__":
    main()
