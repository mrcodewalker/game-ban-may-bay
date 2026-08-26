# -*- coding: utf-8 -*-
import sys, io, os
sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding='utf-8', errors='replace')

try:
    from PIL import Image
    import numpy as np
except ImportError:
    import subprocess
    subprocess.check_call([sys.executable, "-m", "pip", "install", "pillow", "numpy"])
    from PIL import Image
    import numpy as np

ROOT = os.path.dirname(os.path.abspath(__file__))
SRC  = os.path.join(ROOT, "extracted_assets", "AI")
OUT  = os.path.join(ROOT, "extracted_assets", "sprites")
os.makedirs(OUT, exist_ok=True)

saved = []

def remove_white_bg(img, thresh=232):
    img = img.convert("RGBA")
    data = img.getdata()
    new_data = [(255,255,255,0) if r>thresh and g>thresh and b>thresh else (r,g,b,a)
                for r,g,b,a in data]
    img.putdata(new_data)
    return img

def load_img(filename):
    path = os.path.join(SRC, filename)
    img  = Image.open(path).convert("RGBA")
    w, h = img.size
    corners = [img.getpixel((0,0)), img.getpixel((w-1,0)),
               img.getpixel((0,h-1)), img.getpixel((w-1,h-1))]
    white_cnt = sum(1 for r,g,b,a in corners if r>225 and g>225 and b>225)
    if white_cnt >= 3:
        img = remove_white_bg(img, thresh=232)
    print(f"\nLoaded: {filename}  ({w}x{h})")
    return img

def cs(img, x, y, w, h, name):
    iw, ih = img.size
    x2, y2 = min(x+w, iw), min(y+h, ih)
    if x2 <= x or y2 <= y:
        print(f"  [SKIP] {name}")
        return
    crop = img.crop((x, y, x2, y2))
    if crop.mode == "RGBA":
        bb = crop.getbbox()
        if bb:
            crop = crop.crop(bb)
    p = os.path.join(OUT, name)
    crop.save(p, "PNG")
    saved.append(name)
    print(f"  -> {name:50s} {crop.width}x{crop.height}")


# =============================================================
# ENEMY.PNG  (1536 x 1024)  - Measured via pixel scan
# Row 0 (jets, y=68..260): objects at x=18,146,275,438,588,834,1184
# Row 1 (tanks, y=250..480): objects at x=28,174,315,687,860,1030,1230
# Row 2 (bullets, y=470..650): objects at x=27,150,338,485,686,855,1229
# Row 3 (boss ships, y=635..1024): 2 large groups
# =============================================================
def extract_enemy():
    img = load_img("enemy.png")

    print("\n--- Enemy Jets (Row 1) ---")
    # 7 distinct jets detected by scanner
    # [0-1]: small jets, [2-3]: medium, [4]: large single, [5]: huge 2-engine, [6]: boss
    jet_data = [
        (18,  134, 108, 126, "enemy_jet_1_small.png"),
        (146, 135, 113, 125, "enemy_jet_2_medium.png"),
        (275, 111, 146, 149, "enemy_jet_3_medium_b.png"),
        (438, 111, 126, 149, "enemy_jet_4_medium_c.png"),
        (588,  99, 229, 161, "enemy_jet_5_large.png"),
        (834,  68, 334, 192, "enemy_jet_6_huge.png"),
        (1184,  9, 352, 251, "enemy_jet_7_boss.png"),
    ]
    for x,y,w,h,nm in jet_data:
        cs(img, x, y, w, h, nm)

    print("\n--- Enemy Tanks (Row 2) ---")
    # 7 tanks, merging small ones
    tank_data = [
        (28,  250,  89, 230, "enemy_tank_1_small.png"),
        (174, 250, 103, 230, "enemy_tank_2_small_b.png"),
        (315, 250, 340, 230, "enemy_tank_3_group.png"),   # 3 tanks close together
        (687, 250, 123, 230, "enemy_tank_4_medium.png"),
        (860, 250, 118, 230, "enemy_tank_5_large.png"),
        (1030,250, 131, 230, "enemy_tank_6_huge.png"),
        (1230,250, 225, 230, "enemy_tank_7_boss.png"),
    ]
    for x,y,w,h,nm in tank_data:
        cs(img, x, y, w, h, nm)

    # Split tank group manually (315..655 = 3 tanks each ~113px)
    cs(img, 315, 250, 115, 230, "enemy_tank_3a.png")
    cs(img, 430, 250, 115, 230, "enemy_tank_3b.png")
    cs(img, 545, 250, 110, 230, "enemy_tank_3c.png")

    print("\n--- Enemy Bullet Types (Row 3) ---")
    # 7 groups detected: red orbs, orange gems, red crystals, pink, purple orbs,
    # purple crystals, cyan, green, lasers, rockets, big purple
    bullet_data = [
        (27,  470,  91, 163, "enemy_bullet_orb_red.png"),
        (150, 470, 171, 180, "enemy_bullet_gems.png"),    # orange+red gems group
        (338, 470, 121, 180, "enemy_bullet_crystal_pink.png"),
        (485, 470, 160, 180, "enemy_bullet_orb_purple.png"),
        (686, 470, 138, 180, "enemy_bullet_cyan_laser.png"),
        (855, 470, 331, 180, "enemy_bullet_green_laser.png"),
        (1229,470, 269, 180, "enemy_bullet_purple_big.png"),
    ]
    for x,y,w,h,nm in bullet_data:
        cs(img, x, y, w, h, nm)

    # Split gems group into individual bullets
    cs(img, 150, 470, 85, 163, "enemy_bullet_orange_gem.png")
    cs(img, 240, 470, 85, 163, "enemy_bullet_red_crystal.png")

    # Split green laser group (3 sub-types)
    cs(img, 855,  470, 110, 180, "enemy_bullet_rocket_a.png")
    cs(img, 970,  470, 105, 180, "enemy_bullet_rocket_b.png")
    cs(img, 1080, 470, 105, 180, "enemy_bullet_rocket_c.png")

    print("\n--- Boss Ships (Row 4) ---")
    # 2 large groups: left= 4 boss ships, right = 2 spider mechs
    cs(img, 22,  635, 553, 355, "boss_ships_group.png")  # Full group
    cs(img, 597, 635, 904, 382, "boss_mechs_group.png")  # Mech group

    # Split bosses manually (each ~130-140px wide in left group of 4)
    cs(img, 22,  640, 135, 230, "boss_ship_a.png")
    cs(img, 162, 640, 140, 230, "boss_ship_b.png")
    cs(img, 307, 640, 140, 235, "boss_tank_ground.png")
    cs(img, 452, 640, 120, 235, "boss_orb_ship.png")

    # Right group: 2 spider mechs
    cs(img, 600, 635, 320, 370, "boss_spider_a.png")
    cs(img, 920, 635, 310, 370, "boss_spider_b.png")

    # Aliases for game use
    cs(img, 18,  134, 108, 126, "GAME_enemy_jet_small.png")
    cs(img, 588,  99, 229, 161, "GAME_enemy_jet_large.png")
    cs(img, 28,  250,  89, 230, "GAME_enemy_tank.png")
    cs(img, 860, 250, 118, 230, "GAME_enemy_tank_heavy.png")
    cs(img, 27,  470,  91, 163, "GAME_enemy_bullet_orb.png")
    cs(img, 686, 470, 138, 180, "GAME_enemy_bullet_laser.png")


# =============================================================
# SKY-FORCE-NEEDED-TRIM.PNG  (1536 x 1024) - Measured via pixel scan
# Row y=0-155:    Player jets x5, enemy green x2, helis x2, big boss right
# Row y=155-310:  Player jet variant, winged ships, rocket fairies, enemy jets
# Row y=310-445:  Flat fairy ships, small items, rockets strip, boss med right
# Row y=445-615:  Bullets (blue drops, lasers), buffs RIGHT side
# Row y=610-730:  Explosions
# Row y=725-830:  Buffs/powerups row 1
# Row y=825-1024: Buffs row2, Princess row, UI, Helipad, Castle
# =============================================================
def extract_skyforce():
    img = load_img("sky-force-needed-trim.png")

    print("\n--- Player Jets (Row 1, y=10-155) ---")
    # 5 player jets detected at x=15,159,298,433,563
    player_jets = [
        (15,  11, 128, 144, "player_jet_1.png"),   # Jet variant 1
        (159, 10, 125, 145, "player_jet_2.png"),   # Jet variant 2
        (298, 10, 120, 145, "player_jet_3.png"),   # Jet variant 3
        (433, 10, 115, 145, "player_jet_4.png"),   # Jet variant 4
        (563, 11,  69, 143, "player_jet_5.png"),   # Jet variant 5 (small)
    ]
    for x,y,w,h,nm in player_jets:
        cs(img, x, y, w, h, nm)

    print("\n--- Enemy Jets green/heli (Row 1 right, y=10-155) ---")
    sky_enemy_row1 = [
        (669, 14,  98, 141, "sky_enemy_jet_green_a.png"),
        (789, 14,  97, 141, "sky_enemy_jet_green_b.png"),
        (907, 11, 120, 144, "sky_enemy_heli_a.png"),   # Two helis grouped
        (1050, 11, 120, 144, "sky_enemy_heli_b.png"),
        (1295, 10, 241, 145, "sky_enemy_boss_jet.png"), # Boss jet right
    ]
    for x,y,w,h,nm in sky_enemy_row1:
        cs(img, x, y, w, h, nm)

    print("\n--- Player Jet variants + Fairy ships (Row 2, y=155-310) ---")
    row2 = [
        (15,  155, 127, 155, "player_jet_6.png"),        # Alt jet
        (158, 155, 109, 131, "player_jet_7_disc.png"),   # Disc/medal variant
        (282, 155, 187, 155, "player_jet_8_winged.png"), # Winged golden jet
    ]
    for x,y,w,h,nm in row2:
        cs(img, x, y, w, h, nm)

    # Rocket fairy sub-ships (small wing-men, y~186)
    cs(img, 485, 155, 49, 155, "fairy_rocket_a.png")  # Golden rocket
    cs(img, 549, 186, 46, 124, "fairy_rocket_b.png")  # Smaller variant
    cs(img, 607, 186, 38, 124, "fairy_rocket_c.png")  # Smallest

    # Enemy jets row2 right (grey jets)
    grey_jets_r2 = img.crop((669, 155, 1290, 310))
    # 780..1289 = 4 grey jets, each ~127px wide
    cs(img, 669,  155, 122, 155, "sky_enemy_grey_jet_a.png")
    cs(img, 791,  155, 122, 155, "sky_enemy_grey_jet_b.png")
    cs(img, 908,  155, 121, 155, "sky_enemy_grey_jet_c.png")
    cs(img, 1030, 155, 120, 155, "sky_enemy_grey_jet_d.png")
    cs(img, 1152, 155, 127, 155, "sky_enemy_grey_heli_a.png")
    cs(img, 1329, 155, 169, 155, "sky_enemy_boss_medium.png")

    print("\n--- Disc Fairies + small items (Row 3, y=310-445) ---")
    # [0]=disc fairy a x=19, [1]=disc fairy group x=107, [2]=gold flame group x=369
    cs(img, 19,  310,  67, 135, "fairy_disc_a.png")    # Blue disc fairy
    cs(img, 107, 314, 122, 131, "fairy_disc_b.png")    # Disc variant b
    cs(img, 237, 314, 120, 131, "fairy_disc_c.png")    # Disc variant c

    # Golden flame sub-ships (x=369..543)
    cs(img, 369, 310,  85, 135, "fairy_flame_gold_a.png")
    cs(img, 458, 310,  85, 135, "fairy_flame_gold_b.png")

    # Enemy red jets row3 (right side)
    cs(img, 560, 310, 110, 135, "sky_enemy_red_jet_a.png")
    cs(img, 683, 310,  67, 135, "sky_enemy_red_jet_b.png")
    cs(img, 779, 310,  73, 135, "sky_enemy_red_jet_c.png")
    cs(img, 867, 310, 111, 122, "sky_enemy_red_jet_d.png")

    # Rockets row3 right (small enemy projectiles)
    cs(img, 996,  310, 38, 120, "sky_rocket_a.png")
    cs(img, 1059, 310, 31, 119, "sky_rocket_b.png")
    cs(img, 1118, 310, 37, 113, "sky_rocket_c.png")
    cs(img, 1229, 310, 45, 135, "sky_rocket_d.png")
    cs(img, 1308, 310, 210, 135, "sky_enemy_boss_medium_b.png")

    print("\n--- Player Bullets (Row 4 left, y=440-620) ---")
    # Pixel-scanned coords - individual bullets in single columns
    cs(img,  31, 440,  27, 177, "bullet_blue_drop_a.png")    # Blue teardrop (1 col)
    cs(img,  96, 440,  57, 176, "bullet_blue_drops.png")     # Blue drops (3 col)
    cs(img, 198, 440,  29, 176, "bullet_fire_drop_a.png")    # Orange fire drop
    cs(img, 268, 440,  28, 180, "bullet_fire_drop_b.png")    # Orange-red drop
    cs(img, 333, 440,  24, 174, "bullet_laser_thin_a.png")   # Thin laser a
    cs(img, 368, 440,  27, 174, "bullet_laser_thin_b.png")   # Thin laser b
    cs(img, 423, 440,  34, 178, "bullet_laser_blue.png")     # Laser beam blue
    cs(img, 483, 440,  29, 180, "bullet_laser_blue_b.png")   # Laser blue b
    cs(img, 553, 440,  37, 178, "bullet_laser_fire.png")     # Fire laser
    cs(img, 618, 440,  37, 154, "bullet_laser_fire_b.png")   # Fire laser b
    cs(img, 690, 440,  38, 169, "bullet_laser_purple.png")   # Purple laser
    cs(img, 775, 443,  55, 177, "bullet_rocket_a.png")       # Rocket a
    cs(img, 876, 448, 163, 172, "bullet_rocket_group.png")   # Rocket group (b+c)

    print("\n--- Buff/Powerup Items (pixel-accurate from visual) ---")
    # Visual inspection of buff strip (x starting from 640):
    # laser blue at x=640-690, THEN:
    # shield~x=775, heart~x=850, coin~x=945, gem~x=1020, wings~x=1095
    # Row2: magnet~x=1185, capsule~x=1250, star~x=1310, bomb~x=1375
    # Crates: x=1450+
    # Scanner found: x=690(laser w=52), x=775(shield w=69 -> but w=69 is too wide!)
    # x=874(coin+gem+wings combined w=165 -> need to split)
    # x=1068(magnet w=76), x=1178(capsule+star+bomb+crates w=341)
    # Correct individual widths (each buff ~90px wide in original 1536px image):
    cs(img,  774, 418,  93, 105, "buff_shield.png")         # Blue shield
    cs(img,  871, 418,  93, 105, "buff_heart.png")          # Red heart
    cs(img,  965, 418,  93, 105, "buff_coin.png")           # Gold coin
    cs(img, 1059, 418,  93, 105, "buff_gem.png")            # Purple gem/diamond
    cs(img, 1153, 418,  93, 105, "buff_wings.png")          # Golden wings
    # Row 2 (below row 1, same x positions):
    cs(img,  774, 518,  93, 105, "buff_magnet.png")         # Magnet
    cs(img,  871, 518,  93, 105, "buff_weapon_capsule.png") # Weapon capsule
    cs(img,  965, 518,  93, 105, "buff_star.png")           # Gold star
    cs(img, 1059, 518,  93, 105, "buff_bomb.png")           # Bomb skull
    # Crates (4 different color crates after the bomb)
    cs(img, 1153, 518,  93, 105, "buff_crate_green.png")    # Green crate
    cs(img, 1249, 518,  93, 105, "buff_crate_red.png")      # Red crate
    cs(img, 1343, 518,  93, 105, "buff_crate_blue.png")     # Blue crate
    cs(img, 1437, 518,  93, 105, "buff_crate_purple.png")   # Purple crate

    print("\n--- Explosions (Row 5, y=610-730) ---")
    exps = [
        (63,  610,  53,  96, "exp_tiny.png"),
        (135, 610,  80, 100, "exp_small.png"),
        (234, 610,  68, 100, "exp_medium.png"),
        (340, 610,  71, 101, "exp_large.png"),
        (431, 610, 111, 114, "exp_huge.png"),
        (568, 610, 114, 106, "exp_orange.png"),
        (723, 616, 121, 105, "exp_fire.png"),
        (891, 611, 119, 110, "exp_big.png"),
        (1045,620,  77, 103, "exp_smoke_a.png"),
        (1152,636,  98,  85, "exp_smoke_b.png"),
        (1290,610, 246, 120, "exp_fire_huge.png"),
    ]
    for x,y,w,h,nm in exps:
        cs(img, x, y, w, h, nm)

    print("\n--- Princess, Cage, Rescued (Row 7, y=825-1010) ---")
    # Scanner: [1] x=418 w=254 h=179 = 2 princess poses
    # [2] x=700 w=75 = cage
    # [3] x=799 w=101 = rescued couple? 
    cs(img, 418, 825, 120, 179, "princess_idle.png")
    cs(img, 543, 825, 125, 179, "princess_freed.png")
    cs(img, 700, 825,  75,  85, "princess_cage.png")
    cs(img, 799, 825, 101, 101, "princess_rescued.png")   # Knight + princess
    cs(img, 910, 825,  90, 110, "princess_happy.png")

    print("\n--- Helipad + Castle (y=825-1024 right) ---")
    # [4] x=948 w=588 h=182 contains helipad + castle
    cs(img, 948,  825, 295, 182, "helipad.png")
    cs(img, 1200, 700, 330, 320, "castle.png")

    print("\n--- UI (y=825-1024 left) ---")
    cs(img, 12,  825, 376, 165, "ui_hud_lives.png")
    cs(img, 12,  900, 280,  90, "ui_skyforce_logo.png")
    cs(img, 418, 905, 250,  90, "ui_rescue_banner.png")

    print("\n--- GAME aliases (best picks for immediate use) ---")
    cs(img, 15,   11, 128, 144, "GAME_player_jet.png")         # Main player jet
    cs(img, 669,  14,  98, 141, "GAME_enemy_jet_green.png")    # Green enemy jet
    cs(img, 907,  11, 243, 144, "GAME_enemy_heli.png")         # Helicopter enemy
    cs(img, 977, 448,  62, 140, "GAME_buff_shield.png")        # Shield powerup
    cs(img, 1083,448,  61, 148, "GAME_buff_heart.png")         # Heart powerup
    cs(img, 701, 739,  74,  91, "GAME_buff_star.png")          # Star
    cs(img, 817, 731,  85,  99, "GAME_buff_bomb.png")          # Bomb
    cs(img,  0,  445,  90, 170, "GAME_bullet_player.png")      # Player bullet
    cs(img, 334, 445,  60, 169, "GAME_bullet_laser.png")       # Laser beam
    cs(img, 418, 825, 120, 179, "GAME_princess.png")           # Princess
    cs(img, 700, 825,  75,  85, "GAME_princess_cage.png")      # Princess in cage
    cs(img, 948, 825, 295, 182, "GAME_helipad.png")            # Helipad
    # Fairy ships (wing-men):
    cs(img, 369, 310,  85, 135, "GAME_fairy_left.png")         # Left fairy ship
    cs(img, 458, 310,  85, 135, "GAME_fairy_right.png")        # Right fairy ship
    cs(img, 19,  310,  67, 135, "GAME_fairy_disc.png")         # Disc fairy


# =============================================================
if __name__ == "__main__":
    print("="*65)
    print("  SPRITE EXTRACTOR v3 - Pixel-accurate coordinates")
    print("="*65)
    extract_enemy()
    extract_skyforce()
    print(f"\n  Done! {len(saved)} sprites -> {OUT}")
    print("="*65)
