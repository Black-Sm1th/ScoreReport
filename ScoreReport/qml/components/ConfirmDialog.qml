import QtQuick 2.9
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0

// 确认对话框组件
Item {
    id: confirmDialog
    anchors.fill: parent
    z: 10000
    visible: false
    // 可配置属性
    property string title: qsTr("提示")
    property string message: qsTr("确定要执行此操作吗？")
    property string confirmText: qsTr("确定")
    property string cancelText: qsTr("取消")
    property color maskColor: "#80000000"
    property color dialogBackgroundColor: "#FFFFFF"
    property color titleColor: "#D9000000"
    property color messageColor: "#8C000000"
    property color confirmButtonColor: "#006BFF"
    property color cancelButtonColor: "#F5F5F5"
    property color confirmTextColor: "#FFFFFF"
    property color cancelTextColor: "#73000000"
    property int dialogWidth: 400
    property int dialogRadius: 12
    property int recRadius: 0
    // 信号
    signal confirmed()
    signal cancelled()
    signal closed()
    
    // 背景遮罩
    Rectangle {
        id: maskBackground
        anchors.fill: parent
        color: maskColor
        opacity: 0
        radius: recRadius
        // 点击遮罩关闭对话框
        MouseArea {
            anchors.fill: parent
            onClicked: {
                close()
            }
        }
        
        // 遮罩淡入动画
        Behavior on opacity {
            NumberAnimation {
                duration: 300
                easing.type: Easing.OutQuad
            }
        }
    }
    
    // 对话框主体
    Rectangle {
        id: dialogContainer
        width: dialogWidth
        height: 40 + messageText.height + titleText.height + 40 + 48
        radius: dialogRadius
        color: dialogBackgroundColor
        anchors.centerIn: parent
        
        // 初始状态
        opacity: 0
        scale: 0.8
        
        // 轻微边框效果
        border.width: 1
        border.color: "#E5E7EB"
        
        Column {
            anchors.fill: parent
            anchors.margins: 24
            spacing: 20
            
            // 标题
            Text {
                id: titleText
                text: title
                font.family: "Alibaba PuHuiTi 3.0"
                font.pixelSize: 18
                font.weight: Font.Medium
                color: titleColor
                width: parent.width
                wrapMode: Text.WordWrap
            }
            
            // 消息内容
            Text {
                id: messageText
                text: message
                font.family: "Alibaba PuHuiTi 3.0"
                font.pixelSize: 14
                color: messageColor
                width: parent.width
                wrapMode: Text.WordWrap
                lineHeight: 1.4
            }
            
            // 按钮区域
            Row {
                width: parent.width
                height: 40
                spacing: 12
                layoutDirection: Qt.RightToLeft
                
                // 确定按钮
                Rectangle {
                    id: confirmButton
                    width: 80
                    height: 40
                    radius: 8
                    color: confirmButtonPressed ? Qt.darker(confirmButtonColor, 1.1) : confirmButtonColor
                    
                    property bool confirmButtonPressed: false
                    
                    Text {
                        anchors.centerIn: parent
                        text: confirmText
                        font.family: "Alibaba PuHuiTi 3.0"
                        font.pixelSize: 14
                        font.weight: Font.Medium
                        color: confirmTextColor
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onPressed: confirmButton.confirmButtonPressed = true
                        onReleased: confirmButton.confirmButtonPressed = false
                        onExited: confirmButton.confirmButtonPressed = false
                        
                        onClicked: {
                            confirmed()
                            close()
                        }
                    }
                    
                    // 按钮颜色动画
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                            easing.type: Easing.OutQuad
                        }
                    }
                }
                
                // 取消按钮
                Rectangle {
                    id: cancelButton
                    width: 80
                    height: 40
                    radius: 8
                    color: cancelButtonPressed ? Qt.darker(cancelButtonColor, 1.05) : cancelButtonColor
                    border.width: 1
                    border.color: "#E6EAF2"
                    
                    property bool cancelButtonPressed: false
                    
                    Text {
                        anchors.centerIn: parent
                        text: cancelText
                        font.family: "Alibaba PuHuiTi 3.0"
                        font.pixelSize: 14
                        color: cancelTextColor
                    }
                    
                    MouseArea {
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onPressed: cancelButton.cancelButtonPressed = true
                        onReleased: cancelButton.cancelButtonPressed = false
                        onExited: cancelButton.cancelButtonPressed = false
                        
                        onClicked: {
                            cancelled()
                            close()
                        }
                    }
                    
                    // 按钮颜色动画
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                            easing.type: Easing.OutQuad
                        }
                    }
                }
            }
        }
    }
    
    // 显示动画
    ParallelAnimation {
        id: showAnimation
        
        NumberAnimation {
            target: maskBackground
            property: "opacity"
            from: 0
            to: 1
            duration: 300
            easing.type: Easing.OutQuad
        }
        
        NumberAnimation {
            target: dialogContainer
            property: "opacity"
            from: 0
            to: 1
            duration: 300
            easing.type: Easing.OutQuad
        }
        
        NumberAnimation {
            target: dialogContainer
            property: "scale"
            from: 0.8
            to: 1.0
            duration: 300
            easing.type: Easing.OutBack
        }
    }
    
    // 隐藏动画
    ParallelAnimation {
        id: hideAnimation
        
        NumberAnimation {
            target: maskBackground
            property: "opacity"
            from: 1
            to: 0
            duration: 200
            easing.type: Easing.InQuad
        }
        
        NumberAnimation {
            target: dialogContainer
            property: "opacity"
            from: 1
            to: 0
            duration: 200
            easing.type: Easing.InQuad
        }
        
        NumberAnimation {
            target: dialogContainer
            property: "scale"
            from: 1.0
            to: 0.8
            duration: 200
            easing.type: Easing.InBack
        }
        
        onStopped: {
            confirmDialog.visible = false
            closed()
        }
    }
    
    // 键盘事件处理
    Keys.onPressed: {
        if (event.key === Qt.Key_Escape) {
            cancelled()
            close()
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            confirmed()
            close()
            event.accepted = true
        }
    }
    
    // 显示对话框
    function show() {
        confirmDialog.visible = true
        confirmDialog.forceActiveFocus()
        showAnimation.start()
    }
    
    // 关闭对话框
    function close() {
        hideAnimation.start()
    }
}
