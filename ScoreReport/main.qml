import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2

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
            source: "qrc:/image/Group.png"
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
                    dialogWindow.visible = true
                }
            }
        }
    }
    
    // 对话框窗口
    Dialog {
        id: dialogWindow
        title: "悬浮助手"
        width: 400
        height: 300
        
        // 对话框位置 - 显示在屏幕上方
        x: (Screen.width - width) / 2
        y: 100
        
        // 设置对话框也始终置顶
        // flags: Qt.WindowStaysOnTopHint
        
        contentItem: Rectangle {
            color: "white"
            
            Column {
                anchors.fill: parent
                anchors.margins: 20
                spacing: 15
                
                Text {
                    text: "您点击了悬浮助手！"
                    font.pixelSize: 18
                    font.bold: true
                    color: "#333333"
                }
                
                Text {
                    text: "这是一个屏幕悬浮助手，可以在整个屏幕范围内拖动。"
                    font.pixelSize: 14
                    color: "#666666"
                    wrapMode: Text.WordWrap
                    width: parent.width
                }
                
                Rectangle {
                    width: parent.width
                    height: 100
                    color: "#f5f5f5"
                    border.color: "#ddd"
                    border.width: 1
                    radius: 5
                    
                    Text {
                        anchors.centerIn: parent
                        text: "功能区域\n您可以在这里添加各种功能"
                        horizontalAlignment: Text.AlignHCenter
                        color: "#888888"
                    }
                }
                
                Row {
                    anchors.right: parent.right
                    spacing: 10
                    
                    Button {
                        text: "确定"
                        onClicked: dialogWindow.visible = false
                    }
                    
                    Button {
                        text: "取消"
                        onClicked: dialogWindow.visible = false
                    }
                    
                    Button {
                        text: "退出程序"
                        onClicked: Qt.quit()
                    }
                }
            }
        }
    }
}
