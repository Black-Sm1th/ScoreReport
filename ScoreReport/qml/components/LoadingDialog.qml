import QtQuick 2.9
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0

// 加载对话框组件
Item {
    id: loadingDialog
    anchors.fill: parent
    z: 10000
    visible: false
    
    // 可配置属性
    property string message: qsTr("正在加载...")
    property color maskColor: "#80000000"
    property color dialogBackgroundColor: "#FFFFFF"
    property color textColor: "#D9000000"
    property color iconColor: "#006BFF"
    property int dialogWidth: 300
    property int dialogHeight: 120
    property int dialogRadius: 12
    property bool autoHide: false
    property int autoHideDelay: 3000
    
    // 信号
    signal showed()
    signal hidden()
    
    // 自动隐藏定时器
    Timer {
        id: autoHideTimer
        interval: autoHideDelay
        onTriggered: hide()
    }
    
    // 背景遮罩
    Rectangle {
        id: maskBackground
        anchors.fill: parent
        color: maskColor
        opacity: 0
        radius: 20
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
        height: dialogHeight
        radius: dialogRadius
        color: dialogBackgroundColor
        anchors.centerIn: parent
        
        // 初始状态
        opacity: 0
        scale: 0.8
        
        // 轻微边框效果
        border.width: 1
        border.color: "#E5E7EB"
        
        // 投影效果
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
            
            // 加载图标
            AnimatedImage {
                id: loadingIcon
                width: 32
                height: 32
                anchors.horizontalCenter: parent.horizontalCenter
                source: "qrc:/gif/loading.gif"
                playing: loadingDialog.visible
                fillMode: Image.PreserveAspectFit
                smooth: true
            }
            
            // 提示文字
            Text {
                id: messageText
                text: message
                font.family: "Alibaba PuHuiTi 3.0"
                font.pixelSize: 14
                color: textColor
                anchors.horizontalCenter: parent.horizontalCenter
                horizontalAlignment: Text.AlignHCenter
                wrapMode: Text.WordWrap
                width: dialogWidth - 40
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
        
        onStopped: {
            showed()
            if (autoHide) {
                autoHideTimer.start()
            }
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
            loadingDialog.visible = false
            autoHideTimer.stop()
            hidden()
        }
    }
    
    // 显示Loading对话框
    function show(loadingMessage) {
        if (loadingMessage) {
            message = loadingMessage
        }
        loadingDialog.visible = true
        showAnimation.start()
    }
    
    // 隐藏Loading对话框
    function hide() {
        hideAnimation.start()
    }
    
    // 更新消息
    function updateMessage(newMessage) {
        message = newMessage
    }
}
