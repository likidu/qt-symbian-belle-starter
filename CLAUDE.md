# Project Instructions

## Project Overview
- Qt 4.7 / QML 1.1 application for Symbian Belle (Nokia C7 class), self-signed SIS deployment.
- Generated from the qt-symbian-belle-starter template.
- See `docs/PLAN.md` for milestones, `docs/DEVICE_NOTES.md` for the device experiment log.

## Architecture
- C++ managers in `src/` are exposed to QML via `setContextProperty` in `main.cpp`:
  `storage` (StorageManager), `memoryMonitor`, `tlsChecker`, `audioEngine`.
- `StorageManager` handles SQLite with multi-candidate writable-path fallback.
- QML uses Symbian Components 1.1; `AppWindow.qml` is the root, pages live in `qml/`.

## Critical Symbian Rules
- **NEVER write the `position` property on a QML `Audio` element** — causes
  KErrMMAudioDevice (-12014) and bricks ALL audio until phone restart. Drive
  playback through the C++ `audioEngine` (`QMediaPlayer::setPosition()`).
- **Data caging**: `/private/<UID>/` dirs are writable but invisible to
  `QDir::exists()`. Skip exists/mkpath checks and go straight to an I/O test.
- **SQL driver**: prefer `QSYMSQL` over `QSQLITE` on Symbian. Test with the same
  driver production code uses.
- **Path separators**: use `QDir::toNativeSeparators()` for paths passed to SQL
  drivers on Symbian.

## QML 1.1 Compatibility Rules
- **No block expressions in property bindings** — use a helper function or ternary.
- **No named function declarations inside non-root elements** — declare functions
  at the `Page`/root level only.
- **No negative anchor margins** — size a larger `Item` for touch targets instead.
- **SVG icon sizing**: Symbian renders icons using the SVG `viewBox` dimensions,
  ignoring `width`/`height`. To resize, change both the `width`/`height` and the
  `viewBox`, wrapping paths in `<g transform="scale(factor)">`.

## Device Experimentation Log
- After ANY audio/media/platform-API experiment, record it in `docs/DEVICE_NOTES.md`
  with a dated heading (`## YYYY-MM-DD — Title`), including error codes and failed
  approaches. Read it before touching audio/media code — Symbian MMF is fragile.
