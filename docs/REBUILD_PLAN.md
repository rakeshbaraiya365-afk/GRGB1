# GRBG 1 — Free Fire MAX-inspired Rebuild Plan

## Goal
Rebuild GRBG 1 as an original mobile battle-royale game inspired by the presentation and gameplay loop of Free Fire MAX. Do not copy Free Fire names, characters, maps, UI artwork, sounds, or proprietary assets.

## Honest current-state assessment
GRBG 1 remains a Godot 4.3 offline prototype. The latest implementation adds an articulated procedural tactical soldier rig with idle/run movement, muzzle flash and recoil; AI enemies use the same rig. The island now has a coastal water plane, sandy shoreline, road markings, named landmarks (Mahuva Docks, Saurashtra Village, Coastal Outpost), buildings, containers, a watch tower, cover, trees and rocks. Lobby Character, Weapons and Vault pages now save a local operator skin and starting weapon; the selected weapon is loaded into the next match. Combat has three weapon profiles and a headshot damage bonus.

These are procedural prototype assets, not photorealistic licensed character models, mocap animations, finished textured terrain or a production-grade map. AI bots and the five-second queue are local-only; online multiplayer is not implemented. The new scripts have been committed to GitHub, but Godot runtime parsing, Android export and on-device gameplay still need verification through Codemagic and a real Android device.

## Art direction
- Original identity: GRBG 1; rugged coastal-island battle arena inspired by Saurashtra.
- Visual target: colorful, readable, polished mobile shooter; warm coastal sunlight, blue sea, green terrain, detailed compounds, roads, rocks, trees, shipping containers and recognizable landmarks.
- Player: full-body humanoid soldier model with idle, run, sprint, jump, crouch, aim, fire, reload, hit and death animations.
- Camera: responsive third-person follow camera with shoulder offset, aim zoom and collision handling.
- HUD: compact mobile-first layout with left joystick, right-side look area, fire/aim/jump/crouch/prone/reload, weapon slots, ammo, health/armor, minimap, alive count and safe-zone timer.
- Lobby: character showcase, selected outfit, game mode/map cards, inventory/store placeholders only where functional, and a prominent Start button.
- Audio and effects: footsteps by surface, weapon reports, reload, hit feedback, ambient coastal sound, muzzle flash, impact effects and restrained performance-friendly particles.

## Rebuild milestones
1. **Foundation and quality gate**
   - Keep the current working APK workflow as a fallback.
   - Establish clean Godot scene structure, mobile aspect handling, input abstraction and a stable Android export.
   - Add a visual test scene and verify on a real phone before expanding.

2. **Lobby and identity**
   - Build a polished original GRBG 1 lobby with a 3D character showcase, background environment, readable typography and responsive Start flow.
   - No fake store or non-working buttons.

3. **Character and camera**
   - Integrate properly licensed humanoid model(s), animations, weapon attachment points, third-person camera, aim and movement states.

4. **Arena environment**
   - Replace primitive box island with optimized terrain, coastal water, roads, villages, industrial dock, foliage, buildings, collision and landmarks.
   - Use LODs, texture compression and mobile-friendly materials.

5. **Combat loop**
   - Add weapon handling, recoil, hit reactions, damage feedback, loot, inventory, armor, healing and balanced bot behavior.
   - Use real animation and audio assets with clear licenses.

6. **Battle-royale match flow**
   - Plane/drop sequence, parachute, landing, looting, shrinking zone, kill feed, spectator/results and restart.

7. **Online multiplayer (separate major milestone)**
   - Add accounts, matchmaking service, authoritative game server, player replication, latency handling, reconnect and anti-cheat. Local bots/countdown must never be labelled as online matchmaking.

8. **Device QA and release**
   - Test on low-, mid- and high-range Android devices, fix crashes/performance, validate touch layout, then create a signed release APK.

## Quality rules
- Never call a primitive placeholder a finished character, map or weapon.
- Never report a feature complete until it has been run and tested on an Android device.
- Preserve a known-good build workflow while making changes in small, reversible commits.
- Use original or properly licensed assets; record asset source and license.
- Prioritize stable 30 FPS on supported mid-range Android devices before adding expensive effects.

## First implementation target
Build the new lobby as the first visible quality milestone, then show/test that APK before replacing the gameplay foundation. Do not attempt to add all production features in one large untested commit.
