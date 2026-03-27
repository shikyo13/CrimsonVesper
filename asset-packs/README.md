# Gothicvania Asset Packs — Source Reference

These are the raw unzipped Ansimuz Gothicvania pixel art packs used in CrimsonVesper.
Do not modify files here — they are source archives for reference and re-export.

## License

All packs are by **Ansimuz** and distributed under the **Creative Commons Zero (CC0) / Public Domain** license.
You can use, modify, and distribute them in commercial and non-commercial projects without attribution.

See `cemetery/gothicvania-cemetery-files/public-license.pdf` for the original license document.

---

## Pack Inventory

### 1. Cemetery (`cemetery/`) — 5.9 MB
**Source file:** `gothicvania-cemetery-files.zip`
**Theme:** Graveyard at night — tombstones, dead trees, gothic sky

| Category | Contents |
|----------|----------|
| **Player (Hero)** | idle (4f), run (8f), jump (3f), crouch (2f), attack (5f), hurt (2f), death (5f) — spritesheets + individual frames |
| **Enemy: Ghost** | flying loop (4f) + ghost with halo variant |
| **Enemy: Skeleton** | walk (8f), walk-clothed (8f), rise (4f), rise-clothed (4f) |
| **Enemy: Hell-Gato** | walk/idle loop (4f) — demonic flaming cat |
| **Tileset** | `tileset.png` — gravestones, ground, walls, fences |
| **Backgrounds** | `background.png` (dark sky), `graveyard.png` (mid layer), `mountains.png` (far layer) |
| **Parallax BGs** | `bg-moon.png`, `bg-mountains.png`, `bg-graveyard.png` — pre-split for parallax |
| **Props** | tree-1/2/3, stone-1/2/3/4, statue, bush-small/large |
| **VFX** | enemy-death (5f) |

**Godot destinations:**
- `godot/assets/sprites/player/cemetery/` — hero spritesheets
- `godot/assets/sprites/enemies/cemetery/` — ghost, skeleton, hell_gato
- `godot/assets/tilesets/cemetery_tileset.png` (already integrated)
- `godot/assets/backgrounds/cemetery/`
- `godot/assets/sprites/effects/enemy_death/`

---

### 2. Church (`church/`) — 2.4 MB
**Source file:** `gothicvania church files.zip`
**Theme:** Gothic church interior — stone arches, stained glass atmosphere

| Category | Contents |
|----------|----------|
| **Player** | walk (6f), idle (4f), jump (2f), fall (2f), hurt (2f), punch (6f), kick (5f), flying-kick (2f), crouch (2f), crouch-kick (5f) — spritesheet + frames |
| **Enemy: Angel** | idle (8f), attack (3f) — winged church guardian |
| **Enemy: Burning Ghoul** | v1 robed (8f) + v2 bare (8f) — flaming undead |
| **Enemy: Wizard** | idle (5f), fire-cast (10f) — dark sorcerer boss |
| **Tileset** | `tileset.png` — stone floors, arches, columns |
| **Backgrounds** | `backgrounds.png` — church interior layers |
| **Props** | `column.png` |
| **VFX: Fireball** | (3f) — projectile sprite |
| **VFX: Enemy Death** | (9f) — dissolve/burst effect |

**Godot destinations:**
- `godot/assets/sprites/player/church/` — church player (brawler style)
- `godot/assets/sprites/enemies/church/` — angel, burning_ghoul, wizard
- `godot/assets/tilesets/church_tileset.png`
- `godot/assets/backgrounds/church/`
- `godot/assets/sprites/effects/fireball/`, `effects/enemy_death/`

---

### 3. Town (`town/`) — 10.8 MB
**Source file:** `GothicVania-town-files.zip`
**Theme:** Gothicvania town exterior — cobblestone streets, gothic buildings, gas lamps

| Category | Contents |
|----------|----------|
| **NPC: Bearded Man** | idle (5f), walk (6f) — spritesheets + frames |
| **NPC: Hat Man** | idle (4f), walk (6f) — spritesheets + frames |
| **NPC: Old Man** | idle (8f), walk (12f) — spritesheets + frames |
| **NPC: Woman** | idle (7f), walk (6f) — spritesheets + frames |
| **Tileset** | `tileset.png` — cobblestone, building facades, rooftops, stairs, windows |
| **Sliced Tileset** | 40+ individual tile pieces (ground, walls, stairs, roofs, windows, slopes) |
| **Backgrounds** | `background.png` (far sky/buildings), `middleground.png` (mid building layer) |
| **Props** | barrel, crates, wagon, well, sign, street-lamp, houses (a/b/c), church building |
| **Music** | Included in `GothicVania-town-files/Music/` |

**Godot destinations:**
- `godot/assets/sprites/npcs/town/` — bearded, hat_man, oldman, woman
- `godot/assets/tilesets/town_tileset.png`, `tilesets/town_sliced/`
- `godot/assets/backgrounds/town/`

---

### 4. Swamp (`swamp/`) — 2.7 MB
**Source file:** `Gothicvania Swamp files.zip`
**Theme:** Foggy swamp — twisted trees, murky water, dark vegetation

| Category | Contents |
|----------|----------|
| **Player** | idle (6f), run (14f), jump (2f), fall (2f), hurt (2f), crouch (3f), crouch-shoot (3f), shoot (3f), stand (1f) |
| **Enemy: Ghost** | flying (4f) — swamp specter variant |
| **Enemy: Spider** | walk (4f) — large gothic spider |
| **Enemy: Thing** | walk (4f) — large shambling creature (boss candidate) |
| **Tileset** | `tileset.png` — swamp ground, roots, murky water edges |
| **Backgrounds** | `background.png` (far sky/fog), `mid-layer-01.png`, `mid-layer-02.png`, `trees.png` |
| **Props** | `props.png` — swamp vegetation, logs |
| **VFX: Explosion** | (6f) — enemy death burst |
| **VFX: Fire** | (2f) — environmental fire |

**Godot destinations:**
- `godot/assets/sprites/player/swamp/` — shooter-style player
- `godot/assets/sprites/enemies/swamp/` — ghost, spider, thing
- `godot/assets/tilesets/swamp_tileset.png`
- `godot/assets/backgrounds/swamp/`
- `godot/assets/sprites/effects/explosion/`, `effects/fire/`

---

## Godot Asset Tree Summary

```
godot/assets/
├── sprites/
│   ├── player/
│   │   ├── player_*.png          ← Cemetery hero (already integrated)
│   │   ├── cemetery/             ← Cemetery hero spritesheets (raw)
│   │   ├── church/               ← Church brawler player
│   │   └── swamp/                ← Swamp shooter player
│   ├── enemies/
│   │   ├── cemetery/             ← ghost, skeleton, hell_gato
│   │   ├── church/               ← angel, burning_ghoul, wizard
│   │   └── swamp/                ← ghost, spider, thing
│   ├── npcs/
│   │   └── town/                 ← bearded, hat_man, oldman, woman
│   └── effects/
│       ├── enemy_death/          ← cemetery (5f) + church (9f) styles
│       ├── fireball/             ← church projectile (3f)
│       ├── explosion/            ← swamp burst (6f)
│       └── fire/                 ← environmental fire (2f)
├── tilesets/
│   ├── cemetery_tileset.png      ← already integrated
│   ├── cemetery_tileset_raw.png  ← raw source
│   ├── church_tileset.png
│   ├── town_tileset.png
│   ├── town_sliced/              ← 40+ individual tile PNGs
│   └── swamp_tileset.png
└── backgrounds/
    ├── cemetery_bg_*.png         ← already integrated (far/mid/near)
    ├── cemetery/                 ← raw source layers
    ├── church/
    ├── town/
    └── swamp/
```

## Notes

- The **cemetery hero** is already fully integrated into the game as the player character.
  The cemetery player spritesheets here are the raw source for reference.
- The **church player** is a different character (brawler/fighter style — punch/kick combos).
- The **swamp player** is a third character variant (ranged/shooter style — has shoot animations).
- **Town sprites** are NPCs only — no playable character, no enemies. Good for hub/town zones.
- The **wizard** (church pack) is likely a boss — only has idle and fire-casting animations.
- The **thing** (swamp pack) is a large shambling creature — good boss candidate for swamp zone.
- **Music** is included in the town pack (`GothicVania-town-files/Music/`) — not yet copied to audio/.
