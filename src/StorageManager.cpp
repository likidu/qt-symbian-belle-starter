#include "StorageManager.h"
#include "AppConfig.h"

#include <QtCore/QDir>
#include <QtCore/QFile>
#include <QtCore/QCoreApplication>
#include <QtCore/QStringList>
#include <QtCore/QVariant>
#include <QtCore/QDebug>
#include <QtGui/QDesktopServices>
#include <QtSql/QSqlDatabase>
#include <QtSql/QSqlQuery>
#include <QtSql/QSqlError>

namespace {
const char *const kConnectionName = "belleapp_db";
}

StorageManager::StorageManager(QObject *parent)
    : QObject(parent)
{
    initDb();
}

QString StorageManager::lastError() const { return m_lastError; }
QString StorageManager::dbPathForQml() const { return m_dbPath; }
QString StorageManager::dbStatus() const { return m_dbStatus; }
QString StorageManager::dbPathLog() const { return m_dbPathLog; }

void StorageManager::setLastError(const QString &error)
{
    if (m_lastError == error)
        return;
    m_lastError = error;
    if (!error.isEmpty())
        qWarning("Storage error: %s", qPrintable(error));
    emit lastErrorChanged();
}

void StorageManager::clearLastError()
{
    setLastError(QString());
}

QString StorageManager::dbPath()
{
    QString base;
    m_dbPathLog.clear();
#ifdef Q_OS_SYMBIAN
    // Try multiple locations on Symbian. For self-signed apps only the private
    // directory is writable, so probe each candidate with a real SQLite open.
    QStringList candidates;

    QString dataPath = QDesktopServices::storageLocation(QDesktopServices::DataLocation);
    if (!dataPath.isEmpty()) {
        candidates << dataPath;
    }
    m_dbPathLog += QString::fromLatin1("DataLocation: %1\n").arg(dataPath.isEmpty() ? QLatin1String("(empty)") : dataPath);

    QString appPrivate = QCoreApplication::applicationDirPath();
    if (!appPrivate.isEmpty() && !candidates.contains(appPrivate)) {
        candidates << appPrivate;
    }
    m_dbPathLog += QString::fromLatin1("AppDirPath: %1\n").arg(appPrivate.isEmpty() ? QLatin1String("(empty)") : appPrivate);

    candidates << QLatin1String(AppConfig::kPhoneBase);
    candidates << QLatin1String(AppConfig::kMemoryCardBase);

    QString tempPath = QDir::tempPath();
    if (!tempPath.isEmpty() && !candidates.contains(tempPath)) {
        candidates << tempPath;
    }
    m_dbPathLog += QString::fromLatin1("TempPath: %1\n").arg(tempPath.isEmpty() ? QLatin1String("(empty)") : tempPath);
    m_dbPathLog += QString::fromLatin1("Candidates: %1\n").arg(candidates.join(QLatin1String(", ")));

    QString testDriver = QLatin1String("QSQLITE");
    if (QSqlDatabase::isDriverAvailable(QLatin1String("QSYMSQL"))) {
        testDriver = QLatin1String("QSYMSQL");
    }
    m_dbPathLog += QString::fromLatin1("TestDriver: %1\n").arg(testDriver);

    for (int i = 0; i < candidates.size(); ++i) {
        QString candidatePath = candidates.at(i);
        QDir dir(candidatePath);

        // Paths under /private/ are data-caged: QDir::exists() returns false and
        // mkpath() fails even though the dir exists. Skip the check; go straight
        // to the SQLite write test.
        bool isPrivatePath = candidatePath.contains(QLatin1String("/private/"), Qt::CaseInsensitive);
        if (!isPrivatePath) {
            if (!dir.exists()) {
                if (!dir.mkpath(QLatin1String("."))) {
                    m_dbPathLog += QString::fromLatin1("mkdir FAIL: %1\n").arg(candidatePath);
                    continue;
                }
                m_dbPathLog += QString::fromLatin1("mkdir OK: %1\n").arg(candidatePath);
            } else {
                m_dbPathLog += QString::fromLatin1("exists: %1\n").arg(candidatePath);
            }
        } else {
            m_dbPathLog += QString::fromLatin1("private (skip mkdir): %1\n").arg(candidatePath);
        }

        QString testDbPath = QDir::toNativeSeparators(dir.filePath(QLatin1String("test.db")));
        if (QSqlDatabase::contains(QLatin1String("path_test"))) {
            QSqlDatabase::removeDatabase(QLatin1String("path_test"));
        }

        QSqlDatabase testDb = QSqlDatabase::addDatabase(testDriver, QLatin1String("path_test"));
        testDb.setDatabaseName(testDbPath);
        if (testDb.open()) {
            QSqlQuery q(testDb);
            if (q.exec(QLatin1String("CREATE TABLE IF NOT EXISTS test(id INTEGER)"))) {
                testDb.close();
                QSqlDatabase::removeDatabase(QLatin1String("path_test"));
                QFile::remove(testDbPath);
                base = candidatePath;
                m_dbPathLog += QString::fromLatin1("SQLite OK: %1\n").arg(candidatePath);
                break;
            }
            m_dbPathLog += QString::fromLatin1("SQLite CREATE FAIL: %1\n").arg(candidatePath);
        } else {
            m_dbPathLog += QString::fromLatin1("SQLite open FAIL: %1 - %2\n").arg(candidatePath, testDb.lastError().text());
        }
        testDb.close();
        QSqlDatabase::removeDatabase(QLatin1String("path_test"));
        QFile::remove(testDbPath);
    }

    if (base.isEmpty()) {
        qWarning() << "StorageManager: No writable path found, using in-memory database";
        m_dbPathLog += QLatin1String("FALLBACK: in-memory\n");
        m_dbPath = QLatin1String(":memory:");
        return m_dbPath;
    }
#else
    base = QDesktopServices::storageLocation(QDesktopServices::DataLocation);
    m_dbPathLog += QString::fromLatin1("DataLocation: %1\n").arg(base.isEmpty() ? QLatin1String("(empty)") : base);
    if (base.isEmpty()) {
        base = QDir::homePath() + QLatin1String("/.belleapp");
        m_dbPathLog += QString::fromLatin1("Using home fallback: %1\n").arg(base);
    }
#endif
    QDir dir(base);
    bool baseIsPrivate = base.contains(QLatin1String("/private/"), Qt::CaseInsensitive);
    if (!baseIsPrivate && !dir.exists()) {
        if (dir.mkpath(QLatin1String("."))) {
            m_dbPathLog += QString::fromLatin1("Created dir: %1\n").arg(base);
        } else {
            m_dbPathLog += QString::fromLatin1("mkdir FAIL: %1\n").arg(base);
        }
    }
    m_dbPath = QDir::toNativeSeparators(dir.filePath(QLatin1String("belleapp.db")));
    return m_dbPath;
}

bool StorageManager::ensureOpen() const
{
    QSqlDatabase db = QSqlDatabase::database(QLatin1String(kConnectionName), false);
    if (db.isValid() && db.isOpen()) {
        return true;
    }
    if (!db.isValid()) {
        return false;
    }
    if (!db.open()) {
        return false;
    }
    return true;
}

void StorageManager::initDb()
{
    QStringList drivers = QSqlDatabase::drivers();
    qDebug() << "StorageManager: Available SQL drivers:" << drivers;
    m_dbPathLog += QString::fromLatin1("Drivers: %1\n").arg(drivers.join(QLatin1String(", ")));

    if (QSqlDatabase::contains(QLatin1String(kConnectionName))) {
        m_dbStatus = QLatin1String("already exists");
        return;
    }

    QString path = dbPath();
    qDebug() << "StorageManager: Opening database at:" << path;

    QString driverName;
#ifdef Q_OS_SYMBIAN
    if (QSqlDatabase::isDriverAvailable(QLatin1String("QSYMSQL"))) {
        driverName = QLatin1String("QSYMSQL");
    } else
#endif
    if (QSqlDatabase::isDriverAvailable(QLatin1String("QSQLITE"))) {
        driverName = QLatin1String("QSQLITE");
    } else {
        m_dbStatus = QString::fromLatin1("no driver available: %1").arg(drivers.join(QLatin1String(", ")));
        return;
    }
    m_dbPathLog += QString::fromLatin1("Using driver: %1\n").arg(driverName);

    QSqlDatabase db = QSqlDatabase::addDatabase(driverName, QLatin1String(kConnectionName));
    db.setDatabaseName(path);

    if (!db.open()) {
        m_dbStatus = QString::fromLatin1("open failed: %1").arg(db.lastError().text());
        return;
    }

    QSqlQuery createKv(db);
    if (!createKv.exec(QLatin1String("CREATE TABLE IF NOT EXISTS kv (key TEXT PRIMARY KEY, value TEXT)"))) {
        m_dbStatus = QString::fromLatin1("schema failed: %1").arg(createKv.lastError().text());
        return;
    }

    m_dbStatus = QLatin1String("open");
    qDebug() << "StorageManager: Database opened successfully";
}

bool StorageManager::setValue(const QString &key, const QString &value)
{
    if (!ensureOpen()) {
        setLastError(QLatin1String("database not open"));
        return false;
    }
    QSqlDatabase db = QSqlDatabase::database(QLatin1String(kConnectionName));
    QSqlQuery q(db);
    q.prepare(QLatin1String("INSERT OR REPLACE INTO kv (key, value) VALUES (?, ?)"));
    q.addBindValue(key);
    q.addBindValue(value);
    if (!q.exec()) {
        setLastError(q.lastError().text());
        return false;
    }
    clearLastError();
    return true;
}

QString StorageManager::value(const QString &key, const QString &defaultValue) const
{
    QSqlDatabase db = QSqlDatabase::database(QLatin1String(kConnectionName), false);
    if (!db.isValid() || !db.isOpen()) {
        return defaultValue;
    }
    QSqlQuery q(db);
    q.prepare(QLatin1String("SELECT value FROM kv WHERE key = ?"));
    q.addBindValue(key);
    if (q.exec() && q.next()) {
        return q.value(0).toString();
    }
    return defaultValue;
}
