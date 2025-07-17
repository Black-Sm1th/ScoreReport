import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0

Rectangle{
    id: cclsView
    height: cclsColumn.height
    width: parent.width
    color: "transparent"
    Column {
        id: cclsColumn
        spacing: 20
        Rectangle {
            height: 674
            width: parent.width
            color: "red"
        }
        Rectangle {
            height: 1
            width: parent.width
            color: "#0F000000"
        }
        Rectangle {
            height: 59
            width: parent.width
            color: "blue"
        }
    }
}
