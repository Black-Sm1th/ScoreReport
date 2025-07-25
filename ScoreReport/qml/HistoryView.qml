import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import "./components"
// 内容区域
Rectangle {
    width: parent.width
    height: contentRec.height
    property var messageManager: null
    signal toScorer()
    color: "transparent"
    Column{
        id:contentRec
        width: parent.width
        leftPadding: 24
        rightPadding: 24
        spacing: 8
        Rectangle{
            id:titleRec
            height: 29
            width: parent.width - 48
            Text {
                text: "历史记录"
                color: "#D9000000"
                font.family: "Alibaba PuHuiTi 3.0"
                font.weight: Font.Bold
                font.pixelSize: 16
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        Column{
            width: parent.width - 48
            spacing: 16
            topPadding: 40
            bottomPadding: 40
            // visible: //为空的时候
            Rectangle{
                height: 111
                width: 111
                color: "#D9D9D9"
                anchors.horizontalCenter: parent.horizontalCenter
            }
            Text {
                text: "您还没有历史记录，请先进行评分~"
                color: "#73000000"
                font.family: "Alibaba PuHuiTi 3.0"
                font.pixelSize: 16
                anchors.horizontalCenter: parent.horizontalCenter
            }
            CustomButton{
                text: "前往评分"
                width: 88
                height: 36
                backgroundColor: "#006BFF"
                textColor: "#ffffff"
                fontSize: 14
                buttonRadius: 4
                borderWidth: 0
                anchors.horizontalCenter: parent.horizontalCenter
                onClicked: {
                    toScorer()
                }
            }
            Rectangle{
                height: 8
                width: parent.width
                color: "transparent"
            }
        }
        Column{
            width: parent.width - 48
            spacing: 8
            // visible: //不为空的时候
        }
    }
}
