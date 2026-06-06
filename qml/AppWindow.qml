import QtQuick 1.1
import com.nokia.symbian 1.1

BelleAppPageStackWindow {
    id: window
    showStatusBar: true
    showToolBar: true

    function handleBack() {
        if (pageStack.depth <= 1) {
            Qt.quit();
        } else {
            pageStack.pop();
        }
    }

    function showAbout() { aboutDialog.visible = true; }
    function hideAbout() { aboutDialog.visible = false; }

    ToolBarLayout {
        id: toolBarLayout
        ToolButton {
            flat: true
            iconSource: "toolbar-back"
            onClicked: window.handleBack()
        }
        ToolButton {
            flat: true
            iconSource: "toolbar-menu"
            onClicked: appMenu.open()
        }
    }

    Menu {
        id: appMenu
        visualParent: window
        MenuLayout {
            MenuItem {
                text: qsTr("About")
                onClicked: { appMenu.close(); window.showAbout(); }
            }
        }
    }

    Item {
        id: aboutDialog
        visible: false
        anchors.fill: parent
        z: 1000

        Rectangle { anchors.fill: parent; color: "#99000000" }
        MouseArea { anchors.fill: parent; onClicked: window.hideAbout() }

        Rectangle {
            width: parent.width - 48
            height: 220
            radius: 10
            color: "#2b2b2b"
            border.color: "#4b4b4b"
            border.width: 1
            anchors.centerIn: parent

            MouseArea { anchors.fill: parent }

            Column {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.margins: 16
                spacing: 8

                Text {
                    width: parent.width
                    text: qsTr("BelleApp")
                    font.pixelSize: 20
                    color: platformStyle.colorNormalLight
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    width: parent.width
                    text: "v" + appVersion
                    font.pixelSize: 16
                    color: "#cdd6ea"
                    horizontalAlignment: Text.AlignHCenter
                }
                Text {
                    width: parent.width
                    text: qsTr("Qt / Symbian Belle starter template.")
                    font.pixelSize: 14
                    color: "#aeb9d4"
                    wrapMode: Text.WordWrap
                    horizontalAlignment: Text.AlignHCenter
                }
            }

            Button {
                width: parent.width - 32
                text: qsTr("Close")
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.bottom: parent.bottom
                anchors.bottomMargin: 12
                onClicked: window.hideAbout()
            }
        }
    }

    initialPage: SelfTestPage {
        tools: toolBarLayout
    }

    Keys.onReleased: {
        if (event.key === Qt.Key_Escape) {
            window.handleBack();
            event.accepted = true;
        }
    }
}
