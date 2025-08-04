import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import "./components"

Rectangle {
    id: chatView
    height: 754  // 630 + 124
    width: parent.width
    color: "transparent"
    property var messageManager: null
    signal exitScore()

    Column {
        id: chatColumn
        width: parent.width
        spacing: 12

        // 对话记录区域
        Rectangle {
            id: messagesArea
            width: parent.width
            height: 630 - 12
            color: "transparent"

            ScrollView {
                id: scrollView
                anchors.fill: parent
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                Column {
                    id: messagesColumn
                    width: scrollView.width
                    spacing: 20
                    // 使用Repeater显示消息
                    Repeater {
                        id: messagesRepeater
                        model: $chatManager.messages
                        // 消息气泡
                        delegate: Column {
                            id: messageItem
                            width: messageBubble.width
                            anchors.right: modelData.type === "user" ? parent.right : undefined
                            anchors.rightMargin: modelData.type === "user" ? 24 : 0
                            anchors.left: (modelData.type === "ai" || modelData.type === "thinking") ? parent.left : undefined
                            anchors.leftMargin: (modelData.type === "ai" || modelData.type === "thinking") ? 24 : 0
                            spacing: 8
                            
                            // 消息气泡
                            Rectangle {
                                id: messageBubble
                                width: modelData.type !== "thinking" ? messageContent.width : thinkingRow.width
                                height: modelData.type !== "thinking" ? messageContent.height : thinkingRow.height
                                color: modelData.type === "user" ? "#F5F5F5" : "transparent"
                                radius: 12
                                
                                // 普通消息内容
                                Text {
                                    id: messageContent
                                    anchors.centerIn: parent
                                    width: Math.min(implicitWidth, messagesColumn.width - 48)
                                    text: modelData.type === "thinking" ? "" : modelData.content
                                    padding: modelData.type === "user" ? 12 : 0
                                    font.family: "Alibaba PuHuiTi 3.0"
                                    font.pixelSize: 16
                                    color: "#D9000000"
                                    wrapMode: Text.Wrap
                                    textFormat: Text.PlainText
                                    visible: modelData.type !== "thinking"
                                }
                                
                                // 思考中动画
                                Row {
                                    id: thinkingRow
                                    anchors.centerIn: parent
                                    spacing: 2
                                    visible: modelData.type === "thinking"
                                    
                                    Text {
                                        text: qsTr("思考中")
                                         font.weight: Font.Bold
                                        font.family: "Alibaba PuHuiTi 3.0"
                                        font.pixelSize: 16
                                        color: "#D9000000"
                                    }
                                    
                                    Text {
                                        id: dots
                                        text: "."
                                         font.weight: Font.Bold
                                        font.family: "Alibaba PuHuiTi 3.0"
                                        font.pixelSize: 16
                                        color: "#D9000000"
                                        
                                        Timer {
                                            id: dotsTimer
                                            interval: 500
                                            running: modelData.type === "thinking"
                                            repeat: true
                                            property int dotCount: 1
                                            
                                            onTriggered: {
                                                dotCount = (dotCount % 3) + 1
                                                dots.text = ".".repeat(dotCount)
                                            }
                                        }
                                    }
                                }
                            }
                            
                            // AI消息的操作按钮（只在最后一条AI消息显示）
                            Row {
                                id: actionButtons
                                spacing: 4
                                visible: modelData.type === "ai" && index === ($chatManager.messages.length - 1) && !$chatManager.isSending && index !== 0
                                
                                Rectangle {
                                    id: regenerateBtn
                                    width: 88
                                    height: 29
                                    color: "#F5F5F5"
                                    radius: 8
                                    opacity: regenerateBtnArea.containsMouse ? 0.8 : 1
                                    
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        
                                        Image {
                                            source: "qrc:/image/repeat.png"
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        
                                        Text {
                                            text: qsTr("再次生成")
                                            font.family: "Alibaba PuHuiTi 3.0"
                                            font.pixelSize: 14
                                            color: "#73000000"
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                    
                                    MouseArea {
                                        id: regenerateBtnArea
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: $chatManager.regenerateLastResponse()
                                        hoverEnabled: true
                                        onPressed: parent.scale = 0.9
                                        onReleased: parent.scale = 1
                                    }
                                }
                                
                                Rectangle {
                                    id: copyBtn
                                    width: 64
                                    height: 29
                                    color: "#F5F5F5"
                                    radius: 8
                                    opacity: copyBtnArea.containsMouse ? 0.8 : 1
                                    
                                    Row {
                                        anchors.centerIn: parent
                                        spacing: 4
                                        
                                        Image {
                                            source: "qrc:/image/chatCopy.png"
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                        
                                        Text {
                                            text: qsTr("复制")
                                            font.family: "Alibaba PuHuiTi 3.0"
                                            font.pixelSize: 14
                                            color: "#73000000"
                                            anchors.verticalCenter: parent.verticalCenter
                                        }
                                    }
                                    
                                    MouseArea {
                                        id: copyBtnArea
                                        anchors.fill: parent
                                        cursorShape: Qt.PointingHandCursor
                                        onClicked: {
                                            $chatManager.copyToClipboard(modelData.content)
                                            messageManager.success("已复制！")
                                        }
                                        onPressed: parent.scale = 0.9
                                        onReleased: parent.scale = 1
                                        hoverEnabled: true
                                    }
                                }
                            }
                        }
                    }

                }
            }
        }

        // 输入框区域
        Rectangle {
            id: inputArea
            width: parent.width
            height: 124
            color: "transparent"
            Rectangle {
                width: 496
                height: 112
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                radius: 16
                color: closeArea.containsMouse ? "#FFF2F2" : "#ECF3FF"
                border.color: "#E6EAF2"
                border.width: 1
                Rectangle{
                    id:inputTitle
                    anchors.top: parent.top
                    anchors.topMargin: 4
                    anchors.left: parent.left
                    width: parent.width
                    height: 32
                    color: "transparent"
                    Image{
                        id:image
                        width: 20
                        height: 20
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        source: "qrc:/image/CHAT.png"
                    }
                    Text {
                        anchors.left: image.right
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        text: "AI CHAT"
                        font.family: "Alibaba PuHuiTi 3.0"
                        font.pixelSize: 14
                        color: "#A6000000"
                    }
                    Button {
                        id: close
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: 12
                        width: 20
                        height: 20
                        background: Rectangle {
                            color: "transparent"
                        }
                        Image{
                            source: parent.hovered ? "qrc:/image/closeRed.png" : "qrc:/image/closeGrey.png"
                            anchors.centerIn: parent
                        }
                        MouseArea{
                            id:closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                $chatManager.endAnalysis()
                                exitScore()
                            }
                        }
                    }
                }
                Rectangle{
                    anchors.top: inputTitle.bottom
                    anchors.topMargin: 4
                    height: 72 - 1
                    width: 496 -2
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "#FFFFFF"
                    radius: 16
                    Row{
                        height: parent.height
                        width: parent.width
                        padding: 12
                        spacing: 12
                        // 输入框
                        Rectangle {
                            width: parent.width - sendButton.width - 36
                            height: parent.height - 24
                            color: "transparent"
                            ScrollView {
                                anchors.fill: parent
                                contentWidth: width
                                clip: true
                                ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                                TextArea {
                                    id: messageInput
                                    width: parent.width
                                    placeholderText: qsTr("发送消息...")
                                    font.family: "Alibaba PuHuiTi 3.0"
                                    font.pixelSize: 16
                                    color: "#D9000000"
                                    wrapMode: TextArea.Wrap
                                    selectByMouse: true
                                    enabled: !$chatManager.isSending
                                    padding: 0
                                    Keys.onPressed: {
                                        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
                                            if (event.modifiers === Qt.ShiftModifier) {
                                                // Shift+回车：换行（不处理，让默认行为执行）
                                                return
                                            } else if (event.modifiers === Qt.NoModifier) {
                                                // 单独回车：发送消息
                                                sendMessage()
                                                event.accepted = true
                                            }
                                        }
                                    }
                                }
                            }
                        }

                        Image{
                            id: sendButton
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 12
                            source: $chatManager.isSending || messageInput.text.trim().length === 0 ? "qrc:/image/sendDisable.png" : "qrc:/image/send.png"
                            enabled: !$chatManager.isSending && messageInput.text.trim().length > 0
                            opacity: enabled && clickArea.containsMouse ? 0.8 : 1
                            MouseArea {
                                id: clickArea
                                anchors.fill: parent
                                hoverEnabled: true
                                onClicked: sendMessage()
                                cursorShape: Qt.PointingHandCursor
                                onPressed: {
                                    sendButton.scale = 0.9
                                }
                                onReleased: {
                                    sendButton.scale = 1
                                }
                                enabled: parent.enabled
                            }
                        }
                    }
                }
            }
        }
    }

    // 发送消息函数
    function sendMessage() {
        var message = messageInput.text.trim()
        if (message.length > 0 && !$chatManager.isSending) {
            $chatManager.sendMessage(message)
            messageInput.text = ""
        }
    }

    // 重置所有参数的函数
    function resetValue() {
        // 清空输入框
        messageInput.text = ""
        
        // 重置聊天管理器并添加欢迎消息
        $chatManager.resetWithWelcomeMessage()
        
        // 滚动到顶部
        if (scrollView.contentItem) {
            scrollView.contentItem.contentY = 0
        }
    }

    // 监听消息变化，自动滚动到底部
    Connections {
        target: $chatManager
        function onMessagesChanged() {
            scrollToBottom.start()
        }
    }

    // 滚动到底部的动画
    Timer {
        id: scrollToBottom
        interval: 100
        onTriggered: {
            if (messagesRepeater.count > 0) {
                var maxY = Math.max(0, messagesColumn.height - scrollView.height + 32)
                if (scrollView.contentItem) {
                    scrollView.contentItem.contentY = maxY
                }
            }
        }
    }
}
