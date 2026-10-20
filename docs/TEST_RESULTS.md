# Verification results — visual and living-economy alpha 0.2.0

Test host: Linux x86-64, Godot 4.6.3 stable. Rendering checks use the actual Godot
Compatibility renderer through Mesa llvmpipe at 1280×720. This is not an Android
GPU benchmark. Tests exercise the integrated existing game, not separate demos.

## Automated results

| Suite | Result | Scope |
|---|---|---|
| Original economy regressions | 57 checks passed | ₦25,000 start; jobs; trading; investments; bank; loans; purchases; business costs; save/load; corrupt primary recovery; failed-write rollback; invalid balances |
| Integrated gameplay | 42 checks passed | Main menu; grounded walking; camera; touch joystick; all phone pages; room/duplex/mansion entry and exit; sedan/SUV/sports ownership; sports wheel pivots; driving; braking; fuel; garage; paused clock; persistence |
| Living economy | 162 checks passed | Trillion-naira arithmetic and disk round trip; duplicate reward/sale rejection; reputation-gated offers; supply cargo consumption; deterministic varied missions; migration; interrupted temporary files; bankruptcy; exact loan interest; deadline/rest handling |
| Asset checks | 14 checks passed | Full imported skeleton; seven required animation references; changing skeletal pose during walking; palette textures on imported assets |
| External glTF dependencies | Passed | Every referenced image/buffer exists; source hashes retained in `assets/ASSET_HASHES.sha256` |
| APK-packaged resources on host Godot | 42 gameplay checks passed | Extracted exported resources load and run the same gameplay suite using the matching desktop engine. This checks packaging/compiled scripts, not Android installation or gameplay. |

The long simulation covers **15,000 days**: 3,000 days for each of four deterministic
portfolio seeds, plus 3,000 days of unemployed debt accumulation, with additional
identical-seed replays. Histories stay bounded. No invalid balances, state rejection
or overflow occurred. Extreme debt still permits insolvency recovery.

Fixed three-business portfolios ended around ₦51–52 million cash after 3,000 days,
with no debt in these tested starting conditions. Across 36,000 business-days,
1,899 had losses and 34,101 had profits. This verifies that recession/competition
can produce losses; it does not prove balanced first-hour pacing, fun endgame
progression or every player strategy. Exponential business scaling was replaced
with linear capacity; weekly bank interest and milestone rewards are capped.

## Android build verification

- Debug APK export succeeded using the official matching Android template.
- APK ZIP integrity, v2/v3 signature and 16 KB page alignment checks passed.
- Package version 0.2.0, arm64, minimum API 24, target API 36, landscape.
- No Android Internet/network permissions requested. Required sector data, legal
  credits, imported meshes and compiled scripts are inside the package.
- The local upgrade uses the prior local debug signing key and the same package
  identity. Save schema migration is tested; actual Android in-place upgrade is not.
- The prepared GitHub Actions workflow includes source tests, long simulation,
  asset validation, APK signing/alignment verification and artifact upload. It has
  not run remotely because no accessible project repository is configured.

Godot's post-export device scan cannot create the read-only default Android home
in this managed environment. This produces an ADB diagnostic after successful
export; independent verification succeeds. No phone is attached. An initial forced
headless shutdown of extracted resources produced an audio/resource shutdown
warning; the normal cleanup used by the full packaged gameplay suite exits cleanly.

## Actual-engine visual evidence

`docs/screenshots/upgrade-*.png` captures the character, district, SUV, sports car,
mansion, furnished interior and economy screen from the running project. The
capture harness uses temporary test funds and camera positions, not concept art;
these images are visual QA evidence, not a claim that an ordinary new game starts
with the photographed wealth. Regular new games still start with ₦25,000.

Material checks caught missing palette dependencies, which were corrected and
reimported. City texture mipmaps reduce distant shimmering. Hero cars use original
exported mesh shells with wheel wells, rims, glazing and lights. Important city
architecture uses imported facade/building meshes; the villa is an original GLB.
Static details are joined by material and spatially instanced. Three quality presets
control shadows, antialiasing, camera range and pedestrian activation distance.
Final photographed views ranged from 259–834 draw calls and approximately
57,000–555,000 submitted primitives, including shadow passes. The denser district
raises the profiling priority on Android. Samples are recorded in the render log.
They are not FPS measurements or guarantees.

## Not verified / incomplete

Physical Samsung installation, touchscreen ergonomics, sustained 30 FPS, RAM,
thermal behaviour, Android background/process-kill recovery and release signing
remain unverified. Art remains stylised and needs further clothing, vehicle and
city-cohesion work to reach the requested premium finish. NPC navigation is authored
sidewalk motion, traffic is parked scenery, and vehicle entry/exit is immediate.
Advanced rival partnerships/acquisitions, insurance, manager decisions, chains,
fleets, Legacy Mode, difficulty selection and fully authored trillionaire content
are deferred. See `NEXT_STEPS.md`; no production-ready claim is made.
