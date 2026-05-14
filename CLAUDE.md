# Clauden Ring

**Genre:** Souls-like action RPG (parody)
**Engine:** Godot 4.6 (PC)
**Concept:** Elden Ring parody set in the current AI landscape. Gimmicky hook that earns the click — but underneath: tight boss fights, genuine exploration, and a real story worth finishing.

**Separate project** — do not touch or reference any other Godot project on this machine.

---

## Role

You own all engineering. User reviews and corrects direction only.

---

## Workflow

### 1. Parse error check (run after every script change)

```powershell
& "$env:LOCALAPPDATA\Programs\Godot\Godot_v4.6.2-stable_win64.exe" --headless --editor --quit --path "C:\Users\jedin\Desktop\Clauden Ring" 2>&1 | Select-String "ERROR|SCRIPT"
```

### 2. Screenshot testing

Create `tools/capture.ps1`. Steps:
- Patch `DebugCapture.gd`: set `ENABLED=true` and `QUIT_AFTER=true`
- Launch the game
- Wait for exit
- Read screenshot from `C:\Users\jedin\AppData\Roaming\Godot\app_userdata\Clauden Ring\debug_screenshot.png` using the Read tool (it supports images)

Always do this after visual changes before reporting done.

### 3. DebugCapture discipline

**Never leave `ENABLED=true`** — it auto-quits the game and breaks the user's play session. After every screenshot capture, patch it back to `ENABLED=false`.

---

## Godot 4.6 Gotchas

- `minf()` only takes 2 args — chain: `minf(minf(a,b),c)`
- `class_name` in new scripts won't resolve in other scripts until Godot imports them — type vars as `Node` and use duck typing if you hit type-not-found errors
- `Input.parse_input_event()` does NOT call `Node._input()` — use `get_viewport().push_input()` to simulate real input in tests
- Inner classes extending `Node2D` with `_draw()` are unreliable — draw static visuals in the parent scene's `_draw()` instead
- For PC: handle input in player node directly with `_input()` or `_unhandled_input()`, no coordinate conversion needed

---

## Communication Rules

- Be upfront and honest at all times
- Attempt solutions before asking — find tools or workarounds first, report findings not just blockers
- Say explicitly when you can't verify something visually, then use the screenshot tool
- Never claim something works without evidence
- If you need anything installed, install it automatically and tell the user what UAC prompt to expect

---

## Project Structure (target)

```
Clauden Ring/
  scenes/
    world/        # exploration areas
    bosses/       # boss encounters
    ui/           # menus, HUD
    player/
  scripts/
  assets/
    art/
    audio/
  tools/
    capture.ps1   # screenshot testing
  CLAUDE.md
```

---

## Game Design Notes

- **Hook:** AI landscape parody (model names, AI company lore, hallucination mechanics, etc.)
- **Substance:** Souls-like depth — stamina, positioning, boss phases, environmental storytelling
- **Story:** Needs a real arc, not just memes. Player should care about the world by the end.
- **Boss design:** Each major boss = a different AI archetype or company. Mechanically distinct fights, not just reskins.
- **Exploration:** Interconnected world, shortcuts, secrets, environmental narrative.
