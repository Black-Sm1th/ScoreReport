import QtQuick 2.9
import QtQuick.Controls 2.2

// 文字选择按钮组组件
Item {
    id: root
    
    // 公开属性
    property int selectedIndex: -1          // 当前选中的按钮索引 (-1表示未选择)
    property var options: []                // 选项文字数组
    property real buttonHeight: 36          // 按钮高度
    property real spacing: 16               // 按钮间距
    property bool disabled: false           // 是否禁用
    
    // 信号
    signal selectionChanged(int index)
    
    // 计算组件大小
    width: parent.width
    height: buttonHeight
    
    Row {
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        spacing: root.spacing
        
        Repeater {
            model: root.options.length
            
            Rectangle {
                id: optionButton
                width: (root.width - (root.options.length - 1) * root.spacing) / root.options.length
                height: root.buttonHeight
                radius: 6
                
                // 背景色和边框
                color: "transparent"
                border.color: {
                    if (root.disabled) {
                        return root.selectedIndex === index ? "#33006BFF" : "#0F000000"
                    }
                    return root.selectedIndex === index ? "#33006BFF" : "#1F000000"
                }
                border.width: 1
                
                // 鼠标悬停效果
                states: [
                    State {
                        name: "hovered"
                        when: mouseArea.containsMouse && root.selectedIndex !== index && !root.disabled
                        PropertyChanges {
                            target: optionButton
                            color: "#0A006BFF"
                            border.color: "#33006BFF"
                        }
                    }
                ]
                
                transitions: Transition {
                    ColorAnimation {
                        duration: 150
                        easing.type: Easing.OutQuad
                    }
                }
                
                Text {
                    anchors.centerIn: parent
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.pixelSize: 12
                    color: {
                        if (root.disabled) {
                            return root.selectedIndex === index ? "#006BFF" : "#40000000"
                        }
                        return root.selectedIndex === index ? "#006BFF" : "#D9000000"
                    }
                    text: index < root.options.length ? root.options[index] : ""
                    
                    Behavior on color {
                        ColorAnimation {
                            duration: 150
                            easing.type: Easing.OutQuad
                        }
                    }
                }
                
                MouseArea {
                    id: mouseArea
                    anchors.fill: parent
                    hoverEnabled: !root.disabled
                    cursorShape: root.disabled ? Qt.ArrowCursor : Qt.PointingHandCursor
                    
                    onClicked: {
                        if (!root.disabled && root.selectedIndex !== index) {
                            root.selectedIndex = index
                            root.selectionChanged(index)
                        }
                    }
                }
            }
        }
    }
} 
