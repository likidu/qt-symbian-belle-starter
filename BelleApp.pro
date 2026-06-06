TEMPLATE = app
TARGET = BelleApp
VERSION = 0.1.0

# Qt 4.x modules
QT += core gui network declarative sql
CONFIG += mobility
MOBILITY += multimedia
symbian:LIBS += -lhal

CONFIG -= debug_and_release
CONFIG(debug, debug|release) {
    CONFIG += console
    DEFINES += BELLEAPP_DEBUG
}

# Place all build artifacts inside build directory
DESTDIR = $$OUT_PWD
OBJECTS_DIR = $$OUT_PWD/obj
MOC_DIR = $$OUT_PWD/moc
RCC_DIR = $$OUT_PWD/rcc
UI_DIR = $$OUT_PWD/ui

INCLUDEPATH += src

symbian {
    TARGET.EPOCHEAPSIZE = 0x020000 0x2000000
    # Required capabilities for network streaming + local storage
    TARGET.CAPABILITY += NetworkServices ReadUserData WriteUserData UserEnvironment

    # Note: SQLite driver is built into QtSql.dll on Symbian, no separate plugin deployment needed

    # Create the private data directory during installation so the app can write its database
    DEPLOYMENT.installer_header = 0x2002CCCF

    # Deploy an empty placeholder file to create the private directory
    emptyfile.sources = data/.placeholder
    emptyfile.path = /private/e1000001
    DEPLOYMENT += emptyfile
}

SOURCES += \
    src/main.cpp \
    src/MemoryMonitor.cpp \
    src/TlsChecker.cpp \
    src/StorageManager.cpp \
    src/AudioEngine.cpp

HEADERS += \
    src/MemoryMonitor.h \
    src/TlsChecker.h \
    src/AppConfig.h \
    src/StorageManager.h \
    src/AudioEngine.h

RESOURCES += \
    qml/qml.qrc

OTHER_FILES += \
    qml/AppWindow.qml \
    qml/SelfTestPage.qml \
    qml/MemoryBar.qml \
    qml/BelleAppPageStackWindow.qml
