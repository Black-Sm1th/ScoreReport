import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import "./components"
ApplicationWindow {
    id: mainWindow
    visible: true
    // 全局快捷键：Ctrl+F12 打开截图功能
    Shortcut {
        sequence: "Ctrl+F12"
        context: Qt.ApplicationShortcut   // 全应用范围
        enabled: $loginManager.isLoggedIn
        onActivated: {
            if ($loginManager.isLoggedIn) {
                $loginManager.performScreenshotOCR()
            }
        }
    }

    // 全局鼠标区域，用于隐藏右键菜单
    MouseArea {
        anchors.fill: parent
        z: -1
        onPressed: {
            if (contextMenu.visible) {
                contextMenu.hide()
            }
        }
    }

    // 设置窗口属性：无边框、始终置顶、工具窗口
    flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool

    // 设置透明背景
    color: "transparent"

    // 窗口大小只包含悬浮窗本身
    width: 76
    height: 76

    // 初始位置设置在屏幕右下角
    x: Screen.width - width - 50
    y: Screen.height - height - 50

    title: qsTr("悬浮助手")


    DropShadow {
        id:floatingShaow
        anchors.fill: floatingWindow
        source: floatingWindow
        horizontalOffset: 0
        verticalOffset: 0
        radius: 16
        color: "#1F1A1A1A"
        samples: 32
    }

    // 悬浮窗
    Rectangle {
        id: floatingWindow
        width: 56
        height: 56
        color: "#FFFFFF"
        anchors.centerIn: parent
        radius: 12

        // 悬浮窗图标/图片
        Image {
            id: floatingImage
            anchors.centerIn: parent
            source: "qrc:/image/floatIcon.png"
        }

        // 鼠标悬停效果
        states: [
            State {
                name: "hovered"
                when: mouseArea.containsMouse
                PropertyChanges {
                    target: floatingWindow
                    scale: 1.1
                }
                PropertyChanges {
                    target: floatingShaow
                    scale: 1.1
                }
                PropertyChanges {
                    target: floatingImage
                    scale: 1.01
                }
            }
        ]

        transitions: Transition {
            NumberAnimation {
                property: "scale"
                duration: 200
                easing.type: Easing.OutBack
            }
        }

        // 鼠标区域 - 处理拖动和点击
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            property point lastMousePos
            property bool isDragging: false
            cursorShape: Qt.PointingHandCursor
            onPressed: {
                // 任何点击都先隐藏右键菜单（除了右键点击自己）
                if (mouse.button === Qt.LeftButton && contextMenu.visible) {
                    contextMenu.hide()
                }

                if (mouse.button === Qt.LeftButton) {
                    lastMousePos = Qt.point(mouse.x, mouse.y)
                    isDragging = false
                } else if (mouse.button === Qt.RightButton) {
                    // 右键点击，切换右键菜单显示状态
                    if (contextMenu.visible) {
                        contextMenu.hide()
                    } else {
                        contextMenu.showMenu(mouse.x, mouse.y)
                    }
                }
            }

            onPositionChanged: {
                if (pressed && pressedButtons & Qt.LeftButton) {
                    var dx = mouse.x - lastMousePos.x
                    var dy = mouse.y - lastMousePos.y

                    // 如果移动距离超过阈值，开始拖动
                    if (!isDragging && (Math.abs(dx) > 5 || Math.abs(dy) > 5)) {
                        isDragging = true
                    }

                    if (isDragging) {
                        var newX = mainWindow.x + dx
                        var newY = mainWindow.y + dy

                        // 限制拖动范围在屏幕内
                        newX = Math.max(0, Math.min(newX, Screen.width - mainWindow.width))
                        newY = Math.max(0, Math.min(newY, Screen.height - mainWindow.height))

                        mainWindow.x = newX
                        mainWindow.y = newY
                    }
                }
            }

            onClicked: {
                // 只处理左键点击，并且在没有拖动的情况下才响应
                if (mouse.button === Qt.LeftButton && !isDragging) {
                    if(!scoreDialog.visible){
                        scoreDialog.showDialog()
                    }else{
                        scoreDialog.visible = false
                        scoreDialog.isFirstShow = true
                    }
                }
            }

            onReleased: {
                // 拖动结束后重新启用位置动画
                if (isDragging && scoreDialog.visible) {
                    Qt.callLater(function() {
                        scoreDialog.disablePositionAnimation = false
                    })
                }
            }
        }
    }

    // 评分方案选择对话框
    Window {
        id: scoreDialog
        width: contentRect.width + 20  // 增加宽度为阴影留出空间
        height: contentRect.height + 20  // 增加高度为阴影留出空间
        visible: false
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        color: "transparent"
        function resetAllValue(){
            if(contentRect.currentScore !== -1){
                if(contentRect.currentScore == 0){
                    renalView.resetValues()
                }else if(contentRect.currentScore == 1){
                    cclsView.resetValues()
                }else if(contentRect.currentScore == 2){
                    tnmView.resetValues()
                }else if(contentRect.currentScore == 3){
                    uclsmrsView.resetValues()
                }else if(contentRect.currentScore == 4){
                    uclsctsView.resetValues()
                }else if(contentRect.currentScore == 6){
                    $chatManager.endAnalysis()
                }
                contentRect.currentScore = -1
            }
        }
        // 监听登录状态变化，自动切换到HomeView
        Connections {
            target: $loginManager
            function onLoginResult(success, message) {
                if (success) {
                    // 登录成功后自动切换到HomeView，并重置评分页面
                    contentRect.currentIndex = 0
                    contentRect.currentScore = -1
                }
            }
            function onLogoutSuccess(){
                historyView.resetAllValue()
                scoreDialog.resetAllValue()
            }
        }

        // 位置更新防抖定时器
        Timer {
            id: positionUpdateTimer
            interval: 16  // 减少到16ms，约一帧的时间，平衡响应性和稳定性
            repeat: false
            onTriggered: {
                if (scoreDialog.visible) {
                    scoreDialog.updateDialogPosition()
                }
            }
        }

        // 初始位置计算定时器（用于第一次显示）
        Timer {
            id: initialPositionTimer
            interval: 50  // 减少到50ms，更快响应
            repeat: false
            onTriggered: {
                if (scoreDialog.visible) {
                    scoreDialog.updateDialogPosition()
                    // 确保显示
                    if (scoreDialog.opacity === 0) {
                        scoreDialog.opacity = 1
                    }
                    // 重新启用位置动画
                    Qt.callLater(function() {
                        scoreDialog.disablePositionAnimation = false
                    })
                }
            }
        }

        // 高度变化专用定时器，无延迟快速更新
        Timer {
            id: heightChangeTimer
            interval: 1  // 几乎立即执行
            repeat: false
            onTriggered: {
                if (scoreDialog.visible) {
                    // 暂时禁用位置动画
                    scoreDialog.disablePositionAnimation = true
                    scoreDialog.updateDialogPosition()
                    // 重新启用动画
                    Qt.callLater(function() {
                        scoreDialog.disablePositionAnimation = false
                    })
                }
            }
        }

        // 对话框消息组件
        MessageBox {
            id: dialogMessageBox
            anchors.fill: parent
        }

        // 监听悬浮窗位置变化，自动更新对话框位置
        Connections {
            target: mainWindow
            function onXChanged() {
                if (scoreDialog.visible) {
                    // 检查是否正在拖动，如果是则禁用动画
                    if (mouseArea.isDragging || headerDragArea.isDragging) {
                        scoreDialog.disablePositionAnimation = true
                        scoreDialog.updateDialogPosition()
                        // 拖动结束后重新启用动画
                        Qt.callLater(function() {
                            if (!mouseArea.isDragging && !headerDragArea.isDragging) {
                                scoreDialog.disablePositionAnimation = false
                            }
                        })
                    } else {
                        // 使用防抖定时器延迟更新位置
                        positionUpdateTimer.restart()
                    }
                }
            }
            function onYChanged() {
                if (scoreDialog.visible) {
                    // 检查是否正在拖动，如果是则禁用动画
                    if (mouseArea.isDragging || headerDragArea.isDragging) {
                        scoreDialog.disablePositionAnimation = true
                        scoreDialog.updateDialogPosition()
                        // 拖动结束后重新启用动画
                        Qt.callLater(function() {
                            if (!mouseArea.isDragging && !headerDragArea.isDragging) {
                                scoreDialog.disablePositionAnimation = false
                            }
                        })
                    } else {
                        // 使用防抖定时器延迟更新位置
                        positionUpdateTimer.restart()
                    }
                }
            }
        }

        // 计算对话框位置的函数
        function updateDialogPosition() {
            // 如果内容高度还没有确定，跳过位置更新
            if (contentRect.height <= 0) {
                return
            }

            // 如果窗口不可见，不需要更新位置
            if (!scoreDialog.visible) {
                return
            }

            var floatingRect = Qt.rect(
                        mainWindow.x + (mainWindow.width - floatingWindow.width) / 2,
                        mainWindow.y + (mainWindow.height - floatingWindow.height) / 2,
                        floatingWindow.width,
                        floatingWindow.height
                        )

            var dialogHeight = height  // 使用实际窗口高度而不是contentRect高度
            var contentHeight = contentRect.height  // 内容区域的实际高度
            var spaceAbove = floatingRect.y
            var spaceBelow = Screen.height - (floatingRect.y + floatingRect.height)

            var newX, newY

            // 默认优先显示在上方，如果上方空间不够再考虑下方
            if (spaceAbove >= contentHeight + 20) {  // 内容高度 + 间距 + 阴影空间
                // 显示在悬浮窗上方，内容区域右侧对齐（考虑阴影边距）
                newX = floatingRect.x + floatingRect.width - (width - 10)
                newY = floatingRect.y - contentHeight - 20  // 使用内容高度 + 间距 + 阴影空间
            } else if (spaceBelow >= contentHeight + 20) {
                // 显示在悬浮窗下方，内容区域右侧对齐（考虑阴影边距）
                newX = floatingRect.x + floatingRect.width - (width - 10)
                newY = floatingRect.y + floatingRect.height  // 窗口顶部紧贴悬浮窗，内容区域会自然距离10px（因为有10px上方阴影空间）
            } else {
                // 如果上下空间都不够，优先选择上方（允许出屏幕）
                newX = floatingRect.x + floatingRect.width - (width - 10)
                newY = floatingRect.y - contentHeight - 20
            }

            // scoreDialog允许出屏幕，只确保X坐标在合理范围内
            newX = Math.max(-width + 100, Math.min(newX, Screen.width - 100))
            // Y坐标允许出屏幕上方，但不允许完全超出下方
            newY = Math.min(newY, Screen.height - 50)

            // 只在位置确实需要改变时才更新，减少阈值提高精确度
            if (Math.abs(x - newX) > 0.5 || Math.abs(y - newY) > 0.5) {
                x = newX
                y = newY
            }
        }

        property bool isFirstShow: true
        property bool disablePositionAnimation: false

        // 透明度动画
        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutQuad
            }
        }

        // 位置变化平滑动画
        Behavior on x {
            enabled: !scoreDialog.disablePositionAnimation
            NumberAnimation {
                duration: 80  // 减少动画时间，更快响应
                easing.type: Easing.OutQuad
            }
        }

        Behavior on y {
            enabled: !scoreDialog.disablePositionAnimation
            NumberAnimation {
                duration: 80  // 减少动画时间，更快响应
                easing.type: Easing.OutQuad
            }
        }

        function showDialog() {
            if (contentRect.height <= 0 && isFirstShow) {
                // 第一次显示且内容未渲染时，先隐藏显示进行预渲染
                opacity = 0
                visible = true
                isFirstShow = false
                // 禁用位置动画，避免第一次显示时的抖动
                disablePositionAnimation = true
                // 使用定时器等待内容完全渲染后再计算位置
                initialPositionTimer.start()
            } else {
                // 后续显示或内容已渲染时，直接显示
                visible = true
                opacity = 1
                // 立即更新位置，不使用延迟
                updateDialogPosition()
            }
        }

        Rectangle {
            id: contentRect
            width: 520
            height: contentColumn.height
            anchors.centerIn: parent
            color: "white"
            radius: 20
            property int currentIndex: 2
            property int currentScore: -1
            layer.enabled: true
            layer.smooth: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 2
                radius: 14
                color: "#1F1A1A1A"
                samples: 32
                transparentBorder: true
            }

            // 鼠标区域，处理点击对话框内容时隐藏右键菜单
            MouseArea {
                anchors.fill: parent
                z: -1
                onPressed: {
                    if (contextMenu.visible) {
                        contextMenu.hide()
                    }
                }
            }

            // 监听页面切换，重新计算位置
            onCurrentIndexChanged: {
                if (scoreDialog.visible) {
                    // 页面切换时暂时禁用动画，避免抖动
                    scoreDialog.disablePositionAnimation = true
                    // 使用防抖定时器延迟更新位置，确保新页面内容已渲染
                    positionUpdateTimer.restart()
                    // 短暂延迟后重新启用动画
                    Qt.callLater(function() {
                        Qt.callLater(function() {
                            scoreDialog.disablePositionAnimation = false
                        })
                    })
                }
                if(currentIndex == 1){
                    $historyManager.updateList()
                }
            }

            // 监听高度变化，当内容加载完成后更新位置
            onHeightChanged: {
                if (scoreDialog.visible && height > 0) {
                    // 使用高度变化专用定时器，快速且无抖动地更新位置
                    heightChangeTimer.restart()

                    // 如果是隐藏状态（第一次渲染），现在显示出来
                    if (scoreDialog.opacity === 0) {
                        scoreDialog.opacity = 1
                    }
                }
            }
            Column {
                id: contentColumn
                width: parent.width
                // 头部区域
                Rectangle {
                    width: parent.width
                    height: 58
                    color: "transparent"

                    // 添加头部拖动功能的鼠标区域
                    MouseArea {
                        id: headerDragArea
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        property point lastMousePos
                        property bool isDragging: false
                        z: 0  // 确保在其他控件之下

                        onPressed: {
                            // 点击对话框头部时隐藏右键菜单
                            if (contextMenu.visible) {
                                contextMenu.hide()
                            }

                            if (mouse.button === Qt.LeftButton) {
                                lastMousePos = Qt.point(mouse.x, mouse.y)
                                isDragging = false
                            }
                        }

                        onPositionChanged: {
                            if (pressed && pressedButtons & Qt.LeftButton) {
                                var dx = mouse.x - lastMousePos.x
                                var dy = mouse.y - lastMousePos.y

                                // 如果移动距离超过阈值，开始拖动
                                if (!isDragging && (Math.abs(dx) > 5 || Math.abs(dy) > 5)) {
                                    isDragging = true
                                }

                                if (isDragging) {
                                    // 拖动悬浮窗，对话框会通过updateDialogPosition自动跟随
                                    var newX = mainWindow.x + dx
                                    var newY = mainWindow.y + dy

                                    // 限制拖动范围在屏幕内
                                    newX = Math.max(0, Math.min(newX, Screen.width - mainWindow.width))
                                    newY = Math.max(0, Math.min(newY, Screen.height - mainWindow.height))

                                    mainWindow.x = newX
                                    mainWindow.y = newY
                                }
                            }
                        }

                        onReleased: {
                            // 拖动结束后重新启用位置动画
                            if (isDragging && scoreDialog.visible) {
                                Qt.callLater(function() {
                                    scoreDialog.disablePositionAnimation = false
                                })
                            }
                        }
                    }

                    Row {
                        id: title
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 17
                        spacing: 8
                        z: 1  // 确保在拖动区域之上
                        Image {
                            source: "qrc:/image/titleIcon.png"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        Image {
                            source: "qrc:/image/titleName.png"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    CircleButtonGroup {
                        id: titleBtn
                        anchors.right: titleSplit.left
                        selectedIndex: contentRect.currentIndex
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: 12
                        buttonSize: 28        // 按钮大小
                        spacing: 12          // 按钮间距
                        z: 1  // 确保在拖动区域之上
                        iconSources: [       // 图标数组
                            "qrc:/image/home.png",
                            "qrc:/image/history.png",
                            "qrc:/image/user.png"
                        ]
                        iconSelectedSources: [       // 图标数组
                            "qrc:/image/homeSelected.png",
                            "qrc:/image/historySelected.png",
                            "qrc:/image/userSelected.png"
                        ]

                        // 选择变化回调
                        onSelectionChanged: function(index) {
                            // 点击按钮组时隐藏右键菜单
                            if (contextMenu.visible) {
                                contextMenu.hide()
                            }

                            if($loginManager.currentUserName === ""){
                                dialogMessageBox.warning("请先登录！")
                                return
                            }
                            $loginManager.isChangingUser = false
                            $loginManager.isAdding = false
                            contentRect.currentIndex = index
                        }
                    }

                    // 分隔线
                    Rectangle {
                        id: titleSplit
                        width: 1
                        height: 12
                        anchors.rightMargin: 12
                        anchors.right: titleClose.left
                        anchors.verticalCenter: parent.verticalCenter
                        color: "#14000000"
                        z: 1  // 确保在拖动区域之上
                    }

                    Button {
                        id: titleClose
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: 15
                        width: 28
                        height: 28
                        z: 1  // 确保在拖动区域之上
                        background: Rectangle {
                            color: parent.hovered ? "#F5F5F5" : "transparent"
                            radius: 1111
                        }

                        Image{
                            source: "qrc:/image/close.png"
                            anchors.centerIn: parent
                        }
                        MouseArea{
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                // 点击关闭按钮时隐藏右键菜单
                                if (contextMenu.visible) {
                                    contextMenu.hide()
                                }
                                scoreDialog.visible = false
                                scoreDialog.isFirstShow = true
                            }
                        }
                    }
                }

                // 分隔线
                Rectangle {
                    width: parent.width
                    height: 1
                    color: "#F0F0F0"
                }
                Rectangle {
                    width: parent.width
                    height: 16
                    color: "transparent"
                }
                HomeView {
                    visible: contentRect.currentIndex === 0 && contentRect.currentScore === -1
                    messageManager: dialogMessageBox
                    onCurrentPageChanged: {
                        if(index === 6){
                            chatView.resetValue()
                        }
                        contentRect.currentScore = index
                    }
                }
                HistoryView{
                    id:historyView
                    visible: contentRect.currentIndex === 1
                    messageManager: dialogMessageBox
                    onToScorer: {
                        contentRect.currentIndex = 0
                    }
                }
                UserView{
                    visible: contentRect.currentIndex === 2
                    messageManager: dialogMessageBox
                }
                RENAL{
                    id:renalView
                    visible: contentRect.currentIndex === 0 && contentRect.currentScore === 0
                    messageManager: dialogMessageBox
                    onExitScore: {
                        contentRect.currentScore = -1
                    }
                }
                CCLS{
                    id:cclsView
                    visible: contentRect.currentIndex === 0 && contentRect.currentScore === 1
                    messageManager: dialogMessageBox
                    onExitScore: {
                        contentRect.currentScore = -1
                    }
                }
                TNM{
                    id:tnmView
                    visible: contentRect.currentIndex === 0 && contentRect.currentScore === 2
                    messageManager: dialogMessageBox
                    onExitScore: {
                        contentRect.currentScore = -1
                    }
                }
                UCLSMRS{
                    id:uclsmrsView
                    visible: contentRect.currentIndex === 0 && contentRect.currentScore === 3
                    messageManager: dialogMessageBox
                    onExitScore: {
                        contentRect.currentScore = -1
                    }
                }
                UCLSCTS{
                    id:uclsctsView
                    visible: contentRect.currentIndex === 0 && contentRect.currentScore === 4
                    messageManager: dialogMessageBox
                    onExitScore: {
                        contentRect.currentScore = -1
                    }
                }
                CHAT{
                    id:chatView
                    visible: contentRect.currentIndex === 0 && contentRect.currentScore === 6
                    messageManager: dialogMessageBox
                    onExitScore: {
                        contentRect.currentScore = -1
                    }
                }
            }
        }
    }

    // 评分方式选择对话框
    Window {
        id: scoringMethodDialog
        width: scoringMethodContent.width + 40  // 内容宽度 + 边距
        height: scoringMethodContent.height + 40  // 内容高度 + 边距
        visible: false
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        color: "transparent"
        opacity: 0

        // 透明度动画
        Behavior on opacity {
            NumberAnimation {
                duration: 200
                easing.type: Easing.OutQuad
            }
        }

        // 失去焦点时自动隐藏
        onActiveFocusItemChanged: {
            if (!activeFocusItem && visible) {
                hideDialog()
            }
        }

        // 监听窗口激活状态变化
        onActiveChanged: {
            if (!active && visible) {
                hideDialog()
            }
        }

        // 1.5秒延迟显示定时器
        Timer {
            id: showDelayTimer
            interval: 1000
            repeat: false
            onTriggered: {
                scoringMethodDialog.showDialog()
            }
        }

        // 3秒自动隐藏定时器
        Timer {
            id: autoHideTimer
            interval: 3000
            repeat: false
            onTriggered: {
                scoringMethodDialog.hideDialog()
            }
        }

        // 存储鼠标位置
        property int lastMouseX: 0
        property int lastMouseY: 0
        property string currentText: ""
        property string lastProcessedText: ""  // 记录上次处理的文本，防止重复处理

        // 防抖定时器，防止短时间内重复触发
        Timer {
            id: debounceTimer
            interval: 300  // 300ms防抖间隔
            repeat: false
            onTriggered: {
                // 执行实际的弹窗显示逻辑
                if (scoringMethodDialog.visible && scoringMethodDialog.opacity > 0) {
                    // 如果选择框已经显示，重新开始3秒倒计时
                    autoHideTimer.restart()
                } else {
                    // 如果选择框未显示，1秒后显示
                    showDelayTimer.restart()
                    autoHideTimer.stop()
                }
            }
        }

        // 监听划词信号
        Connections {
            target: $loginManager
            function onTextSelectionDetected(text, mouseX, mouseY) {
                if (text && text.length > 0 && $loginManager.isLoggedIn && $loginManager.showDialogOnTextSelection) {
                    // 检查是否与上次处理的文本相同，避免重复处理
                    if (text === scoringMethodDialog.lastProcessedText) {
                        return
                    }

                    // 保存鼠标位置和文本
                    scoringMethodDialog.lastMouseX = mouseX
                    scoringMethodDialog.lastMouseY = mouseY
                    scoringMethodDialog.currentText = text
                    scoringMethodDialog.lastProcessedText = text

                    // 使用防抖定时器，避免短时间内重复触发
                    debounceTimer.restart()
                }
            }
        }

        function showDialog() {
            // 计算弹窗位置
            updateDialogPosition()
            visible = true
            opacity = 1
            autoHideTimer.start()
            // 请求焦点，这样失去焦点时可以自动隐藏
            requestActivate()
        }

        function updateDialogPosition() {
            var spacing = 10  // 与鼠标位置的间距
            var newX = lastMouseX - width / 2  // 水平居中对齐鼠标位置
            var newY = lastMouseY - height - spacing  // 显示在鼠标上方

            // 确保不超出屏幕边界
            if (newX < 10) {
                newX = 10  // 左边界
            } else if (newX + width > Screen.width - 10) {
                newX = Screen.width - width - 10  // 右边界
            }

            // 垂直方向调整
            if (newY < 10) {
                // 如果上方空间不够，显示在鼠标下方
                newY = lastMouseY + spacing
                // 如果下方也放不下，就放在屏幕中央
                if (newY + height > Screen.height - 10) {
                    newY = (Screen.height - height) / 2
                }
            }

            // 确保不超出下边界
            if (newY + height > Screen.height - 10) {
                newY = Screen.height - height - 10
            }

            x = newX
            y = newY
        }

        function hideDialog() {
            opacity = 0
            visible = false
            showDelayTimer.stop()
            autoHideTimer.stop()
            debounceTimer.stop()
            // 清理上次处理的文本记录，允许相同文本再次触发
            lastProcessedText = ""
        }

        Rectangle {
            id: scoringMethodContent
            width: 200
            height: 100
            color: "white"
            radius: 16
            scale: scoringMethodDialog.opacity
            anchors.centerIn: parent

            // 缩放动画
            Behavior on scale {
                NumberAnimation {
                    duration: 200
                    easing.type: Easing.OutBack
                }
            }

            // 简单的鼠标处理
            MouseArea {
                anchors.fill: parent
                onClicked: {
                    // 点击评分方式对话框内容时隐藏右键菜单
                    if (contextMenu.visible) {
                        contextMenu.hide()
                    }
                }
            }

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 4
                radius: 16
                color: "#40000000"
                samples: 32
                transparentBorder: true
            }

            Column {
                anchors.centerIn: parent
                spacing: 20

                // 标题
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.pixelSize: 16
                    font.weight: Font.Medium
                    color: "#D9000000"
                    text: qsTr("请选择评分方式")
                }

                // 按钮组
                Row {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: 20

                    // TNM按钮
                    Rectangle {
                        width: 70
                        height: 40
                        color: tnmMouseArea.containsMouse ? "#E8F4FD" : "#F8F9FA"
                        border.color: tnmMouseArea.containsMouse ? "#1890FF" : "#D9D9D9"
                        border.width: 1
                        radius: 8

                        Text {
                            anchors.centerIn: parent
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 14
                            color: tnmMouseArea.containsMouse ? "#1890FF" : "#666666"
                            text: "TNM"
                        }

                        MouseArea {
                            id: tnmMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                scoringMethodDialog.hideDialog()
                                // 切换到主页面并选择TNM评分
                                scoreDialog.resetAllValue()
                                contentRect.currentIndex = 0
                                contentRect.currentScore = 2  // TNM对应索引2
                                $loginManager.copyToClipboard(scoringMethodDialog.currentText)
                                if($tnmManager.checkClipboard()){
                                    $tnmManager.startAnalysis()
                                }else{
                                    messageManager.warning(qsTr("剪贴板为空，请先复制内容"))
                                }
                                if(!scoreDialog.visible){
                                    scoreDialog.showDialog()
                                }
                            }
                        }
                    }

                    // RENAL按钮
                    Rectangle {
                        width: 70
                        height: 40
                        color: renalMouseArea.containsMouse ? "#E8F4FD" : "#F8F9FA"
                        border.color: renalMouseArea.containsMouse ? "#1890FF" : "#D9D9D9"
                        border.width: 1
                        radius: 8

                        Text {
                            anchors.centerIn: parent
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 14
                            color: renalMouseArea.containsMouse ? "#1890FF" : "#666666"
                            text: "RENAL"
                        }

                        MouseArea {
                            id: renalMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor

                            onClicked: {
                                // 点击RENAL按钮时隐藏右键菜单
                                if (contextMenu.visible) {
                                    contextMenu.hide()
                                }
                                scoringMethodDialog.hideDialog()
                                // 切换到主页面并选择RENAL评分
                                scoreDialog.resetAllValue()
                                contentRect.currentIndex = 0
                                contentRect.currentScore = 0  // RENAL对应索引0
                                $loginManager.copyToClipboard(scoringMethodDialog.currentText)
                                if($renalManager.checkClipboard()){
                                    $renalManager.startAnalysis()
                                }else{
                                    messageManager.warning(qsTr("剪贴板为空，请先复制内容"))
                                }
                                if(!scoreDialog.visible){
                                    scoreDialog.showDialog()
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // 右键菜单
    Window {
        id: contextMenu
        width: menuBackground.width
        height: menuColumn.height
        visible: false
        flags: Qt.FramelessWindowHint | Qt.Popup
        color: "transparent"

        // 失去焦点时自动隐藏
        onActiveFocusItemChanged: {
            if (!activeFocusItem && visible) {
                hide()
            }
        }

        // 监听窗口激活状态变化
        onActiveChanged: {
            if (!active && visible) {
                hide()
            }
        }

        // 显示菜单的函数
        function showMenu(mouseX, mouseY) {
            // 计算菜单在屏幕上的位置
            // 悬浮窗的全局位置 + 鼠标在悬浮窗内的位置
            var globalX = mainWindow.x + mouseX
            var globalY = mainWindow.y + mouseY

            // 确保菜单不超出屏幕右边界
            var menuX = globalX
            if (menuX + width > Screen.width) {
                menuX = globalX - width
            }

            // 确保菜单不超出屏幕下边界
            var menuY = globalY
            if (menuY + height > Screen.height) {
                menuY = globalY - height
            }

            // 确保菜单不超出屏幕上边界
            menuY = Math.max(0, menuY)
            menuX = Math.max(0, menuX)

            x = menuX
            y = menuY
            visible = true
            requestActivate()
        }

        // 隐藏菜单
        function hide() {
            visible = false
        }

        Rectangle {
            id: menuBackground
            width: contentArea.width + 24
            height: parent.height
            color: "#FFFFFF"
            radius: 8

            // 添加阴影效果
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 0
                radius: 16
                color: "#1F1A1A1A"
                samples: 32
            }

            Column {
                id: menuColumn
                width: contentArea.width + 24

                // 语言切换选项
                Rectangle {
                    width: contentArea.width + 24
                    height: 40
                    color: languageMouseArea.containsMouse ? "#F5F5F5" : "transparent"
                    radius: 6

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // 语言图标
                        Rectangle {
                            width: 16
                            height: 16
                            anchors.verticalCenter: parent.verticalCenter
                            color: "transparent"

                            // 简单的语言图标 (A文)
                            Canvas {
                                anchors.fill: parent
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    ctx.fillStyle = "#007ACC"
                                    ctx.font = "bold 10px Arial"
                                    ctx.textAlign = "center"
                                    ctx.textBaseline = "middle"
                                    ctx.fillText("语", 8, 8)
                                }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 14
                            color: languageMouseArea.containsMouse ? "#007ACC" : "#666666"
                            text: qsTr("语言") + " (" + (languageManager ? qsTr(languageManager.getLanguageDisplayName(languageManager.currentLanguage)) : qsTr("中文")) + ")"

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: languageMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            if (languageManager) {
                                // 切换语言：如果当前是中文，切换到英文；如果是英文，切换到中文
                                if (languageManager.currentLanguage === "zh") {
                                    languageManager.setCurrentLanguage("en")
                                } else {
                                    languageManager.setCurrentLanguage("zh")
                                }
                            }
                            contextMenu.hide()
                        }
                    }
                }

                // 分隔线
                Rectangle {
                    width: parent.width - 16
                    height: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "#E0E0E0"
                }

                // 弹窗控制选项
                Rectangle {
                    width: contentArea.width + 24
                    height: 40
                    color: dialogMouseArea.containsMouse ? "#F5F5F5" : "transparent"
                    radius: 6

                    Row {
                        id: contentArea
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // 弹窗图标
                        Rectangle {
                            width: 16
                            height: 16
                            anchors.verticalCenter: parent.verticalCenter
                            color: "transparent"

                            // 简单的弹窗图标
                            Canvas {
                                anchors.fill: parent
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    ctx.strokeStyle = "#007ACC"
                                    ctx.lineWidth = 1.5
                                    ctx.lineCap = "round"

                                    // 绘制弹窗图标（矩形边框）
                                    ctx.strokeRect(2, 3, 12, 8)
                                    // 绘制标题栏
                                    ctx.fillStyle = "#007ACC"
                                    ctx.fillRect(2, 3, 12, 2)
                                }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 14
                            color: dialogMouseArea.containsMouse ? "#007ACC" : "#666666"
                            text: qsTr("弹窗提示") + " (" + ($loginManager.showDialogOnTextSelection ? qsTr("开启") : qsTr("关闭")) + ")"

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: dialogMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            // 切换弹窗显示设置
                            var newSetting = !$loginManager.showDialogOnTextSelection
                            $loginManager.saveShowDialogSetting(newSetting)
                            contextMenu.hide()
                        }
                    }
                }

                // 分隔线
                Rectangle {
                    width: parent.width - 16
                    height: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "#E0E0E0"
                }

                // 截图识字选项
                Rectangle {
                    width: contentArea.width + 24
                    height: 40
                    color: ocrMouseArea.containsMouse && $loginManager.isLoggedIn ? "#F5F5F5" : "transparent"
                    radius: 6

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // 截图识字图标
                        Rectangle {
                            width: 16
                            height: 16
                            anchors.verticalCenter: parent.verticalCenter
                            color: "transparent"

                            // 简单的截图图标
                            Canvas {
                                id: canvas
                                anchors.fill: parent
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    var iconColor = $loginManager.isLoggedIn ? "#007ACC" : "#CCCCCC"
                                    ctx.strokeStyle = iconColor
                                    ctx.lineWidth = 1.5
                                    ctx.lineCap = "round"

                                    // 绘制相机图标
                                    ctx.strokeRect(2, 4, 12, 8)
                                    ctx.fillStyle = iconColor
                                    ctx.fillRect(6, 6, 4, 4)
                                    // 绘制镜头
                                    ctx.strokeRect(1, 2, 2, 2)
                                }

                                // 监听登录状态变化重新绘制
                                Connections {
                                    target: $loginManager
                                    function onIsLoggedInChanged() {
                                        canvas.requestPaint()
                                    }
                                }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 14
                            color: $loginManager.isLoggedIn ?
                                   (ocrMouseArea.containsMouse ? "#007ACC" : "#666666") :
                                   "#CCCCCC"
                            text: qsTr("截图识字")

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: ocrMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: $loginManager.isLoggedIn ? Qt.PointingHandCursor : Qt.ForbiddenCursor

                        onClicked: {
                            contextMenu.hide()
                            if ($loginManager.isLoggedIn) {
                                $loginManager.performScreenshotOCR()
                            }
                        }
                    }
                }

                // 分隔线
                Rectangle {
                    width: parent.width - 16
                    height: 1
                    anchors.horizontalCenter: parent.horizontalCenter
                    color: "#E0E0E0"
                }

                Rectangle {
                    width: parent.width
                    height: 40
                    color: exitMouseArea.containsMouse ? "#F5F5F5" : "transparent"
                    radius: 6

                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // 退出图标
                        Rectangle {
                            width: 16
                            height: 16
                            anchors.verticalCenter: parent.verticalCenter
                            color: "transparent"

                            // 简单的退出图标 (X)
                            Canvas {
                                anchors.fill: parent
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    ctx.strokeStyle = "#FF4444"
                                    ctx.lineWidth = 2
                                    ctx.lineCap = "round"

                                    // 绘制X
                                    ctx.beginPath()
                                    ctx.moveTo(4, 4)
                                    ctx.lineTo(12, 12)
                                    ctx.moveTo(12, 4)
                                    ctx.lineTo(4, 12)
                                    ctx.stroke()
                                }
                            }
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 14
                            color: exitMouseArea.containsMouse ? "#FF4444" : "#666666"
                            text: qsTr("退出程序")

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: exitMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            contextMenu.hide()
                            $loginManager.stopMonitoring()
                            Qt.quit()
                        }
                    }
                }
            }
        }
    }

    // OCR结果对话框
    Window {
        id: ocrResultDialog
        width: 600
        height: 500
        visible: false
        flags: Qt.Dialog | Qt.WindowCloseButtonHint
        title: qsTr("截图识字结果")

        // 设置对话框在屏幕中央
        Component.onCompleted: {
            x = (Screen.width - width) / 2
            y = (Screen.height - height) / 2
        }

        onVisibleChanged: {
            if (visible) {
                x = (Screen.width - width) / 2
                y = (Screen.height - height) / 2
            }
        }

        property string ocrText: ""

        // 监听OCR结果信号
        Connections {
            target: $loginManager
            function onScreenshotOCRResult(text) {
                ocrResultDialog.ocrText = text
                ocrResultDialog.show()
                ocrResultDialog.raise()
                ocrResultDialog.requestActivate()
            }
            function onStartScreenshotSelection() {
                screenshotSelector.startSelection()
            }
        }

        Rectangle {
            anchors.fill: parent
            color: "#FFFFFF"

            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15

                Text {
                    width: parent.width
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.pixelSize: 16
                    font.bold: true
                    color: "#D9000000"
                    text: qsTr("识别结果：")

                    // 添加拖动功能的MouseArea
                    MouseArea {
                        anchors.fill: parent
                        acceptedButtons: Qt.LeftButton
                        z: -1  // 确保不干扰文本选择

                        property point lastMousePos
                        property bool isDragging: false

                        onPressed: {
                            // 只有在没有选中文本时才允许拖动
                            lastMousePos = Qt.point(mouse.x, mouse.y)
                            isDragging = false
                        }
                        onPositionChanged: {
                            if (pressed && pressedButtons & Qt.LeftButton) {
                                var dx = mouse.x - lastMousePos.x
                                var dy = mouse.y - lastMousePos.y

                                // 如果移动距离超过阈值，开始拖动
                                if (!isDragging && (Math.abs(dx) > 5 || Math.abs(dy) > 5)) {
                                    isDragging = true
                                    ocrResultDialog.startSystemMove()
                                }
                            }
                        }
                        onReleased: {
                            isDragging = false
                        }
                    }
                }

                ScrollView {
                    width: parent.width
                    height: parent.height - 80

                    TextArea {
                        id: ocrTextArea
                        width: parent.width
                        text: ocrResultDialog.ocrText
                        font.family: "Alibaba PuHuiTi 3.0"
                        font.pixelSize: 14
                        color: "#D9000000"
                        wrapMode: TextArea.Wrap
                        selectByMouse: true

                        background: Rectangle {
                            color: "#F8F9FA"
                            border.color: "#E0E0E0"
                            border.width: 1
                            radius: 4
                        }
                    }
                }

                Row {
                    spacing: 10
                    CustomButton {
                        width: 80
                        height: 32
                        backgroundColor: "#5792FF"
                        text: "RENAL"
                        onClicked: {
                            // 切换到主页面并选择RENAL评分
                            scoreDialog.resetAllValue()
                            contentRect.currentIndex = 0
                            contentRect.currentScore = 0  // RENAL对应索引0
                            $loginManager.copyToClipboard(ocrTextArea.text)
                            if($renalManager.checkClipboard()){
                                $renalManager.startAnalysis()
                            }else{
                                messageManager.warning(qsTr("剪贴板为空，请先复制内容"))
                            }
                            if(!scoreDialog.visible){
                                scoreDialog.showDialog()
                            }
                        }
                    }
                    CustomButton {
                        width: 80
                        height: 32
                        text:"TNM"
                        backgroundColor: "#FF490D"
                        onClicked: {
                            // 切换到主页面并选择TNM评分
                            scoreDialog.resetAllValue()
                            contentRect.currentIndex = 0
                            contentRect.currentScore = 2  // TNM对应索引2
                            $loginManager.copyToClipboard(ocrTextArea.text)
                            if($tnmManager.checkClipboard()){
                                $tnmManager.startAnalysis()
                            }else{
                                messageManager.warning(qsTr("剪贴板为空，请先复制内容"))
                            }
                            if(!scoreDialog.visible){
                                scoreDialog.showDialog()
                            }
                        }
                    }
                    Rectangle{
                        width: ocrResultDialog.width - 400
                        height: 32
                    }
                    CustomButton {
                        width: 80
                        height: 32
                        text:"复制"
                        backgroundColor: "#006BFF"
                        onClicked: {
                            $loginManager.copyToClipboard(ocrTextArea.text)
                            messageManager.success(qsTr("已复制到剪贴板"))
                        }
                    }
                    CustomButton {
                        width: 80
                        height: 32
                        text:"关闭"
                        backgroundColor: "#FF5132"
                        onClicked: {
                            ocrResultDialog.close()
                        }
                    }
                }
            }
        }
    }

    // 截图选择器
    Window {
        id: screenshotSelector
        visible: false
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
        color: "transparent"

        property bool isSelecting: false
        property int startX: 0
        property int startY: 0
        property int endX: 0
        property int endY: 0

        // 窗口显示时获得焦点
        onVisibleChanged: {
            if (visible) {
                // 延迟一点确保窗口完全显示后再获得焦点
                Qt.callLater(function() {
                    screenshotSelector.requestActivate()
                })
            }
        }



        function startSelection() {
            // 获取屏幕尺寸
            var screen = Qt.application.screens[0]
            width = screen.width
            height = screen.height
            x = screen.virtualX
            y = screen.virtualY

            isSelecting = false
            startX = 0
            startY = 0
            endX = 0
            endY = 0

            visible = true
            raise()
            requestActivate()
        }

        function finishSelection() {
            // 立即隐藏窗口，避免蒙层继续阻挡鼠标事件
            visible = false
            isSelecting = false

            var selX = Math.min(startX, endX)
            var selY = Math.min(startY, endY)
            var selWidth = Math.abs(endX - startX)
            var selHeight = Math.abs(endY - startY)

            if (selWidth > 10 && selHeight > 10) {
                // 使用延迟调用，确保窗口完全隐藏后再处理截图
                Qt.callLater(function() {
                    $loginManager.processScreenshotArea(selX, selY, selWidth, selHeight)
                })
            }
        }

        function cancelSelection() {
            isSelecting = false
            visible = false
            // 重置选择区域
            startX = 0
            startY = 0
            endX = 0
            endY = 0
        }

        // 使用四个矩形来创建带透明选中区域的遮罩
        Item {
            anchors.fill: parent
            focus: true  // 确保能接收键盘事件
            Component.onCompleted: {
                forceActiveFocus()
            }

            // 计算选中区域的坐标
            property int selX: screenshotSelector.isSelecting ? Math.min(screenshotSelector.startX, screenshotSelector.endX) : 0
            property int selY: screenshotSelector.isSelecting ? Math.min(screenshotSelector.startY, screenshotSelector.endY) : 0
            property int selWidth: screenshotSelector.isSelecting ? Math.abs(screenshotSelector.endX - screenshotSelector.startX) : 0
            property int selHeight: screenshotSelector.isSelecting ? Math.abs(screenshotSelector.endY - screenshotSelector.startY) : 0

            // 上方遮罩
            Rectangle {
                x: 0
                y: 0
                width: parent.width
                height: parent.selY
                color: "#80000000"
                visible: screenshotSelector.isSelecting && height > 0
            }

            // 下方遮罩
            Rectangle {
                x: 0
                y: parent.selY + parent.selHeight
                width: parent.width
                height: parent.height - y
                color: "#80000000"
                visible: screenshotSelector.isSelecting && height > 0
            }

            // 左侧遮罩
            Rectangle {
                x: 0
                y: parent.selY
                width: parent.selX
                height: parent.selHeight
                color: "#80000000"
                visible: screenshotSelector.isSelecting && width > 0
            }

            // 右侧遮罩
            Rectangle {
                x: parent.selX + parent.selWidth
                y: parent.selY
                width: parent.width - x
                height: parent.selHeight
                color: "#80000000"
                visible: screenshotSelector.isSelecting && width > 0
            }

            // 选中区域边框（透明区域）
            Rectangle {
                id: selectionRect
                x: parent.selX
                y: parent.selY
                width: parent.selWidth
                height: parent.selHeight
                color: "transparent"
                border.color: "#00AAFF"
                border.width: 2
                visible: screenshotSelector.isSelecting

                // 选择区域的尺寸显示
                Text {
                    anchors.bottom: parent.top
                    anchors.left: parent.left
                    anchors.bottomMargin: 5
                    color: "#FFFFFF"
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.pixelSize: 12
                    text: parent.width + " × " + parent.height
                    visible: parent.width > 50 && parent.height > 20

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -2
                        color: "#80000000"
                        radius: 2
                        z: -1
                    }
                }
            }

            // 未开始选择时的全屏遮罩
            Rectangle {
                anchors.fill: parent
                color: "#80000000"
                visible: !screenshotSelector.isSelecting
            }

            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.CrossCursor
                acceptedButtons: Qt.LeftButton | Qt.RightButton
                focus: true

                onPressed: {
                    // 确保获得焦点
                    forceActiveFocus()

                    if (mouse.button === Qt.RightButton) {
                        // 右键直接取消
                        screenshotSelector.cancelSelection()
                        return
                    }

                    if (mouse.button === Qt.LeftButton) {
                        screenshotSelector.isSelecting = true
                        screenshotSelector.startX = mouse.x
                        screenshotSelector.startY = mouse.y
                        screenshotSelector.endX = mouse.x
                        screenshotSelector.endY = mouse.y
                    }
                }

                onPositionChanged: {
                    if (screenshotSelector.isSelecting && pressedButtons & Qt.LeftButton) {
                        screenshotSelector.endX = mouse.x
                        screenshotSelector.endY = mouse.y
                    }
                }

                onReleased: {
                    if (mouse.button === Qt.LeftButton && screenshotSelector.isSelecting) {
                        screenshotSelector.finishSelection()
                    }
                }

                // MouseArea级别的键盘事件处理
                Keys.onEscapePressed: {
                    screenshotSelector.cancelSelection()
                }
            }

            // 使用Shortcut组件确保ESC键能被捕获
            Shortcut {
                sequence: "Escape"
                enabled: screenshotSelector.visible
                onActivated: {
                    screenshotSelector.cancelSelection()
                }
            }

            // 提示文字
            Text {
                anchors.top: parent.top
                anchors.left: parent.left
                anchors.margins: 20
                color: "#FFFFFF"
                font.family: "Alibaba PuHuiTi 3.0"
                font.pixelSize: 16
                text: qsTr("拖拽选择截图区域，右键或ESC键取消")
            }
        }
    }
}
