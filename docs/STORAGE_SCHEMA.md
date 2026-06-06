# Storage Schema

`StorageManager` (`src/StorageManager.{h,cpp}`) opens a single SQLite database
via the Symbian multi-candidate writable-path probe (see `dbPath()`), preferring
the `QSYMSQL` driver and falling back to `QSQLITE`, then `:memory:`.

## Tables

### `kv`
| Column | Type | Notes |
|--------|------|-------|
| `key`   | TEXT | Primary key |
| `value` | TEXT | Arbitrary string |

Accessed from QML via `storage.setValue(key, value)` and
`storage.value(key, default)`. The self-test page writes/reads the `selftest`
key to prove the DB round-trips on-device.

Add your own tables in `StorageManager::initDb()` and expose typed
`Q_INVOKABLE` accessors as your app needs them.
