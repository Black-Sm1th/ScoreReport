import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import "./components"

Rectangle {
    id: tnmView
    height: tnmColumn.height
    width: parent.width
    color: "transparent"
    property var messageManager: null
    signal exitScore()
    
    // 省略号动画状态
    property int dotCount: 1
    
    // 省略号动画定时器
    Timer {
        id: dotTimer
        interval: 500  // 每500ms切换一次
        running: $tnmManager.isAnalyzing
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
        id: tnmColumn
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
                text: $tnmManager.clipboardContent
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
                    source: "qrc:/image/TNM.png"
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
                    text: {
                        if($tnmManager.isAnalyzing){
                            return "TNM分析中" + getDots()
                        }
                        if($tnmManager.isCompleted){
                            return "已完成TNM分析！"
                        }else if(!$tnmManager.isCompleted && $tnmManager.inCompleteInfo){
                            return $tnmManager.inCompleteInfo
                        }else{
                            return ""
                        }
                    }
                }
            }
            Repeater {
                model: $tnmManager.tipList.length  // 来自 C++
                delegate: Rectangle {
                    width:parent.width - 48
                    height: 52 + 12 + 148
                    Rectangle{
                        color: "#ECF3FF"
                        radius: 8
                        width:parent.width
                        height: 52
                        Text{
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 18
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: "#D9000000"
                            text: $tnmManager.tipList[index]
                        }
                    }
                    MultiLineTextInput{
                        width: parent.width
                        height: 148
                        y:64
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
                visible: $tnmManager.isAnalyzing
                text: "终止"
                width: 88
                height: 36
                fontSize: 14
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                onClicked: {
                    $tnmManager.endAnalysis()
                    exitScore()
                }
            }

            CustomButton {
                id: stopBtn
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 24
                visible: !$tnmManager.isAnalyzing && !$tnmManager.isCompleted
                text: "终止"
                width: 88
                height: 36
                fontSize: 14
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                onClicked: {
                    $tnmManager.endAnalysis()
                    exitScore()
                }
            }

            CustomButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: stopBtn.right
                anchors.leftMargin: 12
                visible: !$tnmManager.isAnalyzing && !$tnmManager.isCompleted
                text: "重置"
                width: 88
                height: 36
                fontSize: 14
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                onClicked: {

                }
            }

            CustomButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 24
                visible: !$tnmManager.isAnalyzing && !$tnmManager.isCompleted
                text: "提交"
                width: 88
                height: 36
                fontSize: 14
                backgroundColor: "#006BFF"
                textColor: "#FFFFFF"
                onClicked: {

                }
            }
        }
    }
}
