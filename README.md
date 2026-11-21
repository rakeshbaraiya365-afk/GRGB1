# GRBG 1

Original Godot 4 / GDScript third-person and first-person battle royale prototype.

## Current demo
- START button opens a five-second matchmaking countdown.
- The local demo match begins automatically after the countdown.
- Six procedural 3D soldier-style AI enemies spawn into the arena.
- Enemies detect and chase the player, turn toward the player, and fire when they have line of sight and are in range.
- Player can shoot and eliminate enemies; enemy health, player health, ammo, kills and match timer are shown.
- Touch HUD includes movement, jump, fire, reload and camera switching.
- The soldier models are built from original Godot 3D primitives at runtime; they are prototype visuals, not final animated character assets.

## Run
1. Install Godot 4.3 or newer.
2. Open this repository folder in Godot Project Manager.
3. Run `scenes/main.tscn`.
4. Press START. After five seconds the offline AI demo match starts.

## Controls
- Keyboard: WASD / arrows, Space to jump, Shift to sprint, left mouse button to fire, R to reload, V to switch camera.
- Touch: use the on-screen movement, jump, fire, reload and camera buttons.

## Demo limitations
Matchmaking is a local five-second demo timer, not a real online matchmaking service. The six enemies are local AI, not human players. Real 20-player multiplayer, authoritative servers, accounts, lobby services, final Gujarat map, parachute, vehicles, animations, sound, anti-cheat and Android release testing are still future work. This project has not yet been verified by a Godot runtime test in this environment.
