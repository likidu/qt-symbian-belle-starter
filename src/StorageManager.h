#ifndef STORAGEMANAGER_H
#define STORAGEMANAGER_H

#include <QtCore/QObject>
#include <QtCore/QString>

// Minimal persistence layer for the starter template. Encodes the Symbian
// multi-candidate writable-path probe and QSYMSQL/QSQLITE driver selection
// (the hard-won parts), backed by a generic kv(key, value) table. Replace or
// extend with real tables as your app grows.
class StorageManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString lastError READ lastError NOTIFY lastErrorChanged)
    Q_PROPERTY(QString dbPath READ dbPathForQml CONSTANT)
    Q_PROPERTY(QString dbStatus READ dbStatus CONSTANT)
    Q_PROPERTY(QString dbPathLog READ dbPathLog CONSTANT)

public:
    explicit StorageManager(QObject *parent = 0);

    QString lastError() const;
    QString dbPathForQml() const;
    QString dbStatus() const;
    QString dbPathLog() const;

    Q_INVOKABLE bool setValue(const QString &key, const QString &value);
    Q_INVOKABLE QString value(const QString &key, const QString &defaultValue = QString()) const;
    Q_INVOKABLE void clearLastError();

signals:
    void lastErrorChanged();

private:
    QString dbPath();
    bool ensureOpen() const;
    void initDb();
    void setLastError(const QString &error);

    QString m_lastError;
    QString m_dbPath;
    QString m_dbStatus;
    QString m_dbPathLog;
};

#endif // STORAGEMANAGER_H
