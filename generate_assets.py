#!/usr/bin/env python3
"""Generate pixel art assets for Crimson Vesper Godot project."""

from PIL import Image, ImageDraw
import math
import os

BASE = os.path.join(os.path.dirname(__file__), "godot", "assets")

# ─── Palette ────────────────────────────────────────────────────────────────
TRANSPARENT   = (0, 0, 0, 0)
BLACK         = (0, 0, 0, 255)
DARK_BG       = (10, 8, 18, 255)

# Player – dark purple/blue armor
ARMOR_DARK    = (28, 22, 58, 255)
ARMOR_MID     = (45, 38, 90, 255)
ARMOR_LIGHT   = (70, 60, 130, 255)
SILVER        = (180, 185, 200, 255)
SILVER_DARK   = (120, 125, 140, 255)
CAPE_DARK     = (80, 10, 20, 255)
CAPE_MID      = (120, 18, 30, 255)
CAPE_LIGHT    = (160, 28, 45, 255)
SKIN          = (220, 185, 155, 255)
SWORD_BLADE   = (210, 220, 235, 255)
SWORD_GOLD    = (200, 170, 60, 255)

# Skeleton
BONE_BRIGHT   = (230, 225, 210, 255)
BONE_MID      = (180, 175, 160, 255)
BONE_DARK     = (120, 115, 100, 255)
SKEL_BG       = (0, 0, 0, 0)

# Bat
BAT_DARK      = (35, 15, 55, 255)
BAT_MID       = (60, 25, 85, 255)
BAT_LIGHT     = (90, 40, 120, 255)
BAT_EYE       = (220, 60, 60, 255)

# Tileset gothic
STONE_DARK    = (42, 42, 58, 255)
STONE_MID     = (74, 74, 90, 255)
STONE_LIGHT   = (106, 106, 122, 255)
MORTAR        = (26, 26, 42, 255)
MOSS          = (40, 65, 40, 255)
TORCH_BASE    = (80, 60, 40, 255)
TORCH_FLAME1  = (255, 102, 51, 255)
TORCH_FLAME2  = (255, 170, 51, 255)
TORCH_FLAME3  = (255, 221, 102, 255)
SPIKE_METAL   = (90, 95, 110, 255)
SPIKE_TIP     = (200, 210, 225, 255)
DOOR_DARK     = (30, 20, 15, 255)
DOOR_MID      = (55, 38, 28, 255)
DOOR_LIGHT    = (80, 60, 42, 255)
DOOR_METAL    = (100, 100, 120, 255)

# Backgrounds
BG_FAR_BASE   = (8, 6, 20, 255)
BG_FAR_STONE  = (18, 14, 38, 255)
BG_FAR_ARCH   = (25, 20, 50, 255)
BG_MID_BASE   = (12, 9, 28, 255)
BG_MID_STONE  = (28, 22, 55, 255)
BG_MID_ARCH   = (38, 30, 70, 255)
BG_NEAR_BASE  = (16, 12, 35, 255)
BG_NEAR_STONE = (40, 32, 75, 255)
BG_NEAR_ARCH  = (55, 44, 95, 255)


# ─── Helper: pixel setter ────────────────────────────────────────────────────
def px(img, x, y, color):
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), color)


def row(img, x1, x2, y, color):
    for x in range(x1, x2 + 1):
        px(img, x, y, color)


def col(img, x, y1, y2, color):
    for y in range(y1, y2 + 1):
        px(img, x, y, color)


def rect(img, x1, y1, x2, y2, color):
    for y in range(y1, y2 + 1):
        row(img, x1, x2, y, color)


def outline_rect(img, x1, y1, x2, y2, color):
    row(img, x1, x2, y1, color)
    row(img, x1, x2, y2, color)
    col(img, x1, y1, y2, color)
    col(img, x2, y1, y2, color)


# ─── PLAYER SPRITESHEET  32×48 per frame ────────────────────────────────────
# Frames: 4 idle, 6 run, 2 jump, 2 fall, 4 attack, 2 dash = 20 total
# Width = 20 * 32 = 640,  Height = 48

def draw_knight(img, ox, oy, pose="idle", frame=0):
    """Draw a humanoid knight (dark purple armor, cape, sword) at offset ox,oy."""
    # ── Cape (behind body) ──────────────────────────────────────────────────
    cape_flap = 0
    if pose == "run":
        cape_flap = [-2, -3, -2, -1, 0, -1][frame % 6]
    elif pose in ("jump", "fall"):
        cape_flap = 2
    elif pose == "dash":
        cape_flap = -4

    cape_color = CAPE_MID if frame % 2 == 0 else CAPE_DARK
    # Cape body
    rect(img, ox+12, oy+8, ox+12+abs(cape_flap)+4, oy+28, CAPE_DARK)
    rect(img, ox+13, oy+9, ox+13+abs(cape_flap)+2, oy+26, cape_color)
    # Cape bottom tapers
    for i in range(4):
        rect(img, ox+13, oy+27+i, ox+13+max(0, abs(cape_flap)+1-i), oy+27+i, CAPE_DARK)

    # ── Legs ────────────────────────────────────────────────────────────────
    leg_offset_l = 0
    leg_offset_r = 0
    if pose == "run":
        cycle = [0, 2, 3, 0, -2, -3]
        leg_offset_l = cycle[frame % 6]
        leg_offset_r = cycle[(frame + 3) % 6]
    elif pose == "jump":
        leg_offset_l = -3
        leg_offset_r = 3
    elif pose == "fall":
        leg_offset_l = -2
        leg_offset_r = 2

    # Left leg
    rect(img, ox+10, oy+28+max(0, leg_offset_l), ox+13, oy+38+max(0, leg_offset_l), ARMOR_MID)
    rect(img, ox+10, oy+36+max(0, leg_offset_l), ox+13, oy+42+max(0, leg_offset_l), ARMOR_DARK)  # boot
    # Right leg
    rect(img, ox+18, oy+28+max(0, leg_offset_r), ox+21, oy+38+max(0, leg_offset_r), ARMOR_MID)
    rect(img, ox+18, oy+36+max(0, leg_offset_r), ox+21, oy+42+max(0, leg_offset_r), ARMOR_DARK)  # boot

    # ── Body / torso ─────────────────────────────────────────────────────────
    body_y = oy + 14
    if pose in ("jump",) and frame == 0:
        body_y = oy + 16  # crouch
    rect(img, ox+9, body_y, ox+22, body_y+13, ARMOR_MID)
    rect(img, ox+10, body_y+1, ox+21, body_y+12, ARMOR_LIGHT)
    # Chest plate highlight
    row(img, ox+12, ox+19, body_y+2, SILVER_DARK)
    row(img, ox+13, ox+18, body_y+3, SILVER)
    # Pauldrons (shoulders)
    rect(img, ox+7, body_y, ox+10, body_y+4, ARMOR_DARK)
    rect(img, ox+21, body_y, ox+24, body_y+4, ARMOR_DARK)
    px(img, ox+8, body_y+1, SILVER_DARK)
    px(img, ox+22, body_y+1, SILVER_DARK)

    # ── Sword arm ────────────────────────────────────────────────────────────
    sword_x = ox + 23
    sword_y = body_y + 3
    attack_angle = 0
    if pose == "attack":
        swing = [(-8, -4), (-4, -2), (4, 4), (8, 6)][frame % 4]
        sword_x += swing[0]
        sword_y += swing[1]
    elif pose == "run":
        sword_y += [-1, 0, 1, 0, -1, 0][frame % 6]

    # Sword handle
    rect(img, sword_x, sword_y+2, sword_x+2, sword_y+5, SWORD_GOLD)
    # Cross-guard
    rect(img, sword_x-2, sword_y+5, sword_x+4, sword_y+6, SWORD_GOLD)
    # Blade (7px long)
    col(img, sword_x+1, sword_y-7, sword_y+4, SWORD_BLADE)
    col(img, sword_x, sword_y-5, sword_y+3, SWORD_BLADE)
    px(img, sword_x+1, sword_y-7, SILVER)  # tip highlight

    # ── Shield/off arm ──────────────────────────────────────────────────────
    shield_x = ox + 6
    shield_y = body_y + 4
    rect(img, shield_x, shield_y, shield_x+3, shield_y+6, ARMOR_DARK)
    rect(img, shield_x+1, shield_y+1, shield_x+2, shield_y+5, SILVER_DARK)

    # ── Neck ────────────────────────────────────────────────────────────────
    rect(img, ox+13, body_y-2, ox+18, body_y, SKIN)

    # ── Helmet ──────────────────────────────────────────────────────────────
    helm_y = oy + 2
    if pose in ("jump",) and frame == 0:
        helm_y = oy + 4
    # Dome
    rect(img, ox+10, helm_y+2, ox+21, helm_y+8, ARMOR_DARK)
    rect(img, ox+11, helm_y+1, ox+20, helm_y+8, ARMOR_MID)
    row(img, ox+12, ox+19, helm_y, ARMOR_MID)
    # Visor slit
    row(img, ox+12, ox+20, helm_y+5, MORTAR)
    # Plume
    col(img, ox+15, oy, helm_y+1, CAPE_LIGHT)
    col(img, ox+16, oy, helm_y+1, CAPE_MID)
    # Cheek guards
    rect(img, ox+10, helm_y+6, ox+11, helm_y+10, ARMOR_DARK)
    rect(img, ox+20, helm_y+6, ox+21, helm_y+10, ARMOR_DARK)

    # ── Idle breathing offset ────────────────────────────────────────────────
    # (already baked into individual frame positions above for simple cases)


def make_player_spritesheet():
    # 20 frames × 32 wide × 48 tall
    frames_config = [
        ("idle",   4),
        ("run",    6),
        ("jump",   2),
        ("fall",   2),
        ("attack", 4),
        ("dash",   2),
    ]
    total = sum(n for _, n in frames_config)
    img = Image.new("RGBA", (total * 32, 48), TRANSPARENT)

    frame_idx = 0
    for pose, count in frames_config:
        for f in range(count):
            ox = frame_idx * 32
            oy = 0
            # subtle idle breath
            if pose == "idle":
                oy = f % 2  # shift 0 or 1px
            draw_knight(img, ox, oy, pose=pose, frame=f)
            frame_idx += 1

    path = os.path.join(BASE, "sprites", "player", "player_spritesheet.png")
    img.save(path)
    print(f"  Saved {path}  ({img.width}×{img.height})")


# ─── SKELETON  32×32 per frame ──────────────────────────────────────────────
# 4 idle, 4 walk, 2 attack, 2 death = 12 total

def draw_skeleton(img, ox, oy, pose="idle", frame=0):
    # Legs
    leg_l = 0
    leg_r = 0
    if pose == "walk":
        cycle = [0, 2, 0, -2]
        leg_l = cycle[frame % 4]
        leg_r = cycle[(frame + 2) % 4]

    # Left tibia + femur
    col(img, ox+10, oy+18+max(0, leg_l), oy+25+max(0, leg_l), BONE_MID)
    col(img, ox+11, oy+18+max(0, leg_l), oy+25+max(0, leg_l), BONE_BRIGHT)
    # Left foot
    rect(img, ox+8, oy+24+max(0, leg_l), ox+12, oy+26+max(0, leg_l), BONE_DARK)
    # Right tibia
    col(img, ox+20, oy+18+max(0, leg_r), oy+25+max(0, leg_r), BONE_MID)
    col(img, ox+21, oy+18+max(0, leg_r), oy+25+max(0, leg_r), BONE_BRIGHT)
    # Right foot
    rect(img, ox+20, oy+24+max(0, leg_r), ox+24, oy+26+max(0, leg_r), BONE_DARK)

    # Pelvis
    rect(img, ox+10, oy+16, ox+21, oy+18, BONE_MID)

    # Spine
    for i in range(8):
        c = BONE_BRIGHT if i % 2 == 0 else BONE_MID
        rect(img, ox+14, oy+8+i, ox+17, oy+8+i, c)

    # Ribcage
    rect(img, ox+9, oy+9, ox+22, oy+15, TRANSPARENT)  # clear first
    for rib in range(3):
        row(img, ox+9, ox+22, oy+10+rib*2, BONE_DARK)
        row(img, ox+10, ox+21, oy+10+rib*2, BONE_MID)
    # Sternum
    col(img, ox+15, oy+9, oy+15, BONE_BRIGHT)

    # Left arm
    arm_l_raise = 0
    arm_r_raise = 0
    if pose == "attack":
        arm_r_raise = -4 if frame == 0 else 4
    col(img, ox+7, oy+10+arm_l_raise, oy+18+arm_l_raise, BONE_MID)
    col(img, ox+8, oy+10+arm_l_raise, oy+18+arm_l_raise, BONE_BRIGHT)
    # Right arm
    col(img, ox+23, oy+10+arm_r_raise, oy+18+arm_r_raise, BONE_MID)
    col(img, ox+24, oy+10+arm_r_raise, oy+18+arm_r_raise, BONE_BRIGHT)
    # Claws
    for cx in [ox+5, ox+6, ox+7]:
        px(img, cx, oy+19+arm_l_raise, BONE_DARK)
    for cx in [ox+24, ox+25, ox+26]:
        px(img, cx, oy+19+arm_r_raise, BONE_DARK)

    # Skull
    skull_y = oy + 2
    if pose == "death":
        skull_y = oy + 18 + frame * 4  # falling
    rect(img, ox+12, skull_y+2, ox+19, skull_y+7, BONE_MID)
    rect(img, ox+11, skull_y+3, ox+20, skull_y+6, BONE_BRIGHT)
    row(img, ox+13, ox+18, skull_y+1, BONE_MID)
    row(img, ox+13, ox+18, skull_y+8, BONE_DARK)
    # Eye sockets
    rect(img, ox+12, skull_y+3, ox+14, skull_y+5, MORTAR)
    rect(img, ox+17, skull_y+3, ox+19, skull_y+5, MORTAR)
    px(img, ox+13, skull_y+4, (60, 60, 80, 255))
    px(img, ox+18, skull_y+4, (60, 60, 80, 255))
    # Jaw
    rect(img, ox+12, skull_y+7, ox+19, skull_y+9, BONE_MID)
    for tx in range(ox+13, ox+19, 2):
        px(img, tx, skull_y+9, BONE_BRIGHT)


def make_skeleton_spritesheet():
    frames_config = [
        ("idle",   4),
        ("walk",   4),
        ("attack", 2),
        ("death",  2),
    ]
    total = sum(n for _, n in frames_config)
    img = Image.new("RGBA", (total * 32, 32), TRANSPARENT)
    frame_idx = 0
    for pose, count in frames_config:
        for f in range(count):
            draw_skeleton(img, frame_idx * 32, 0, pose=pose, frame=f)
            frame_idx += 1
    path = os.path.join(BASE, "sprites", "enemies", "skeleton_spritesheet.png")
    img.save(path)
    print(f"  Saved {path}  ({img.width}×{img.height})")


# ─── BAT  16×16 per frame, 4 fly frames ─────────────────────────────────────

def draw_bat(img, ox, oy, frame=0):
    # Body
    rect(img, ox+6, oy+7, ox+9, oy+11, BAT_DARK)
    rect(img, ox+7, oy+6, ox+8, oy+12, BAT_MID)
    # Eyes
    px(img, ox+6, oy+7, BAT_EYE)
    px(img, ox+9, oy+7, BAT_EYE)
    # Wing positions cycle
    wing_offsets = [(0, 3), (1, 1), (0, -1), (-1, 1)]  # (x_spread, y_pos)
    ws, wy = wing_offsets[frame % 4]

    # Left wing
    wing_y = oy + 5 + wy
    for i in range(6 + ws):
        wc = BAT_MID if i < 3 else BAT_DARK
        col(img, ox + 5 - i, wing_y, wing_y + 3, wc)
    # Right wing
    for i in range(6 + ws):
        wc = BAT_MID if i < 3 else BAT_DARK
        col(img, ox + 10 + i, wing_y, wing_y + 3, wc)
    # Wing membrane details
    px(img, ox+4, wing_y+1, BAT_LIGHT)
    px(img, ox+11, wing_y+1, BAT_LIGHT)
    # Ears
    px(img, ox+7, oy+5, BAT_DARK)
    px(img, ox+8, oy+5, BAT_DARK)


def make_bat_spritesheet():
    img = Image.new("RGBA", (64, 16), TRANSPARENT)
    for f in range(4):
        draw_bat(img, f * 16, 0, frame=f)
    path = os.path.join(BASE, "sprites", "enemies", "bat_spritesheet.png")
    img.save(path)
    print(f"  Saved {path}  ({img.width}×{img.height})")


# ─── CASTLE TILESET  32×32 each, 4-column grid ──────────────────────────────
# Tile layout (row, col):
#  0: stone_floor    1: stone_wall     2: platform       3: pillar_top
#  4: pillar_mid     5: pillar_base    6: torch_f1       7: torch_f2
#  8: torch_f3       9: bg_stone      10: spikes        11: door

TILE_W = 32
TILE_H = 32
GRID_COLS = 4


def tile_offset(idx):
    r = idx // GRID_COLS
    c = idx % GRID_COLS
    return c * TILE_W, r * TILE_H


def draw_stone_floor(img, ox, oy):
    rect(img, ox, oy, ox+31, oy+31, STONE_MID)
    # Mortar lines
    for my in [oy+7, oy+15, oy+23, oy+31]:
        row(img, ox, ox+31, my, MORTAR)
    for y_band in [0, 8, 16, 24]:
        offset = 16 if (y_band // 8) % 2 == 0 else 0
        for mx in range(offset, 32, 16):
            col(img, ox+mx, oy+y_band, oy+y_band+7, MORTAR)
    # Surface cracks
    px(img, ox+4, oy+3, STONE_DARK)
    px(img, ox+5, oy+4, STONE_DARK)
    px(img, ox+20, oy+11, STONE_DARK)
    px(img, ox+21, oy+12, STONE_DARK)
    # Highlights on top edge
    row(img, ox, ox+31, oy, STONE_LIGHT)


def draw_stone_wall(img, ox, oy):
    rect(img, ox, oy, ox+31, oy+31, STONE_DARK)
    # Brick pattern
    for by in range(0, 32, 8):
        offset = 16 if (by // 8) % 2 == 0 else 0
        rect(img, ox, oy+by, ox+31, oy+by+6, STONE_MID)
        row(img, ox, ox+31, oy+by+7, MORTAR)
        for bx in range(offset, 32, 16):
            col(img, ox+bx, oy+by, oy+by+6, MORTAR)
    # Moss specks
    for mx, my in [(3, 2), (14, 10), (25, 18), (6, 26)]:
        px(img, ox+mx, oy+my, MOSS)
        px(img, ox+mx+1, oy+my, MOSS)


def draw_platform(img, ox, oy):
    # Top surface
    row(img, ox, ox+31, oy, STONE_LIGHT)
    row(img, ox, ox+31, oy+1, STONE_MID)
    rect(img, ox, oy+2, ox+31, oy+10, STONE_MID)
    rect(img, ox, oy+11, ox+31, oy+31, STONE_DARK)
    # Mortar on face
    for my in [oy+5, oy+10]:
        row(img, ox, ox+31, my, MORTAR)
    for mx in [ox+8, ox+16, ox+24]:
        col(img, mx, oy+2, oy+9, MORTAR)
    # Worn edge chips
    px(img, ox, oy, STONE_MID)
    px(img, ox+31, oy, STONE_MID)


def draw_pillar_top(img, ox, oy):
    rect(img, ox+4, oy, ox+27, oy+4, STONE_LIGHT)
    rect(img, ox+6, oy+4, ox+25, oy+31, STONE_MID)
    col(img, ox+6, oy+4, oy+31, STONE_LIGHT)
    col(img, ox+25, oy+4, oy+31, STONE_DARK)
    # Cap details
    row(img, ox+4, ox+27, oy+2, STONE_LIGHT)
    px(img, ox+4, oy, MORTAR)
    px(img, ox+27, oy, MORTAR)


def draw_pillar_mid(img, ox, oy):
    rect(img, ox+6, oy, ox+25, oy+31, STONE_MID)
    col(img, ox+6, oy, oy+31, STONE_LIGHT)
    col(img, ox+25, oy, oy+31, STONE_DARK)
    # Vertical groove
    col(img, ox+15, oy, oy+31, STONE_DARK)
    col(img, ox+16, oy, oy+31, STONE_MID)


def draw_pillar_base(img, ox, oy):
    rect(img, ox+6, oy, ox+25, oy+26, STONE_MID)
    col(img, ox+6, oy, oy+26, STONE_LIGHT)
    col(img, ox+25, oy, oy+26, STONE_DARK)
    # Base spread
    rect(img, ox+3, oy+27, ox+28, oy+31, STONE_MID)
    row(img, ox+3, ox+28, oy+27, STONE_LIGHT)
    row(img, ox+3, ox+28, oy+31, MORTAR)


def draw_torch(img, ox, oy, flame_frame=0):
    # Wall mount
    rect(img, ox+13, oy+16, ox+18, oy+28, TORCH_BASE)
    # Bracket
    rect(img, ox+10, oy+14, ox+21, oy+17, STONE_DARK)
    px(img, ox+15, oy+14, TORCH_BASE)
    # Flame
    flames = [
        [(15, 4), (14, 5), (15, 5), (16, 5), (14, 6), (16, 6), (14, 7), (15, 7), (16, 7),
         (13, 8), (15, 8), (17, 8), (14, 9), (15, 9), (16, 9), (15, 10), (14, 11), (16, 11),
         (15, 12), (15, 13), (14, 14), (16, 14), (15, 15)],
        [(15, 3), (14, 4), (16, 4), (13, 5), (15, 5), (17, 5), (14, 6), (16, 6),
         (14, 7), (15, 7), (16, 7), (15, 8), (14, 9), (16, 9), (15, 10), (15, 11),
         (14, 12), (16, 12), (15, 13), (15, 14)],
        [(15, 2), (14, 3), (16, 3), (15, 4), (14, 5), (16, 5),
         (13, 6), (15, 6), (17, 6), (14, 7), (16, 7), (15, 8),
         (14, 9), (16, 9), (15, 10), (14, 11), (16, 11), (15, 12), (15, 13)],
    ]
    flame_colors = [TORCH_FLAME1, TORCH_FLAME2, TORCH_FLAME3]
    flame_data = flames[flame_frame % 3]
    for i, (fx, fy) in enumerate(flame_data):
        ci = min(i // 4, 2)
        fc = flame_colors[ci]
        px(img, ox+fx, oy+fy, fc)
    # Core bright
    for (fx, fy) in flame_data[:4]:
        px(img, ox+fx, oy+fy, TORCH_FLAME3)


def draw_bg_stone(img, ox, oy):
    """Background stone tile — lighter, less detail."""
    rect(img, ox, oy, ox+31, oy+31, (30, 28, 48, 255))
    for by in range(0, 32, 10):
        row(img, ox, ox+31, oy+by+9, (20, 18, 35, 255))


def draw_spikes(img, ox, oy):
    rect(img, ox, oy+20, ox+31, oy+31, STONE_DARK)
    for sx in range(2, 30, 6):
        # Spike triangle
        for h in range(0, 12):
            w = max(0, 2 - h // 3)
            for dx in range(-w, w+1):
                px(img, ox+sx+dx, oy+20-h, SPIKE_METAL)
        px(img, ox+sx, oy+8, SPIKE_TIP)


def draw_door(img, ox, oy):
    # Frame
    rect(img, ox+2, oy, ox+29, oy+31, DOOR_DARK)
    rect(img, ox+2, oy, ox+4, oy+31, STONE_MID)
    rect(img, ox+27, oy, ox+29, oy+31, STONE_MID)
    row(img, ox+2, ox+29, oy, STONE_MID)
    # Door panels
    rect(img, ox+5, oy+2, ox+14, oy+31, DOOR_MID)
    rect(img, ox+15, oy+2, ox+26, oy+31, DOOR_MID)
    # Panel lines
    col(img, ox+14, oy+2, oy+31, DOOR_DARK)
    col(img, ox+15, oy+2, oy+31, DOOR_DARK)
    # Arch keystone at top
    rect(img, ox+11, oy, ox+20, oy+3, STONE_LIGHT)
    # Door handle
    rect(img, ox+12, oy+15, ox+14, oy+17, DOOR_METAL)
    rect(img, ox+17, oy+15, ox+19, oy+17, DOOR_METAL)
    # Wood grain lines
    for gy in range(5, 30, 5):
        row(img, ox+5, ox+13, oy+gy, DOOR_DARK)
        row(img, ox+16, ox+26, oy+gy, DOOR_DARK)


TILE_DRAW_FNS = [
    draw_stone_floor,
    draw_stone_wall,
    draw_platform,
    draw_pillar_top,
    draw_pillar_mid,
    draw_pillar_base,
    lambda img, ox, oy: draw_torch(img, ox, oy, 0),
    lambda img, ox, oy: draw_torch(img, ox, oy, 1),
    lambda img, ox, oy: draw_torch(img, ox, oy, 2),
    draw_bg_stone,
    draw_spikes,
    draw_door,
]
# 12 tiles → 4 cols × 3 rows
GRID_ROWS = math.ceil(len(TILE_DRAW_FNS) / GRID_COLS)


def make_castle_tileset():
    img = Image.new("RGBA", (GRID_COLS * TILE_W, GRID_ROWS * TILE_H), TRANSPARENT)
    for i, fn in enumerate(TILE_DRAW_FNS):
        ox, oy = tile_offset(i)
        fn(img, ox, oy)
    path = os.path.join(BASE, "tilesets", "castle_tileset.png")
    img.save(path)
    print(f"  Saved {path}  ({img.width}×{img.height})")


# ─── BACKGROUNDS  960×540 ────────────────────────────────────────────────────

def lerp_color(a, b, t):
    return tuple(int(a[i] + (b[i] - a[i]) * t) for i in range(4))


def draw_gradient_bg(img, top_color, bot_color):
    h = img.height
    for y in range(h):
        t = y / h
        c = lerp_color(top_color, bot_color, t)
        row(img, 0, img.width - 1, y, c)


def draw_arch(img, cx, base_y, w, h, color_outer, color_inner, thickness=4):
    """Draw a gothic pointed arch."""
    for x in range(cx - w // 2, cx + w // 2 + 1):
        rel = abs(x - cx) / (w // 2)
        # Pointed arch: y = base_y - h * (1 - rel^1.5)
        arch_top = int(base_y - h * (1 - rel ** 1.5))
        col_c = color_inner if abs(x - cx) < w // 2 - thickness else color_outer
        col(img, x, arch_top, base_y, col_c)


def draw_column_far(img, cx, top_y, bot_y, w):
    col_c = BG_FAR_ARCH
    rect(img, cx - w // 2, top_y, cx + w // 2, bot_y, col_c)
    col(img, cx - w // 2, top_y, bot_y, BG_FAR_STONE)


def draw_column_mid(img, cx, top_y, bot_y, w):
    rect(img, cx - w // 2, top_y, cx + w // 2, bot_y, BG_MID_ARCH)
    col(img, cx - w // 2, top_y, bot_y, BG_MID_STONE)
    # Capital detail
    rect(img, cx - w // 2 - 2, top_y, cx + w // 2 + 2, top_y + 4, BG_MID_STONE)


def draw_column_near(img, cx, top_y, bot_y, w):
    rect(img, cx - w // 2, top_y, cx + w // 2, bot_y, BG_NEAR_ARCH)
    col(img, cx - w // 2, top_y, bot_y, BG_NEAR_STONE)
    col(img, cx + w // 2, top_y, bot_y, (20, 15, 40, 255))
    # Capital
    rect(img, cx - w // 2 - 3, top_y, cx + w // 2 + 3, top_y + 6, BG_NEAR_STONE)
    row(img, cx - w // 2 - 3, cx + w // 2 + 3, top_y, (70, 58, 110, 255))


def make_castle_bg_far():
    img = Image.new("RGBA", (960, 540), TRANSPARENT)
    draw_gradient_bg(img,
                     (6, 4, 16, 255),
                     (14, 10, 30, 255))
    # Floor line
    row(img, 0, 959, 480, BG_FAR_ARCH)
    # Distant columns
    for cx in range(80, 960, 160):
        draw_column_far(img, cx, 60, 480, 18)
    # Arches between columns
    for cx in range(160, 960, 160):
        draw_arch(img, cx, 200, 120, 160, BG_FAR_STONE, BG_FAR_ARCH, thickness=3)
    # Stars / ambient specks
    import random
    rng = random.Random(42)
    for _ in range(80):
        sx = rng.randint(0, 959)
        sy = rng.randint(0, 300)
        brightness = rng.randint(30, 70)
        px(img, sx, sy, (brightness, brightness, brightness + 10, 255))
    path = os.path.join(BASE, "backgrounds", "castle_bg_far.png")
    img.save(path)
    print(f"  Saved {path}  ({img.width}×{img.height})")


def make_castle_bg_mid():
    img = Image.new("RGBA", (960, 540), TRANSPARENT)
    draw_gradient_bg(img,
                     (8, 6, 22, 255),
                     (20, 15, 42, 255))
    row(img, 0, 959, 490, BG_MID_ARCH)
    for cx in range(100, 960, 140):
        draw_column_mid(img, cx, 40, 490, 22)
    for cx in range(170, 960, 140):
        draw_arch(img, cx, 230, 110, 200, BG_MID_STONE, BG_MID_ARCH, thickness=4)
    # Window-like niches
    for cx in range(170, 960, 140):
        rect(img, cx - 22, 260, cx + 22, 340, (6, 4, 16, 255))
        outline_rect(img, cx - 22, 260, cx + 22, 340, BG_MID_STONE)
    path = os.path.join(BASE, "backgrounds", "castle_bg_mid.png")
    img.save(path)
    print(f"  Saved {path}  ({img.width}×{img.height})")


def make_castle_bg_near():
    img = Image.new("RGBA", (960, 540), TRANSPARENT)
    draw_gradient_bg(img,
                     (10, 8, 26, 255),
                     (26, 20, 52, 255))
    row(img, 0, 959, 500, BG_NEAR_ARCH)
    for cx in range(120, 960, 180):
        draw_column_near(img, cx, 20, 500, 28)
    for cx in range(210, 960, 180):
        draw_arch(img, cx, 250, 130, 240, BG_NEAR_STONE, BG_NEAR_ARCH, thickness=5)
    # Larger niche details
    for cx in range(210, 960, 180):
        rect(img, cx - 30, 280, cx + 30, 380, (8, 5, 20, 255))
        outline_rect(img, cx - 30, 280, cx + 30, 380, BG_NEAR_STONE)
        # Inner arch of niche
        draw_arch(img, cx, 310, 50, 40, BG_NEAR_STONE, (8, 5, 20, 255), thickness=2)
    # Foreground floor detail
    for fx in range(0, 960, 8):
        rect(img, fx, 500, fx + 6, 539, STONE_DARK if (fx // 8) % 2 == 0 else STONE_MID)
    path = os.path.join(BASE, "backgrounds", "castle_bg_near.png")
    img.save(path)
    print(f"  Saved {path}  ({img.width}×{img.height})")


# ─── MAIN ────────────────────────────────────────────────────────────────────
if __name__ == "__main__":
    print("Generating Crimson Vesper pixel art assets...")
    make_player_spritesheet()
    make_skeleton_spritesheet()
    make_bat_spritesheet()
    make_castle_tileset()
    make_castle_bg_far()
    make_castle_bg_mid()
    make_castle_bg_near()
    print("Done.")
