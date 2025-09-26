import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0

// 圆形按钮组组件
Item {
    id: root
    
    // 公开属性
    property int selectedIndex: -1  // 当前选中的按钮索引 (-1表示无选中)
    property var iconSources: []    // 图标源数组
    property var iconSelectedSources: []    // 图标源数组
    property real buttonSize: 28    // 按钮大小
    property real spacing: 12        // 按钮间距
    
    // 信号
    signal selectionChanged(int index)
    
    // 计算组件大小
    width: buttonSize * 2 + spacing * 1
    height: buttonSize
    
    Row {
        anchors.centerIn: parent
        spacing: root.spacing
        
        Repeater {
            model: 2
            
            CircleButton {
                id: button
                size: root.buttonSize
                iconSource: index < root.iconSources.length ? root.iconSources[index] : ""
                iconSelectedSource: index < root.iconSources.length ? root.iconSelectedSources[index] : ""
                isSelected: root.selectedIndex === index
                login: index === 1 && $loginManager.isLoggedIn
                onClicked: {
                    if (root.selectedIndex === index) {
                        return
                    }
                    root.selectionChanged(index)
                }
            }
        }
    }

    // 单个圆形按钮组件
    component CircleButton: Rectangle {
        id: circleButton

        property real size: 28
        property string iconSource: ""
        property string iconSelectedSource: ""
        property bool isSelected: false
        property bool login: false
        signal clicked()

        width: size
        height: size
        radius: size / 2
        // 背景色
        color: isSelected ? "#1A006BFF" : "#0A000000"

        // 鼠标悬停效果
        states: [
            State {
                name: "hovered"
                when: mouseArea.containsMouse && !isSelected
                PropertyChanges {
                    target: circleButton
                    color: "#1A006BFF"
                }
            }
        ]

        transitions: Transition {
            ColorAnimation {
                duration: 150
                easing.type: Easing.OutQuad
            }
        }
        // 图标
        Item {
            anchors.centerIn: parent
            width: 12
            height: 12
            visible: !login
            Image {
                id: icon
                anchors.fill: parent
                source: circleButton.isSelected? circleButton.iconSelectedSource :  circleButton.iconSource
            }
        }
        Item {
            visible: login
            anchors.fill: parent
            
            Image {
                id: loginAvatarImage
                anchors.fill: parent
                source: $loginManager.currentUserAvatar ? $loginManager.currentUserAvatar : "qrc:/image/loginHead.png"
                fillMode: Image.PreserveAspectCrop
                visible: false
            }
            
            Rectangle {
                id: loginMaskRect
                anchors.fill: parent
                radius: circleButton.size / 2
                visible: false
            }
            
            OpacityMask {
                anchors.centerIn: parent
                width: parent.width - 2
                height: parent.height - 2
                source: loginAvatarImage
                maskSource: loginMaskRect
            }
            
            // 选中状态的边框
            Rectangle {
                anchors.fill: parent
                radius: circleButton.size / 2
                color: "transparent"
                border.color: isSelected && login ? "#CC006BFF" : "transparent"
                border.width: 1
            }
        }
        MouseArea {
            id: mouseArea
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                circleButton.clicked()
            }
        }
    }
}

