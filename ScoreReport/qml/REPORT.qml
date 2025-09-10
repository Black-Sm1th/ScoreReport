import QtQuick 2.15
import QtQuick.Controls 2.15
import "./components"

Rectangle {
    id: reportView
    height: reportColumn.height
    width: parent.width
    color: "transparent"
    property var messageManager: null
    signal exitScore()
    function resetValues(){
        tabswitcher.currentIndex = 0
    }
    Column{
        id: reportColumn
        width: parent.width
        leftPadding: 24
        rightPadding: 24
        TabSwitcher{
            id: tabswitcher
            tabTitles: ["报告", "模板"]
        }
    }
}
