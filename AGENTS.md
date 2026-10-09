# Assembloids

## Build
```sh
make
```
Output: `Assembloids.rom`

Pipeline: `cvbasic --msx game.bas game.asm` → `gasm80 game.asm -o Assembloids.rom`

## Game
Face-matching swap puzzle (port of MSX "Quartet" by bitsofbas/Ilkke). 4×4 grid of face quadrants (4 faces × 4 quadrants). Single cursor moves pieces by swapping with adjacent cell; moving into an empty cell (already-completed face) loses a life. Completed 2×2 faces disappear, timer counts down.

### Controls
- D-pad: move piece in that direction, swapping with adjacent piece
- Moving into an empty slot (completed face) or timer expiry loses a life
- Consoles: Fire button starts the game; any other key = 0-9/*/# shows the Help screen (MSX `CONT1.KEY`)

### Scoring (aligned with original Quartet ROM)
- Partial face: 5 pts per correctly placed piece
- Full face: 20 pts + face removed
- Clear all 4 faces: +1 life + 50 bonus
- Hiscore persists across games (16-bit, high scores > 255 supported)

### Timer (aligned with original Quartet ROM)
- Stage 1: 200 frames (~3.3s at 60Hz)
- Stage 2+: 166 frames (~2.8s)

## Title Screen
Four faces displayed side-by-side as 2×2 tile blocks (rows 4-5), title text (row 1), hiscore (row 8), blinking "PRESS FIRE" (row 10). Pressing any key (Fire) starts the game; other keys show the Help screen.

## Help Screen
Modeled on the original Quartet's HOW-TO-PLAY screen (msxdev18_quartet_005.png). Reached from the title via any non-fire key, returns to title on Fire. Faces shown 2×2 at rows 3-4, then objective, move rule, controls, and a lose-a-life warning, plus a blinking "PRESS FIRE" (row 19).

## Tile Data
From `Assembloids.bmp` via TMSColor with Pletter compression (`-z` flag).

- 253 tiles, DEFINE CHAR/COLOR PLETTER using `image_char` / `image_color` labels
- Face pieces span block rows 4-5. Each 2×2 face = top tiles (block row 4) + bottom tiles (block row 5), mapped at runtime via `f()` lookup in `game.bas`:
  - Face 0 (red): 169,170 / 209,210
  - Face 1 (white): 174,175 / 214,215
  - Face 2 (blue): 185,186 / 225,226
  - Face 3 (green): 190,191 / 230,231
- Background: tile 0, Board bg: tile 154, Cursor: tile 155
- Text: font glyphs for ASCII 32-127 are baked into tiles 32-127 of `Assembloids.bmp`, so `DEFINE CHAR PLETTER 0,253` ships the full font in `image_char` (no runtime font copy). Text color comes from the BMP's color data (white-on-black)
- VDP note: color byte = bits 7-4 foreground (pattern bit 1), bits 3-0 background (pattern bit 0)
- Timer bar: tiles 1 (green block) / 2 (red block), solid patterns written at runtime (VPOKE $0008.. / $0010.. = 255) with foreground colors $31 (light green) / $81 (red). NOTE: VDP color byte = bits 7-4 foreground (pattern bit 1), bits 3-0 background (pattern bit 0); solid 255 blocks show the *foreground* color

## Code Layout (game.bas)
- Lines 1-7: header, DEFINE statements
- Lines 9-27: timer bar setup (solid block patterns + green/red colors)
- Lines 29-52: `f()` face lookup table + variables
- Lines 54-100: main loop (restart, title_loop, help_loop, begin_game, next_stage)
- Lines 102-124: `setup_stage` procedure
- Lines 126-252: `handle_input` / `check_faces` procedures (directional swap + empty-cell check, scoring + face completion)
- Lines 254-300: `update_timer` / `shuffle_board` procedures
- Lines 302-340: `draw_board` procedure (grid, faces, timer bar, HUD)
- Lines 342-374: `draw_title` procedure (faces + text)
- Lines 376-411: `draw_help` procedure (HOW TO PLAY screen)
- Lines 413-425: `game_over` screen
- Lines 431+: Pletter-compressed tile data

## Key Files
- `game.bas` — main source
- `Assembloids.bmp` — tile source (320×240)
- `Assembloids.rom` — built ROM (8 KB)
- `Makefile` — build rules (copies prologue/epilogue from `/g/CVBasic/`)
- `AGENTS.md` — project summary
