Symbian packaging and device verification
========================================

Prerequisites
- Symbian Qt SDK installed (Qt 4.7.4 toolchain). Default path assumed by scripts: C:\Symbian\QtSDK
- Symbian SDK root (example): C:\Symbian\QtSDK\Symbian\SDKs\SymbianSR1Qt474
- RVCT 4.0 toolchain for device builds.
- Device: a Symbian Belle handset, such as Nokia C7 or X7, with the Qt runtime installed.

Build + package (one step)
   pwsh scripts/build-sis.ps1 -Config Release -Arch armv5

This runs the build and packaging stages below and writes the self-signed SIS to
build-symbian\armv5-release\BelleApp_selfsigned.sis. Useful flags:
- -Clean  : force a clean rebuild. Use this after editing QML, JS, qrc, or SVG
            resources because rcc can otherwise bake stale UI into the app.
- -Force  : regenerate the self-signed certificate.

Build + package (separate stages)
1. Build the binaries:
   pwsh scripts/build-symbian.ps1 -Config Release -Arch armv5
   Output is staged into build-symbian\armv5-release.
2. Confirm BelleApp_template.pkg has the package UID and version you want.
   - The default UID is in the self-signed test range (0xE0000000-0xEFFFFFFF).
3. Create the SIS:
   pwsh scripts/package-symbian.ps1 -Config Release -Arch armv5
   Outputs:
   - build-symbian\armv5-release\BelleApp_selfsigned.sis
   - build-symbian\armv5-release\BelleApp_unsigned.sis
   - build-symbian\armv5-release\BelleApp_local.pkg

Install on device
- Copy the .sis to the phone (USB mass storage or Nokia Suite) and install it.
- On device, allow installing from unknown sources (Application manager settings) and disable online cert check if prompted.

Troubleshooting notes
- If QML/UI edits do not appear on device, rebuild with -Clean.
- If BelleApp.rsc or BelleApp_reg.rsc is missing, rebuild and confirm the Symbian SDK path is correct.
- If network requests fail with a capability error, add NetworkServices to the Symbian capabilities in BelleApp.pro and rebuild.
- If the app fails to launch due to missing Qt libraries, install the Qt runtime for Symbian Belle.

Manual smoke test
- Self-test page loads without QML errors.
- TLS check reports pass.
- SQLite round-trip reports pass.
- Memory monitor reports live RAM values.
- Audio playback is audible on device.
- Close and reopen the app; persisted storage still works.
- After any failed audio, media, network, storage, or platform API experiment, append the result to docs/DEVICE_NOTES.md.
