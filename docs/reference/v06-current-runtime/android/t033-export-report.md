# T033 Android debug export report

Date: 2026-07-20 (JST)

## Export result

- Godot 4.7 Android debug export: passed.
- APK: `build/android/dice-slot-trip-debug.apk`
- Size: 105,495,811 bytes
- SHA-256: `fa6f070af9efd2abb9c8bb7046c1875c4d734801d4b5df1cb5cffca39df46403`
- Package: `com.madowaku.diceslottrip.dev`
- Target / compile SDK: 36
- Native ABI: `arm64-v8a`
- Portrait feature and small/normal/large/xlarge screen support: present.
- Launcher alias (`MAIN` + `DEFAULT` + `LAUNCHER`) is present after setting `package/show_as_launcher_app=true`.
- Custom dangerous permissions: none declared in `export_presets.cfg`.
- APK signature: apksigner v2 and v3 verified.

## Device gate

- Android SDK and Godot 4.7 export templates are installed locally.
- ADB is available at `C:\Users\hiro\AppData\Local\Android\Sdk\platform-tools\adb.exe`.
- `adb devices` returned no attached device, so install, cold launch, touch, MAP, one-step movement, boss-ready, pause/resume, and screenshot capture remain pending on a real or emulated device.

## Notes

- Godot reports the existing non-blocking warning that no project icon is specified; the APK export and signature verification still complete successfully.
- No runtime or scene changes were needed for the export gate.
