import QtQuick 2.15
import QtQuick.Window 2.2
import QtQuick.Controls 2.15
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import "./components"

Rectangle {
    id: resultView
    height: resultColumn.height
    width: parent.width
    color: "transparent"
    property var messageManager: null
    signal exitScore()
    function resetValues(){

    }

    // 省略号动画状态
    property int dotCount: 1

    // 省略号动画定时器
    Timer {
        id: dotTimer
        interval: 500  // 每500ms切换一次
        running: $diagnosisResultManager.isSending
        repeat: true
        onTriggered: {
            dotCount = (dotCount % 3) + 1
        }
    }
    // 滚动到底部的动画
    Timer {
        id: scrollToBottom
        interval: 100
        onTriggered: {

            var maxY = Math.max(0, resultColumnChild.height - scrollView.height)
            console.log(resultColumnChild.height, scrollView.height)
            if (scrollView.contentItem) {
                scrollView.contentItem.contentY = maxY
            }
    }
    }
    Connections{
        target: $diagnosisResultManager
        function onRollToBottom(){
            scrollToBottom.start()
        }
    }
    // 生成省略号文本的函数
    function getDots() {
        var dots = ""
        for (var i = 0; i < dotCount; i++) {
            dots += "."
        }
        return dots
    }

    Column {
        id: resultColumn
        spacing: 20
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        Rectangle {
            width: parent.width
            height: Math.min(scrollView.contentHeight, 674)
            color: "transparent"
            ScrollView {
                id: scrollView
                anchors.fill: parent
                clip: true
                contentWidth: width
                contentHeight: resultColumnChild.height
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                Column {
                    id:resultColumnChild
                    width: parent.width
                    leftPadding: 24
                    rightPadding: 24
                    spacing: 12
                    Text {
                        font.family: "Alibaba PuHuiTi 3.0"
                        font.pixelSize: 16
                        font.weight: Font.Medium
                        color: "#D9000000"
                        text: qsTr("检查所见：")
                    }
                    Text {
                        width: resultColumnChild.width - 48
                        text: $diagnosisResultManager.originalMessages
                        font.family: "Alibaba PuHuiTi 3.0"
                        font.pixelSize: 14
                        color: "#D9000000"
                        wrapMode: Text.Wrap
                    }
                    Text{
                        font.family: "Alibaba PuHuiTi 3.0"
                        font.pixelSize: 16
                        visible: !$diagnosisResultManager.isSending && $diagnosisResultManager.responseMessages
                        font.weight: Font.Medium
                        color: "#D9000000"
                        text: qsTr("检查结论：")
                    }
                    Text {
                        width: resultColumnChild.width - 48
                        text: $diagnosisResultManager.responseMessages
                        visible: !$diagnosisResultManager.isSending && $diagnosisResultManager.responseMessages
                        font.family: "Alibaba PuHuiTi 3.0"
                        font.pixelSize: 14
                        color: "#D9000000"
                        wrapMode: Text.Wrap
                    }
                    Text {
                        visible: $diagnosisResultManager.isSending
                        font.family: "Alibaba PuHuiTi 3.0"
                        font.weight: Font.Bold
                        font.pixelSize: 16
                        color: "#D9000000"
                        text: "结论生成中" + getDots()
                    }
                }
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
                id: copyResult
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 24
                text: qsTr("复制结论")
                width: 88
                height: 36
                fontSize: 14
                radius: 4
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                visible: !$diagnosisResultManager.isSending && $diagnosisResultManager.resultText !== ""
                onClicked: {
                    $diagnosisResultManager.copyToClipboard(0)
                    messageManager.success("复制成功")
                }
            }
            CustomButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: copyResult.right
                anchors.leftMargin: 12
                text: qsTr("复制全部")
                width: 88
                height: 36
                fontSize: 14
                radius: 4
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                visible: !$diagnosisResultManager.isSending && $diagnosisResultManager.allText !== ""
                onClicked: {
                    $diagnosisResultManager.copyToClipboard(1)
                    messageManager.success("复制成功")
                }
            }
            CustomButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 24
                text: qsTr($diagnosisResultManager.isSending ? "终止" : "退出")
                width: 88
                height: 36
                fontSize: 14
                radius: 4
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                onClicked: {
                    $diagnosisResultManager.endAnalysis()
                    exitScore()
                }
            }
        }
    }
}
