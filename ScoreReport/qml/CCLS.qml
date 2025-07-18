import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import "./components"
Rectangle{
    id: cclsView
    height: cclsColumn.height
    width: parent.width
    color: "transparent"
    signal exitScore()
    property int step: 1
    Column {
        id: cclsColumn
        spacing: 20
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        Rectangle {
            height: 674
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 48
            Rectangle{
                height: 32
                width: parent.width
                Image{
                    id: cclsImage
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    height: 32
                    source: "qrc:/image/CCLS.png"
                }
                Text {
                    id: cclsInfo
                    anchors.left: cclsImage.right
                    anchors.leftMargin: 8
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.weight: Font.Medium
                    font.pixelSize: 16
                    color: "#D9000000"
                    anchors.verticalCenter: parent.verticalCenter
                    text: qsTr("CCLS评分分析中，请填写以下信息")
                }
            }
            Column{
                id:step1
                height: 70
                width: parent.width
                leftPadding: 40
                spacing: 10
                Rectangle{
                    height: 24
                    width:parent.width-40
                    Text{
                        font.family: "Alibaba PuHuiTi 3.0"
                        font.weight: Font.Medium
                        font.pixelSize: 16
                        color: "#D9000000"
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("T2信号（相对肾皮质）")
                    }
                }
                Row {
                    height: 36
                    width:parent.width-40
                    spacing: 16
                }
            }
        }

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
            CustomButton{
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: resetBtn.left
                anchors.rightMargin:12
                text: "终止"
                width: 44
                height: 36
                fontSize: 14
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                onClicked: {
                    cclsView.step = 1
                    cclsView.exitScore()
                }
            }
            CustomButton{
                id: resetBtn
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin:24
                text: "重置"
                width: 72
                height: 36
                fontSize: 14
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                onClicked: {

                }
            }
        }
    }
}
