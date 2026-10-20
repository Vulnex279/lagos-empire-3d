# Verification results

Verified in the managed Linux workspace with Godot 4.6.3. These results describe the playable foundation, not a finished production release.

| Area | Result and evidence |
| --- | --- |
| Godot import and GDScript compilation | Successful headless editor import; no script parse failures |
| Economy behavioural suite | 57 assertions passed; no failures |
| Gameplay integration suite | 34 assertions passed; no failures |
| Rendering | Actual Godot OpenGL Compatibility render on Mesa llvmpipe; menu, exploration, street, phone map, driving and interior captures inspected |
| Android compilation/export | Debug arm64 APK exported using official Godot Android templates |
| APK signature and integrity | Independent `apksigner verify`: v2 and v3 signatures verified; ZIP integrity and 16 KB native-library alignment checks passed |
| Manifest | Package `com.lagosempire.game`, version 0.1.0, minimum API 24, target API 36, landscape, arm64, backup disabled |
| Network/privacy | No Android permissions requested; no gameplay network dependency |
| Installation and gameplay on Android | **Not tested**: no target phone or emulator gameplay available |
| Mid-range Samsung FPS / RAM / thermals | **Not measured** |
| GitHub Actions execution | Workflow supplied; remote execution blocked until an accessible repository is supplied |

## Automated coverage

Economy tests exercise new game, exact starting balance, insufficient funds, negative quantities, deposit/withdrawal conservation, overdraft rejection, remote pickup/completion rejection, single active mission, one-time intro rewards, completion replay after reload, passenger vehicle requirement, deadlines, goods inventory, stock fees, overselling rejection, loans and repayments, first-car purchase, duplicate ownership, mansion/furniture/business purchases, upgrades, daily revenue and costs, debt interest, market movement, full persistence, negative and NaN state rejection, unknown assets, corrupt-save backup recovery and rollback on failed storage.

Gameplay tests instantiate the real main scene. They exercise menu startup, floor collision, walking displacement, camera input, touch press/release, every phone screen, both interior transitions, car entry, acceleration, fuel use, braking, safe exit, storage/retrieval, both vehicle types, pausing and persistent ownership. The tests use direct input and game-state setup where needed; they are not a complete end-to-end manual playthrough or hardware touch test.

Two defects found by the first test pass were fixed: JSON number-type changes on reload and a vehicle-exit ground-overlap probe. Visual inspection also drove a lighting correction, clearer shop frontage, interior roofing and removal of an oversized near-camera interior sign. Static world geometry now uses spatial MultiMesh batches, retaining independent collision bodies.

Clean-package verification exposed an intermittent audio-playback resource reference during immediate shutdown. Teardown now stops and releases streams and gives the mixer a short drain interval before quitting; the test and capture harnesses use the same cleanup.

Run `bash tools/validate.sh` to reproduce checks. `tests/capture_screens.gd` requires a real rendering display (a virtual X display with software OpenGL also works). Tests use separate save files and clean them up; screenshot capture uses volatile state. No test needs a paid service or online gameplay backend.

Retained evidence: `docs/economy-tests.log`, `docs/gameplay-tests.log`, `docs/apk-signature.txt`, `docs/render-validation.log` and `docs/screenshots/`. Render samples include draw-call and primitive counters from the software renderer; they are not phone benchmarks. APK packaging checks also confirmed that engine legal notices are included and test scripts are excluded.

## Remaining verification work

- Install on the intended Samsung phone and play the complete introductory quest without developer setup.
- Test simultaneous movement/look/use, device cutouts, wide landscape ratios and Android Back.
- Test background/resume, process termination, low storage and a corrupt primary save on Android.
- Measure sustained frame time, memory, load time, battery and temperature at all presets.
- Drive both vehicles around every road and inspect all wall/door exits manually.
- Run extended balance simulations and long play sessions toward ₦1 billion.
- Trigger the supplied GitHub workflow after repository access is available; verify its uploaded artifact separately.
