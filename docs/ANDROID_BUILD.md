# Reproducing the Android build

## Versions

- Godot **4.6.3 stable**, standard build with GDScript.
- Matching official **4.6.3.stable** Android export templates.
- JDK 17 for CI; the local export was also exercised with JDK 21.
- Android SDK command-line tools, platform-tools, **platforms;android-36**, **build-tools;36.0.0**.
- Linux x86-64 build host. Game APK targets arm64 Android.

This project uses Godot's supported **prebuilt Android template export**, not a custom Gradle engine build. It needs no Android plugins, native extensions or Gradle downloads. Minimum and target SDK levels come from the pinned official template; do not override the Gradle-only SDK fields while Gradle export is disabled. ETC2/ASTC import is enabled in the project for Android compatibility.

## GitHub Actions

Push to `main`, open a pull request, or run **Validate and build Android APK** manually. The workflow checks out source, installs Java/SDK/Godot/templates, imports resources, runs economy/gameplay tests, generates a debug signing key, exports and verifies the APK, then uploads **lagos-empire-3d-android-debug** for 14 days.

The artifact contains the APK, checksum, test logs, export log and package information. Download it from the completed run's **Artifacts** section. No store release or public release publishing is configured. Debug signing keys generated on separate runners differ, so outputs are reproducible by process and pinned engine version, not bit-for-bit identical signatures.

## Local export

Install Godot and matching templates, accept the Android SDK licences, and set `ANDROID_SDK_ROOT` (or `ANDROID_HOME`) and `JAVA_HOME`. With Godot available as `godot`:

```bash
sdkmanager 'platform-tools' 'platforms;android-36' 'build-tools;36.0.0'
mkdir -p "$HOME/.android"
keytool -genkeypair -keystore "$HOME/.android/debug.keystore" \
  -storepass android -alias androiddebugkey -keypass android \
  -dname 'CN=Android Debug,O=Android,C=US' \
  -keyalg RSA -keysize 2048 -validity 10000
python3 tools/configure_android.py
bash tools/validate.sh
godot --headless --path . --export-debug Android build/lagos-empire-3d-debug.apk
"$ANDROID_SDK_ROOT/build-tools/36.0.0/apksigner" verify --verbose build/lagos-empire-3d-debug.apk
```

Skip key creation if a debug key already exists. `GODOT_DEBUG_KEYSTORE` may select another local debug key. Do not commit keystores. Local Godot settings can be placed outside the default home using `XDG_CONFIG_HOME`, `XDG_DATA_HOME` and `XDG_CACHE_HOME`.

Godot template location on Linux: `$XDG_DATA_HOME/godot/export_templates/4.6.3.stable/` or `~/.local/share/godot/export_templates/4.6.3.stable/`, containing `android_debug.apk` and `android_release.apk`. The workflow downloads the official archive and extracts those files.

## Verification versus hardware testing

Signature verification, ZIP integrity, manifest inspection and source tests are build evidence. They do not prove installation or gameplay on a Samsung phone. Install using the phone's package installer or `adb install -r`, launch, test multi-touch, background/resume, saving, driving, interiors and sustained performance on the actual target device.

The managed build environment's Java SDK installer could not retrieve repository manifests through its proxy. For the local build, official Android package archives were downloaded through the configured HTTP proxy and checked against their published repository SHA-1 values. CI uses the normal SDK installer on GitHub's runner.

The local environment also prevents ADB from creating its default home directory; Godot's exit-time device scan logs this limitation after export. It does not invalidate the produced signed APK. No USB phone or Android emulator gameplay has been exercised here.
