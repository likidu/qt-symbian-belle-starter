#pragma once

#include <QtCore/QLatin1String>
#include <QtCore/QString>

namespace AppConfig {

// App name and version
static const char *const kAppName    = "BelleApp";
static const char *const kAppVersion = "0.1.0";

// Base data directories (tried in priority order)
static const char *const kMemoryCardBase = "E:/BelleApp";
static const char *const kPhoneBase      = "C:/Data/BelleApp";

// Subdirectories
static const char *const kLogsSubdir     = "logs";

} // namespace AppConfig
