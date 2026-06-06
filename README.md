# Qt / Symbian Belle Starter

A GitHub template for new Qt 4.7 / QML 1.1 apps targeting **Symbian Belle**
(Nokia C7 class). It boots with storage, logging, networking/TLS, memory
monitoring, and audio already wired, plus build/package/scaffold scripts — so
you start from a running app, not an empty `main()`.

The default app is named **BelleApp** and its landing screen is a **subsystem
self-test**: TLS, SQLite round-trip, live RAM, and audio playback each report
pass/fail. Run it first on a fresh device to confirm the platform layers work
before you write any app code.

## Use this template

1. Click **Use this template** on GitHub (or clone this repo).
2. Personalize the name + Symbian UID:
   ```powershell
   pwsh scripts/init-project.ps1 -AppName "MyApp" -Uid 0xE1234567
   ```
   Pick a UID in the self-signed range `0xE0000000–0xEFFFFFFF`.
3. Build and run on the simulator:
   ```powershell
   pwsh scripts/build-simulator.ps1 -Config Debug -Clean
   pwsh -File build-simulator\debug\MyApp.run.ps1
   ```

## Build for a device

```powershell
pwsh scripts/build-symbian.ps1   -Config Release -Arch armv5
pwsh scripts/package-symbian.ps1 -Config Release -Arch armv5
```
Produces a self-signed `.sis`. See `docs/SYMBIAN_PACKAGING.md` for install steps,
and `docs/DEVICE_NOTES.md` for hard-won device gotchas.

## Layout

| Path | What |
|------|------|
| `BelleApp.pro` | qmake project |
| `src/` | C++ managers (Storage, Audio, Memory, Tls) + bootstrap |
| `qml/` | QML UI: `AppWindow`, `SelfTestPage`, page-stack shell |
| `scripts/` | build / package / inspect / init PowerShell scripts |
| `docs/` | packaging guide, storage schema, device log, plan |

## Prerequisites
- Qt SDK with Qt Simulator (Qt 4.7.4, MinGW), typically under `C:\Symbian\QtSDK`.
- For device builds: the Symbian SDK (`SymbianSR1Qt474`) with RVCT 4.0.

> On-device behaviour can't be verified from CI (the legacy toolchain isn't
> hostable on hosted runners). Always smoke-test the self-test page on hardware.

## License
MIT — see `LICENSE`.
