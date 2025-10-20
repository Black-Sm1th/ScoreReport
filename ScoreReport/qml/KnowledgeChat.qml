import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import "./components"

Rectangle {
    id: chatView
    width: parent.width
    height: calculateHeight()
    color: "transparent"

    // 属性
    property var messageManager: null
    property bool specialPage: false
    property var chatManager: $chatManager  // 默认使用全局的ChatManager，可以被覆盖

    // 信号
    signal exitScore()

    // 高度计算函数
    function calculateHeight() {
        if (messagesArea.visible) {
            return 754
        }
        return chatManager.files.length > 0 ? 248 + 41 : 124 + 41
    }

    // 文件选择对话框
    FileDialog {
        id: fileDialog
        selectMultiple: true
        title: qsTr("选择文件")
        nameFilters: ["支持的文件格式 (*.txt *.doc *.docx *.jpg *.jpeg *.png *.bmp *.gif)",
                     "文本文件 (*.txt)",
                     "Word文档 (*.doc *.docx)",
                     "图片文件 (*.jpg *.jpeg *.png *.bmp *.gif)"]
        onAccepted: {
            var filePaths = extractFilePathsFromUrls(fileDialog.fileUrls)
            handleFileAddition(filePaths)
        }
    }
    function sendText(text) {
        messageInput.text = text
        sendMessage();
    }

    Column {
        id: chatColumn
        width: parent.width
        spacing: 12

        Row{
            height: 29
            anchors.left: parent.left
            anchors.leftMargin: 24
            Text {
                font.family: "Alibaba PuHuiTi 3.0"
                font.weight: Font.Normal
                font.pixelSize: 16
                color: "#D9000000"
                text: "选择知识库："
                anchors.verticalCenter: parent.verticalCenter
            }
            KnowledgeSelector{
                id: chooseKnowledge
                anchors.verticalCenter: parent.verticalCenter
                knowledgeList: chatManager.knowledgeBaseList
                dropdownWidth: 200
                maxDropdownHeight: chatView.height > 220 ? 250 : chatView.height - 25
                onSelectionChanged: {
                    // 更新选中的知识库ID列表
                    var selectedIds = []
                    for (var i = 0; i < selectedItems.length; i++) {
                        selectedIds.push(selectedItems[i].id)
                    }
                    chatManager.selectedKnowledgeBases = selectedIds
                }
            }
        }

        // 对话记录区域
        Rectangle {
            id: messagesArea
            width: parent.width
            height: chatManager.files.length > 0 ? 518 - 36 - 29 : 630 - 24 - 29  // 调整以适应新的文件列表高度
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
                                    text: {
                                        if (modelData.type === "thinking" || modelData.type === "interrupt") {
                                            return ""
                                        }
                                        // 将字面量的\n转换为实际的换行符
                                        var content = modelData.content || ""
                                        return content.replace(/\\n/g, "\n")
                                    }
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

                            // 参考文件列表（只在AI消息且有元数据时显示）
                            Column {
                                id: referenceFiles
                                width: Math.min(messageContent.width, messagesColumn.width - 48)
                                spacing: 6
                                visible: modelData.type === "ai" && index === (chatManager.messages.length - 1) && chatManager.retrievedMetadata.length > 0
                                
                                // 标题
                                Text {
                                    text: "参考文件："
                                    font.family: "Alibaba PuHuiTi 3.0"
                                    font.pixelSize: 12
                                    color: "#73000000"
                                    font.weight: Font.Medium
                                }
                                
                                // 文件列表
                                Repeater {
                                    model: chatManager.retrievedMetadata
                                    delegate: Rectangle {
                                        width: parent.width
                                        height: fileText.height + filePage.height + 12
                                        color: fileArea.containsMouse ? "#F0F7FF" : "#F8F9FA"
                                        radius: 6
                                        border.color: "#E6EAF2"
                                        border.width: 1
                                        
                                        Row {
                                            anchors.left: parent.left
                                            anchors.leftMargin: 8
                                            anchors.verticalCenter: parent.verticalCenter
                                            spacing: 6
                                            
                                            // 文档图标
                                            Rectangle {
                                                width: 16
                                                height: 16
                                                anchors.verticalCenter: parent.verticalCenter
                                                color: "#006BFF"
                                                radius: 2
                                                
                                                Rectangle {
                                                    width: 8
                                                    height: 10
                                                    anchors.centerIn: parent
                                                    color: "white"
                                                    radius: 1
                                                    
                                                    Rectangle {
                                                        width: parent.width - 2
                                                        height: 1
                                                        anchors.centerIn: parent
                                                        y: parent.height * 0.3
                                                        color: "#006BFF"
                                                    }
                                                    
                                                    Rectangle {
                                                        width: parent.width - 2
                                                        height: 1
                                                        anchors.centerIn: parent
                                                        y: parent.height * 0.5
                                                        color: "#006BFF"
                                                    }
                                                    
                                                    Rectangle {
                                                        width: parent.width - 2
                                                        height: 1
                                                        anchors.centerIn: parent
                                                        y: parent.height * 0.7
                                                        color: "#006BFF"
                                                    }
                                                }
                                            }
                                            
                                            Column {
                                                anchors.verticalCenter: parent.verticalCenter
                                                spacing: 2
                                                
                                                Text {
                                                    id: fileText
                                                    text: modelData.file_name || ""
                                                    font.family: "Alibaba PuHuiTi 3.0"
                                                    font.pixelSize: 12
                                                    color: fileArea.containsMouse ? "#006BFF" : "#333333"
                                                    elide: Text.ElideRight
                                                    width: Math.min(implicitWidth, referenceFiles.width - 40)
                                                }
                                                
                                                Text {
                                                    leftPadding: 8
                                                    id: filePage
                                                    text: {
                                                        var pages = modelData.page_numbers || []
                                                        if (pages.length > 0) {
                                                            return "第" + pages.join(", ") + "页"
                                                        }
                                                        return ""
                                                    }
                                                    font.family: "Alibaba PuHuiTi 3.0"
                                                    font.pixelSize: 10
                                                    color: "#999999"
                                                    visible: text !== ""
                                                }
                                            }
                                        }
                                        
                                        MouseArea {
                                            id: fileArea
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: Qt.PointingHandCursor
                                            onClicked: {
                                                var url = modelData.url || ""
                                                if (url !== "") {
                                                    Qt.openUrlExternally(url)
                                                } else {
                                                    messageManager.warning("暂无可访问的网页链接")
                                                }
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
                                            // 将字面量的\n转换为实际的换行符后再复制
                                            var content = modelData.content || ""
                                            var formattedContent = content.replace(/\\n/g, "\n")
                                            chatManager.copyToClipboard(formattedContent)
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
            height: chatManager.files.length > 0 ? 112 : 0  // 增加高度以适应新的文件项高度
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
                            height: 88  // 增加高度以适应进度条
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
                                spacing: 8

                                Text {
                                    id: fileName
                                    width: parent.width
                                    text: modelData.name || ""
                                    font.family: "Alibaba PuHuiTi 3.0"
                                    font.pixelSize: 14
                                    font.weight: Font.Bold
                                    color: "#D9000000"
                                    elide: Text.ElideMiddle
                                }

                                Text {
                                    property var progressInfo: chatManager.fileReadProgress[modelData.path] || {}
                                    property bool isReading: progressInfo.isReading || false
                                    property bool success: progressInfo.success !== undefined ? progressInfo.success : true
                                    id: fileInfo
                                    text: (modelData.extension || "") + "   " + (modelData.formattedSize || "")
                                    font.family: "Alibaba PuHuiTi 3.0"
                                    font.pixelSize: 12
                                    color: "#73000000"
                                    visible: !isReading && success
                                }

                                // 读取状态指示器
                                Text {
                                    id: readStatus
                                    property var progressInfo: chatManager.fileReadProgress[modelData.path] || {}
                                    property bool isReading: progressInfo.isReading || false
                                    property int percentage: progressInfo.percentage || 0
                                    property bool success: progressInfo.success !== undefined ? progressInfo.success : true

                                    text: {
                                        if (isReading) {
                                            return "读取中 " + percentage + "%"
                                        } else if (!success) {
                                            return "读取失败"
                                        } else {
                                            return "已读取"
                                        }
                                    }
                                    font.family: "Alibaba PuHuiTi 3.0"
                                    font.pixelSize: 12
                                    color: {
                                        if (isReading) return "#006BFF"
                                        else if (!success) return "#FF4444"
                                        else return "#00AA44"
                                    }
                                    visible: isReading || !success
                                }

                                // 进度条
                                Rectangle {
                                    id: progressBar
                                    width: parent.width
                                    height: 3
                                    color: "#E6EAF2"
                                    radius: 1.5

                                    property var progressInfo: chatManager.fileReadProgress[modelData.path] || {}
                                    property bool isReading: progressInfo.isReading || false
                                    property int percentage: progressInfo.percentage || 0

                                    visible: isReading

                                    Rectangle {
                                        width: parent.width * (parent.percentage / 100.0)
                                        height: parent.height
                                        color: "#006BFF"
                                        radius: parent.radius

                                        Behavior on width {
                                            NumberAnimation {
                                                duration: 200
                                                easing.type: Easing.OutQuad
                                            }
                                        }
                                    }
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
                                property var progressInfo: chatManager.fileReadProgress[modelData.path] || {}
                                property bool isReading: progressInfo.isReading || false
                                visible: !isReading
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
                    enabled: !chatManager.isSending && !chatManager.isUploading && $loginManager.isLoggedIn
                    onDropped: {
                        if (drop.hasUrls) {
                            var filePaths = extractFilePathsFromUrls(drop.urls)
                            handleFileAddition(filePaths)
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
                                chatManager.endAnalysis(!specialPage)
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
                                    enabled: !chatManager.isSending && !chatManager.isUploading && $loginManager.isLoggedIn
                                    padding: 0
                                    Keys.onPressed: {
                                        if ((event.key === Qt.Key_Return || event.key === Qt.Key_Enter)) {
                                            if (event.modifiers === Qt.ShiftModifier) {
                                                // Shift+回车：换行（不处理，让默认行为执行）
                                                return
                                            } else if (event.modifiers === Qt.NoModifier) {
                                                // 单独回车：发送消息
                                                if (!chatManager.isUploading) sendMessage()
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
                            enabled: !chatManager.isSending && !chatManager.isUploading && $loginManager.isLoggedIn
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
                            source: !enabled ? "qrc:/image/sendDisable.png" : "qrc:/image/send.png"
                            enabled: !chatManager.isSending && !chatManager.isUploading && messageInput.text.trim().length > 0 && $loginManager.isLoggedIn
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

        // 清空知识库多选选项
        chooseKnowledge.setSelectedIds([])

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
            // 解析可能的多个文件路径
            var filePaths = parseFilePaths(clipboardText)

            if (filePaths.length > 0) {
                // 有文件路径，处理文件添加
                handleFileAddition(filePaths)
                // 无论成功失败，都不粘贴为文本，错误信息已在C++中显示
            } else {
                // 不是文件路径，作为普通文本粘贴
                messageInput.paste()
            }
        }
    }

    // 提取文件路径的通用函数
    function extractFilePathsFromUrls(urls) {
        var filePaths = []

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

        return filePaths
    }

    // 处理文件添加的通用函数
    function handleFileAddition(filePaths) {
        if (filePaths.length === 1) {
            // 单个文件直接添加，显示详细消息
            chatManager.addFile(filePaths[0])
        } else if (filePaths.length > 1) {
            // 多个文件批量添加，显示汇总消息
            chatManager.addFiles(filePaths)
        }
    }

    // 解析剪贴板中的文件路径，支持多个文件
    function parseFilePaths(text) {
        var filePaths = []

        // 按行分割文本，处理可能的多行文件路径
        var lines = text.split(/\r?\n/)

        for (var i = 0; i < lines.length; i++) {
            var line = lines[i].trim()
            if (line.length > 0 && isFilePath(line)) {
                // 移除file://前缀
                var cleanPath = line
                if (cleanPath.startsWith("file:///")) {
                    cleanPath = cleanPath.substring(8)
                } else if (cleanPath.startsWith("file://")) {
                    cleanPath = cleanPath.substring(7)
                }
                filePaths.push(cleanPath)
            }
        }

        // 如果没有找到按行分割的文件路径，检查整个文本是否是单个文件路径
        if (filePaths.length === 0) {
            var trimmedText = text.trim()
            if (isFilePath(trimmedText)) {
                // 移除file://前缀
                var cleanPath = trimmedText
                if (cleanPath.startsWith("file:///")) {
                    cleanPath = cleanPath.substring(8)
                } else if (cleanPath.startsWith("file://")) {
                    cleanPath = cleanPath.substring(7)
                }
                filePaths.push(cleanPath)
            }
        }

        return filePaths
    }

    // 判断是否是文件路径（简单检查，详细验证在C++中进行）
    function isFilePath(text) {
        text = text.trim()

        // 移除file://前缀进行检查
        var checkPath = text
        if (checkPath.startsWith("file:///")) {
            checkPath = checkPath.substring(8)
        } else if (checkPath.startsWith("file://")) {
            checkPath = checkPath.substring(7)
        }

        // 检查是否包含文件扩展名
        var hasExtension = /\.\w+$/.test(checkPath)
        // 检查是否是Windows或Linux路径格式
        var isPath = /^[A-Za-z]:\\|^\/|^\.\/|^\.\.\//.test(checkPath) || checkPath.includes('\\') || checkPath.includes('/')
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
