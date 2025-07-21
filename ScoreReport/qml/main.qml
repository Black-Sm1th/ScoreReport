import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import "./components"
ApplicationWindow {
    id: mainWindow
    visible: true
    
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
    width: 62
    height: 62
    
    // 初始位置设置在屏幕右下角
    x: Screen.width - width - 50
    y: Screen.height - height - 50
    
    title: qsTr("悬浮助手")

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
        }
    }
    
    // 评分方案选择对话框
    Window {
        id: scoreDialog
        width: 520
        height: contentRect.height
        visible: false
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint
        color: "transparent"
        
        // // 位置更新定时器
        // Timer {
        //     id: positionUpdateTimer
        //     interval: 50
        //     repeat: false
        //     onTriggered: {
        //         if (scoreDialog.visible) {
        //             scoreDialog.updateDialogPosition()
        //         }
        //     }
        // }
        
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
                    scoreDialog.updateDialogPosition()
                }
            }
            function onYChanged() {
                if (scoreDialog.visible) {
                    scoreDialog.updateDialogPosition()
                }
            }
        }
        
        // 计算对话框位置的函数
        function updateDialogPosition() {
            // 如果内容高度还没有确定，跳过位置更新
            if (contentRect.height <= 0) {
                return
            }
            
            var floatingRect = Qt.rect(
                        mainWindow.x + (mainWindow.width - floatingWindow.width) / 2,
                        mainWindow.y + (mainWindow.height - floatingWindow.height) / 2,
                        floatingWindow.width,
                        floatingWindow.height
                        )
            
            var dialogHeight = contentRect.height
            var spaceAbove = floatingRect.y
            var spaceBelow = Screen.height - (floatingRect.y + floatingRect.height)
            
            // 默认优先显示在上方，如果上方空间不够再考虑下方
            if (spaceAbove >= dialogHeight + 8) {
                // 显示在悬浮窗上方，右侧对齐
                x = floatingRect.x + floatingRect.width - width
                y = floatingRect.y - dialogHeight - 8
            } else if (spaceBelow >= dialogHeight + 8) {
                // 显示在悬浮窗下方，右侧对齐
                x = floatingRect.x + floatingRect.width - width
                y = floatingRect.y + floatingRect.height + 8
            } else {
                // 如果上下空间都不够，优先选择上方（允许出屏幕）
                x = floatingRect.x + floatingRect.width - width
                y = floatingRect.y - dialogHeight - 8
            }
            
            // scoreDialog允许出屏幕，只确保X坐标在合理范围内
            x = Math.max(-width + 100, Math.min(x, Screen.width - 100))
            // Y坐标允许出屏幕上方，但不允许完全超出下方
            y = Math.min(y, Screen.height - 50)
        }
        
        property bool isFirstShow: true
        
        // 透明度动画
        Behavior on opacity {
            NumberAnimation {
                duration: 150
                easing.type: Easing.OutQuad
            }
        }
        
        function showDialog() {
            if (contentRect.height <= 0 && isFirstShow) {
                // 第一次显示且内容未渲染时，先隐藏显示进行预渲染
                opacity = 0
                visible = true
                isFirstShow = false
            } else {
                // 后续显示或内容已渲染时，直接计算位置并显示
                scoreDialog.updateDialogPosition()
                opacity = 1
                visible = true
            }
        }
        
        Rectangle {
            id: contentRect
            width: parent.width
            height: contentColumn.height
            color: "white"
            radius: 20
            property int currentIndex: 2
            property int currentScore: -1
            
            // 监听页面切换，重新计算位置
            onCurrentIndexChanged: {
                if (scoreDialog.visible) {
                    // 使用Timer延迟更新位置，确保新页面内容已渲染
                    scoreDialog.updateDialogPosition()
                }
            }
            
            // 监听高度变化，当内容加载完成后更新位置
            onHeightChanged: {
                if (scoreDialog.visible && height > 0) {
                    // 使用Timer确保位置更新的稳定性
                    scoreDialog.updateDialogPosition()
                    
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
                    Row {
                        id: title
                        anchors.left: parent.left
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.leftMargin: 17
                        spacing: 8
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
                            if($loginManager.currentUserName === ""){
                                dialogMessageBox.warning("请先登录！")
                                return
                            }
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
                    }
                    
                    Button {
                        id: titleClose
                        anchors.right: parent.right
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.rightMargin: 15
                        width: 28
                        height: 28
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
                        contentRect.currentScore = index
                    }
                }
                UserView{
                    visible: contentRect.currentIndex === 2
                    messageManager: dialogMessageBox
                }
                CCLS{
                    visible: contentRect.currentIndex === 0 && contentRect.currentScore === 1
                    messageManager: dialogMessageBox
                    onExitScore: {
                        contentRect.currentScore = -1
                    }
                }
                TNM{
                    visible: contentRect.currentIndex === 0 && contentRect.currentScore === 2
                    messageManager: dialogMessageBox
                    onExitScore: {
                        contentRect.currentScore = -1
                    }
                }
            }
        }
    }
    
    // 右键菜单
    Window {
        id: contextMenu
        width: 120
        height: menuColumn.height
        visible: false
        flags: Qt.FramelessWindowHint | Qt.WindowStaysOnTopHint | Qt.Popup
        color: "transparent"
        
        // 失去焦点时自动隐藏
        onActiveFocusItemChanged: {
            if (!activeFocusItem) {
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
            anchors.fill: parent
            color: "#FFFFFF"
            radius: 8
            border.color: "#E0E0E0"
            border.width: 1
            
            // 添加阴影效果
            layer.enabled: true
            layer.effect: DropShadow {
                horizontalOffset: 0
                verticalOffset: 2
                radius: 8
                samples: 16
                color: "#20000000"
            }
            
            Column {
                id: menuColumn
                width: parent.width
                
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
                            text: "退出程序"
                            
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
                            Qt.quit()
                        }
                    }
                }
            }
        }
    }
}
