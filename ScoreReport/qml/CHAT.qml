import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import "./components"

Rectangle {
    id: chatView
    height: chatColumn.height
    width: parent.width
    color: "transparent"
    property var messageManager: null
    signal exitScore()
    Column{
        id:chatColumn
        width: parent.width
        ScrollView {
            id: scrollView
            anchors.fill: parent
            contentWidth: width
            contentHeight: 650
            clip: true
            ScrollBar.vertical.policy: ScrollBar.AsNeeded
        }
    }
}
