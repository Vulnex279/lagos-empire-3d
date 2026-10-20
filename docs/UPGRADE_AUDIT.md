# Visual and living-economy upgrade audit

Baseline: existing v0.1 source and commit history retained. Godot 4.6.3, Compatibility renderer, arm64 template export, local save version 1. No project recreation or public publishing.

## Existing systems

| System | Implementation | Upgrade action |
| --- | --- | --- |
| Player | `player.gd`, `scenes/player.tscn` | Preserve CharacterBody3D movement and spring-arm camera; replace `Geo.person` and child-index limb animation with imported skinned humanoid and animation state logic |
| NPCs | `world.gd`, `Geo.person` | Replace cuboid people; capped proximity-active pedestrian routes and reactive dialogue |
| Vehicles | `vehicle.gd`, `scenes/vehicle.tscn` | Preserve fuel, collision, acceleration and ownership APIs; replace visible BoxMesh/CylinderMesh assembly with imported body/wheel meshes, add sports car |
| World | `world.gd`, `geometry.gd` | Replace important visible building/prop primitives with imported modular assets; preserve street layout and location identifiers for saves/missions |
| Economy | `economy.gd` autoload | Keep centralized atomic transactions; add version migration, 64-bit limits, scheduled sector simulation and idempotence |
| Missions | `Catalog.JOBS`, economy acceptance/completion | Keep intro jobs; add deterministic contextual offers, bounded history and meaningful requirements |
| Homes | Catalog registry, main transitions | Preserve starter room/mansion; add enterable apartment and portfolio data |
| Interface | `ui.gd`, `main.gd`, `district_map.gd` | Preserve working touch controls and apps; expose actual new simulation data |
| Tests/build | tests, Android export preset and Actions | Extend behavioural coverage, asset checks, seeded multi-thousand-day simulation and real-engine screenshots |

## Acceptance checklist

- [x] Imported humanoid with Skeleton3D, skinned mesh, clothing/hair and working idle/walk/run; no runtime cuboid character fallback.
- [x] Imported SUV and sports car, visible separate wheels, usable controls, purchase/save/load, no primitive body fallback.
- [x] Imported architectural meshes at every important interactive building, additional roadside shopfronts, petrol pumps/service and three actual enterable homes (further art direction remains).
- [x] Asset provenance, source licence evidence and checksums retained; no paid assets or proprietary game models.
- [x] Asset validation checks animation tracks, textures and geometry; real Godot screenshots cover player/city/SUV/sports car/mansion/finance.
- [x] New game retains ₦25,000; old saves migrate; repeated reward/day/sale triggers cannot duplicate money.
- [x] Seeded sector cycles, rival decisions, business profits/losses and reputation affect real opportunities.
- [x] Accounting supports at least ₦10 trillion with explicit rounding and bounded arithmetic.
- [x] Multiple deterministic seeds complete thousands of simulated days without invalid balances, invalid ownership or arithmetic overflow.
- [x] Existing gameplay checks and new tests pass from clean source; debug APK exports, signs and verifies.
- [x] Physical Android and 30 FPS claims remain unverified until device testing actually occurs.

The requested scope is larger than a single production milestone. Any deferred item must be named in BUILD_STATUS/NEXT_STEPS rather than presented as complete.

Completion here describes the measured integration checkpoint, not the entire premium/endgame brief. Source-level tests and export are verified; physical-device acceptance and a finished premium art standard remain open in NEXT_STEPS.
