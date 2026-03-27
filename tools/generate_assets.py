#!/usr/bin/env python3
"""
Crimson Vesper — Pixel Art Asset Generator
Generates all game sprites, tilesets, and backgrounds as PNG files.
"""
from PIL import Image, ImageDraw
import os

# --- Output dirs ---
BASE = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
GODOT = os.path.join(BASE, "godot")
SPRITES_DIR = os.path.join(GODOT, "assets", "sprites")
PLAYER_DIR  = os.path.join(SPRITES_DIR, "player")
ENEMY_DIR   = os.path.join(SPRITES_DIR, "enemies")
TILES_DIR   = os.path.join(GODOT, "assets", "tilesets")
BG_DIR      = os.path.join(GODOT, "assets", "backgrounds")

for d in [PLAYER_DIR, ENEMY_DIR, TILES_DIR, BG_DIR]:
    os.makedirs(d, exist_ok=True)

# --- Palette ---
T   = (0,   0,   0,   0)    # transparent
K   = (8,   6,  12, 255)    # void black
SD  = (25,  22,  35, 255)   # stone darkest
SM  = (42,  38,  55, 255)   # stone dark
SB  = (62,  57,  80, 255)   # stone mid
SL  = (88,  82, 110, 255)   # stone light
SH  = (115,108, 140, 255)   # stone highlight
PD  = (28,  12,  48, 255)   # purple dark
PM  = (55,  28,  85, 255)   # purple mid
PL  = (88,  52, 120, 255)   # purple light
TD  = (140,  50,  10, 255)  # torch dark/ember
TM  = (210,  90,  20, 255)  # torch orange
TL  = (240, 170,  40, 255)  # torch yellow
TH  = (255, 240, 180, 255)  # torch hot white
MD  = (32,  35,  45, 255)   # metal dark
MM  = (58,  65,  78, 255)   # metal mid
ML  = (95, 105, 125, 255)   # metal light
MS  = (160,175, 200, 255)   # metal shine
MW  = (220,230, 245, 255)   # metal white
CD  = (38,  18,  52, 255)   # cloth dark
CM  = (62,  30,  82, 255)   # cloth mid
CL  = (92,  50, 115, 255)   # cloth light
BN  = (145,130, 100, 255)   # bone dark
BM  = (185,170, 135, 255)   # bone mid
BL  = (215,200, 165, 255)   # bone light
EG  = (80, 180, 255, 255)   # eye glow (player)
ER  = (200,  50,  50, 255)  # enemy eye red
EO  = (255, 120,  20, 255)  # enemy eye orange
RD  = (140,  20,  20, 255)  # blood red
FL  = (30,  45,  25, 255)   # floor/ground dark
FG  = (50,  70,  40, 255)   # ground mid green tint
BT  = (20,  18,  28, 255)   # bat dark
BW  = (45,  40,  60, 255)   # bat wing

def px(img, x, y, color):
    """Safe pixel set."""
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), color)

def row(img, y, x0, x1, color):
    for x in range(x0, x1+1):
        px(img, x, y, color)

def col(img, x, y0, y1, color):
    for y in range(y0, y1+1):
        px(img, x, y, color)

def rect(img, x0, y0, x1, y1, color):
    for y in range(y0, y1+1):
        for x in range(x0, x1+1):
            px(img, x, y, color)

def outline_rect(img, x0, y0, x1, y1, fg, bg=None):
    if bg:
        rect(img, x0+1, y0+1, x1-1, y1-1, bg)
    row(img, y0, x0, x1, fg); row(img, y1, x0, x1, fg)
    col(img, x0, y0, y1, fg); col(img, x1, y0, y1, fg)

def blit(dst, src, x, y):
    dst.paste(src, (x, y), src)

# ─────────────────────────────────────────────────────────────
# PLAYER KNIGHT  (32×48 per frame)
# Layout: each row = one animation, frames left-to-right
#   idle   4f  row 0  (y=  0)
#   run    6f  row 1  (y= 48)
#   jump   2f  row 2  (y= 96)
#   fall   2f  row 3  (y=144)
#   attack 4f  row 4  (y=192)
#   dash   2f  row 5  (y=240)
# Sheet: 192×288  (6 frames wide × 6 rows tall)
# ─────────────────────────────────────────────────────────────

FW, FH = 32, 48   # frame size

def draw_knight_base(img, ox, oy, bob=0, lean_x=0, crouch=0):
    """Draw a gothic knight. bob = y-offset for idle bounce, lean = dash lean."""
    cy = oy + bob          # base y with bob
    cx = ox + 16 + lean_x  # center x

    # --- Cape (behind body, wide) ---
    rect(img, cx-7, cy+10, cx+7, cy+28+crouch, CD)
    rect(img, cx-6, cy+28, cx+6, cy+36+crouch, CM)
    # cape bottom fringe
    for fx in range(-5, 6, 2):
        col(img, cx+fx, cy+36+crouch, cy+38+crouch, CD)

    # --- Legs ---
    # left leg
    rect(img, cx-7, cy+28, cx-3, cy+37+crouch, MM)
    rect(img, cx-7, cy+37+crouch, cx-3, cy+44+crouch, MD)
    # right leg
    rect(img, cx+3, cy+28, cx+7, cy+37+crouch, MM)
    rect(img, cx+3, cy+37+crouch, cx+7, cy+44+crouch, MD)
    # boots
    rect(img, cx-8, cy+42+crouch, cx-2, cy+46+crouch, MD)
    rect(img, cx+2, cy+42+crouch, cx+8, cy+46+crouch, MD)
    # boot highlight
    row(img, cy+42+crouch, cx-8, cx-2, MM)
    row(img, cy+42+crouch, cx+2, cx+8, MM)
    # greave detail
    row(img, cy+33+crouch, cx-7, cx-3, ML)
    row(img, cy+33+crouch, cx+3, cx+7, ML)

    # --- Torso / Breastplate ---
    rect(img, cx-7, cy+12, cx+7, cy+28, MM)
    rect(img, cx-6, cy+13, cx+6, cy+27, ML)
    # breastplate center ridge
    col(img, cx, cy+13, cy+27, MS)
    # pauldrons (shoulders)
    rect(img, cx-10, cy+10, cx-6, cy+16, MM)
    rect(img, cx+6,  cy+10, cx+10, cy+16, MM)
    row(img, cy+10, cx-10, cx-6, ML)
    row(img, cy+10, cx+6, cx+10, ML)
    # belt
    rect(img, cx-7, cy+25, cx+7, cy+28, MD)
    # belt buckle
    rect(img, cx-2, cy+25, cx+2, cy+28, SH)
    px(img, cx, cy+26, MS)

    # --- Arms (right holds sword) ---
    # left arm
    rect(img, cx-10, cy+16, cx-6, cy+26, MM)
    rect(img, cx-11, cy+22, cx-6, cy+29, MD)  # gauntlet
    row(img, cy+22, cx-11, cx-6, ML)
    # right arm
    rect(img, cx+6, cy+16, cx+10, cy+26, MM)
    rect(img, cx+6, cy+22, cx+11, cy+29, MD)  # gauntlet
    row(img, cy+22, cx+6, cx+11, ML)

    # --- Sword (held in right hand, pointing down/forward) ---
    # Handle
    rect(img, cx+8, cy+26, cx+11, cy+31, SB)
    # Guard (crossguard)
    row(img, cy+31, cx+5, cx+14, SH)
    # Blade  (narrowing downward)
    col(img, cx+9, cy+32, cy+43, MS)
    col(img, cx+10, cy+32, cy+42, ML)
    col(img, cx+11, cy+32, cy+40, SL)
    # blade tip
    px(img, cx+10, cy+44, ML)
    px(img, cx+9, cy+43, SH)

    # --- Helmet ---
    # dome
    rect(img, cx-5, cy+2, cx+5, cy+10, MM)
    rect(img, cx-4, cy+1, cx+4, cy+3, MM)
    px(img, cx, cy, ML)  # crest top
    px(img, cx-1, cy, MM); px(img, cx+1, cy, MM)
    # dome highlights
    row(img, cy+2, cx-4, cx-2, ML)
    # visor slit (T-shape)
    row(img, cy+6, cx-4, cx+4, SD)
    row(img, cy+7, cx-4, cx+4, SD)
    row(img, cy+5, cx-1, cx+1, SD)
    # eye glow behind visor
    px(img, cx-2, cy+6, EG); px(img, cx+2, cy+6, EG)
    px(img, cx-2, cy+7, EG); px(img, cx+2, cy+7, EG)
    # gorget (neck/chin guard)
    rect(img, cx-4, cy+10, cx+4, cy+13, MD)
    row(img, cy+10, cx-4, cx+4, MM)
    # cheek plates
    rect(img, cx-6, cy+6, cx-4, cy+10, MM)
    rect(img, cx+4, cy+6, cx+6, cy+10, MM)
    # crest/plume (tiny)
    col(img, cx, cy-2, cy+1, CL)
    col(img, cx-1, cy-1, cy, CM)
    col(img, cx+1, cy-1, cy, CM)

    # --- Coat of arms on chest (tiny shield) ---
    rect(img, cx-2, cy+16, cx+2, cy+21, SD)
    px(img, cx, cy+17, RD)

def draw_knight_run_legs(img, ox, oy, frame):
    """Overlay running legs (0-5 frames)."""
    cy = oy; cx = ox + 16
    # 6-frame run cycle
    leg_offsets = [
        # (lleg_y_front, rleg_y_front, lleg_swing, rleg_swing)
        (-2, 2, -3, 3),
        (-4, 4, -5, 4),
        (-3, 5, -6, 2),
        ( 2,-2,  3,-3),
        ( 4,-4,  4,-5),
        ( 5,-3,  2,-6),
    ]
    lf, rf, ls, rs = leg_offsets[frame % 6]
    # erase old legs area
    rect(img, cx-10, cy+28, cx+10, cy+48, T)
    # redraw cape bottom (partial)
    rect(img, cx-5, cy+28, cx+5, cy+34, CD)
    # draw dynamic legs
    # left leg
    rect(img, cx-7+ls//2, cy+28+lf, cx-3+ls//2, cy+36+lf, MM)
    rect(img, cx-7+ls//2, cy+36+lf, cx-3+ls//2, cy+42+lf, MD)
    rect(img, cx-8+ls//2, cy+40+lf, cx-2+ls//2, cy+44+lf, MD)
    # right leg
    rect(img, cx+3+rs//2, cy+28+rf, cx+7+rs//2, cy+36+rf, MM)
    rect(img, cx+3+rs//2, cy+36+rf, cx+7+rs//2, cy+42+rf, MD)
    rect(img, cx+2+rs//2, cy+40+rf, cx+8+rs//2, cy+44+rf, MD)

def make_player_sheet():
    sheet = Image.new("RGBA", (192, 288), T)

    # IDLE (4 frames) - gentle float bob
    bobs = [0, -1, -2, -1]
    for i, bob in enumerate(bobs):
        f = Image.new("RGBA", (FW, FH), T)
        draw_knight_base(f, 0, 0, bob=bob)
        blit(sheet, f, i*FW, 0)

    # RUN (6 frames)
    for i in range(6):
        f = Image.new("RGBA", (FW, FH), T)
        draw_knight_base(f, 0, 0, bob=0, lean_x=1 if i < 3 else 0)
        draw_knight_run_legs(f, 0, 0, i)
        blit(sheet, f, i*FW, FH)

    # JUMP (2 frames: crouch-spring, full extend)
    for i in range(2):
        f = Image.new("RGBA", (FW, FH), T)
        if i == 0:
            draw_knight_base(f, 0, 0, bob=3, crouch=2)  # coil
        else:
            draw_knight_base(f, 0, 0, bob=-3)  # extend upward
            # stretch legs down
            rect(f, 9, 38, 23, 44, MM)
        blit(sheet, f, i*FW, FH*2)

    # FALL (2 frames: peak, falling)
    for i in range(2):
        f = Image.new("RGBA", (FW, FH), T)
        draw_knight_base(f, 0, 0, bob=0)
        if i == 1:
            # tuck legs slightly, arms out
            rect(f, 9, 28, 23, 44, T)  # erase legs
            rect(f, 10, 30, 14, 43, MM)  # left leg tucked
            rect(f, 18, 30, 22, 43, MM)
            rect(f, 10, 41, 14, 45, MD)
            rect(f, 18, 41, 22, 45, MD)
        blit(sheet, f, i*FW, FH*3)

    # ATTACK (4 frames: ready, swing-up, swing-down, recover)
    sword_y_offsets = [0, -8, 6, 2]
    sword_x_offsets = [0, 3, -2, 0]
    for i in range(4):
        f = Image.new("RGBA", (FW, FH), T)
        draw_knight_base(f, 0, 0, bob=0)
        # Erase default sword and redraw with attack motion
        so_y = sword_y_offsets[i]
        so_x = sword_x_offsets[i]
        cx = 16
        # Guard
        row(f, 31+so_y, cx+5+so_x, cx+14+so_x, SH)
        if i == 1:  # swinging up
            col(f, cx+12, 18, 30, MS)
            col(f, cx+13, 18, 28, ML)
            px(f, cx+14, 17, SH)
        elif i == 2:  # swing down/forward
            # horizontal slash
            for sx in range(cx+5, cx+22):
                px(f, sx, 22, MS)
                px(f, sx, 23, ML)
            # slash effect streak
            row(f, 21, cx+8, cx+20, TH)
        blit(sheet, f, i*FW, FH*4)

    # DASH (2 frames: lean-forward, afterglow)
    for i in range(2):
        f = Image.new("RGBA", (FW, FH), T)
        draw_knight_base(f, 0, 0, lean_x=3 if i==0 else 4)
        if i == 1:
            # afterimage: draw ghost at half alpha offset to left
            ghost = Image.new("RGBA", (FW, FH), T)
            draw_knight_base(ghost, 0, 0, lean_x=1)
            # darken ghost
            for gx in range(FW):
                for gy in range(FH):
                    c = ghost.getpixel((gx, gy))
                    if c[3] > 0:
                        ghost.putpixel((gx, gy), (c[0]//3, c[1]//3, c[2]//2, 80))
            blit(f, ghost, -4, 0)
            draw_knight_base(f, 0, 0, lean_x=4)
        blit(sheet, f, i*FW, FH*5)

    out = os.path.join(PLAYER_DIR, "knight_sheet.png")
    sheet.save(out)
    print(f"  Saved: {out}  ({sheet.width}×{sheet.height})")

# ─────────────────────────────────────────────────────────────
# SKELETON ENEMY  (32×32 per frame)
# idle 4f (row 0), walk 4f (row 1) → sheet 128×64
# ─────────────────────────────────────────────────────────────

def draw_skeleton_base(img, ox, oy, bob=0, walk=0):
    cy = oy + bob
    cx = ox + 16

    # Pelvis/hip
    rect(img, cx-4, cy+18, cx+4, cy+20, BM)
    # Spine
    col(img, cx, cy+8, cy+17, BM)
    col(img, cx-1, cy+12, cy+15, BN)

    # Legs
    # walk offset: alternating leg forward/back
    lleg = walk; rleg = -walk
    # left leg
    rect(img, cx-5, cy+20+lleg, cx-2, cy+26+lleg, BM)
    rect(img, cx-5, cy+26+lleg, cx-2, cy+30+lleg, BN)
    rect(img, cx-6, cy+30+lleg, cx-1, cy+32, BM)  # foot
    # right leg
    rect(img, cx+2, cy+20+rleg, cx+5, cy+26+rleg, BM)
    rect(img, cx+2, cy+26+rleg, cx+5, cy+30+rleg, BN)
    rect(img, cx+1, cy+30+rleg, cx+6, cy+32, BM)  # foot

    # Rib cage
    rect(img, cx-5, cy+8, cx+5, cy+18, BN)
    # Ribs (3 pairs)
    for rib in range(3):
        ry = cy+10+rib*3
        row(img, ry, cx-5, cx-2, BL)
        row(img, ry, cx+2, cx+5, BL)
    # Sternum
    col(img, cx, cy+9, cy+17, BL)

    # Arms (both down, with scythes or fists)
    # left arm
    rect(img, cx-8, cy+8, cx-5, cy+18, BM)
    rect(img, cx-9, cy+16, cx-5, cy+22, BN)  # forearm
    # left fist/claw
    rect(img, cx-10, cy+21, cx-5, cy+24, BM)
    # right arm
    rect(img, cx+5, cy+8, cx+8, cy+18, BM)
    rect(img, cx+5, cy+16, cx+9, cy+22, BN)
    # right fist
    rect(img, cx+5, cy+21, cx+10, cy+24, BM)
    # Claws
    for cl in range(-9, -5):
        px(img, cl+ox+16, cy+24, BL)
    for cl in range(5, 11):
        px(img, cl+cx-16+16, cy+24, BL)

    # Skull
    rect(img, cx-5, cy+1, cx+5, cy+8, BL)
    rect(img, cx-4, cy, cx+4, cy+2, BM)
    # eye sockets
    rect(img, cx-4, cy+3, cx-2, cy+6, SD)
    rect(img, cx+2, cy+3, cx+4, cy+6, SD)
    # eye glow
    px(img, cx-3, cy+4, ER); px(img, cx-3, cy+5, ER)
    px(img, cx+3, cy+4, ER); px(img, cx+3, cy+5, ER)
    # nasal cavity
    rect(img, cx-1, cy+5, cx+1, cy+7, SD)
    # jaw
    rect(img, cx-4, cy+7, cx+4, cy+9, BM)
    # teeth
    for tx in [cx-3, cx-1, cx+1, cx+3]:
        px(img, tx, cy+8, BL)
        px(img, tx, cy+9, BL)

    # Torn cloth remnants
    rect(img, cx-3, cy+18, cx+3, cy+24, CD)
    for fx in [-2, 0, 2]:
        col(img, cx+fx, cy+24, cy+27, CM)

def make_skeleton_sheet():
    sheet = Image.new("RGBA", (128, 64), T)
    # idle 4 frames (bob)
    bobs = [0, -1, 0, 1]
    for i, bob in enumerate(bobs):
        f = Image.new("RGBA", (32, 32), T)
        draw_skeleton_base(f, 0, 0, bob=bob)
        blit(sheet, f, i*32, 0)
    # walk 4 frames
    walks = [3, 1, -3, -1]
    for i, walk in enumerate(walks):
        f = Image.new("RGBA", (32, 32), T)
        draw_skeleton_base(f, 0, 0, walk=walk)
        blit(sheet, f, i*32, 32)

    out = os.path.join(ENEMY_DIR, "skeleton_sheet.png")
    sheet.save(out)
    print(f"  Saved: {out}  ({sheet.width}×{sheet.height})")

# ─────────────────────────────────────────────────────────────
# BAT ENEMY  (16×16 per frame)
# fly 4f  row 0 → sheet 64×16
# ─────────────────────────────────────────────────────────────

def draw_bat(img, ox, oy, wing_phase):
    cx = ox + 8; cy = oy + 8
    # Wing spread based on phase (0-3)
    spread = [4, 7, 7, 4][wing_phase]
    wing_y = [1, -1, -1, 1][wing_phase]
    # Wings
    rect(img, cx-spread-2, cy+wing_y-1, cx-2, cy+wing_y+2, BW)
    row(img, cy+wing_y-2, cx-spread, cx-4, BT)
    rect(img, cx+2, cy+wing_y-1, cx+spread+2, cy+wing_y+2, BW)
    row(img, cy+wing_y-2, cx+4, cx+spread, BT)
    # Wing membrane detail
    for wm in range(-spread, -2):
        px(img, cx+wm, cy+wing_y+3, BT)
    for wm in range(3, spread+1):
        px(img, cx+wm, cy+wing_y+3, BT)
    # Body
    rect(img, cx-2, cy, cx+2, cy+4, BT)
    rect(img, cx-1, cy-1, cx+1, cy+5, BW)
    # Head
    rect(img, cx-2, cy-2, cx+2, cy+1, BT)
    # Ears
    px(img, cx-2, cy-3, BT); px(img, cx+2, cy-3, BT)
    # Eyes
    px(img, cx-1, cy-1, EO); px(img, cx+1, cy-1, EO)
    # Feet
    px(img, cx-1, cy+5, BT); px(img, cx+1, cy+5, BT)

def make_bat_sheet():
    sheet = Image.new("RGBA", (64, 16), T)
    for i in range(4):
        f = Image.new("RGBA", (16, 16), T)
        draw_bat(f, 0, 0, i)
        blit(sheet, f, i*16, 0)
    out = os.path.join(ENEMY_DIR, "bat_sheet.png")
    sheet.save(out)
    print(f"  Saved: {out}  ({sheet.width}×{sheet.height})")

# ─────────────────────────────────────────────────────────────
# CASTLE TILESET  (32×32 per tile)
# 10 tiles wide × 1 row = 320×32
# Order: stone_floor, stone_wall, platform, pillar_top, pillar_mid,
#        torch_1, torch_2, torch_3, door_top, spikes
# ─────────────────────────────────────────────────────────────

def draw_tile_stone_floor(img, ox, oy):
    """Carved stone floor with brick lines and cracks."""
    rect(img, ox, oy, ox+31, oy+31, SM)
    # mortar joints (horizontal)
    row(img, oy+10, ox, ox+31, SD)
    row(img, oy+21, ox, ox+31, SD)
    row(img, oy+31, ox, ox+31, SD)
    # mortar joints (vertical, staggered)
    col(img, ox+15, oy, oy+9, SD)
    col(img, ox+7,  oy+11, oy+20, SD)
    col(img, ox+23, oy+11, oy+20, SD)
    col(img, ox+11, oy+22, oy+31, SD)
    col(img, ox+23, oy+22, oy+31, SD)
    # Top-face highlights
    row(img, oy, ox, ox+31, SL)
    row(img, oy+1, ox, ox+31, SB)
    # Small surface variation
    for cx, cy in [(ox+4,oy+5),(ox+18,oy+14),(ox+8,oy+26),(ox+28,oy+18)]:
        rect(img, cx, cy, cx+1, cy+1, SD)
    # crack detail
    px(img, ox+20, oy+5, SD); px(img, ox+21, oy+6, SD); px(img, ox+22, oy+7, SD)

def draw_tile_stone_wall(img, ox, oy):
    """Stone wall with bricks and dark mortar."""
    rect(img, ox, oy, ox+31, oy+31, SB)
    # Horizontal mortar lines
    for my in range(oy, oy+32, 8):
        row(img, my, ox, ox+31, SD)
    # Vertical mortar (staggered per brick row)
    offsets = [0, 16, 8, 24, 0, 16]
    for ri, off in enumerate(offsets):
        ry = oy + ri*8
        for vx in range(ox+off, ox+32, 16):
            col(img, vx, ry+1, ry+6, SD)
    # Block face shadow/highlight
    for ri in range(4):
        ry = oy + ri*8 + 1
        for ci in range(2):
            bx = ox + ci*16 + (4 if ri%2==0 else 4)
            row(img, ry, bx, bx+12, SL)   # top highlight
            row(img, ry+5, bx, bx+12, SM)  # bottom shadow
    # Left edge shadow
    col(img, ox, oy, oy+31, SD)
    row(img, oy+31, ox, ox+31, SD)

def draw_tile_platform(img, ox, oy):
    """Thick stone platform/ledge."""
    # Top surface
    rect(img, ox, oy, ox+31, oy+11, SB)
    row(img, oy, ox, ox+31, SL)
    row(img, oy+1, ox, ox+31, SL)
    # Carved face below
    rect(img, ox, oy+12, ox+31, oy+31, SM)
    row(img, oy+12, ox, ox+31, SD)
    # Horizontal groove
    row(img, oy+20, ox, ox+31, SD)
    # Vertical panel lines
    col(img, ox+10, oy+13, oy+31, SD)
    col(img, ox+21, oy+13, oy+31, SD)
    # Panel highlights
    row(img, oy+13, ox+1, ox+9, SL)
    row(img, oy+13, ox+11, ox+20, SL)
    row(img, oy+13, ox+22, ox+31, SL)
    # Bottom shadow
    row(img, oy+31, ox, ox+31, SD)
    col(img, ox+31, oy, oy+31, SD)

def draw_tile_pillar_top(img, ox, oy):
    """Pillar capital (decorative top)."""
    rect(img, ox, oy, ox+31, oy+31, SB)
    # Capital flare
    rect(img, ox, oy, ox+31, oy+7, SM)
    row(img, oy, ox, ox+31, SL)
    # Scroll volutes
    rect(img, ox+2, oy+3, ox+7, oy+9, SD)
    rect(img, ox+24, oy+3, ox+29, oy+9, SD)
    px(img, ox+4, oy+5, SH); px(img, ox+26, oy+5, SH)
    # Shaft
    rect(img, ox+8, oy+7, ox+23, oy+31, SB)
    col(img, ox+8, oy+7, oy+31, SD)
    col(img, ox+23, oy+7, oy+31, SH)
    # Fluting (vertical grooves)
    for fx in [ox+12, ox+16, ox+20]:
        col(img, fx, oy+8, oy+31, SM)

def draw_tile_pillar_mid(img, ox, oy):
    """Pillar middle section."""
    rect(img, ox, oy, ox+31, oy+31, SB)
    # Shaft
    rect(img, ox+8, oy, ox+23, oy+31, SB)
    col(img, ox+8, oy, oy+31, SD)
    col(img, ox+23, oy, oy+31, SH)
    # Background side panels (darker)
    rect(img, ox, oy, ox+7, oy+31, SM)
    rect(img, ox+24, oy, ox+31, oy+31, SM)
    # Fluting
    for fx in [ox+12, ox+16, ox+20]:
        col(img, fx, oy, oy+31, SM)

def draw_tile_torch(img, ox, oy, frame):
    """Torch tile with animated flame (3 frames)."""
    # Wall backing
    rect(img, ox, oy, ox+31, oy+31, SM)
    row(img, oy, ox, ox+31, SL)
    col(img, ox+31, oy, oy+31, SD)
    # Torch bracket
    cx = ox+16
    rect(img, cx-4, oy+14, cx+4, oy+22, SB)
    rect(img, cx-3, oy+18, cx+3, oy+24, MD)
    row(img, oy+24, cx-3, cx+3, ML)
    # Flame (varies per frame)
    flame_offsets = [(0,0), (-1,1), (1,-1)]
    fo_x, fo_y = flame_offsets[frame]
    # Outer flame (orange)
    rect(img, cx-3+fo_x, oy+6+fo_y, cx+3+fo_x, oy+15+fo_y, TM)
    rect(img, cx-2+fo_x, oy+4+fo_y, cx+2+fo_x, oy+8+fo_y, TL)
    # Inner core
    rect(img, cx-1+fo_x, oy+5+fo_y, cx+1+fo_x, oy+12+fo_y, TL)
    px(img, cx+fo_x, oy+4+fo_y, TH)
    # Base ember glow
    rect(img, cx-2, oy+13, cx+2, oy+15, TD)
    # Light corona (soft glow dots)
    for gx, gy, gc in [(cx-5,oy+8,TM),(cx+5,oy+8,TM),(cx,oy+3,TL),(cx-4,oy+12,TD),(cx+4,oy+12,TD)]:
        if 0 <= gx < img.width and 0 <= gy < img.height:
            img.putpixel((gx, gy), gc)

def draw_tile_door_top(img, ox, oy):
    """Pointed gothic arch door top."""
    rect(img, ox, oy, ox+31, oy+31, SM)
    # Arch outline (pointed gothic arch)
    arch_pts = [(8,31),(8,16),(10,10),(12,6),(14,3),(16,2),(18,3),(20,6),(22,10),(24,16),(24,31)]
    for i in range(len(arch_pts)-1):
        x1,y1 = arch_pts[i]; x2,y2 = arch_pts[i+1]
        col(img, ox+x1, oy+y1-1, oy+y2+1, SD) if x1==x2 else row(img, oy+y1, ox+x1, ox+x2, SD)
        for ax in range(min(x1,x2), max(x1,x2)+1):
            for ay in range(min(y1,y2), max(y1,y2)+1):
                px(img, ox+ax, oy+ay, SD)
    # Fill arch opening (void)
    for ay in range(2, 32):
        for ax in range(8, 25):
            pt = img.getpixel((ox+ax, oy+ay))
            if pt != SD:
                px(img, ox+ax, oy+ay, K)
    # Arch stones
    row(img, oy, ox, ox+31, SL)
    row(img, oy+1, ox, ox+7, SB)
    row(img, oy+1, ox+24, ox+31, SB)
    # Keystone
    rect(img, ox+14, oy+2, ox+18, oy+5, SH)
    px(img, ox+16, oy+1, MS)

def draw_tile_spikes(img, ox, oy):
    """Floor spikes (hazard)."""
    rect(img, ox, oy, ox+31, oy+31, SD)
    row(img, oy+31, ox, ox+31, SM)
    row(img, oy+30, ox, ox+31, SB)
    # Spike bases
    rect(img, ox, oy+24, ox+31, oy+31, SM)
    # Individual spikes (5)
    spike_xs = [3, 9, 15, 21, 27]
    for sx in spike_xs:
        col(img, ox+sx, oy+10, oy+24, ML)
        col(img, ox+sx-1, oy+14, oy+24, MM)
        col(img, ox+sx+1, oy+14, oy+24, MM)
        px(img, ox+sx, oy+9, MS)  # tip
    # Blood accent on some tips
    px(img, ox+spike_xs[1], oy+10, RD)
    px(img, ox+spike_xs[3], oy+10, RD)

def make_tileset():
    """10 tiles × 32 = 320px wide, 32 tall. Plus row 2 for torch frames."""
    # Row 0: main tiles (10)
    # Row 1: extra torch frames 2-3 + more tiles
    # Let's just do a single row of 12 tiles (384×32) for simplicity
    # Tiles: 0=floor 1=wall 2=platform 3=pillar_top 4=pillar_mid
    #        5=torch1 6=torch2 7=torch3 8=door_top 9=spikes
    #       10=floor_dark 11=ceiling
    sheet = Image.new("RGBA", (384, 32), T)
    draw_tile_stone_floor(sheet, 0, 0)
    draw_tile_stone_wall(sheet, 32, 0)
    draw_tile_platform(sheet, 64, 0)
    draw_tile_pillar_top(sheet, 96, 0)
    draw_tile_pillar_mid(sheet, 128, 0)
    draw_tile_torch(sheet, 160, 0, 0)
    draw_tile_torch(sheet, 192, 0, 1)
    draw_tile_torch(sheet, 224, 0, 2)
    draw_tile_door_top(sheet, 256, 0)
    draw_tile_spikes(sheet, 288, 0)
    # Floor dark (for ceiling/upper walls)
    rect(sheet, 320, 0, 351, 31, SD)
    row(sheet, 0, 320, 351, SM)
    row(sheet, 1, 320, 351, SB)
    for vy in range(8, 32, 8):
        row(sheet, vy, 320, 351, K)
    # Ceiling tile
    rect(sheet, 352, 0, 383, 31, SM)
    row(sheet, 31, 352, 383, SL)
    row(sheet, 30, 352, 383, SB)
    for vy in range(0, 24, 8):
        row(sheet, vy, 352, 383, K)

    out = os.path.join(TILES_DIR, "castle_tiles.png")
    sheet.save(out)
    print(f"  Saved: {out}  ({sheet.width}×{sheet.height})")

# ─────────────────────────────────────────────────────────────
# PARALLAX BACKGROUNDS  (640×360 each, tile horizontally)
# Layer 0 (far):   distant columns silhouette, 640×360
# Layer 1 (mid):   gothic arches mid-distance
# Layer 2 (near):  foreground arch frames, darker
# ─────────────────────────────────────────────────────────────

def make_bg_far():
    """Far layer: distant pillars and moody gradient sky."""
    img = Image.new("RGBA", (640, 360), T)

    # Sky gradient (deep purple → very dark blue)
    for y in range(360):
        t = y / 359
        r = int(8  + t * 5)
        g = int(5  + t * 4)
        b = int(18 + t * 14)
        row(img, y, 0, 639, (r, g, b, 255))

    # Moon (faint)
    for mx in range(500, 540):
        for my in range(30, 70):
            dist = ((mx-520)**2 + (my-50)**2)**0.5
            if dist < 18:
                alpha = int(120 - dist*5)
                px(img, mx, my, (220, 210, 180, alpha))

    # Distant architecture (dark columns far away)
    col_positions = [60, 160, 260, 380, 480, 580]
    for cpx in col_positions:
        # column
        rect(img, cpx-8, 80, cpx+8, 360, (18, 15, 28, 255))
        # capital
        rect(img, cpx-12, 76, cpx+12, 82, (22, 18, 32, 255))
        # highlight
        col(img, cpx-8, 80, 360, (25, 20, 36, 255))

    # Arch between columns (silhouette)
    for i in range(len(col_positions)-1):
        x1 = col_positions[i]+8; x2 = col_positions[i+1]-8
        mid = (x1+x2)//2; w = (x2-x1)//2
        # pointed arch curve (rough)
        for ax in range(x1, x2):
            t = (ax - mid) / max(w, 1)
            arch_h = int(60 * (1 - abs(t)**1.5))
            ay = 200 - arch_h
            for py in range(ay, 200):
                img.putpixel((ax, py), (14, 11, 22, 255))

    # Floor suggestion
    rect(img, 0, 320, 639, 359, (20, 17, 30, 255))
    row(img, 320, 0, 639, (30, 25, 42, 255))

    out = os.path.join(BG_DIR, "bg_far.png")
    img.save(out)
    print(f"  Saved: {out}  ({img.width}×{img.height})")

def make_bg_mid():
    """Mid layer: gothic arches with subtle detail."""
    img = Image.new("RGBA", (640, 360), T)

    # Gradient (transparent top → dark bottom for overlay)
    for y in range(360):
        a = int(min(255, y * 0.6))
        row(img, y, 0, 639, (0, 0, 0, 0))  # start transparent

    # Arch window frames (stone)
    arches = [80, 240, 400, 560]
    for apx in arches:
        # Stone border of archway
        rect(img, apx-30, 40, apx-22, 280, (35, 30, 48, 220))
        rect(img, apx+22, 40, apx+30, 280, (35, 30, 48, 220))
        # Pointed arch top
        for ax in range(apx-30, apx+31):
            t = (ax - apx) / 30
            ah = int(60*(1 - abs(t)**1.2))
            img.putpixel((ax, 40 - ah), (35, 30, 48, 200))
        # Interior dark void
        rect(img, apx-21, 41, apx+21, 280, (12, 8, 20, 180))
        # Stone detail
        row(img, 40, apx-30, apx+30, (50, 44, 68, 220))
        col(img, apx-22, 40, 280, (50, 44, 68, 180))
        col(img, apx+22, 40, 280, (28, 24, 40, 180))

    # Floor
    rect(img, 0, 280, 639, 360, (32, 28, 45, 200))
    row(img, 280, 0, 639, (55, 48, 72, 220))

    out = os.path.join(BG_DIR, "bg_mid.png")
    img.save(out)
    print(f"  Saved: {out}  ({img.width}×{img.height})")

def make_bg_near():
    """Near layer: foreground columns/frames, mostly transparent."""
    img = Image.new("RGBA", (640, 360), T)

    # Thick foreground column frames on sides
    col_positions = [0, 120, 520, 640]
    for i, cpx in enumerate([30, 610]):
        # big pillar
        rect(img, cpx-18, 0, cpx+18, 360, (42, 36, 58, 240))
        col(img, cpx-18, 0, 360, (55, 48, 75, 240))
        col(img, cpx+18, 0, 360, (28, 24, 40, 240))
        # fluting detail
        for fx in [cpx-8, cpx, cpx+8]:
            col(img, fx, 0, 360, (35, 30, 50, 200))

    # Chains hanging from top
    for cx_chain in [180, 460]:
        for cy_chain in range(0, 180, 4):
            rect(img, cx_chain-3, cy_chain, cx_chain+3, cy_chain+2, (45, 40, 58, 200))
            # chain link angle
            if (cy_chain//4) % 2 == 0:
                row(img, cy_chain+1, cx_chain-4, cx_chain+4, (55, 50, 68, 180))

    # Ceiling edge
    rect(img, 0, 0, 639, 10, (38, 32, 52, 230))
    row(img, 10, 0, 639, (52, 45, 70, 200))
    row(img, 11, 0, 639, (28, 24, 40, 180))

    out = os.path.join(BG_DIR, "bg_near.png")
    img.save(out)
    print(f"  Saved: {out}  ({img.width}×{img.height})")

# ─────────────────────────────────────────────────────────────
# MAIN
# ─────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────
# PRE-TILED SURFACE STRIPS (for use as Sprite2D textures)
# ─────────────────────────────────────────────────────────────

def make_floor_strip():
    """1920×48 pre-tiled castle floor strip."""
    img = Image.new("RGBA", (1920, 48), T)
    for tx in range(60):
        draw_tile_stone_floor(img, tx*32, 0)
    # Sub-floor dark band (below tiles)
    for wx in range(60):
        rect(img, wx*32, 32, wx*32+31, 47, SD)
        if wx % 2 == 0:
            col(img, wx*32+15, 33, 47, K)
        else:
            col(img, wx*32+7, 33, 47, K)
    out = os.path.join(TILES_DIR, "castle_floor_strip.png")
    img.save(out)
    print(f"  Saved: {out}  ({img.width}×{img.height})")

def make_platform_strip():
    """320×48 pre-tiled platform strip."""
    img = Image.new("RGBA", (320, 48), T)
    rect(img, 0, 0, 319, 10, SB)
    row(img, 0, 0, 319, SL); row(img, 1, 0, 319, SL); row(img, 2, 0, 319, SB)
    rect(img, 0, 11, 319, 47, SM)
    row(img, 11, 0, 319, SD); row(img, 12, 0, 319, SB)
    for p in range(32, 320, 32):
        col(img, p, 12, 47, SD)
    for p in range(0, 320, 32):
        row(img, 13, p, min(p+30, 319), SL)
    row(img, 30, 0, 319, SD); row(img, 31, 0, 319, SM)
    row(img, 47, 0, 319, SD)
    col(img, 0, 0, 47, SL); col(img, 319, 0, 47, SD)
    out = os.path.join(TILES_DIR, "castle_platform_strip.png")
    img.save(out)
    print(f"  Saved: {out}  ({img.width}×{img.height})")

def make_individual_tiles():
    """Save individual tile PNGs for easy use in scenes."""
    # torch sheet (3 frames): 96×32
    sheet = Image.new("RGBA", (96, 32), T)
    for fi in range(3):
        draw_tile_torch(sheet, fi*32, 0, fi)
    out = os.path.join(TILES_DIR, "torch_frames.png")
    sheet.save(out)
    print(f"  Saved: {out}")

# ─────────────────────────────────────────────────────────────
# FULL-RESOLUTION BACKGROUNDS (1920×1080, horizontal tiling room)
# ─────────────────────────────────────────────────────────────

def make_bg_far_hd():
    """1920×1080 far background."""
    img = Image.new("RGBA", (1920, 1080), T)
    for y in range(1080):
        t = y / 1079
        r = int(8  + t * 6);  g = int(5 + t*4);  b = int(18 + t*15)
        row(img, y, 0, 1919, (r, g, b, 255))
    # Moon
    for mx in range(1550, 1620):
        for my in range(60, 130):
            dist = ((mx-1585)**2 + (my-95)**2)**0.5
            if dist < 30:
                a = int(max(0, 100 - dist*3))
                px(img, mx, my, (220, 210, 180, a))
    # Distant columns (20 of them across 1920px)
    for ci in range(20):
        cpx = 48 + ci * 96
        rect(img, cpx-12, 200, cpx+12, 1080, (18, 15, 28, 255))
        rect(img, cpx-18, 194, cpx+18, 202, (22, 18, 32, 255))
        col(img, cpx-12, 200, 1080, (25, 20, 36, 255))
    # Arches between columns
    for ci in range(19):
        x1 = 48 + ci*96 + 12; x2 = 48 + (ci+1)*96 - 12
        mid = (x1+x2)//2; w = (x2-x1)//2
        for ax in range(x1, x2):
            t = abs(ax - mid) / max(w, 1)
            ah = int(120*(1 - t**1.4))
            ay = 500 - ah
            for gy in range(ay, 500):
                img.putpixel((ax, gy), (14, 11, 22, 255))
    # Ceiling
    rect(img, 0, 0, 1919, 180, (14, 11, 22, 255))
    row(img, 180, 0, 1919, (25, 20, 36, 255))
    # Floor
    rect(img, 0, 900, 1919, 1079, (20, 17, 30, 255))
    row(img, 900, 0, 1919, (32, 27, 44, 255))
    out = os.path.join(BG_DIR, "bg_far.png")
    img.save(out)
    print(f"  Saved: {out}  ({img.width}×{img.height})")

def make_bg_mid_hd():
    """1920×1080 mid background (gothic arches)."""
    img = Image.new("RGBA", (1920, 1080), T)
    # Slightly lighter than far, still very dark
    for y in range(1080):
        t = y / 1079
        r = int(12 + t*8); g = int(10+t*5); b = int(22+t*18)
        row(img, y, 0, 1919, (r, g, b, 255))
    # Large gothic arch windows
    for ai in range(6):
        apx = 160 + ai*320
        # Frame
        rect(img, apx-55, 120, apx-42, 820, (38, 32, 52, 255))
        rect(img, apx+42, 120, apx+55, 820, (38, 32, 52, 255))
        # Pointed arch top
        for ax in range(apx-55, apx+56):
            t = abs(ax-apx)/55
            ah = int(180*(1-t**1.2))
            ay = 120-ah
            for gy in range(ay, 122):
                if 0 <= gy < 1080:
                    img.putpixel((ax, gy), (38, 32, 52, 255))
        # Interior (dark void)
        rect(img, apx-41, 122, apx+41, 820, (10, 7, 18, 255))
        # Arch highlight
        row(img, 120, apx-55, apx+55, (55, 48, 72, 255))
        col(img, apx-42, 120, 820, (55, 48, 72, 255))
        col(img, apx+42, 120, 820, (28, 22, 40, 255))
    # Stone wall fill between arches
    # (already covered by the background gradient)
    # Top and bottom ledges
    rect(img, 0, 0, 1919, 118, (28, 24, 40, 255))
    row(img, 118, 0, 1919, (45, 38, 62, 255))
    row(img, 119, 0, 1919, (38, 32, 52, 255))
    rect(img, 0, 820, 1919, 1079, (28, 24, 40, 255))
    row(img, 820, 0, 1919, (45, 38, 62, 255))
    out = os.path.join(BG_DIR, "bg_mid.png")
    img.save(out)
    print(f"  Saved: {out}  ({img.width}×{img.height})")

def make_bg_near_hd():
    """1920×1080 near background (foreground columns, mostly transparent)."""
    img = Image.new("RGBA", (1920, 1080), T)
    # Side columns
    for cpx in [55, 1865]:
        rect(img, cpx-28, 0, cpx+28, 1080, (45, 38, 62, 230))
        col(img, cpx-28, 0, 1080, (62, 54, 82, 230))
        col(img, cpx+28, 0, 1080, (30, 25, 42, 230))
        for fx in [cpx-12, cpx, cpx+12]:
            col(img, fx, 0, 1080, (38, 32, 52, 200))
    # Interior columns (every 320px from x=320)
    for ci in range(5):
        cpx = 320 + ci*320
        rect(img, cpx-16, 0, cpx+16, 1080, (40, 34, 56, 200))
        col(img, cpx-16, 0, 1080, (55, 48, 75, 200))
        col(img, cpx+16, 0, 1080, (28, 22, 40, 200))
        for fx in [cpx-6, cpx+6]:
            col(img, fx, 0, 1080, (34, 28, 48, 180))
    # Hanging chains
    for cx_chain in [160, 480, 800, 1120, 1440, 1760]:
        for cy_chain in range(0, 320, 5):
            rect(img, cx_chain-4, cy_chain, cx_chain+4, cy_chain+3, (48, 42, 62, 200))
            if (cy_chain//5) % 2 == 0:
                row(img, cy_chain+2, cx_chain-6, cx_chain+6, (62, 55, 80, 180))
    # Ceiling edge
    rect(img, 0, 0, 1919, 14, (42, 36, 58, 240))
    row(img, 14, 0, 1919, (58, 50, 78, 220))
    row(img, 15, 0, 1919, (32, 26, 46, 200))
    out = os.path.join(BG_DIR, "bg_near.png")
    img.save(out)
    print(f"  Saved: {out}  ({img.width}×{img.height})")


if __name__ == "__main__":
    print("Generating Crimson Vesper pixel art assets...")
    print("\nPlayer:")
    make_player_sheet()
    print("\nEnemies:")
    make_skeleton_sheet()
    make_bat_sheet()
    print("\nTileset:")
    make_tileset()
    print("\nSurface strips:")
    make_floor_strip()
    make_platform_strip()
    make_individual_tiles()
    print("\nBackgrounds (1920×1080):")
    make_bg_far_hd()
    make_bg_mid_hd()
    make_bg_near_hd()
    print("\nDone! All assets generated.")
