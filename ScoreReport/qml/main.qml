import QtQuick 2.15
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
            // 只有在右键菜单不可见的情况下才隐藏scoreDialog
            if (!contextMenu.visible) {
                scoreDialog.hideDialog()
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
        property int currentHoverIndex: 0
        property int currentAppearIndex: 0
        
        // 动画状态：default, hover1, hover2, appear1, appear2
        property string animationState: "appear1"
        property int currentFrame: 0
        
        // 各动画的帧数
        property var frameCount: {
            "default": 50,
            "hover1": 50,
            "hover2": 50,
            "appear1": 112,
            "appear2": 165
        }
        
        // 动画定时器
        Timer {
            id: frameTimer
            interval: 50  // 20fps
            repeat: true
            running: true
            onTriggered: {
                var maxFrame = floatingWindow.frameCount[floatingWindow.animationState]
                
                // 先更新图片源（显示当前帧）
                var paddedFrame = ("000" + floatingWindow.currentFrame).slice(-3)
                floatingImage.source = "qrc:/image/" + floatingWindow.animationState + "/" + paddedFrame + ".png"
                
                // 然后递增帧数
                floatingWindow.currentFrame++
                
                // 检查是否到达最后一帧
                if (floatingWindow.currentFrame >= maxFrame) {
                    // 帧播放完毕
                    if (floatingWindow.animationState.indexOf("appear") === 0) {
                        // appear动画播放完切换到default
                        floatingWindow.animationState = "default"
                        floatingWindow.currentFrame = 0
                    } else {
                        // hover和default循环播放
                        floatingWindow.currentFrame = 0
                    }
                }
            }
        }

        function showHoverImages(){
            if(floatingWindow.animationState === "default"){
                floatingWindow.currentHoverIndex = (floatingWindow.currentHoverIndex + 1) % 2
                floatingWindow.animationState = "hover" + (floatingWindow.currentHoverIndex + 1)
                floatingWindow.currentFrame = 0
            }
        }
        
        function showAppearImages(){
            if(floatingWindow.animationState === "default"){
                floatingWindow.currentAppearIndex = (floatingWindow.currentAppearIndex + 1) % 2
                floatingWindow.animationState = "appear" + (floatingWindow.currentAppearIndex + 1)
                floatingWindow.currentFrame = 0
            }
        }
        
        function showDefaultImages(){
            if(floatingWindow.animationState !== "default"){
                floatingWindow.animationState = "default"
                floatingWindow.currentFrame = 0
            }
        }
        
        // 悬浮窗图标/图片
        Image {
            id: floatingImage
            anchors.fill: parent
            anchors.centerIn: parent
            source: "qrc:/image/appear1/000.png"
            scale: 1.1
            smooth: true
        }
        Timer{
            id: appearTimer
            interval: 5 * 60 * 1000
            repeat: true
            onTriggered: {
                floatingWindow.showAppearImages()
            }
        }
        Component.onCompleted: {
            appearTimer.restart()
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
                if(isDragging){
                    return
                }
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
                floatingWindow.showHoverImages()
            }
            onExited: {
                if(isDragging){
                    return
                }
                if(scoreDialog.isEntered == false && !contextMenu.visible){
                    disabledTimer.start()
                    // 鼠标离开时重启帮助定时器（仅在开启设置时）
                    if ($loginManager.showHelpBubble) {
                        helpBubbleTimer.restart()
                    }
                }
                floatingWindow.showDefaultImages()
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
                isDragging = false
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
                }
                // else if(contentRect.currentScore == 6){
                //     $chatManager.endAnalysis(true)
                // }
                else if(contentRect.currentScore == 7){
                    reportView.resetValues()
                }else if(contentRect.currentScore == 8){
                    knowledgeView.resetValues()
                }else if(contentRect.currentScore == 9){
                    knowledgeChatView.resetValues()
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
                    $independentChatManager.loadKnowledgeBaseList()
                }
            }
            function onLogoutSuccess(){
                // historyView.resetAllValue()
                scoreDialog.resetAllValue()
                $independentChatManager.clearKnowledgeBaseList()
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
                    if(!mouseArea.containsMouse && !contextMenu.visible){
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
                // 对话框隐藏后重启帮助定时器（仅在开启设置时）
                if (!mouseArea.containsMouse && $loginManager.showHelpBubble) {
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
                // 计算悬浮窗位置作为动画起始点
                var fr = _floatingRect()
                var floatingCenterX = fr.x + fr.width / 2

                // 设置正确的高度，现在内容组件应该已经更新了
                height = contentRect.height + 20

                // 设置初始状态（在悬浮窗正上方，小尺寸）
                contentRect.scale = 0.1
                contentRect.opacity = 0.0
                x = floatingCenterX - width / 2
                y = fr.y - height - 10  // 在悬浮窗正上方，留10像素间距

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

            // 计算悬浮窗正上方位置作为动画终点
            var fr = _floatingRect()
            var floatingCenterX = fr.x + fr.width / 2

            // 设置动画目标并启动
            hideXAnim.to = floatingCenterX - width / 2  // x动画
            hideYAnim.to = fr.y - height - 10  // y动画，回到悬浮窗正上方
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
            property int currentIndex: 1
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

            // 更新确认对话框
            ConfirmDialog {
                id: updateConfirmDialog
                title: qsTr("软件更新")
                message: qsTr("发现新版本 %1，是否立即下载并更新？").arg($loginManager.latestVersion)
                confirmText: qsTr("立即更新")
                cancelText: qsTr("稍后提醒")
                visible: false
                recRadius: parent.radius
                onConfirmed: {
                    loadingDialog.show(qsTr("正在下载更新..."))
                    $loginManager.downloadAndInstallUpdate()
                }
            }

            // 清除缓存确认对话框
            ConfirmDialog {
                id: clearCacheConfirmDialog
                title: qsTr("清除缓存")
                message: qsTr("确定要清除所有缓存吗？此操作不可恢复。")
                confirmText: qsTr("确定")
                cancelText: qsTr("取消")
                visible: false
                recRadius: parent.radius
                onConfirmed: {
                    $loginManager.clearAllCache()
                    dialogMessageBox.success(qsTr("缓存清除成功！"))
                }
            }

            // 加载对话框
            LoadingDialog {
                id: loadingDialog
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
            // // 监听页面切换
            // onCurrentIndexChanged: {
            //     if(currentIndex == 1){
            //         $historyManager.updateList()
            //     }
            // }
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
                            // "qrc:/image/history.png",
                            "qrc:/image/user.png"
                        ]
                        iconSelectedSources: [       // 图标数组
                            "qrc:/image/homeSelected.png",
                            // "qrc:/image/historySelected.png",
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
                        }else if(index === 9){
                            knowledgeChatView.resetValue()
                        }
                        contentRect.currentScore = index
                    }
                }
                // HistoryView{
                //     id:historyView
                //     visible: contentRect.currentIndex === 1
                //     messageManager: dialogMessageBox
                //     onToScorer: {
                //         contentRect.currentIndex = 0
                //     }
                // }
                UserView{
                    visible: contentRect.currentIndex === 1
                    messageManager: dialogMessageBox
                }
                // RENAL{
                //     id:renalView
                //     visible: contentRect.currentIndex === 0 && contentRect.currentScore === 0
                //     messageManager: dialogMessageBox
                //     onExitScore: {
                //         contentRect.currentScore = -1
                //     }
                // }
                // CCLS{
                //     id:cclsView
                //     visible: contentRect.currentIndex === 0 && contentRect.currentScore === 1
                //     messageManager: dialogMessageBox
                //     onExitScore: {
                //         contentRect.currentScore = -1
                //     }
                // }
                // TNM{
                //     id:tnmView
                //     visible: contentRect.currentIndex === 0 && contentRect.currentScore === 2
                //     messageManager: dialogMessageBox
                //     onExitScore: {
                //         contentRect.currentScore = -1
                //     }
                // }
                // UCLSMRS{
                //     id:uclsmrsView
                //     visible: contentRect.currentIndex === 0 && contentRect.currentScore === 3
                //     messageManager: dialogMessageBox
                //     onExitScore: {
                //         contentRect.currentScore = -1
                //     }
                // }
                // UCLSCTS{
                //     id:uclsctsView
                //     visible: contentRect.currentIndex === 0 && contentRect.currentScore === 4
                //     messageManager: dialogMessageBox
                //     onExitScore: {
                //         contentRect.currentScore = -1
                //     }
                // }
                KnowledgeChat{
                    id:knowledgeChatView
                    visible: contentRect.currentIndex === 0 && contentRect.currentScore === 9
                    messageManager: dialogMessageBox
                    chatManager: $knowledgeChatManager
                    onExitScore: {
                        contentRect.currentScore = -1
                    }
                }
                // CHAT{
                //     id:chatView
                //     visible: contentRect.currentIndex === 0 && contentRect.currentScore === 6
                //     messageManager: dialogMessageBox
                //     chatManager: $chatManager
                //     onExitScore: {
                //         contentRect.currentScore = -1
                //     }
                // }
                Knowledge{
                    id:knowledgeView
                    visible: contentRect.currentIndex === 0 && contentRect.currentScore === 8
                    messageManager: dialogMessageBox
                    loadingDialog: loadingDialog
                    onExitScore: {
                        contentRect.currentScore = -1
                    }
                }
                // REPORT{
                //     id:reportView
                //     visible: contentRect.currentIndex === 0 && contentRect.currentScore === 7
                //     messageManager: dialogMessageBox
                //     onExitScore: {
                //         contentRect.currentScore = -1
                //     }
                // }
            }
        }
    }

    // 评分方式选择对话框
    Window {
        id: scoringMethodDialog
        width: scoringMethodContent.width + 40  // 内容宽度 + 边距
        height: scoringMethodContent.height + 40  // 内容高度 + 边距
        visible: false
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
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

        // 显示延迟定时器，确保位置设置完成后再显示
        Timer {
            id: showDelayTimer
            interval: 100  // 10ms 延迟
            repeat: false
            onTriggered: {
                // 暂停帮助定时器
                helpBubbleTimer.stop()
                if (helpBubble.visible) {
                    helpBubble.hideBubble()
                }
                // 现在显示对话框，位置已经是正确的了
                scoringMethodDialog.opacity = 1
                autoHideTimer.restart()
                scoringMethodDialog.raise()
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
                if(inputArea.containsMouse){
                    return
                }
                scoringMethodDialog.hideDialog()
            }
        }

        function showDialog() {
            // 先计算目标位置（在窗口显示之前）
            var spacing = 10
            var targetX = lastMouseX - width / 2
            var targetY = lastMouseY - height - spacing

            // 边界检查
            if (targetX < 10) {
                targetX = 10
            } else if (targetX + width > Screen.width - 10) {
                targetX = Screen.width - width - 10
            }

            if (targetY < 10) {
                targetY = lastMouseY + spacing
                if (targetY + height > Screen.height - 10) {
                    targetY = (Screen.height - height) / 2
                }
            }

            if (targetY + height > Screen.height - 10) {
                targetY = Screen.height - height - 10
            }

            // 在显示窗口之前设置位置和透明度
            x = targetX
            y = targetY
            opacity = 0
            visible = true
            
            // 使用延迟定时器确保位置设置完成后再显示
            showDelayTimer.restart()
        }

        function hideDialog() {
            $loginManager.changeMouseStatus(false)
            autoHideTimer.stop()
            showDelayTimer.stop()  // 停止延迟显示定时器
            opacity = 0
            visible = false
            // 清理上次处理的文本记录，允许相同文本再次触发
            lastProcessedText = ""
            // 重启帮助定时器（仅在开启设置时）
            if (!scoreDialog.visible && !contextMenu.visible && !chatWindow.visible && $loginManager.showHelpBubble) {
                helpBubbleTimer.restart()
            }
        }

        Rectangle {
            id: scoringMethodContent
            width: 200
            height: scoringMethodDialogCol.height + 32
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
                id:scoringMethodDialogCol
                anchors.centerIn: parent
                spacing: 8

                // 标题
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.pixelSize: 16
                    font.weight: Font.Medium
                    color: "#D9000000"
                    text: qsTr("看看我能帮您做哪些吧?")
                }

                // // 按钮组
                // Row {
                //     anchors.horizontalCenter: parent.horizontalCenter
                //     spacing: 8
                //     CustomButton {
                //         id:tnmBtn
                //         width: 80
                //         height: 32
                //         text:"TNM"
                //         backgroundColor: "#FF490D"
                //         onClicked: {
                //             scoringMethodDialog.hideDialog()
                //             // 切换到主页面并选择TNM评分
                //             scoreDialog.resetAllValue()
                //             contentRect.currentIndex = 0
                //             contentRect.currentScore = 2  // TNM对应索引2
                //             $loginManager.copyToClipboard(scoringMethodDialog.currentText)
                //             if($tnmManager.checkClipboard()){
                //                 $tnmManager.startAnalysis()
                //             }else{
                //                 messageManager.warning(qsTr("剪贴板为空，请先复制内容"))
                //             }
                //             if(!scoreDialog.visible){
                //                 scoreDialog.showDialog()
                //             }
                //         }
                //     }
                //     CustomButton {
                //         id:renalBtn
                //         width: 80
                //         height: 32
                //         backgroundColor: "#5792FF"
                //         text: "RENAL"
                //         onClicked: {
                //             // 点击RENAL按钮时隐藏右键菜单
                //             if (contextMenu.visible) {
                //                 contextMenu.hide()
                //             }
                //             scoringMethodDialog.hideDialog()
                //             // 切换到主页面并选择RENAL评分
                //             scoreDialog.resetAllValue()
                //             contentRect.currentIndex = 0
                //             contentRect.currentScore = 0  // RENAL对应索引0
                //             $loginManager.copyToClipboard(scoringMethodDialog.currentText)
                //             if($renalManager.checkClipboard()){
                //                 $renalManager.startAnalysis()
                //             }else{
                //                 messageManager.warning(qsTr("剪贴板为空，请先复制内容"))
                //             }
                //             if(!scoreDialog.visible){
                //                 scoreDialog.showDialog()
                //             }
                //         }
                //     }
                // }

                SingleLineTextInput{
                    id: questionInput
                    inputWidth: 168
                    inputHeight: 32
                    backgroundColor: "#ffffff"
                    borderColor: "#E6EAF2"
                    fontSize: 14
                    placeholderText: "请输入您的问题..."
                    Keys.onPressed: {
                        if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            if(questionInput.text === ""){
                                return
                            }
                            var text = scoringMethodDialog.currentText + "\n" + questionInput.text
                            scoringMethodDialog.hideDialog()
                            chatWindow.show()
                            chatWindowContent.sendText(text)
                            questionInput.text = ""
                        }
                    }
                    onFocusChanged: {
                        if (hasFocus) {
                            // 输入框获得焦点时停止自动隐藏定时器
                            autoHideTimer.stop()
                        } else {
                            // 输入框失去焦点时重新启动自动隐藏定时器
                            autoHideTimer.restart()
                        }
                    }
                    onTextChanged: {
                        // 用户正在输入时停止自动隐藏定时器
                        autoHideTimer.stop()
                    }
                    MouseArea{
                        id: inputArea
                        anchors.fill: parent
                        hoverEnabled: true
                        acceptedButtons: Qt.LeftButton
                        cursorShape: Qt.IBeamCursor
                        onClicked: {
                            // 点击输入框区域时强制聚焦
                            questionInput.forceActiveFocus()
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
            // 右键菜单关闭时，如果scoreDialog可见且鼠标不在scoreDialog和悬浮窗上，启动关闭定时器
            if (scoreDialog.visible && !scoreDialog.isEntered && !mouseArea.containsMouse) {
                disabledTimer.start()
            }
            // 重启帮助定时器（仅在开启设置时）
            if (!scoreDialog.visible && !scoringMethodDialog.visible && !chatWindow.visible && $loginManager.showHelpBubble) {
                helpBubbleTimer.restart()
            }
        }

        Rectangle {
            id: menuBackground
            width: contentArea2.width + 24
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
                // // 语言切换选项
                // Rectangle {
                //     width: parent.width
                //     height: 40
                //     color: languageMouseArea.containsMouse ? "#F5F5F5" : "transparent"
                //     radius: 6

                //     Row {
                //         id: contentArea1
                //         anchors.left: parent.left
                //         anchors.leftMargin: 12
                //         anchors.verticalCenter: parent.verticalCenter
                //         spacing: 8

                //         // 语言图标
                //         Image{
                //             anchors.verticalCenter: parent.verticalCenter
                //             source: "qrc:/image/language.png"
                //         }

                //         Text {
                //             anchors.verticalCenter: parent.verticalCenter
                //             font.family: "Alibaba PuHuiTi 3.0"
                //             font.pixelSize: 14
                //             color: languageMouseArea.containsMouse ? "#006BFF" : "#D9000000"
                //             text: qsTr("语言") + " (" + (languageManager ? qsTr(languageManager.getLanguageDisplayName(languageManager.currentLanguage)) : qsTr("中文")) + ")"

                //             Behavior on color {
                //                 ColorAnimation {
                //                     duration: 150
                //                     easing.type: Easing.OutQuad
                //                 }
                //             }
                //         }
                //     }

                //     MouseArea {
                //         id: languageMouseArea
                //         anchors.fill: parent
                //         hoverEnabled: true
                //         cursorShape: Qt.PointingHandCursor

                //         onClicked: {
                //             if (languageManager) {
                //                 // 切换语言：如果当前是中文，切换到英文；如果是英文，切换到中文
                //                 if (languageManager.currentLanguage === "zh") {
                //                     languageManager.setCurrentLanguage("en")
                //                 } else {
                //                     languageManager.setCurrentLanguage("zh")
                //                 }
                //             }
                //             contextMenu.hide()
                //         }
                //     }
                // }

                // // 分隔线
                // Rectangle {
                //     width: parent.width - 16
                //     height: 1
                //     anchors.horizontalCenter: parent.horizontalCenter
                //     color: "#E0E0E0"
                // }

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

                // 聊天气泡控制选项
                Rectangle {
                    width: parent.width
                    height: 40
                    color: helpBubbleMouseArea.containsMouse ? "#F5F5F5" : "transparent"
                    radius: 6

                    Row {
                        id: contentAreaHelpBubble
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // 聊天气泡图标
                        Image{
                            anchors.verticalCenter: parent.verticalCenter
                            source: "qrc:/image/chatBubble.png"
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 14
                            color: helpBubbleMouseArea.containsMouse ? "#006BFF" : "#D9000000"
                            text: qsTr("聊天气泡") + " (" + ($loginManager.showHelpBubble ? qsTr("开启") : qsTr("关闭")) + ")"

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: helpBubbleMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            // 切换聊天气泡显示设置
                            var newSetting = !$loginManager.showHelpBubble
                            $loginManager.saveHelpBubbleSetting(newSetting)
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

                // // 截图识字选项
                // Rectangle {
                //     width: parent.width
                //     height: 40
                //     color: ocrMouseArea.containsMouse ? "#F5F5F5" : "transparent"
                //     radius: 6

                //     Row {
                //         id: contentArea3
                //         anchors.left: parent.left
                //         anchors.leftMargin: 12
                //         anchors.verticalCenter: parent.verticalCenter
                //         spacing: 8

                //         // 截图图标
                //         Image{
                //             anchors.verticalCenter: parent.verticalCenter
                //             source: "qrc:/image/screenshoot.png"
                //         }

                //         Text {
                //             anchors.verticalCenter: parent.verticalCenter
                //             font.family: "Alibaba PuHuiTi 3.0"
                //             font.pixelSize: 14
                //             color: ocrMouseArea.containsMouse ? "#006BFF" : "#D9000000"
                //             text: qsTr("截图分析")

                //             Behavior on color {
                //                 ColorAnimation {
                //                     duration: 150
                //                     easing.type: Easing.OutQuad
                //                 }
                //             }
                //         }
                //     }

                //     MouseArea {
                //         id: ocrMouseArea
                //         anchors.fill: parent
                //         hoverEnabled: true
                //         cursorShape: Qt.PointingHandCursor
                //         onClicked: {
                //             contextMenu.hide()
                //             screenshotSelector.startSelection()
                //         }
                //     }
                // }

                // // 分隔线
                // Rectangle {
                //     width: parent.width - 16
                //     height: 1
                //     anchors.horizontalCenter: parent.horizontalCenter
                //     color: "#E0E0E0"
                // }
                // 检查更新选项
                Rectangle {
                    width: parent.width
                    height: 40
                    color: updateMouseArea.containsMouse ? "#F5F5F5" : "transparent"
                    radius: 6

                    Row {
                        id: contentArea5
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // 清除缓存图标
                        Image{
                            anchors.verticalCenter: parent.verticalCenter
                            source: "qrc:/image/update.png"  // 使用repeat图标表示重置/清除
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 14
                            color: updateMouseArea.containsMouse ? "#006BFF" : "#D9000000"
                            text: qsTr("检查更新")

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: updateMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            contextMenu.hide()
                            $loginManager.manualCheckForUpdates()
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

                // 清除缓存选项
                Rectangle {
                    width: parent.width
                    height: 40
                    color: clearCacheMouseArea.containsMouse ? "#F5F5F5" : "transparent"
                    radius: 6

                    Row {
                        id: contentArea6
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 8

                        // 清除缓存图标
                        Image{
                            anchors.verticalCenter: parent.verticalCenter
                            source: "qrc:/image/clearCache.png"  // 使用repeat图标表示重置/清除
                        }

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 14
                            color: clearCacheMouseArea.containsMouse ? "#006BFF" : "#D9000000"
                            text: qsTr("清除缓存")

                            Behavior on color {
                                ColorAnimation {
                                    duration: 150
                                    easing.type: Easing.OutQuad
                                }
                            }
                        }
                    }

                    MouseArea {
                        id: clearCacheMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor

                        onClicked: {
                            contextMenu.hide()
                            clearCacheConfirmDialog.show()
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
    // // 截图选择器
    // Window {
    //     id: screenshotSelector
    //     visible: false
    //     flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Tool
    //     color: "transparent"

    //     property bool isSelecting: false
    //     property int startX: 0
    //     property int startY: 0
    //     property int endX: 0
    //     property int endY: 0

    //     // 窗口显示时获得焦点
    //     onVisibleChanged: {
    //         if (visible) {
    //             // 延迟一点确保窗口完全显示后再获得焦点
    //             Qt.callLater(function() {
    //                 screenshotSelector.requestActivate()
    //             })
    //         }
    //     }



    //     function startSelection() {
    //         // 获取屏幕尺寸
    //         var screen = Qt.application.screens[0]
    //         width = screen.width
    //         height = screen.height
    //         x = screen.virtualX
    //         y = screen.virtualY

    //         isSelecting = false
    //         startX = 0
    //         startY = 0
    //         endX = 0
    //         endY = 0

    //         visible = true
    //         raise()
    //         requestActivate()
    //     }

    //     function finishSelection() {
    //         // 立即隐藏窗口，避免蒙层继续阻挡鼠标事件
    //         visible = false
    //         isSelecting = false

    //         var selX = Math.min(startX, endX)
    //         var selY = Math.min(startY, endY)
    //         var selWidth = Math.abs(endX - startX)
    //         var selHeight = Math.abs(endY - startY)

    //         if (selWidth > 10 && selHeight > 10) {
    //             // 使用延迟调用，确保窗口完全隐藏后再处理截图
    //             Qt.callLater(function() {
    //                 $loginManager.processScreenshotArea(selX, selY, selWidth, selHeight)
    //             })
    //         }
    //     }

    //     function cancelSelection() {
    //         isSelecting = false
    //         visible = false
    //         // 重置选择区域
    //         startX = 0
    //         startY = 0
    //         endX = 0
    //         endY = 0
    //     }

    //     // 使用四个矩形来创建带透明选中区域的遮罩
    //     Item {
    //         anchors.fill: parent
    //         focus: true  // 确保能接收键盘事件
    //         Component.onCompleted: {
    //             forceActiveFocus()
    //         }

    //         // 计算选中区域的坐标
    //         property int selX: screenshotSelector.isSelecting ? Math.min(screenshotSelector.startX, screenshotSelector.endX) : 0
    //         property int selY: screenshotSelector.isSelecting ? Math.min(screenshotSelector.startY, screenshotSelector.endY) : 0
    //         property int selWidth: screenshotSelector.isSelecting ? Math.abs(screenshotSelector.endX - screenshotSelector.startX) : 0
    //         property int selHeight: screenshotSelector.isSelecting ? Math.abs(screenshotSelector.endY - screenshotSelector.startY) : 0

    //         // 上方遮罩
    //         Rectangle {
    //             x: 0
    //             y: 0
    //             width: parent.width
    //             height: parent.selY
    //             color: "#80000000"
    //             visible: screenshotSelector.isSelecting && height > 0
    //         }

    //         // 下方遮罩
    //         Rectangle {
    //             x: 0
    //             y: parent.selY + parent.selHeight
    //             width: parent.width
    //             height: parent.height - y
    //             color: "#80000000"
    //             visible: screenshotSelector.isSelecting && height > 0
    //         }

    //         // 左侧遮罩
    //         Rectangle {
    //             x: 0
    //             y: parent.selY
    //             width: parent.selX
    //             height: parent.selHeight
    //             color: "#80000000"
    //             visible: screenshotSelector.isSelecting && width > 0
    //         }

    //         // 右侧遮罩
    //         Rectangle {
    //             x: parent.selX + parent.selWidth
    //             y: parent.selY
    //             width: parent.width - x
    //             height: parent.selHeight
    //             color: "#80000000"
    //             visible: screenshotSelector.isSelecting && width > 0
    //         }

    //         // 选中区域边框（透明区域）
    //         Rectangle {
    //             id: selectionRect
    //             x: parent.selX
    //             y: parent.selY
    //             width: parent.selWidth
    //             height: parent.selHeight
    //             color: "transparent"
    //             border.color: "#00AAFF"
    //             border.width: 2
    //             visible: screenshotSelector.isSelecting

    //             // 选择区域的尺寸显示
    //             Text {
    //                 anchors.bottom: parent.top
    //                 anchors.left: parent.left
    //                 anchors.bottomMargin: 5
    //                 color: "#FFFFFF"
    //                 font.family: "Alibaba PuHuiTi 3.0"
    //                 font.pixelSize: 12
    //                 text: parent.width + " × " + parent.height
    //                 visible: parent.width > 50 && parent.height > 20

    //                 Rectangle {
    //                     anchors.fill: parent
    //                     anchors.margins: -2
    //                     color: "#80000000"
    //                     radius: 2
    //                     z: -1
    //                 }
    //             }
    //         }

    //         // 未开始选择时的全屏遮罩
    //         Rectangle {
    //             anchors.fill: parent
    //             color: "#80000000"
    //             visible: !screenshotSelector.isSelecting
    //         }

    //         MouseArea {
    //             anchors.fill: parent
    //             cursorShape: Qt.CrossCursor
    //             acceptedButtons: Qt.LeftButton | Qt.RightButton
    //             focus: true

    //             onPressed: {
    //                 // 确保获得焦点
    //                 forceActiveFocus()

    //                 if (mouse.button === Qt.RightButton) {
    //                     // 右键直接取消
    //                     screenshotSelector.cancelSelection()
    //                     return
    //                 }

    //                 if (mouse.button === Qt.LeftButton) {
    //                     screenshotSelector.isSelecting = true
    //                     screenshotSelector.startX = mouse.x
    //                     screenshotSelector.startY = mouse.y
    //                     screenshotSelector.endX = mouse.x
    //                     screenshotSelector.endY = mouse.y
    //                 }
    //             }

    //             onPositionChanged: {
    //                 if (screenshotSelector.isSelecting && pressedButtons & Qt.LeftButton) {
    //                     screenshotSelector.endX = mouse.x
    //                     screenshotSelector.endY = mouse.y
    //                 }
    //             }

    //             onReleased: {
    //                 if (mouse.button === Qt.LeftButton && screenshotSelector.isSelecting) {
    //                     screenshotSelector.finishSelection()
    //                 }
    //             }

    //             // MouseArea级别的键盘事件处理
    //             Keys.onEscapePressed: {
    //                 screenshotSelector.cancelSelection()
    //             }
    //         }

    //         // 使用Shortcut组件确保ESC键能被捕获
    //         Shortcut {
    //             sequence: "Escape"
    //             enabled: screenshotSelector.visible
    //             onActivated: {
    //                 screenshotSelector.cancelSelection()
    //             }
    //         }

    //         // 提示文字
    //         Text {
    //             anchors.top: parent.top
    //             anchors.left: parent.left
    //             anchors.margins: 20
    //             color: "#FFFFFF"
    //             font.family: "Alibaba PuHuiTi 3.0"
    //             font.pixelSize: 16
    //             text: qsTr("拖拽选择截图区域，右键或ESC键取消")
    //         }
    //     }
    // }

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
                // 窗口隐藏时重启帮助定时器（仅在开启设置时）
                if (!scoreDialog.visible && !scoringMethodDialog.visible && !contextMenu.visible && $loginManager.showHelpBubble) {
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
            y = Math.max(0, centerY - height / 2)
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
            MouseArea {
                anchors.fill: parent
                z: -1
                onPressed: {
                    if (contextMenu.visible) {
                        contextMenu.hide()
                    }
                }
            }
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
                KnowledgeChat {
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
        property bool isLeft: false
        property bool isFirst: true
        // 应用启动完成后启动帮助定时器
        Component.onCompleted: {
            helpBubble.showBubble()
        }
        
        // 监听showHelpBubble属性变化
        Connections {
            target: $loginManager
            function onShowHelpBubbleChanged() {
                if (!$loginManager.showHelpBubble) {
                    // 如果关闭了聊天气泡设置，立即隐藏当前气泡并停止定时器
                    helpBubbleTimer.stop()
                    autoHideBubbleTimer.stop()
                    if (helpBubble.visible) {
                        helpBubble.hideBubble()
                    }
                } else {
                    // 如果开启了聊天气泡设置，重新启动定时器
                    if (!scoreDialog.visible && !scoringMethodDialog.visible && !contextMenu.visible && !chatWindow.visible) {
                        helpBubbleTimer.restart()
                    }
                }
            }
        }
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

        // 横幅拉出动画 - X方向
        NumberAnimation {
            id: slideAnimation
            target: helpBubble
            property: "x"
            duration: 400
            easing.type: Easing.OutBack
        }

        // 横幅拉出动画 - Y方向
        NumberAnimation {
            id: slideYAnimation
            target: helpBubble
            property: "y"
            duration: 400
            easing.type: Easing.OutBack
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

        // 帮助提示定时器 - 每30秒弹出一次
        Timer {
            id: helpBubbleTimer
            interval: helpBubble.isFirst ? 20000 : 120000  // 2分钟
            repeat: false
            onTriggered: {
                // 只有在没有其他对话框显示时且开启了聊天气泡设置时才显示帮助气泡
                if (!scoreDialog.visible && !scoringMethodDialog.visible && !contextMenu.visible && !chatWindow.visible && $loginManager.showHelpBubble) {
                    helpBubble.isFirst = false
                    helpBubble.showBubble()
                }
            }
        }

        function showBubble() {
            // 选择要显示的消息
            if (helpBubbleContent.isFirstShow) {
                // 第一次显示，使用默认消息
                helpBubbleContent.currentMessage = "我是汇小曦，您的知识库小助理~看看能帮您干些啥？"
                helpBubbleContent.isFirstShow = false
            } else {
                // 非第一次显示，从helpContent中随机选择
                var randomIndex = Math.floor(Math.random() * helpBubbleContent.helpContent.length)
                helpBubbleContent.currentMessage = helpBubbleContent.helpContent[randomIndex]
            }
            contentRow.forceLayout()
            // 计算悬浮窗位置
            var floatingRect = Qt.rect(
                mainWindow.x + (mainWindow.width - floatingWindow.width) / 2,
                mainWindow.y + (mainWindow.height - floatingWindow.height) / 2,
                floatingWindow.width,
                floatingWindow.height
            )

            var bubbleX, bubbleY
            var spacing = 1  // 与悬浮窗的间距

            // 优先显示在左侧
            var leftX = floatingRect.x - width - spacing
            if (leftX >= 10) {
                // 左侧有足够空间
                bubbleX = leftX
                bubbleY = floatingRect.y + (floatingRect.height - height) / 2
            } else {
                // 左侧空间不够，显示在右侧
                bubbleX = floatingRect.x + floatingRect.width + spacing
                bubbleY = floatingRect.y + (floatingRect.height - height) / 2

                // 如果右侧也放不下，回退到上方
                if (bubbleX + width > Screen.width - 10) {
                    bubbleX = floatingRect.x + floatingRect.width / 2 - width / 2
                    bubbleY = floatingRect.y - height - spacing
                }
            }

            // 最终边界检查
            bubbleX = Math.max(10, Math.min(bubbleX, Screen.width - width - 10))
            bubbleY = Math.max(10, Math.min(bubbleY, Screen.height - height - 10))

            // 设置初始位置（横幅拉出效果的起始位置）
            var targetX = bubbleX
            var targetY = bubbleY
            var isHorizontal = false

            // 根据最终位置确定拉出方向和尖角方向
            if (bubbleX < floatingRect.x) {
                // 在左侧，从右向左拉出
                bubbleX = floatingRect.x
                isHorizontal = true
                helpBubble.isLeft = false  // 尖角指向右侧（悬浮窗）
            } else if (bubbleX > floatingRect.x + floatingRect.width) {
                // 在右侧，从左向右拉出
                bubbleX = floatingRect.x + floatingRect.width - width
                isHorizontal = true
                helpBubble.isLeft = true   // 尖角指向左侧（悬浮窗）
            } else {
                // 在上方，从下向上拉出
                bubbleY = floatingRect.y
                isHorizontal = false
                helpBubble.isLeft = false  // 垂直尖角向下
            }

            x = bubbleX
            y = bubbleY
            visible = true
            opacity = 1
            bubbleScale = 1.0

            // 启动拉出动画
            slideAnimation.to = targetX
            slideYAnimation.to = targetY
            slideAnimation.start()
            autoHideBubbleTimer.restart()
            floatingWindow.showHoverImages()
        }

        function hideBubble() {
            autoHideBubbleTimer.stop()
            opacity = 0
            bubbleScale = 0.8
            // 延迟隐藏窗口
            Qt.callLater(function() {
                visible = false
                if ($loginManager.showHelpBubble) {
                    helpBubbleTimer.restart()
                }
                if(!helpBubble.isFirst){
                    floatingWindow.showDefaultImages()
                }
            })
        }

        // 气泡内容背景
        Rectangle {
            id: helpBubbleContent
            width: contentRow.width + 40
            height: 60
            color: "#FFFFFF"
            radius: 61
            scale: helpBubble.bubbleScale
            anchors.centerIn: parent
            property bool isFirstShow: true
            property string currentMessage: "我是汇小曦，您的知识库小助理~看看能帮您干些啥？"
            property var helpContent: [
                "设备科最怕的警报：不是机器宕机，是放射科老师那声‘师傅，您先别走，好像又不行了’的深情呼唤。",
                "一台CT的年度保养费够买一辆车，区别是：车会贬值，而它会‘报错’。",
                "工程师远程调试设备时，那专注的眼神——像极了在给一台精密的电子宠物做心理疏导。",
                "核磁失超？对我们来说，相当于目睹一台印钞机瞬间把自己变成了一块昂贵的冰箱磁铁。",
                "预防性维护报告：字面意思是‘防患于未然’，实际读作‘一份来自设备科的、充满求生欲的预言’。",
                "采购新设备的技术论证会，本质上是一场‘我要最好的’与‘不，你预算不够’的终极哲学辩论。",
                "备件库里那根等了三周的国际快递线缆，它的旅程比你的假期更漫长、更昂贵。",
                "设备科工程师的终极噩梦：凌晨两点，手机响起，电话那头说：‘MR的液氦水平……它在唱歌……",
                "每当水冷机报警，我们都感觉像是在照顾一位身骄肉贵的‘顶级巨星’，它一闹脾气，整个影棚都得停工。",
                "设备验收时的性能检测，堪称工程师的‘高考现场’，手里捏着测试模体，心里念着千万别‘挂科’。",
                "采购新设备的谈判，就是一场‘我们想要太空堡垒’与‘预算只够拼模型’之间的现实版拉锯战。",
                "看到工程师对着电路图沉思，那不是在维修，是在进行一场与机器灵魂的深度对话，偶尔还需要‘驱魔’（更换主板）。",
                "预防性维护就像给设备做‘SPA’，指望它能投桃报李，别在业务最繁忙的时候‘玉体欠安’。",
                "核磁的液氦填充日，是全科的‘重大仪式’，气氛紧张得像在给一颗跳动的心脏做移植手术。",
                "那个价值六位数的备件，在仓库里是‘镇库之宝’，在故障现场是‘救命稻草’，在财务那里是‘心跳回忆’。",
                "设备科的日常：用最专业的工具，拧最精密的螺丝，听最无奈的抱怨——‘怎么又坏了？’",
                "软件系统升级，表面上风平浪静，背地里我们都做好了迎接‘惊喜大礼包’（未知Bug）的万全准备。",
                "每当成功修复一台设备，我们感觉不是修好了一台机器，而是安抚了一个傲娇的‘电子生命体’，成就感爆棚。"
            ]
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 0
                radius: 16
                color: "#40000000"
                samples: 32
                transparentBorder: true
            }

            // 气泡文字内容
            Row {
                id: contentRow
                anchors.centerIn: parent
                spacing: 4
                Image{
                    visible: helpBubble.isLeft
                    source: "qrc:/image/finger.png"
                    rotation: 180
                }
                Text {
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.pixelSize: 16
                    font.weight: Font.Normal
                    color: "#D9000000"
                    text: helpBubbleContent.currentMessage
                }
                Image{
                    visible: !helpBubble.isLeft
                    source: "qrc:/image/finger.png"
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

    // 连接LoginManager的更新信号
    Connections {
        target: $loginManager
        
        // 当有更新可用时显示确认对话框
        function onUpdateAvailable(version, fileName) {
            updateConfirmDialog.show()
        }

        function onNoneUpdateAvailable() {
            dialogMessageBox.info(qsTr("暂无可用的更新！"))
        }

        // 下载完成后的处理
        function onUpdateDownloadCompleted() {
            loadingDialog.updateMessage(qsTr("正在安装更新..."))
        }
        
        // 安装完成后的处理
        function onUpdateInstallationCompleted() {
            loadingDialog.hide()
        }
    }
}
