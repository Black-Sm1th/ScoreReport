import QtQuick 2.15
import QtQuick.Controls 2.15
import "./components"

Rectangle {
    id: reportView
    height: reportColumn.height
    width: parent.width
    color: "transparent"
    property var messageManager: null
    property var templateLists: []
    signal exitScore()
    function resetValues(){
        tabswitcher.currentIndex = 0
    }
    Connections{
        target: $reportManager
        function onTemplateListChanged(){
            templateLists.clear()
        }
    }
    Column{
        id: reportColumn
        width: parent.width
        leftPadding: 24
        rightPadding: 24
        spacing: 16
        TabSwitcher{
            id: tabswitcher
            tabTitles: ["报告", "设置模板"]
            currentIndex: 0
        }
        Column {
            width: parent.width - reportColumn.leftPadding - reportColumn.rightPadding
            visible: tabswitcher.currentIndex === 0
            spacing: 8
            Text {
                font.family: "Alibaba PuHuiTi 3.0"
                font.weight: Font.Normal
                font.pixelSize: 16
                color: "#D9000000"
                text: "输入报告"
            }
            MultiLineTextInput{
                width: parent.width
                height: 300
            }
            Row{
                height: 29
                Text {
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.weight: Font.Normal
                    font.pixelSize: 16
                    color: "#D9000000"
                    text: "选择模板："
                    anchors.verticalCenter: parent.verticalCenter
                }
                ScoreTypeDropdown{
                    anchors.verticalCenter: parent.verticalCenter
                    scoreTypes: templateLists
                }
            }
        }
        Rectangle{
            width: parent.width
            height: 630
            anchors.horizontalCenter: parent.horizontalCenter
            visible: tabswitcher.currentIndex === 1
            ScrollView {
                id: scrollView
                anchors.fill: parent
                clip: true
            }
        }
        // 底部按钮栏
        Rectangle {
            height: 60
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            color: "transparent"

            Rectangle {
                height: 1
                width: parent.width
                color: "#0F000000"
            }
            CustomButton {
                id:stopBtn
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 24
                text: qsTr("退出")
                width: 88
                height: 36
                radius: 4
                fontSize: 14
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                onClicked: {
                    exitScore()
                }
            }
        }
    }
}
