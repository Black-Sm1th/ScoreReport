import QtQuick 2.15
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0

import "./components"
ApplicationWindow {
    id: mainWindow
    visible: true

    // 应用启动完成后启动帮助定时器
    Component.onCompleted: {
        helpBubbleTimer.start()
    }
    // 全局快捷键：Ctrl+F12 打开截图功能
    Shortcut {
        sequence: "Ctrl+F12"
        context: Qt.ApplicationShortcut   // 全应用范围
        onActivated: {
            screenshotSelector.startSelection()
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
    width: 90
    height: 90

    // 初始位置设置在屏幕右下角
    x: Screen.width - width - 50
    y: Screen.height - height - 50

    title: qsTr("悬浮助手")

    Timer{
        id: disabledTimer
        interval: 1000
        repeat: false
        onTriggered: {
            scoreDialog.hideDialog()
        }
    }

    // 帮助提示定时器 - 每30秒弹出一次
    Timer {
        id: helpBubbleTimer
        interval: 8000  // 30秒
        repeat: true
        running: true  // 初始不运行
        onTriggered: {
            // 只有在没有其他对话框显示时才显示帮助气泡
            if (!scoreDialog.visible && !scoringMethodDialog.visible && !contextMenu.visible && !chatWindow.visible) {
                helpBubble.showBubble()
            }
        }
    }
    DropShadow {
        id:floatingShaow
        anchors.fill: floatingWindow
        source: floatingWindow
        horizontalOffset: 0
        verticalOffset: 0
        radius: 16
        color: "#1F1A1A1A"
        samples: 32
        scale: 1.1
    }

    // 悬浮窗
    Rectangle {
        id: floatingWindow
        width: 65
        height: 65
        color: "transparent"
        scale: 1.1
        anchors.centerIn: parent
        property int currentIndex: 0
        property var images: ["qrc:/image/floatIcon/icon1.png", "qrc:/image/floatIcon/icon2.png", "qrc:/image/floatIcon/icon3.png", "qrc:/image/floatIcon/icon4.png", "qrc:/image/floatIcon/icon5.png", "qrc:/image/floatIcon/icon6.png", "qrc:/image/floatIcon/icon7.png", "qrc:/image/floatIcon/icon8.png", "qrc:/image/floatIcon/icon9.png", "qrc:/image/floatIcon/icon10.png"]
        // 悬浮窗图标/图片
        Image {
            id: floatingImage
            anchors.fill: parent
            anchors.centerIn: parent
            fillMode: Image.PreserveAspectFit
            source: floatingWindow.images[floatingWindow.currentIndex]
            scale: 1.1
        }
        Timer {
            interval: 250; running: true; repeat: true
            onTriggered: {
                floatingWindow.currentIndex = (floatingWindow.currentIndex + 1) % floatingWindow.images.length
                floatingImage.source = floatingWindow.images[floatingWindow.currentIndex]
            }
        }
        // 鼠标悬停效果
        states: [
            State {
                name: "hovered"
                when: mouseArea.containsMouse
                PropertyChanges {
                    target: floatingWindow
                    scale: 1.2
                }
                PropertyChanges {
                    target: floatingShaow
                    scale: 1.2
                }
                PropertyChanges {
                    target: floatingImage
                    scale: 1.2
                }
            }
        ]

        transitions: Transition {
            NumberAnimation {
                property: "scale"
                duration: 300
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
            onEntered: {
                disabledTimer.stop()
                // 鼠标悬停时暂停帮助定时器
                helpBubbleTimer.stop()
                // 隐藏帮助气泡
                if (helpBubble.visible) {
                    helpBubble.hideBubble()
                }
                if(!scoreDialog.visible){
                    scoreDialog.showDialog()
                }
            }
            onExited: {
                if(scoreDialog.isEntered == false){
                    disabledTimer.start()
                    // 鼠标离开时重启帮助定时器
                    helpBubbleTimer.restart()
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
                    // 打开独立的chat窗口
                    chatWindow.show()
                }
            }
        }
    }

    // 评分方案选择对话框
    Window {
        id: scoreDialog
        width: contentRect.width + 20  // 增加宽度为阴影留出空间
        height: 20  // 增加高度为阴影留出空间
        visible: false
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
        color: "transparent"
        property bool isEntered: false
        property bool animating: false
        property bool isFirst: true
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
                    $chatManager.endAnalysis(true)
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

        // 对话框消息组件
        MessageBox {
            id: dialogMessageBox
            anchors.fill: parent
        }
        HoverHandler {
            id: hover
            acceptedDevices: PointerDevice.Mouse
            onHoveredChanged: {
                if (hover.hovered){
                    scoreDialog.isEntered = true
                    disabledTimer.stop()
                }
                else {
                    scoreDialog.isEntered = false
                    if(!mouseArea.containsMouse){
                        disabledTimer.start()
                    }
                }
            }
        }
        // —— 动画：高度 + 位置 同步推进 ——
        ParallelAnimation {
            id: growAnim
            NumberAnimation {
                id: hAnim
                target: scoreDialog
                property: "height"
                duration: 260
                easing.type: Easing.OutCubic
            }
            NumberAnimation {
                id: yAnim
                target: scoreDialog
                property: "y"
                duration: 260
                easing.type: Easing.OutCubic
            }
        }

        // —— 显示动画：从悬浮窗吐出效果 ——
        ParallelAnimation {
            id: showAnim
            NumberAnimation {
                target: contentRect
                property: "scale"
                from: 0.1
                to: 1.0
                duration: 400
                easing.type: Easing.OutBack
            }
            NumberAnimation {
                target: contentRect
                property: "opacity"
                from: 0.0
                to: 1.0
                duration: 300
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                id: showXAnim
                target: scoreDialog
                property: "x"
                duration: 400
                easing.type: Easing.OutBack
            }
            NumberAnimation {
                id: showYAnim
                target: scoreDialog
                property: "y"
                duration: 400
                easing.type: Easing.OutBack
            }
            onFinished: {
                // 动画完成后，恢复正常的跟随行为
                scoreDialog.animating = false
            }
        }

        // —— 隐藏动画：吸回悬浮窗效果 ——
        ParallelAnimation {
            id: hideAnim
            NumberAnimation {
                target: contentRect
                property: "scale"
                from: 1.0
                to: 0.1
                duration: 300
                easing.type: Easing.InBack
            }
            NumberAnimation {
                target: contentRect
                property: "opacity"
                from: 1.0
                to: 0.0
                duration: 200
                easing.type: Easing.InQuad
            }
            NumberAnimation {
                id: hideXAnim
                target: scoreDialog
                property: "x"
                duration: 300
                easing.type: Easing.InBack
            }
            NumberAnimation {
                id: hideYAnim
                target: scoreDialog
                property: "y"
                duration: 300
                easing.type: Easing.InBack
            }
            onFinished: {
                scoreDialog.visible = false
                scoreDialog.animating = false
                // 恢复正常缩放和透明度
                contentRect.scale = 1.0
                contentRect.opacity = 1.0
                // 对话框隐藏后重启帮助定时器
                if (!mouseArea.containsMouse) {
                    helpBubbleTimer.restart()
                }
            }
        }

        // 计算悬浮窗的外接矩形
        function _floatingRect() {
            return Qt.rect(
                        mainWindow.x + (mainWindow.width - floatingWindow.width) / 2,
                        mainWindow.y + (mainWindow.height - floatingWindow.height) / 2,
                        floatingWindow.width,
                        floatingWindow.height
                    )
        }

        // 仅跟随悬浮窗移动（不改高度、不播放动画）
        function followFloatingInstantly() {
            if (!visible) return

            // 如果正在动画，停止动画并立即跟随（拖动时优先跟随）
            if (animating) {
                showAnim.stop()
                hideAnim.stop()
                animating = false
                // 恢复正常状态
                contentRect.scale = 1.0
                contentRect.opacity = 1.0
            }

            var fr = _floatingRect()
            var newX = fr.x + fr.width - (width - 10)
            var newY = fr.y - height

            newX = Math.max(-width + 100, Math.min(newX, Screen.width - 100))
            newY = Math.min(newY, Screen.height - 50)

            x = newX
            y = newY
        }

        // 依据内容新高度，height 与 y 同步动画（"从下往上长高"）
        function relayoutAndAnimate() {
            if (!visible || animating) return  // 动画期间不执行

            var newHeight = contentRect.height + 20     // 你原来 Window 的边距留白
            var fr = _floatingRect()
            var newX = fr.x + fr.width - (width - 10)
            var newY = fr.y - newHeight                 // 底边贴住悬浮窗上方

            newX = Math.max(-width + 100, Math.min(newX, Screen.width - 100))
            newY = Math.min(newY, Screen.height - 50)

            // 停止旧动画，设置目标，一起开跑
            growAnim.stop()
            x = newX                 // x 直接到位，不需要动画
            hAnim.to = newHeight
            yAnim.to = newY
            // 若目标与当前相同就不必启动动画
            if (height !== newHeight || y !== newY)
                growAnim.start()
        }

        // —— 打开对话框：带动画效果，从悬浮窗吐出 ——
        function showDialog() {
            if (animating) return  // 防止动画期间重复调用
            // 显示对话框时暂停帮助定时器并隐藏气泡
            helpBubbleTimer.stop()
            if (helpBubble.visible) {
                helpBubble.hideBubble()
            }
            if(!scoreDialog.isFirst){
                animating = true
                visible = true
                contentRect.opacity = 0
            }
            // 延迟一帧，确保内容组件完全加载和布局更新
            Qt.callLater(function() {
                if(scoreDialog.isFirst){
                    animating = true
                    visible = true
                    scoreDialog.isFirst = false
                }
                // 计算悬浮窗中心位置作为动画起始点
                var fr = _floatingRect()
                var floatingCenterX = fr.x + fr.width / 2
                var floatingCenterY = fr.y + fr.height / 2

                // 设置正确的高度，现在内容组件应该已经更新了
                height = contentRect.height + 20

                // 设置初始状态（在悬浮窗位置，小尺寸）
                contentRect.scale = 0.1
                contentRect.opacity = 0.0
                x = floatingCenterX - width / 2
                y = floatingCenterY - height / 2

                // 计算目标位置
                var targetX = fr.x + fr.width - (width - 10)
                var targetY = fr.y - height

                // 边界检查
                targetX = Math.max(-width + 100, Math.min(targetX, Screen.width - 100))
                targetY = Math.min(targetY, Screen.height - 50)

                // 设置动画目标并启动
                showXAnim.to = targetX  // x动画
                showYAnim.to = targetY  // y动画
                showAnim.start()
            })
        }

        // —— 隐藏对话框：带动画效果，吸回悬浮窗 ——
        function hideDialog() {
            if (animating) return  // 防止动画期间重复调用

            animating = true

            // 计算悬浮窗中心位置作为动画终点
            var fr = _floatingRect()
            var floatingCenterX = fr.x + fr.width / 2
            var floatingCenterY = fr.y + fr.height / 2

            // 设置动画目标并启动
            hideXAnim.to = floatingCenterX - width / 2  // x动画
            hideYAnim.to = floatingCenterY - height / 2  // y动画
            hideAnim.start()
        }

        // === 连接：悬浮窗移动时“瞬时”跟随 ===
        Connections {
            target: mainWindow
            function onXChanged() { scoreDialog.followFloatingInstantly() }
            function onYChanged() { scoreDialog.followFloatingInstantly() }
        }

        // === 连接：内容高度发生变化时，触发“同步动画上长” ===
        Connections {
            target: contentRect
            function onHeightChanged() { scoreDialog.relayoutAndAnimate() }
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
                id:scoreDialogMouseArea
                anchors.fill: parent
                z: -1
                onPressed: {
                    if (contextMenu.visible) {
                        contextMenu.hide()
                    }
                }
            }
            // 监听页面切换
            onCurrentIndexChanged: {
                if(currentIndex == 1){
                    $historyManager.updateList()
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
                                    // 拖动悬浮窗，对话框会通过自动跟随
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
                                scoreDialog.hideDialog()
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
                    chatManager: $chatManager
                    onExitScore: {
                        contentRect.currentScore = -1
                    }
                }
                REPORT{
                    id:reportView
                    visible: contentRect.currentIndex === 0 && contentRect.currentScore === 7
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
                    scoringMethodDialog.showDialog()
                }
            }
            function onMouseEvent(){
                if(tnmBtn.containsMouse || renalBtn.containsMouse){
                    return
                }
                scoringMethodDialog.hideDialog()
            }
        }

        function showDialog() {
            // 计算弹窗位置
            $loginManager.changeMouseStatus(true)
            updateDialogPosition()
            // 暂停帮助定时器
            helpBubbleTimer.stop()
            if (helpBubble.visible) {
                helpBubble.hideBubble()
            }
            visible = true
            opacity = 1
            autoHideTimer.restart()
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
            $loginManager.changeMouseStatus(false)
            autoHideTimer.stop()
            opacity = 0
            visible = false
            // 清理上次处理的文本记录，允许相同文本再次触发
            lastProcessedText = ""
            // 重启帮助定时器
            if (!scoreDialog.visible && !contextMenu.visible && !chatWindow.visible) {
                helpBubbleTimer.restart()
            }
        }

        Rectangle {
            id: scoringMethodContent
            width: 200
            height: 100
            color: "white"
            radius: 16
            scale: scoringMethodDialog.opacity
            anchors.centerIn: parent
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
                spacing: 12

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
                    spacing: 8
                    CustomButton {
                        id:tnmBtn
                        width: 80
                        height: 32
                        text:"TNM"
                        backgroundColor: "#FF490D"
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
                    CustomButton {
                        id:renalBtn
                        width: 80
                        height: 32
                        backgroundColor: "#5792FF"
                        text: "RENAL"
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

    // 右键菜单
    Window {
        id: contextMenu
        width: menuBackground.width + 15
        height: menuBackground.height + 15
        visible: false
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
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
            var globalX = mainWindow.x + mouseX + 15
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

            // 暂停帮助定时器
            helpBubbleTimer.stop()
            if (helpBubble.visible) {
                helpBubble.hideBubble()
            }

            x = menuX
            y = menuY
            visible = true
            requestActivate()
        }

        // 隐藏菜单
        function hide() {
            visible = false
            // 重启帮助定时器
            if (!scoreDialog.visible && !scoringMethodDialog.visible && !chatWindow.visible) {
                helpBubbleTimer.restart()
            }
        }

        Rectangle {
            id: menuBackground
            width: Math.max(Math.max(contentArea1.width, contentArea2.width), Math.max(contentArea3.width, contentArea4.width)) + 24
            height: menuColumn.height
            color: "#FFFFFF"
            radius: 8
            anchors.centerIn: parent
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
                width: parent.width
                // 语言切换选项
                Rectangle {
                    width: parent.width
                    height: 40
                    color: languageMouseArea.containsMouse ? "#F5F5F5" : "transparent"
                    radius: 6

                    Row {
                        id: contentArea1
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // 语言图标
                        Image{
                            anchors.verticalCenter: parent.verticalCenter
                            source: "qrc:/image/language.png"
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 14
                            color: languageMouseArea.containsMouse ? "#006BFF" : "#D9000000"
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
                    width: parent.width
                    height: 40
                    color: dialogMouseArea.containsMouse ? "#F5F5F5" : "transparent"
                    radius: 6

                    Row {
                        id: contentArea2
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // 弹窗图标
                        Image{
                            anchors.verticalCenter: parent.verticalCenter
                            source: "qrc:/image/popup.png"
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 14
                            color: dialogMouseArea.containsMouse ? "#006BFF" : "#D9000000"
                            text: qsTr("划词弹窗") + " (" + ($loginManager.showDialogOnTextSelection ? qsTr("开启") : qsTr("关闭")) + ")"

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
                    width: parent.width
                    height: 40
                    color: ocrMouseArea.containsMouse ? "#F5F5F5" : "transparent"
                    radius: 6

                    Row {
                        id: contentArea3
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // 截图图标
                        Image{
                            anchors.verticalCenter: parent.verticalCenter
                            source: "qrc:/image/screenshoot.png"
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 14
                            color: ocrMouseArea.containsMouse ? "#006BFF" : "#D9000000"
                            text: qsTr("截图分析")

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
                        cursorShape: Qt.PointingHandCursor
                        onClicked: {
                            contextMenu.hide()
                            screenshotSelector.startSelection()
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
                        id: contentArea4
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // 退出图标
                        Image{
                            anchors.verticalCenter: parent.verticalCenter
                            source: "qrc:/image/exit.png"
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 14
                            color: exitMouseArea.containsMouse ? "#FF5132" : "#D9000000"
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

    // 独立的Chat窗口
    Window {
        id: chatWindow
        width: 520 + 20
        height: chatWindowContent.height + 20 + 12
        visible: false
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
        color: "transparent"

        // 监听窗口显示状态变化
        onVisibleChanged: {
            if (visible) {
                // 窗口显示时暂停帮助定时器
                helpBubbleTimer.stop()
                if (helpBubble.visible) {
                    helpBubble.hideBubble()
                }
            } else {
                // 窗口隐藏时重启帮助定时器
                if (!scoreDialog.visible && !scoringMethodDialog.visible && !contextMenu.visible) {
                    helpBubbleTimer.restart()
                }
            }
        }

        // 记录窗口是否被用户拖拽过
        property bool isDragged: false
        property real centerY: Screen.height / 2  // 记录窗口中心Y坐标

        // 窗口居中显示
        x: (Screen.width - width) / 2
        y: centerY - height / 2

        // 高度和y坐标同步动画
        Behavior on height {
            NumberAnimation {
                id: heightchange
                duration: 300
                easing.type: Easing.OutCubic
            }
        }

        // 监听高度变化，实时调整y坐标保持中心点不变
        // 移除y的Behavior，让y跟随高度变化同步更新
        onHeightChanged: {
            // 直接设置y坐标，不使用动画，这样y会跟随高度的动画进度同步变化
            y = centerY - height / 2
        }
        // 窗口阴影
        DropShadow {
            anchors.fill: chatWindowBackground
            source: chatWindowBackground
            horizontalOffset: 0
            verticalOffset: 0
            radius: 16
            color: "#1F1A1A1A"
            samples: 32
        }

        // 窗口内容背景
        Rectangle {
            id: chatWindowBackground
            width: 520
            height: chatWindowContent.height + 12
            anchors.centerIn: parent
            color: "#ffffff"
            radius: 16
            Column{
                anchors.fill: parent
                Rectangle{
                    color: "transparent"
                    height: 16
                    width: parent.width

                    // 拖动提示横线
                    Rectangle {
                        width: 40
                        height: 2
                        anchors.centerIn: parent
                        color: "#D0D0D0"
                        radius: 1
                    }

                    // 添加拖动功能
                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.SizeAllCursor

                        property point lastMousePos

                        onPressed: {
                            lastMousePos = Qt.point(mouse.x, mouse.y)
                        }

                        onPositionChanged: {
                            if (pressed) {
                                var dx = mouse.x - lastMousePos.x
                                var dy = mouse.y - lastMousePos.y

                                var newX = chatWindow.x + dx
                                var newY = chatWindow.y + dy

                                // 限制窗口在屏幕范围内
                                newX = Math.max(0, Math.min(newX, Screen.width - chatWindow.width))
                                newY = Math.max(0, Math.min(newY, Screen.height - chatWindow.height))

                                chatWindow.x = newX
                                chatWindow.y = newY

                                // 标记为已拖拽，并更新中心Y坐标
                                chatWindow.isDragged = true
                                chatWindow.centerY = newY + chatWindow.height / 2
                            }
                        }
                    }
                }
                // 使用CHAT组件，指定使用独立的ChatManager
                CHAT {
                    id: chatWindowContent
                    messageManager: chatWindowMessageBox
                    chatManager: $independentChatManager  // 使用独立的ChatManager实例
                    specialPage: true
                    // 重写exitScore信号处理，关闭窗口而不是返回主界面
                    onExitScore: {
                        chatWindow.close()
                    }
                }
            }
            // 独立的消息组件
            MessageBox {
                id: chatWindowMessageBox
                anchors.fill: parent
            }
        }
    }

    // 帮助气泡提示窗口
    Window {
        id: helpBubble
        width: helpBubbleContent.width + 20
        height: helpBubbleContent.height + 20
        visible: false
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
        color: "transparent"
        opacity: 0

        // 透明度动画
        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutQuad
            }
        }

        // 缩放动画
        property real bubbleScale: 0.8
        Behavior on bubbleScale {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutBack
            }
        }

        // 自动隐藏定时器 - 5秒后隐藏
        Timer {
            id: autoHideBubbleTimer
            interval: 5000
            repeat: false
            onTriggered: {
                helpBubble.hideBubble()
            }
        }

        function showBubble() {
            // 计算气泡位置 - 显示在悬浮窗上方
            var floatingRect = Qt.rect(
                mainWindow.x + (mainWindow.width - floatingWindow.width) / 2,
                mainWindow.y + (mainWindow.height - floatingWindow.height) / 2,
                floatingWindow.width,
                floatingWindow.height
            )

            var bubbleX = floatingRect.x + floatingRect.width / 2 - width / 2
            var bubbleY = floatingRect.y - height

            // 边界检查
            bubbleX = Math.max(10, Math.min(bubbleX, Screen.width - width - 10))
            bubbleY = Math.max(10, bubbleY)

            x = bubbleX
            y = bubbleY

            visible = true
            opacity = 1
            bubbleScale = 1.0
            autoHideBubbleTimer.restart()
        }

        function hideBubble() {
            autoHideBubbleTimer.stop()
            opacity = 0
            bubbleScale = 0.8
            // 延迟隐藏窗口
            Qt.callLater(function() {
                visible = false
            })
        }

        // 气泡内容背景
        Rectangle {
            id: helpBubbleContent
            width: 180
            height: 60
            color: "#FFFFFF"
            radius: 20
            scale: helpBubble.bubbleScale
            anchors.centerIn: parent

            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 0
                radius: 16
                color: "#40000000"
                samples: 32
                transparentBorder: true
            }

            // 气泡尖角
            Canvas {
                id: bubbleTriangle
                width: 20
                height: 10
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.top: parent.bottom
                anchors.topMargin: -1

                onPaint: {
                    var ctx = getContext("2d")
                    ctx.reset()
                    ctx.fillStyle = "#FFFFFF"
                    ctx.beginPath()
                    ctx.moveTo(0, 0)
                    ctx.lineTo(width / 2, height)
                    ctx.lineTo(width, 0)
                    ctx.closePath()
                    ctx.fill()
                }
            }

            // 气泡文字内容
            Column {
                anchors.centerIn: parent
                spacing: 4

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.pixelSize: 14
                    font.weight: Font.BOLD
                    color: "#D9000000"
                    text: qsTr("请问需要什么帮助嘛？")
                }

                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.pixelSize: 12
                    color: "#73000000"
                    text: qsTr("点击或触碰悬浮窗开始使用")
                }
            }

            // 点击气泡关闭
            MouseArea {
                anchors.fill: parent
                cursorShape: Qt.PointingHandCursor
                onClicked: {
                    helpBubble.hideBubble()
                    // 点击气泡后打开主对话框
                    if (!scoreDialog.visible) {
                        scoreDialog.showDialog()
                    }
                }
            }
        }
    }
}
