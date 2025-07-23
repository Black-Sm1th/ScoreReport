import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import "./components"

Rectangle {
    id: renalView
    height: renalColumn.height
    width: parent.width
    color: "transparent"
    property var messageManager: null
    signal exitScore()

    // 省略号动画状态
    property int dotCount: 1

    Connections{
        target: $renalManager
        function onCheckFailed(){
            messageManager.warning("剪贴板为空，请先复制内容")
        }
    }

    // 省略号动画定时器
    Timer {
        id: dotTimer
        interval: 500  // 每500ms切换一次
        running: $renalManager.isAnalyzing
        repeat: true
        onTriggered: {
            dotCount = (dotCount % 3) + 1
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
        id: renalColumn
        spacing: 20
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        Column {
            width: parent.width
            leftPadding: 24
            rightPadding: 24
            spacing: 12
            TextArea {
                id: contentText
                leftPadding: 12
                rightPadding: 12
                topPadding: 12
                bottomPadding: 12
                text: $renalManager.clipboardContent
                font.family: "Alibaba PuHuiTi 3.0"
                font.pixelSize: 16
                color: "#D9000000"
                readOnly: true
                width: parent.width - 48
                wrapMode: TextArea.Wrap
                background: Rectangle {
                    color: "#F5F5F5"
                    radius: 12
                }
            }

            // 标题栏
            Rectangle {
                height: 32
                width: parent.width
                color: "transparent"

                Image {
                    id: cclsImage
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    height: 32
                    source: "qrc:/image/RENAL.png"
                }

                Text {
                    id: cclsInfo
                    anchors.left: cclsImage.right
                    anchors.leftMargin: 8
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.weight: Font.Bold
                    font.pixelSize: 16
                    color: "#D9000000"
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        if($renalManager.isAnalyzing){
                            return "RENAL分析中" + getDots()
                        }
                        if($renalManager.isCompleted){
                            return "已完成RENAL分析！"
                        }else if(!$renalManager.isCompleted && $renalManager.inCompleteInfo){
                            return $renalManager.inCompleteInfo
                        }else{
                            return ""
                        }
                    }
                }
            }

            Rectangle {
                width:parent.width - 48
                height: 300
                visible:!$renalManager.isAnalyzing && !$renalManager.isCompleted
                color: "red"
            }

            Rectangle {
                width: parent.width - 48
                height: resultColumn.height
                visible:!$renalManager.isAnalyzing && $renalManager.isCompleted
                color: "#ECF3FF"
                radius: 8
                Column {
                    id: resultColumn
                    anchors.centerIn: parent
                    spacing: 4
                    width: parent.width
                    leftPadding: 18
                    rightPadding: 18
                    topPadding: 14
                    bottomPadding: 14
                    // 综合评分
                    Row {
                        height: 24
                        width: parent.width -36
                        Text {
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.weight: Font.Bold
                            font.pixelSize: 16
                            color: "#D9000000"
                            text: "RENAL评分："
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.weight: Font.Bold
                            font.pixelSize: 16
                            color: "#D9000000"
                            text: "" + "分"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Column {
                        id: resultText
                        width: parent.width -36

                    }
                    Rectangle{
                        height: 4
                        width: parent.width -36
                        color:"transparent"
                    }
                    Text{
                        id: sourceText
                        font.family: "Alibaba PuHuiTi 3.0"
                        font.pixelSize: 12
                        color: "#73000000"
                        text: $renalManager.sourceText
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
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 24
                visible: $renalManager.isAnalyzing || (!$renalManager.isAnalyzing && !$renalManager.isCompleted)
                text: "终止"
                width: 88
                height: 36
                fontSize: 14
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                onClicked: {
                    $renalManager.endAnalysis()
                    resetAllInputs()
                    exitScore()
                }
            }

            CustomButton {
                id: resetBtn
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 24
                visible: !$renalManager.isAnalyzing && $renalManager.isCompleted
                text: "粘贴并评分"
                width: 88
                height: 36
                fontSize: 14
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                onClicked: {
                    $renalManager.pasteAnalysis()
                    resetAllInputs()
                }
            }

            CustomButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: resetBtn.right
                anchors.leftMargin: 12
                visible: !$renalManager.isAnalyzing && $renalManager.isCompleted
                text: "重选方案"
                width: 88
                height: 36
                fontSize: 14
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                onClicked: {
                    $renalManager.endAnalysis()
                    resetAllInputs()
                    exitScore()
                }
            }

            CustomButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 24
                visible: !$renalManager.isAnalyzing && $renalManager.isCompleted
                text: "复制"
                width: 88
                height: 36
                fontSize: 14
                backgroundColor: "#006BFF"
                textColor: "#FFFFFF"
                onClicked: {
                    $renalManager.copyToClipboard(text)
                    messageManager.success("复制成功")
                }
            }
        }
    }
}
