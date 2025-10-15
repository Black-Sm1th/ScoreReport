import QtQuick 2.9
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0

Rectangle {
    id: selectorContainer
    
    // 使组件能够获得焦点
    focus: true
    activeFocusOnTab: true
    
    // 确保下拉框在最顶层
    z: dropdownOpen ? 10000 : 1
    
    // 可配置属性
    property int dropdownWidth: 200
    property int dropdownHeight: 29
    property int maxDropdownHeight: 250
    property color backgroundColor: "#FFFFFF"
    property color borderColor: "#E6EAF2"
    property color hoverColor: "#F8FAFF"
    property color selectedColor: "#F0F7FF"
    property bool enabled: true
    
    // 多选相关属性
    property var knowledgeList: []
    property var selectedKnowledgeBases: []
    
    // 选择改变信号
    signal selectionChanged(var selectedItems)
    
    width: dropdownWidth
    height: dropdownHeight
    color: enabled ? (mainMouseArea.containsMouse ? hoverColor : backgroundColor) : "#F5F5F5"
    border.color: enabled ? (dropdownOpen ? "#33006BFF" : "#0F000000") : "#E0E0E0"
    border.width: 1
    radius: 8
    opacity: enabled ? 1.0 : 0.6
    
    property bool dropdownOpen: false
    
    // 内容显示区域
    Row {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: arrowIcon.left
        anchors.rightMargin: 4
        spacing: 4
        
        // 显示选中的数量或提示文本
        Text {
            id: displayText
            text: {
                if (selectedKnowledgeBases.length === 0) {
                    return "选择知识库"
                } else if (selectedKnowledgeBases.length === 1) {
                    // 显示单个选中的知识库名称
                    for (var i = 0; i < knowledgeList.length; i++) {
                        if (knowledgeList[i].id === selectedKnowledgeBases[0]) {
                            return knowledgeList[i].name
                        }
                    }
                    return "已选择 1 个"
                } else {
                    return "已选择 " + selectedKnowledgeBases.length + " 个"
                }
            }
            font.family: "Alibaba PuHuiTi 3.0"
            font.pixelSize: 14
            color: enabled ? (selectedKnowledgeBases.length > 0 ? "#D9000000" : "#73000000") : "#BFBFBF"
            anchors.verticalCenter: parent.verticalCenter
            elide: Text.ElideRight
            width: parent.width
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
            if (enabled) {
                ctx.fillStyle = dropdownOpen ? "#006BFF" : "#73000000"
            } else {
                ctx.fillStyle = "#BFBFBF"
            }
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
        enabled: selectorContainer.enabled
        hoverEnabled: enabled
        cursorShape: enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        
        onClicked: {
            if (enabled) {
                selectorContainer.forceActiveFocus()
                if (dropdownOpen) {
                    dropdownPopup.close()
                } else {
                    dropdownOpen = true
                    dropdownPopup.open()
                }
                arrowIcon.requestPaint()
            }
        }
    }
    
    // 下拉选项弹窗
    Popup {
        id: dropdownPopup
        width: selectorContainer.width
        height: Math.min(Math.max(listView.contentHeight + 64, 100), maxDropdownHeight) // 64 = 按钮区域高度 + 间距
        x: 0
        y: selectorContainer.height + 2
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
            radius: 8
        }
        
        Column {
            anchors.fill: parent
            spacing: 8
            
            // 知识库列表
            ListView {
                id: listView
                width: parent.width
                height: parent.height - buttonRow.height - parent.spacing
                model: knowledgeList
                clip: true
                ScrollBar.vertical: ScrollBar {
                   policy: ScrollBar.AsNeeded   // 滚动条策略
                }
                delegate: Rectangle {
                    width: listView.width
                    height: 32
                    color: itemMouseArea.containsMouse ? hoverColor : "transparent"
                    radius: 4
                    
                    Row {
                        anchors.left: parent.left
                        anchors.leftMargin: 8
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 8
                        spacing: 8
                        
                        // 复选框
                        Rectangle {
                            id: checkbox
                            width: 16
                            height: 16
                            anchors.verticalCenter: parent.verticalCenter
                            color: "transparent"
                            border.color: isSelected ? "#006BFF" : "#D0D0D0"
                            border.width: 2
                            radius: 2
                            
                            property bool isSelected: selectedKnowledgeBases.indexOf(modelData.id) !== -1
                            
                            // 选中标记
                            Canvas {
                                anchors.centerIn: parent
                                width: 10
                                height: 8
                                visible: parent.isSelected
                                
                                onPaint: {
                                    var ctx = getContext("2d")
                                    ctx.clearRect(0, 0, width, height)
                                    ctx.strokeStyle = "#006BFF"
                                    ctx.lineWidth = 2
                                    ctx.lineCap = "round"
                                    ctx.lineJoin = "round"
                                    ctx.beginPath()
                                    ctx.moveTo(2, 4)
                                    ctx.lineTo(4, 6)
                                    ctx.lineTo(8, 2)
                                    ctx.stroke()
                                }
                            }
                        }
                        
                        // 知识库名称
                        Text {
                            text: modelData.name || ""
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 14
                            color: "#D9000000"
                            anchors.verticalCenter: parent.verticalCenter
                            elide: Text.ElideRight
                            width: parent.width - checkbox.width - parent.spacing
                        }
                    }
                    
                    MouseArea {
                        id: itemMouseArea
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        
                        onClicked: {
                            toggleSelection(modelData.id)
                        }
                    }
                }
            }
            
            // 底部按钮区域
            Row {
                id: buttonRow
                width: parent.width
                height: 32
                spacing: 8
                
                CustomButton{
                    width: (parent.width - parent.spacing) / 2
                    height: parent.height
                    borderWidth: 0
                    backgroundColor: "#FF5132"
                    textColor: "#ffffff"
                    text: qsTr("清空选择")
                    fontSize: 14
                    onClicked: {
                        selectedKnowledgeBases = []
                        selectionChanged(getSelectedKnowledgeBases())
                    }
                }

                CustomButton{
                    width: (parent.width - parent.spacing) / 2
                    height: parent.height
                    borderWidth: 0
                    backgroundColor: "#006BFF"
                    textColor: "#ffffff"
                    text: qsTr("全选")
                    fontSize: 14
                    onClicked: {
                        var allIds = []
                        for (var i = 0; i < knowledgeList.length; i++) {
                            allIds.push(knowledgeList[i].id)
                        }
                        selectedKnowledgeBases = allIds
                        selectionChanged(getSelectedKnowledgeBases())
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
        if (dropdownOpen && !dropdownPopup.visible && enabled) {
            dropdownPopup.open()
        } else if (!dropdownOpen && dropdownPopup.visible) {
            dropdownPopup.close()
        }
    }
    
    // 当 enabled 状态改变时重新绘制箭头
    onEnabledChanged: {
        arrowIcon.requestPaint()
        if (!enabled && dropdownOpen) {
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
    function toggleSelection(knowledgeId) {
        var newSelection = selectedKnowledgeBases.slice() // 复制数组
        var index = newSelection.indexOf(knowledgeId)
        
        if (index !== -1) {
            // 如果已选中，则取消选择
            newSelection.splice(index, 1)
        } else {
            // 如果未选中，则添加选择
            newSelection.push(knowledgeId)
        }
        
        selectedKnowledgeBases = newSelection
        selectionChanged(getSelectedKnowledgeBases())
    }
    
    function getSelectedKnowledgeBases() {
        var selected = []
        for (var i = 0; i < knowledgeList.length; i++) {
            if (selectedKnowledgeBases.indexOf(knowledgeList[i].id) !== -1) {
                selected.push(knowledgeList[i])
            }
        }
        return selected
    }
    
    function setSelectedIds(ids) {
        selectedKnowledgeBases = ids.slice() // 复制数组
        selectionChanged(getSelectedKnowledgeBases())
    }
    
    function getSelectedIds() {
        return selectedKnowledgeBases.slice()
    }
}
