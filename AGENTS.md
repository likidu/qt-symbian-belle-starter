# Repository Instructions

## Project Overview
- Qt 4.7 / QML 1.1 application for Symbian Belle, targeting Nokia C7-class devices with self-signed SIS deployment.
- Generated from the `qt-symbian-belle-starter` template.
- See `docs/PLAN.md` for milestones and `docs/DEVICE_NOTES.md` for the device experiment log.

## Architecture
- C++ managers in `src/` are exposed to QML via `setContextProperty` in `main.cpp`:
  `storage` (`StorageManager`), `memoryMonitor`, `tlsChecker`, and `audioEngine`.
- `StorageManager` handles SQLite with a multi-candidate writable-path fallback.
- QML uses Symbian Components 1.1. `AppWindow.qml` is the root, and pages live in `qml/`.
- Qt 4 has no `QJsonDocument`; use the vendored `lib/qjson` library for native JSON.
- See `docs/QT4_SYMBIAN_PRACTICES.md` for reusable networking, qrc, file URL, and device-verification practices.

## Critical Symbian Rules
- Never write the `position` property on a QML `Audio` element. This causes `KErrMMAudioDevice` (`-12014`) and can break all audio until the phone restarts. Drive playback through the C++ `audioEngine` with `QMediaPlayer::setPosition()`.
- Data caging: `/private/<UID>/` directories are writable but invisible to `QDir::exists()`. Skip `exists()`/`mkpath()` checks and go straight to an I/O test.
- SQL driver: prefer `QSYMSQL` over `QSQLITE` on Symbian. Tests should use the same driver as production code.
- Path separators: use `QDir::toNativeSeparators()` for paths passed to SQL drivers on Symbian.

## QML 1.1 Compatibility Rules
- No block expressions in property bindings. Use a helper function or ternary.
- No named function declarations inside non-root elements. Declare functions only at the `Page` or root level.
- No negative anchor margins. Size a larger `Item` for touch targets instead.
- SVG icon sizing: Symbian renders icons using the SVG `viewBox` dimensions and ignores `width`/`height`. To resize, change both `width`/`height` and `viewBox`, wrapping paths in `<g transform="scale(factor)">`.

## Device Experimentation Log
- After any audio, media, or platform API experiment, record the result in `docs/DEVICE_NOTES.md` with a dated heading in the form `## YYYY-MM-DD - Title`.
- Include error codes and failed approaches in the log.
- Read `docs/DEVICE_NOTES.md` before touching audio or media code because Symbian MMF behavior is fragile.
