import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import "./components"
ApplicationWindow {
    id: mainWindow
    visible: true
    
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
            
            property point lastMousePos
            property bool isDragging: false
            cursorShape: Qt.PointingHandCursor
            onPressed: {
                lastMousePos = Qt.point(mouse.x, mouse.y)
                isDragging = false
            }
            
            onPositionChanged: {
                if (pressed) {
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
                // 只有在没有拖动的情况下才响应点击
                if (!isDragging) {
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
            
            // 检查上方是否有足够空间（对话框高度 + 8px间距）
            if (spaceAbove >= dialogHeight + 8) {
                // 显示在悬浮窗上方，右侧对齐
                x = floatingRect.x + floatingRect.width - width
                y = floatingRect.y - dialogHeight - 8
            } else {
                // 显示在悬浮窗下方，右侧对齐
                x = floatingRect.x + floatingRect.width - width
                y = floatingRect.y + floatingRect.height + 8
            }
            
            // 确保对话框不超出屏幕边界
            x = Math.max(0, Math.min(x, Screen.width - width))
            y = Math.max(0, Math.min(y, Screen.height - height))
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
        
        // 使用估计高度计算位置（用于首次显示）
        function updateDialogPositionWithEstimatedHeight() {
            var floatingRect = Qt.rect(
                        mainWindow.x + (mainWindow.width - floatingWindow.width) / 2,
                        mainWindow.y + (mainWindow.height - floatingWindow.height) / 2,
                        floatingWindow.width,
                        floatingWindow.height
                        )
            
            // 估计对话框高度：头部58px + 内容区域（标题40px + 间距20px + 网格2行*110px + 行间距20px + 边距40px + bottomPadding24px）
            var estimatedHeight = 58 + (40 + 20 + 220 + 20 + 40 + 24)
            var spaceAbove = floatingRect.y
            var spaceBelow = Screen.height - (floatingRect.y + floatingRect.height)
            
            // 检查上方是否有足够空间（对话框高度 + 8px间距）
            if (spaceAbove >= estimatedHeight + 8) {
                // 显示在悬浮窗上方，右侧对齐
                x = floatingRect.x + floatingRect.width - width
                y = floatingRect.y - estimatedHeight - 8
            } else {
                // 显示在悬浮窗下方，右侧对齐
                x = floatingRect.x + floatingRect.width - width
                y = floatingRect.y + floatingRect.height + 8
            }
            
            // 确保对话框不超出屏幕边界
            x = Math.max(0, Math.min(x, Screen.width - width))
            y = Math.max(0, Math.min(y, Screen.height - height))
        }
        
        Rectangle {
            id: contentRect
            width: parent.width
            height: contentColumn.height
            color: "white"
            radius: 20
            property int currentIndex: 2
            // 监听高度变化，当内容加载完成后更新位置
            onHeightChanged: {
                if (scoreDialog.visible && height > 0) {
                    // 使用实际高度更新位置
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
                        selectedIndex: 2
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
                    anchors.bottomMargin: 16
                }
                HomeView {
                    visible: contentRect.currentIndex === 0
                    messageManager: dialogMessageBox
                }
                UserView{
                    visible: contentRect.currentIndex === 2
                    messageManager: dialogMessageBox
                }
                // 分隔线
                Rectangle {
                    width: parent.width
                    height: 24
                    color: "transparent"
                }
            }
        }
    }
}
