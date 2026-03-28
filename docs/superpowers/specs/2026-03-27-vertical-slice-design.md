# Crimson Vesper — Vertical Slice Demo Design

## Overview

A complete vertical slice demo for Crimson Vesper, a 2D SOTN-inspired metroidvania built in Godot 4.6 using Gothicvania store assets. The demo covers title screen through 4 rooms to a multi-phase boss fight, ending with a teaser cutscene.

**Target experience:** A polished first impression — someone plays start to finish and walks away wanting more.

**Approach:** Fix-First, Then Layer (Approach A). Four phases executed sequentially:
1. Make it work (fix critical bugs, playable loop)
2. Game systems (items, abilities, menus, stats, leveling)
3. Content & combat (multi-phase boss, room content, teaser ending)
4. Lighting & visual art pass (Ori/Lightfall-tier atmosphere)

**Standing rules:**
- Proper version control throughout — meaningful commits, feature branches, no big-bang commits
- Source free marketplace assets when needed, matching the Gothicvania pixel art style
- Sprites/graphics properly scaled — character-to-environment proportions must feel right (SOTN reference: Alucard is ~2-3 tiles tall, properly proportioned to doors, stairs, pillars)

---

## Phase 1: Make It Work

**Goal:** Playable loop from title screen through all 4 rooms to boss defeat and back to title.

### 1.1 Fix Routing

**Bug:** `intro_cinematic.gd` line 5 hardcodes `GAME_SCENE` to `test_room.tscn` (which contains the boss). `title_screen.gd` line 6 has the same issue.

**Fix:**
- Change both to `"res://scenes/rooms/entry_hall.tscn"`
- Verify room-to-room transitions work through RoomManager: entry_hall → corridor → pre_boss → boss_arena
- Each room's door/exit zones must be wired correctly via `RoomManager.transition_to(path, spawn_name)`
- Verify spawn points position the player logically (entering from the direction they came)

### 1.2 Fix Visuals

**Bug:** `test_room.tscn` CanvasModulate at `Color(0.102, 0.102, 0.18)` crushes everything to 10% brightness. Sprites appear as dark silhouettes on a flat gray floor.

**Fix:**
- Routing away from test_room resolves this for normal play
- Verify each real room's CanvasModulate and lighting renders sprites visibly:
  - entry_hall: `Color(0.45, 0.45, 0.6)` — should be fine
  - corridor: read CanvasModulate from .tscn, run room, verify sprites visible against church tileset
  - pre_boss: read CanvasModulate from .tscn, run room, verify sprites visible against town tileset
  - boss_arena: `Color(0.3, 0.18, 0.22)` — run room, verify player and boss sprites are clearly visible in this dark-red ambient
- Run each room individually to confirm sprites, tiles, and backgrounds display correctly
- Fix any rooms where programmatic tileset generation (`TileSet.new()` + `TileSetAtlasSource`) isn't rendering

### 1.3 Sprite Scale Audit

- Verify player sprite scale vs tile size — player should be ~2-3 tiles tall, proportioned to doors/architecture
- Verify enemy sprites match the same scale language
- Ensure nearest-neighbor texture filtering (crisp pixel art, no blurring)
- Adjust `transform.scale` or sprite assets as needed to hit correct proportions

### 1.4 Basic Death/Respawn

- Player HP reaches 0 → game over screen with "Retry from Save" and "Quit to Title"
- "Retry from Save" loads last save point (SaveManager already tracks this)
- If no save exists, restart from entry_hall with default stats

### 1.5 End-to-End Verification

- Play through: title → intro → entry_hall → corridor → pre_boss (save) → boss_arena
- Confirm HUD (HP/MP bars) works throughout
- Confirm enemies spawn and combat functions in each room
- Confirm save point in pre_boss works
- Confirm boss fight is reachable and fightable

---

## Phase 2: Game Systems

**Goal:** All RPG/metroidvania mechanics working — items, abilities, menus, stats, leveling.

### 2.1 Stats & Leveling

- StatsManager tracks: HP, MP, STR, DEF, LCK, EXP, Level
- Enemies grant EXP on kill
- Level ups increase base stats (SOTN-style flat scaling)
- Level up triggers brief visual/audio cue (flash + chime), auto-heals a portion of HP
- Stats viewable in a pause menu sub-screen

### 2.2 Inventory & Items

- InventoryManager bag + equipment slots (weapon, armor, accessory x2) — already scaffolded
- Items defined in `data/items/` JSON files (7 items already defined)
- Pickup interaction: consumables auto-collect on walk-over, equipment requires interact button
- Equipment changes reflected in stats immediately
- Consumables for demo: health potion (restore HP), mana potion (restore MP)
- Enemy loot tables: item ID + drop chance percentage per enemy type

### 2.3 Abilities

- AbilityManager tracks unlocked abilities — already scaffolded
- Demo ability progression:
  - Start with: basic melee attack + jump + dash
  - Corridor: double-jump pickup (mid-room reward for exploration)
  - Pre-Boss: fireball/spell pickup (prepares player for boss fight)
- Each new ability expands combat options for the boss

### 2.4 Menus

- **Pause Menu**: Resume, Inventory/Equipment, Stats, Options, Quit to Title
- **Inventory Screen**: Grid of collected items, equipment slots on side, stat comparison when hovering gear
- **Stats Screen**: Level, EXP bar to next level, all stats listed, play time
- **Game Over Screen**: "You Died" → Retry from Save / Quit to Title
- **Options Menu**: Already exists (volume sliders, controls)

### 2.5 Save/Load

- SaveManager handles 3 save slots — already scaffolded
- Save data includes: current room, player position, stats, inventory, abilities, play time
- "Continue" on title screen loads last used save slot
- Save point interaction: walk up → press interact → brief save animation → confirmation text
- Save point in pre_boss is the primary checkpoint before boss

### 2.6 Asset Sourcing

- If any UI elements, icons, or item sprites are missing, source from free Godot Asset Library or itch.io
- Must match Gothicvania pixel art style (16-bit era aesthetic, similar palette)
- Nearest-neighbor scaling, no anti-aliasing

---

## Phase 3: Content & Combat

**Goal:** Multi-phase boss, polished room content, teaser ending, satisfying combat feel.

### 3.1 Multi-Phase Boss — The Crimson Warden

**Boss Intro:**
- Player enters arena → door locks behind them
- Boss appears with name title card: "THE CRIMSON WARDEN"
- Brief dramatic pause before fight begins

**Phase 1 (100%–60% HP):**
- Ground-based melee attacks
- Slow sweeping attacks, telegraphed overhead slam
- 2-3 attack types with learnable patterns
- Player can safely observe and learn timing

**Phase 2 (60%–30% HP):**
- Gets faster, adds ranged attack (projectile or ground wave)
- Music intensifies
- Transition animation: boss roars/flashes, arena lighting shifts redder

**Phase 3 (30%–0% HP):**
- Desperate — combines all attacks with shorter windows
- Adds one new "desperation" move
- Arena visually intensifies (more particles, screen shake on big hits)

### 3.2 Room Content Design

- Returning to a previous room respawns basic monsters like SOTN. If we have unique encounters, they do not replay/respawn. 

**Entry Hall (Cemetery tileset):**
- 3 skeletons teach combat spacing
- First skeleton alone (safe to learn), next two paired (crowd management)
- Clear path forward to corridor exit
- Teaches: movement, jumping, basic melee attack

**Corridor (Church tileset):**
- Vertical platforming challenge with ghosts
- Ghosts teach dealing with aerial enemies
- Double-Jump halfway through — rewards exploration
- Teaches: platforming, aerial combat, dash ability

**Pre-Boss (Town tileset):**
- Safe room — calm before the storm
- Save point visually prominent
- Fireball/mana pickups prepare for boss fight
- Optional health potion pickup
- Teaches: saving, using items/abilities

**Boss Arena:**
- Open flat arena — pure combat space, no platforming distractions
- Locked door behind player, boss ahead
- Teaches: using everything learned together

### 3.3 Teaser Ending

- Boss death: dramatic death animation, screen flash, music cuts to silence
- Loot drop (key item or powerful weapon)
- Brief pause, then the locked door behind the boss opens — a deeper passage revealed
- Short cutscene: camera pans through doorway showing a glimpse of a new, darker area (reuse/tint existing tileset art)
- Text overlay: "The cathedral's depths beckon..."
- Fade to: "To be continued..."
- Return to title screen

### 3.4 Combat Feel

- **Screen shake**: small on regular hits, medium on boss hits, large on boss phase transitions
- **Hit flash**: enemies flash white for 1-2 frames on damage
- **Hit stop**: 2-3 frame pause on melee contact for impact feel
- **Knockback**: tuned per enemy type — skeletons stagger back, ghosts drift, boss barely flinches
- **I-frames**: player gets brief invulnerability after taking damage with sprite flicker
- **SFX**: distinct sounds for hit, miss, enemy death, player hurt

---

## Phase 4: Lighting & Visual Art Pass

**Goal:** Ori and the Blind Forest / Lightfall-tier visual atmosphere. Light as a storytelling tool.

### 4.1 Lighting Philosophy

- Light tells the story of each room — it's not just illumination
- Light sources feel physical: torches flicker, moonlight streams, save points radiate warmth
- Darkness is used intentionally, creating contrast and drama, never just as a blanket dimmer
- Player and enemies remain readable against any background at all times

### 4.2 Per-Room Lighting

**Entry Hall:**
- Cool moonlight from above (blueish-white ambient)
- Warm orange torch pools along the path
- Fog/mist particles near ground level
- Parallax sky: subtle gradient glow behind the moon

**Corridor:**
- Interior — no moonlight
- Warm candlelight from sconces creates pools of safety
- Shadows between lights feel dangerous
- Stained glass windows cast colored light shafts (tinted PointLight2D)

**Pre-Boss:**
- Warmest room in the demo
- Save point emits soft golden radiance
- Gentle ambient glow — the player catches their breath here
- Feels safe, welcoming, a respite

**Boss Arena:**
- Starts cold and dim
- Phase 1: crimson torches at edges of arena
- Phase 2: torches flare brighter, red intensifies
- Phase 3: arena pulses with light synchronized to boss attacks, dramatic shadows

### 4.3 Technical Approach

- `PointLight2D` with custom `GradientTexture2D` (radial fill) for each light source — existing pattern
- `CanvasModulate` sets base ambient darkness per room
- `Light2D` energy and color animate during boss phase transitions
- `GPUParticles2D` systems: dust motes, fog wisps, ember sparks near torches, boss arena effects
- Light shafts: textured `Sprite2D` with additive blending + slow sway animation
- Optional: subtle vignette overlay (screen-space) for atmosphere

### 4.4 Global Visual Polish

- Parallax backgrounds: 3+ layers per room with subtle movement
- Smooth camera with slight lookahead in movement direction
- Sprite rim lighting or subtle outline for readability against complex backgrounds
- Consistent pixel-perfect rendering — no sub-pixel movement artifacts

---

## Known Existing Assets & Systems

**Already implemented (needs verification/fixing):**
- Player state machine (9 states: idle, run, jump, fall, attack, dash, hurt, spell, death)
- 4 enemy types (skeleton, ghost, hell_gato, boss_warden)
- RoomManager with fade transitions
- SaveManager with 3 slots
- AudioManager with multi-bus layout
- InventoryManager with bag + equipment
- AbilityManager
- StatsManager
- HUD scene
- Pause menu, options menu
- Title screen with parallax
- Intro cinematic (4 slides)
- VFX: death_burst, hit_spark
- Fireball projectile

**Needs to be built:**
- Level-up system and EXP tracking
- Inventory/equipment UI screen
- Stats display screen
- Game over screen
- Enemy loot tables
- Multi-phase boss behavior
- Boss intro sequence
- Teaser ending cutscene
- Combat feel (screen shake, hit stop, hit flash, i-frames)
- Phase 4 lighting systems (particles, light shafts, animated lights)
- Any missing assets (source free, matching style)

---

## Out of Scope (for this demo)

- Map/fast travel system
- Metroidvania backtracking / ability gates
- Multiple save file management UI
- Additional rooms beyond the 4
- Story/dialogue system
- NPC interactions
- Multiple weapon types (beyond what drops exist)
- Online features
- Platform-specific builds/exports
