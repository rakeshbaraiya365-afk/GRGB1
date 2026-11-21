# GRBG 1 roadmap

## Implemented offline demo gameplay
- [x] Godot 4 project and Android-friendly GL Compatibility renderer
- [x] Five-second local matchmaking countdown
- [x] Saurashtra-inspired island blockout and named locations
- [x] Eight procedural 3D soldier-style AI enemies
- [x] Enemy detection, chase, simple obstacle sidestep and line-of-sight attacks
- [x] Player health, movement, jump and sprint
- [x] First-person / third-person camera modes
- [x] Touch movement buttons and drag-to-look area
- [x] Assault rifle, SMG and shotgun demo weapon profiles
- [x] Reload, ammo and loot pickups
- [x] Parachute-style opening drop
- [x] Shrinking safe zone and outside-zone damage
- [x] Kill counter, match timer, victory / elimination and restart screen

## Still requires separate production work
- [ ] Real online matchmaking, accounts and dedicated authoritative server
- [ ] Real 20-player networking, replication, reconnect and anti-cheat
- [ ] Final-quality animated character and weapon assets
- [ ] Full Gujarat-scale terrain, roads, buildings and optimized environment art
- [ ] Vehicle driving, aircraft sequence, audio, effects and animation polish
- [ ] Device QA, Android export preset, signing and APK installation test

Only the offline test features above are implemented in this repository. Online multiplayer cannot be delivered by a local Godot-only code change; it needs a deployed backend and server.
