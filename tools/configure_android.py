"""Configure Godot's editor settings from standard Android/JDK locations."""
import os
from pathlib import Path

config = Path(os.environ.get('XDG_CONFIG_HOME', str(Path.home() / '.config'))) / 'godot'
config.mkdir(parents=True, exist_ok=True)
sdk = os.environ.get('ANDROID_SDK_ROOT') or os.environ.get('ANDROID_HOME')
jdk = os.environ.get('JAVA_HOME')
key = os.environ.get('GODOT_DEBUG_KEYSTORE', str(Path.home() / '.android' / 'debug.keystore'))
if not sdk or not jdk:
    raise SystemExit('ANDROID_SDK_ROOT (or ANDROID_HOME) and JAVA_HOME must be set')
settings = config / 'editor_settings-4.6.tres'
text = settings.read_text() if settings.exists() else '[gd_resource type="EditorSettings" format=3]\n\n[resource]\n'
values = {'export/android/android_sdk_path': sdk, 'export/android/java_sdk_path': jdk,
          'export/android/debug_keystore': key, 'export/android/debug_keystore_user': 'androiddebugkey',
          'export/android/debug_keystore_pass': 'android'}
lines = [line for line in text.splitlines() if not any(line.startswith(k + ' =') for k in values)]
for k, v in values.items():
    lines.append(f'{k} = "{v}"')
settings.write_text('\n'.join(lines) + '\n')
print('Configured Android export paths for Godot 4.6.')
