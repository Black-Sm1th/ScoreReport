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
        spacing: 0

        // 对话记录区域
        Rectangle {
            id: messagesArea
            width: parent.width
            height: 630
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
                        delegate: Rectangle {
                                id: messageBubble
                                width: messageContent.width
                                height: messageContent.height
                                anchors.right: modelData.type === "user" ? parent.right : undefined
                                anchors.rightMargin: modelData.type === "user" ? 24 : 0
                                anchors.left: modelData.type === "ai" ? parent.left : undefined
                                anchors.leftMargin: modelData.type === "ai" ? 24 : 0
                                color: modelData.type === "user" ? "#F5F5F5" : "transparent"
                                radius: 12
                                // 消息内容
                                Text {
                                    id: messageContent
                                    anchors.centerIn: parent
                                    width: Math.min(implicitWidth, messagesColumn.width - 48)
                                    text: modelData.content
                                    padding: modelData.type === "user" ? 12 : 0
                                    font.family: "Alibaba PuHuiTi 3.0"
                                    font.pixelSize: 16
                                    color: "#D9000000"
                                    wrapMode: Text.WrapAnywhere
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
                                    placeholderText: "发送消息..."
                                    font.family: "Alibaba PuHuiTi 3.0"
                                    font.pixelSize: 16
                                    color: "#D9000000"
                                    wrapMode: TextArea.Wrap
                                    selectByMouse: true
                                    enabled: !$chatManager.isSending
                                    padding: 0
                                    Keys.onPressed: {
                                        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter) && event.modifiers === Qt.ControlModifier) {
                                            sendMessage()
                                            event.accepted = true
                                        }
                                    }
                                }
                            }
                        }
                        // 发送按钮
                        Rectangle {
                            id: sendButton
                            width: 40
                            height: 40
                            anchors.verticalCenter: parent.verticalCenter
                            color: $chatManager.isSending || messageInput.text.trim().length === 0 ? "#D1D5DB" : "#007AFF"
                            radius: 8
                            enabled: !$chatManager.isSending && messageInput.text.trim().length > 0

                            Text {
                                anchors.centerIn: parent
                                text: "发送"
                                font.family: "Alibaba PuHuiTi 3.0"
                                font.pixelSize: 14
                                color: "#FFFFFF"
                            }

                            MouseArea {
                                anchors.fill: parent
                                onClicked: sendMessage()
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
