# GRBG 1 - Godot Battle Royale Prototype

Godot 4 project using GDScript. Open this folder in Godot 4.3+ and run `scenes/main.tscn`.

## Included offline demo
- START button with a five-second local matchmaking countdown.
- Saurashtra-inspired test island with named blockout locations: Mahuva Docks, Saurashtra Village and Coastal Outpost.
- Eight procedural soldier-style AI enemies with helmet, tactical vest, backpack and rifle silhouettes.
- AI detection, pursuit, simple obstacle sidestepping, line-of-sight attacks and health.
- Player health, three weapon types (assault rifle, SMG, shotgun), reload and ammo.
- Loot pickups: medkit, ammo, SMG and shotgun.
- Parachute-style drop at match start.
- Shrinking safe-zone disc and outside-zone damage.
- Touch movement, look-drag, jump, fire, reload, weapon switch, sprint and camera toggle.
- Kill counter, match timer, win/death result screen and Play Again restart.
- First-person / third-person camera modes.

## Controls
- Keyboard: WASD / arrow keys, Space jump, Shift sprint, left mouse fire, R reload, V camera switch.
- Mouse: hold left mouse button and move to look around.
- Touch: left-side direction buttons to move; drag the upper/right screen area to look; use the action buttons.

## Matchmaking note
The five-second matchmaking is intentionally an offline test simulation. The eight enemies are local AI bots, not real players. This project does not yet have a backend, accounts, dedicated authoritative server, online matchmaking, or 20-player networking. Those features require a separate deployed server and multiplayer protocol.

## Android build
Use Godot Android export templates matching the Godot editor version, Android SDK/JDK, and a configured Android export preset/signing key in the build environment. This repository does not contain private signing credentials. Build an APK only after setting up the export preset in your Godot/Codemagic workflow.

## Testing status
Code has not been run through a Godot editor/runtime test in this environment. Build and test on an Android device before calling it release-ready.
