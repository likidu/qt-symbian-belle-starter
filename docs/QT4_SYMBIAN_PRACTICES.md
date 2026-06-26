# Qt 4 / Symbian Belle Practices

These notes capture reusable lessons from device and simulator work. Keep app-specific API details in the app repo; keep template-level platform rules here.

## JSON and Native Networking

- Qt 4.7 has no `QJsonDocument`. Use the vendored `lib/qjson` library for JSON parse/serialize in C++.
- Include `parser.h` and `serializer.h` from C++ code after `BelleApp.pro` includes `lib/qjson/qjson.pri`.
- Prefer native `QNetworkAccessManager` clients for authenticated or structured APIs. QML `XMLHttpRequest` on Qt 4.7 can lose useful error details on HTTP failure paths.
- Read HTTP status from `QNetworkRequest::HttpStatusCodeAttribute`, not from parsed response bodies.
- Add explicit request timeouts for API clients. A 15 second single-shot `QTimer` around a reply is a good starting point.
- If a C++ network client must tolerate stale Symbian CA stores, connect each reply's `sslErrors` signal and call `ignoreSslErrors()` there. QML image loads that go through the app's custom QML network manager do not automatically cover separate C++ managers.

Minimal parse example:

```cpp
#include "parser.h"
#include "serializer.h"

QJson::Parser parser;
bool ok = false;
const QVariant root = parser.parse(reply->readAll(), &ok);
if (ok) {
    const QVariantMap map = root.toMap();
}
```

## QML Resource Rebuilds

- qmake-generated Makefiles may only track `qml/qml.qrc`, not every `.qml`, `.js`, or SVG file inside it.
- After editing embedded QML resources, use a clean build or delete the generated `rcc/qrc_qml.cpp` and matching object file before rebuilding.
- If a simulator or device run shows stale UI after a QML-only change, suspect the resource compiler first.

## Files, URLs, and Media

- QML `Image.source` needs a URL. Emit `QUrl::fromLocalFile(path).toString()` for local cached files instead of raw paths.
- Do not infer cached image extensions from URL paths alone. Prefer `Content-Type` when saving downloaded images.
- Exclude `.part` temp files and the active temp file when cleaning or probing a cache directory.
- Do not rely on broad `QDir::entryList()` glob matches for critical cache state on Symbian. Prefer direct `QFile::exists()` probes for known filenames/extensions.
- Media that Symbian MMF must decode should live in a public path such as `E:/AppName/audio` or `C:/Data/AppName/audio`, not in `/private/<UID>/`.

## Device Verification

- Simulator checks prove control flow and QML loading, not Symbian server behavior. Retest filesystem, TLS, MMF audio, and device-key behavior on hardware.
- Record every audio, media, network, storage, or platform API experiment in `docs/DEVICE_NOTES.md` with exact error codes and failed approaches.
- If audio begins failing with `-14`, `-12014`, silent output, or stuck media status after experiments, reboot the phone before concluding the latest code is wrong. Symbian MMF can remain wedged across app restarts.
- For Qt Simulator screenshots in automated shells, capture the host "Qt Simulator" window. The launched app process may not own a top-level window.
