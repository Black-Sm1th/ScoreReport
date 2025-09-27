import QtQuick 2.15
import QtQuick.Controls 2.15
import "./components"

Rectangle {
    id: knowledgeView
    height: knowledgeColumn.height
    width: parent.width
    color: "transparent"
    // 属性
    property var messageManager: null
    // 信号
    signal exitScore()
    function resetValues(){

    }
    Column{
        id: knowledgeColumn
        width: parent.width
        spacing: 16
        ScrollView {
            id: scrollView
            height: 674
            width: parent.width
            clip: true
            Column
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
                anchors.left: parent.left
                anchors.leftMargin: 24
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
                    resetValues()
                    exitScore()
                }
            }
        }
    }
}
