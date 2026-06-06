import QtQuick 1.1
import com.nokia.symbian 1.1

Page {
    id: page
    objectName: "SelfTestPage"

    property string tlsState: "idle"
    property string tlsMsg: qsTr("not run")
    property string storageState: "idle"
    property string storageMsg: qsTr("not run")
    property string audioState: "idle"
    property string audioMsg: qsTr("not run")

    function pillColor(state) {
        if (state === "pass") return "#2e7d32";
        if (state === "fail") return "#c62828";
        if (state === "busy") return "#f9a825";
        return "#37474f";
    }

    function runStorageTest() {
        page.storageState = "busy";
        page.storageMsg = qsTr("writing...");
        var token = "selftest-" + page.width + "x" + page.height;
        var ok = storage.setValue("selftest", token);
        if (!ok) {
            page.storageState = "fail";
            page.storageMsg = storage.lastError;
            return;
        }
        var readBack = storage.value("selftest", "");
        if (readBack === token) {
            page.storageState = "pass";
            page.storageMsg = qsTr("round-trip OK @ ") + storage.dbStatus;
        } else {
            page.storageState = "fail";
            page.storageMsg = qsTr("mismatch: ") + readBack;
        }
    }

    function runAudioTest() {
        page.audioState = "busy";
        page.audioMsg = qsTr("loading tone...");
        audioEngine.setSource("qrc:/qml/sfx/test-tone.wav");
        audioEngine.play();
    }

    function stopAudioTest() {
        audioEngine.stop();
        page.audioState = "idle";
        page.audioMsg = qsTr("stopped");
    }

    Flickable {
        anchors.fill: parent
        anchors.margins: 16
        contentHeight: col.height

        Column {
            id: col
            width: parent.width
            spacing: 16

            Text {
                width: parent.width
                text: qsTr("Subsystem Self-Test")
                font.pixelSize: 22
                color: platformStyle.colorNormalLight
            }
            Text {
                width: parent.width
                text: qsTr("Confirms the platform layers work on this device before you build your app.")
                font.pixelSize: 13
                color: "#9fb0d3"
                wrapMode: Text.WordWrap
            }

            // ---- TLS ----
            Row {
                width: parent.width
                spacing: 8
                Rectangle {
                    width: 64; height: 24; radius: 12
                    color: page.pillColor(tlsChecker.running ? "busy" : page.tlsState)
                    Text { anchors.centerIn: parent; color: "white"; font.pixelSize: 11
                        text: tlsChecker.running ? "BUSY" : page.tlsState.toUpperCase() }
                }
                Text { text: qsTr("TLS 1.2"); font.pixelSize: 16; color: platformStyle.colorNormalLight
                    anchors.verticalCenter: parent.verticalCenter }
            }
            Text { width: parent.width; text: page.tlsMsg; font.pixelSize: 12; color: "#aeb9d4"; wrapMode: Text.WordWrap }
            Button { text: qsTr("Run TLS check"); enabled: !tlsChecker.running; onClicked: tlsChecker.startCheck() }

            // ---- Storage ----
            Row {
                width: parent.width
                spacing: 8
                Rectangle {
                    width: 64; height: 24; radius: 12; color: page.pillColor(page.storageState)
                    Text { anchors.centerIn: parent; color: "white"; font.pixelSize: 11; text: page.storageState.toUpperCase() }
                }
                Text { text: qsTr("Storage"); font.pixelSize: 16; color: platformStyle.colorNormalLight
                    anchors.verticalCenter: parent.verticalCenter }
            }
            Text { width: parent.width; text: page.storageMsg; font.pixelSize: 12; color: "#aeb9d4"; wrapMode: Text.WordWrap }
            Text { width: parent.width; text: storage.dbPath; font.pixelSize: 11; color: "#6c7a99"; wrapMode: Text.WrapAnywhere }
            Button { text: qsTr("Run storage check"); onClicked: page.runStorageTest() }

            // ---- Memory ----
            Text { text: qsTr("Memory"); font.pixelSize: 16; color: platformStyle.colorNormalLight }
            MemoryBar { width: parent.width }

            // ---- Audio ----
            Row {
                width: parent.width
                spacing: 8
                Rectangle {
                    width: 64; height: 24; radius: 12; color: page.pillColor(page.audioState)
                    Text { anchors.centerIn: parent; color: "white"; font.pixelSize: 11; text: page.audioState.toUpperCase() }
                }
                Text { text: qsTr("Audio"); font.pixelSize: 16; color: platformStyle.colorNormalLight
                    anchors.verticalCenter: parent.verticalCenter }
            }
            Text { width: parent.width; text: page.audioMsg; font.pixelSize: 12; color: "#aeb9d4"; wrapMode: Text.WordWrap }
            Row {
                spacing: 8
                Button { text: qsTr("Play tone"); onClicked: page.runAudioTest() }
                Button { text: qsTr("Stop"); onClicked: page.stopAudioTest() }
            }
        }
    }

    Connections {
        target: tlsChecker
        onFinished: {
            page.tlsState = ok ? "pass" : "fail";
            page.tlsMsg = message;
        }
    }

    Connections {
        target: audioEngine
        onStateChanged: {
            if (audioEngine.state === audioEngine.playingState) {
                page.audioState = "pass";
                page.audioMsg = qsTr("playing (MMF init OK)");
            }
        }
        onErrorStringChanged: {
            if (audioEngine.errorString.length > 0) {
                page.audioState = "fail";
                page.audioMsg = audioEngine.errorString;
            }
        }
    }
}
