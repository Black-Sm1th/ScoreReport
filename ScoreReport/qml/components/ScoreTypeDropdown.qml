import QtQuick 2.9
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0

Rectangle {
    id: dropdownContainer
    
    // 使组件能够获得焦点
    focus: true
    activeFocusOnTab: true
    
    // 确保下拉框在最顶层
    z: dropdownOpen ? 10000 : 1
    
    // 可配置属性
    property int dropdownWidth: 120
    property int dropdownHeight: 29
    property int maxDropdownHeight: 250
    property color backgroundColor: "#FFFFFF"
    property color borderColor: "#E6EAF2"
    property color hoverColor: "#F8FAFF"
    property color selectedColor: "#F0F7FF"
    property string placeholderText: "全部"
    property int currentIndex: 0
    property string currentText: scoreTypes[currentIndex].text
    
    // 选择改变信号
    signal selectionChanged(int index, string text, string value)
    
    // 评分类型数据
    property var scoreTypes: [
        { text: "全部类型", value: "all", iconUrl: "" },
        { text: "RENAL", value: "renal", iconUrl: "qrc:/image/RENAL.png" },
        { text: "CCLS", value: "ccls", iconUrl: "qrc:/image/CCLS.png" },
        { text: "TNM", value: "tnm", iconUrl: "qrc:/image/TNM.png" },
        { text: "UCLS-MRS", value: "ucls-mrs", iconUrl: "qrc:/image/UCLS-MRS.png" },
        { text: "UCLS-CTS", value: "ucls-cts", iconUrl: "qrc:/image/UCLS-CTS.png" },
        { text: "BIOSNAK", value: "biosnak", iconUrl: "qrc:/image/BIOSNAK.png" }
    ]
    
    width: dropdownWidth
    height: dropdownHeight
    color: mainMouseArea.containsMouse ? hoverColor : backgroundColor
    border.color: dropdownOpen ? "#33006BFF" : "#0F000000"
    border.width: 1
    radius: 6
    
    property bool dropdownOpen: false
    
    // 内容显示区域
    Row {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: arrowIcon.left
        anchors.rightMargin: 4
        spacing: 4
        
        // 选中项的图标
        Image {
            id: selectedIcon
            anchors.verticalCenter: parent.verticalCenter
            source: currentIndex >= 0 && currentIndex < scoreTypes.length ? scoreTypes[currentIndex].iconUrl : ""
            visible: source !== "" && currentIndex > 0  // 只有选中具体类型时才显示图标，全部类型不显示
            width: 14
            height: 14
        }
        
        // 选中的文本
        Text {
            id: selectedText
            text: currentText
            font.family: "Alibaba PuHuiTi 3.0"
            font.pixelSize: 14
            color: "#D9000000"
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            width: Math.max(0, parent.width - (selectedIcon.visible ? selectedIcon.width + parent.spacing : 0))
        }
    }
    
    // 下拉箭头
    Canvas {
        id: arrowIcon
        width: 8
        height: 6
        anchors.right: parent.right
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        
        onPaint: {
            var ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)
            ctx.fillStyle = dropdownOpen ? "#006BFF" : "#73000000"
            ctx.beginPath()
            if (dropdownOpen) {
                // 向上箭头
                ctx.moveTo(1, 5)
                ctx.lineTo(width/2, 1)
                ctx.lineTo(width-1, 5)
            } else {
                // 向下箭头
                ctx.moveTo(1, 1)
                ctx.lineTo(width/2, 5)
                ctx.lineTo(width-1, 1)
            }
            ctx.closePath()
            ctx.fill()
        }
    }
    
    // 主鼠标交互区域
    MouseArea {
        id: mainMouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        
        onClicked: {
            dropdownContainer.forceActiveFocus()
            if (dropdownOpen) {
                dropdownPopup.close()
            } else {
                dropdownOpen = true
                dropdownPopup.open()
            }
            arrowIcon.requestPaint()
        }
    }
    
    // 下拉选项弹窗
    Popup {
        id: dropdownPopup
        width: dropdownContainer.width
        height: Math.min(listView.contentHeight + 12, maxDropdownHeight)
        x: 0
        y: dropdownContainer.height + 2
        visible: dropdownOpen
        modal: false
        focus: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        onClosed: {
            dropdownOpen = false
            arrowIcon.requestPaint()
        }
        
        background: Rectangle {
            color: backgroundColor
            border.color: "#E6EAF2"
            border.width: 1
            radius: 6
        }
        
        ListView {
            id: listView
            anchors.fill: parent
            model: scoreTypes
            clip: true
            
            delegate: Rectangle {
                width: listView.width
                height: 28
                color: itemMouseArea.containsMouse ? hoverColor : (index === currentIndex ? selectedColor : "transparent")
                radius: 3
                
                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 4
                    leftPadding: 4
                    // 图标
                    Image {
                        anchors.verticalCenter: parent.verticalCenter
                        source: modelData.iconUrl
                        visible: source !== "" && index > 0  // 只有具体类型才显示图标
                        width: 14
                        height: 14
                    }
                    
                    // 文本
                    Text {
                        text: modelData.text
                        font.family: "Alibaba PuHuiTi 3.0"
                        font.pixelSize: 14
                        color: index === currentIndex ? "#006BFF" : "#D9000000"
                        anchors.verticalCenter: parent.verticalCenter
                    }
                }

                
                MouseArea {
                    id: itemMouseArea
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    
                    onClicked: {
                        currentIndex = index
                        currentText = modelData.text
                        dropdownPopup.close()
                        selectionChanged(index, modelData.text, modelData.value)
                    }
                }
            }
        }

        enter: Transition {
            NumberAnimation {
                property: "opacity"
                from: 0
                to: 1
                duration: 150
                easing.type: Easing.OutQuad
            }
            NumberAnimation {
                property: "scale"
                from: 0.8
                to: 1.0
                duration: 150
                easing.type: Easing.OutBack
            }
        }

        exit: Transition {
            NumberAnimation {
                property: "opacity"
                from: 1
                to: 0
                duration: 150
                easing.type: Easing.OutQuad
            }
        }
    }
    
    // 确保状态同步
    onDropdownOpenChanged: {
        if (dropdownOpen && !dropdownPopup.visible) {
            dropdownPopup.open()
        } else if (!dropdownOpen && dropdownPopup.visible) {
            dropdownPopup.close()
        }
    }
    
    // 动画效果
    Behavior on border.color {
        ColorAnimation {
            duration: 150
            easing.type: Easing.OutQuad
        }
    }
    
    // 组件方法
    function selectByValue(value) {
        for (var i = 0; i < scoreTypes.length; i++) {
            if (scoreTypes[i].value === value) {
                currentIndex = i
                currentText = scoreTypes[i].text
                break
            }
        }
    }
    
    function selectByIndex(index) {
        if (index >= 0 && index < scoreTypes.length) {
            currentIndex = index
            currentText = scoreTypes[index].text
        }
    }
    
    function getCurrentValue() {
        return currentIndex >= 0 && currentIndex < scoreTypes.length ? scoreTypes[currentIndex].value : ""
    }
} 
