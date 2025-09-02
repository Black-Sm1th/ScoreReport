import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import "./components"

Rectangle {
    id: chatView
    height: messagesArea.visible ? 754 : (chatManager.files.length > 0 ? 236 : 124)  // 630 + 124 + 可选文件列表100
    width: parent.width
    color: "transparent"
    property var messageManager: null
    property bool specialPage: false
    property var chatManager: $chatManager  // 默认使用全局的ChatManager，可以被覆盖
    signal exitScore()

    // 文件选择对话框
    FileDialog {
        id: fileDialog
        selectMultiple: true
        title: qsTr("选择文件")
        nameFilters: ["支持的文件格式 (*.pdf *.txt *.doc *.docx *.jpg *.jpeg *.png *.bmp *.gif)",
                     "PDF文件 (*.pdf)",
                     "文本文件 (*.txt)",
                     "Word文档 (*.doc *.docx)",
                     "图片文件 (*.jpg *.jpeg *.png *.bmp *.gif)"]
        onAccepted: {
            var filePaths = []
            var urls = fileDialog.fileUrls  // 使用 fileUrls 获取多个文件
            
            // 处理所有选中的文件
            for (var i = 0; i < urls.length; i++) {
                var filePath = urls[i].toString()
                // 移除file://前缀
                if (filePath.startsWith("file:///")) {
                    filePath = filePath.substring(8)
                } else if (filePath.startsWith("file://")) {
                    filePath = filePath.substring(7)
                }
                filePaths.push(filePath)
            }
            
            // 使用批量添加方法
            if (filePaths.length === 1) {
                // 单个文件直接添加，显示详细消息
                chatManager.addFile(filePaths[0])
            } else if (filePaths.length > 1) {
                // 多个文件批量添加，显示汇总消息
                chatManager.addFiles(filePaths)
            }
        }
    }

    Column {
        id: chatColumn
        width: parent.width
        spacing: 12

        // 对话记录区域
        Rectangle {
            id: messagesArea
            width: parent.width
            height: chatManager.files.length > 0 ? 530 - 24 : 630 - 12
            color: "transparent"
            visible: !specialPage || chatManager.messages.length > 0
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
                        model: chatManager.messages
                        // 消息气泡
                        delegate: Column {
                            id: messageItem
                            width: messageBubble.width
                            anchors.right: modelData.type === "user" ? parent.right : undefined
                            anchors.rightMargin: modelData.type === "user" ? 24 : 0
                            anchors.left: (modelData.type === "ai" || modelData.type === "thinking" || modelData.type === "interrupt") ? parent.left : undefined
                            anchors.leftMargin: (modelData.type === "ai" || modelData.type === "thinking" || modelData.type === "interrupt") ? 24 : 0
                            spacing: 8
                            
                            // 消息气泡
                            Rectangle {
                                id: messageBubble
                                width: (modelData.type !== "thinking" && modelData.type !== "interrupt") ? messageContent.width : thinkingRow.width
                                height: (modelData.type !== "thinking" && modelData.type !== "interrupt") ? messageContent.height : thinkingRow.height
                                color: modelData.type === "user" ? "#F5F5F5" : "transparent"
                                radius: 12
                                
                                // 普通消息内容
                                Text {
                                    id: messageContent
                                    anchors.centerIn: parent
                                    width: Math.min(implicitWidth, messagesColumn.width - 48)
                                    text: (modelData.type === "thinking" || modelData.type === "interrupt") ? "" : modelData.content
                                    padding: modelData.type === "user" ? 12 : 0
                                    font.family: "Alibaba PuHuiTi 3.0"
                                    font.pixelSize: 16
                                    color: "#D9000000"
                                    wrapMode: Text.Wrap
                                    textFormat: Text.MarkdownText
                                    visible: (modelData.type !== "thinking" && modelData.type !== "interrupt")
                                }
                                
                                // 思考中动画
                                Row {
                                    id: thinkingRow
                                    anchors.centerIn: parent
                                    spacing: 2
                                    visible: modelData.type === "thinking" || modelData.type === "interrupt"
                                    
                                    Text {
                                        text: qsTr(modelData.content)
                                         font.weight: Font.Bold
                                        font.family: "Alibaba PuHuiTi 3.0"
                                        font.pixelSize: 16
                                        color: "#D9000000"
                                    }
                                    
                                    Text {
                                        id: dots
                                        text: "."
                                        font.weight: Font.Bold
                                        visible: modelData.type === "thinking"
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
                                visible: modelData.type === "ai" && index === (chatManager.messages.length - 1) && !chatManager.isSending && index !== 0
                                
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
                                        onClicked: chatManager.regenerateLastResponse()
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
                                            chatManager.copyToClipboard(modelData.content)
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

        // 文件列表显示区域
        Rectangle {
            id: fileListArea
            width: parent.width
            height: chatManager.files.length > 0 ? 100 : 0
            color: "transparent"
            visible: chatManager.files.length > 0
            
            Rectangle {
                width: 496
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#F8F9FA"
                radius: 12
                border.color: "#E6EAF2"
                border.width: 1
                
                Flow {
                    anchors.fill: parent
                    anchors.margins: 12
                    spacing: 8
                    
                    Repeater {
                        model: chatManager.files
                        delegate: Rectangle {
                            width: (parent.width - 16) / 3 // 最多3列
                            height: 76
                            color: "#FFFFFF"
                            radius: 8
                            border.color: "#E6EAF2"
                            border.width: 1
                            
                            Column {
                                anchors.left: parent.left
                                anchors.leftMargin: 12
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: closeBtn.left
                                anchors.rightMargin: 8
                                spacing: 16
                                
                                Text {
                                    id: fileName
                                    width: parent.width
                                    text: modelData.name || ""
                                    font.family: "Alibaba PuHuiTi 3.0"
                                    font.pixelSize: 16
                                    font.weight: Font.Bold
                                    color: "#D9000000"
                                    elide: Text.ElideMiddle
                                }
                                
                                Text {
                                    id: fileInfo
                                    width: parent.width
                                    text: (modelData.extension || "") + "   " + (modelData.formattedSize || "")
                                    font.family: "Alibaba PuHuiTi 3.0"
                                    font.pixelSize: 12
                                    color: "#73000000"
                                }
                            }
                            
                            Image {
                                id: closeBtn
                                width: 16
                                height: 16
                                anchors.right: parent.right
                                anchors.rightMargin: 8
                                anchors.top: parent.top
                                anchors.topMargin: 8
                                source: "qrc:/image/close.png"
                                opacity: closeBtnArea.containsMouse ? 0.8 : 0.6
                                
                                MouseArea {
                                    id: closeBtnArea
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    hoverEnabled: true
                                    onClicked: {
                                        chatManager.removeFile(index)
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
                id: inputRec
                width: 496
                height: 112
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.top
                radius: 16
                color: dropArea.containsDrag ? "#E3F2FD" : "#ECF3FF"
                border.color: dropArea.containsDrag ? "#006BFF" : "#E6EAF2"
                border.width: 1
                
                // 拖拽区域
                DropArea {
                    id: dropArea
                    anchors.fill: parent
                    enabled: !chatManager.isSending && $loginManager.isLoggedIn
                    onDropped: {
                        if (drop.hasUrls) {
                            var filePaths = []
                            var urls = drop.urls
                            
                            // 处理所有文件路径
                            for (var i = 0; i < urls.length; i++) {
                                var filePath = urls[i].toString()
                                // 移除file://前缀
                                if (filePath.startsWith("file:///")) {
                                    filePath = filePath.substring(8)
                                } else if (filePath.startsWith("file://")) {
                                    filePath = filePath.substring(7)
                                }
                                filePaths.push(filePath)
                            }
                            
                            // 使用C++的批量添加方法
                            if (filePaths.length === 1) {
                                // 单个文件直接添加，显示详细消息
                                chatManager.addFile(filePaths[0])
                            } else {
                                // 多个文件批量添加，显示汇总消息
                                chatManager.addFiles(filePaths)
                            }
                        }
                        drop.accept()
                    }
                }
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
                            id:closeImage
                            source: "qrc:/image/closeGrey.png"
                            anchors.centerIn: parent
                        }
                        MouseArea{
                            id:closeArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                chatManager.endAnalysis()
                                exitScore()
                                inputRec.color = "#ECF3FF"
                                closeImage.source = "qrc:/image/closeGrey.png"
                            }
                            onEntered: {
                                inputRec.color = "#FFF2F2"
                                closeImage.source = "qrc:/image/closeRed.png"
                            }
                            onExited: {
                                inputRec.color = "#ECF3FF"
                                closeImage.source = "qrc:/image/closeGrey.png"
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
                        spacing: 8
                        // 输入框
                        Rectangle {
                            width: parent.width - sendButton.width - uploadButton.width - 40
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
                                    placeholderText: $loginManager.isLoggedIn ? qsTr("发送消息...") : qsTr("请先登录后使用本功能！")
                                    font.family: "Alibaba PuHuiTi 3.0"
                                    font.pixelSize: 16
                                    color: "#D9000000"
                                    wrapMode: TextArea.Wrap
                                    selectByMouse: true
                                    enabled: !chatManager.isSending && $loginManager.isLoggedIn
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
                                        } else if (event.key === Qt.Key_V && (event.modifiers & Qt.ControlModifier)) {
                                            // Ctrl+V：处理粘贴，检查是否是文件路径
                                            handlePaste()
                                            event.accepted = true
                                        }
                                    }
                                }
                            }
                        }

                        // 上传按钮
                        Image {
                            id: uploadButton
                            anchors.verticalCenter:sendButton.verticalCenter
                            width: 32
                            height: 32
                            source: "qrc:/image/upload.png"
                            opacity: !enabled ? 0.2 : (uploadButtonArea.containsMouse ? 0.8 : 0.6)
                            enabled: !chatManager.isSending && $loginManager.isLoggedIn
                            MouseArea {
                                enabled: parent.enabled
                                id: uploadButtonArea
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: fileDialog.open()
                                onPressed: parent.scale = 0.9
                                onReleased: parent.scale = 1
                            }
                        }

                        Image{
                            id: sendButton
                            anchors.bottom: parent.bottom
                            anchors.bottomMargin: 12
                            source: chatManager.isSending || messageInput.text.trim().length === 0 ? "qrc:/image/sendDisable.png" : "qrc:/image/send.png"
                            enabled: !chatManager.isSending && messageInput.text.trim().length > 0 && $loginManager.isLoggedIn
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
        if (message.length > 0 && !chatManager.isSending) {
            chatManager.sendMessage(message)
            messageInput.text = ""
        }
    }

    // 重置所有参数的函数
    function resetValue() {
        // 清空输入框
        messageInput.text = ""
        // 重置聊天管理器并添加欢迎消息
        chatManager.resetWithWelcomeMessage()

        // 滚动到顶部
        if (scrollView.contentItem) {
            scrollView.contentItem.contentY = 0
        }
    }
    
    // 处理粘贴功能
    function handlePaste() {
        // 从剪贴板获取内容
        var clipboardText = chatManager.getClipboardText()
        
        if (clipboardText && clipboardText.length > 0) {
            // 检查是否是文件路径
            if (isFilePath(clipboardText)) {
                // 尝试添加文件，如果是文件路径就不再粘贴为文本
                chatManager.addFile(clipboardText)
                // 无论成功失败，都不粘贴为文本，错误信息已在C++中显示
            } else {
                // 不是文件路径，作为普通文本粘贴
                messageInput.paste()
            }
        }
    }
    
    // 判断是否是文件路径（简单检查，详细验证在C++中进行）
    function isFilePath(text) {
        text = text.trim()
        // 检查是否包含文件扩展名
        var hasExtension = /\.\w+$/.test(text)
        // 检查是否是Windows或Linux路径格式
        var isPath = /^[A-Za-z]:\\|^\/|^\.\/|^\.\.\//.test(text) || text.includes('\\') || text.includes('/')
        return hasExtension && isPath
    }

    // 监听消息变化，自动滚动到底部
    Connections {
        target: chatManager
        function onMessagesChanged() {
            scrollToBottom.start()
        }
        
        function onFileOperationResult(message, type) {
            if (messageManager) {
                switch(type) {
                    case "success":
                        messageManager.success(message)
                        break
                    case "warning":
                        messageManager.warning(message, 2000)
                        break
                    case "error":
                        messageManager.error(message, 2000)
                        break
                    case "info":
                        messageManager.info(message)
                        break
                    default:
                        messageManager.info(message)
                        break
                }
            }
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
