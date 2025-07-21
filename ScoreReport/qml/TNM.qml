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
    
    Connections {
        target: $tnmManager
        function onAnalysisCompleted(success, message) {
            console.log("TNM analysis completed:", success, message)
            // 这里可以添加分析完成后的处理逻辑
        }
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
                    text: $tnmManager.isAnalyzing ? "TNM分析中" + getDots() : ""
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
                text: "终止"
                width: 88
                height: 36
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
