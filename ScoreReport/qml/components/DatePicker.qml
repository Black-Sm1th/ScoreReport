import QtQuick 2.9
import QtQuick.Controls 2.2
import QtGraphicalEffects 1.0

Rectangle {
    id: datePickerContainer
    
    // 使组件能够获得焦点
    focus: true
    activeFocusOnTab: true
    
    // 确保日期选择器在最顶层
    z: datePickerOpen ? 10000 : 1
    
    // 可配置属性
    property int dropdownWidth: 110
    property int dropdownHeight: 29
    property color backgroundColor: "#FFFFFF"
    property color borderColor: "#0F000000"
    property color hoverColor: "#F8FAFF"
    property color selectedColor: "#F0F7FF"
    property string placeholderText: "日期"
    property bool hasSelection: false
    property date selectedDate: new Date()
    property string currentText: placeholderText
    
    // 选择改变信号
    signal dateSelected(date selectedDate)
    signal dateCleared()
    
    width: dropdownWidth
    height: dropdownHeight
    color: mainMouseArea.containsMouse ? hoverColor : backgroundColor
    border.color: datePickerOpen ? "#33006BFF" : "#0F000000"
    border.width: 1
    radius: 8
    
    property bool datePickerOpen: false
    
    // 内容显示区域
    Row {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: arrowIcon.left
        anchors.rightMargin: 4
        spacing: 4
        
        // 显示的文本
        Text {
            id: displayText
            text: currentText
            font.family: "Alibaba PuHuiTi 3.0"
            font.pixelSize: 14
            color: "#D9000000"
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
            ctx.fillStyle = datePickerOpen ? "#006BFF" : "#73000000"
            ctx.beginPath()
            if (datePickerOpen) {
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
            datePickerContainer.forceActiveFocus()
            if (datePickerOpen) {
                datePickerPopup.close()
            } else {
                datePickerOpen = true
                datePickerPopup.open()
            }
            arrowIcon.requestPaint()
        }
    }
    
    // 日期选择弹窗
    Popup {
        id: datePickerPopup
        width: 280
        height: 320
        x: dropdownWidth - width
        y: datePickerContainer.height + 2
        visible: datePickerOpen
        modal: false
        focus: false
        closePolicy: Popup.CloseOnEscape | Popup.CloseOnPressOutside
        
        onClosed: {
            datePickerOpen = false
            arrowIcon.requestPaint()
        }
        
        background: Rectangle {
            color: backgroundColor
            border.color: "#0F000000"
            border.width: 1
            radius: 8
        }
        
        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8
            
            // 头部操作区域
            Row {
                width: parent.width
                
                Text {
                    text: "选择日期"
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.pixelSize: 14
                    font.weight: Font.Medium
                    color: "#D9000000"
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                Item {
                    width: parent.width - clearButton.width - parent.children[0].width
                    height: 1
                }
                
                CustomButton {
                    id: clearButton
                    text: "取消"
                    buttonWidth: 50
                    buttonHeight: 24
                    backgroundColor: "#FF5132"
                    textColor: "#ffffff"
                    fontSize: 14
                    buttonRadius: 4
                    borderWidth: 0
                    onClicked: {
                        reset()
                        dateCleared()
                    }
                }
            }
            
            // 分隔线
            Rectangle {
                width: parent.width
                height: 1
                color: "#F0F0F0"
            }
            
            // 年月选择器
            Row {
                width: parent.width
                spacing: 8
                
                // 年份选择
                Rectangle {
                    width: (parent.width - 8) / 2
                    height: 32
                    border.color: "#E6EAF2"
                    border.width: 1
                    radius: 4
                    color: "#FFFFFF"
                    
                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        
                        CustomButton {
                            buttonWidth: 30
                            buttonHeight: 20
                            text: "<"
                            backgroundColor: "transparent"
                            borderColor: "transparent"
                            textColor: "#40000000"
                            hoverTextColor: "#73000000"
                            fontSize: 12
                            buttonRadius: 2
                            
                            onClicked: {
                                calendar.currentYear--
                                calendar.updateCalendar()
                            }
                        }
                        
                        Text {
                            id: yearText
                            text: calendar.currentYear
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 12
                            color: "#D9000000"
                            width: 30
                            horizontalAlignment: Text.AlignHCenter
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        CustomButton {
                            buttonWidth: 30
                            buttonHeight: 20
                            text: ">"
                            backgroundColor: "transparent"
                            borderColor: "transparent"
                            textColor: "#40000000"
                            hoverTextColor: "#73000000"
                            fontSize: 12
                            buttonRadius: 2
                            
                            onClicked: {
                                calendar.currentYear++
                                calendar.updateCalendar()
                            }
                        }
                    }
                }
                
                // 月份选择
                Rectangle {
                    width: (parent.width - 8) / 2
                    height: 32
                    border.color: "#E6EAF2"
                    border.width: 1
                    radius: 4
                    color: "#FFFFFF"
                    
                    Row {
                        anchors.centerIn: parent
                        spacing: 4
                        
                        CustomButton {
                            buttonWidth: 30
                            buttonHeight: 20
                            text: "<"
                            backgroundColor: "transparent"
                            borderColor: "transparent"
                            textColor: "#40000000"
                            hoverTextColor: "#73000000"
                            fontSize: 12
                            buttonRadius: 2
                            
                            onClicked: {
                                if (calendar.currentMonth === 1) {
                                    calendar.currentMonth = 12
                                    calendar.currentYear--
                                } else {
                                    calendar.currentMonth--
                                }
                                calendar.updateCalendar()
                            }
                        }
                        
                        Text {
                            id: monthText
                            text: calendar.currentMonth + "月"
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 12
                            color: "#D9000000"
                            width: 30
                            horizontalAlignment: Text.AlignHCenter
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        CustomButton {
                            buttonWidth: 30
                            buttonHeight: 20
                            text: ">"
                            backgroundColor: "transparent"
                            borderColor: "transparent"
                            textColor: "#40000000"
                            hoverTextColor: "#73000000"
                            fontSize: 12
                            buttonRadius: 2
                            
                            onClicked: {
                                if (calendar.currentMonth === 12) {
                                    calendar.currentMonth = 1
                                    calendar.currentYear++
                                } else {
                                    calendar.currentMonth++
                                }
                                calendar.updateCalendar()
                            }
                        }
                    }
                }
            }
            
            // 星期标题
            Grid {
                width: parent.width
                columns: 7
                columnSpacing: 2
                
                Repeater {
                    model: ["日", "一", "二", "三", "四", "五", "六"]
                    
                    Rectangle {
                        width: (parent.width - parent.columnSpacing * 6) / 7
                        height: 24
                        color: "transparent"
                        
                        Text {
                            text: modelData
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 11
                            font.weight: Font.Medium
                            color: "#73000000"
                            anchors.centerIn: parent
                        }
                    }
                }
            }
            
            // 日期网格
            Grid {
                id: calendar
                width: parent.width
                columns: 7
                columnSpacing: 2
                rowSpacing: 2
                
                property int currentYear: new Date().getFullYear()
                property int currentMonth: new Date().getMonth() + 1
                property int selectedDay: -1
                property var calendarModel: []
                
                function updateCalendar() {
                    calendarModel = []
                    var firstDay = new Date(currentYear, currentMonth - 1, 1)
                    var firstDayOfWeek = firstDay.getDay()
                    var daysInMonth = new Date(currentYear, currentMonth, 0).getDate()
                    
                    // 添加上个月的日期填充
                    var prevMonth = currentMonth === 1 ? 12 : currentMonth - 1
                    var prevYear = currentMonth === 1 ? currentYear - 1 : currentYear
                    var daysInPrevMonth = new Date(prevYear, prevMonth, 0).getDate()
                    
                    for (var i = firstDayOfWeek - 1; i >= 0; i--) {
                        calendarModel.push({
                            day: daysInPrevMonth - i,
                            isCurrentMonth: false,
                            month: prevMonth,
                            year: prevYear
                        })
                    }
                    
                    // 添加当前月的日期
                    for (var day = 1; day <= daysInMonth; day++) {
                        calendarModel.push({
                            day: day,
                            isCurrentMonth: true,
                            month: currentMonth,
                            year: currentYear
                        })
                    }
                    
                    // 添加下个月的日期填充
                    var totalCells = calendarModel.length
                    var nextMonth = currentMonth === 12 ? 1 : currentMonth + 1
                    var nextYear = currentMonth === 12 ? currentYear + 1 : currentYear
                    
                    for (var j = 1; totalCells < 42; j++) {
                        calendarModel.push({
                            day: j,
                            isCurrentMonth: false,
                            month: nextMonth,
                            year: nextYear
                        })
                        totalCells++
                    }
                    
                    calendarRepeater.model = calendarModel
                }
                
                Component.onCompleted: updateCalendar()
                
                Repeater {
                    id: calendarRepeater
                    
                    Rectangle {
                        width: (calendar.width - calendar.columnSpacing * 6) / 7
                        height: 24
                        color: {
                            if (!modelData.isCurrentMonth) return "transparent"
                            if (modelData.day === calendar.selectedDay && modelData.month === calendar.currentMonth && modelData.year === calendar.currentYear) return "#006BFF"
                            if (dayMouseArea.containsMouse) return "#ECF3FF"
                            return "transparent"
                        }
                        radius: 3
                        
                        Text {
                            text: modelData.day
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 12
                            color: {
                                if (!modelData.isCurrentMonth) return "#40000000"
                                if (modelData.day === calendar.selectedDay && modelData.month === calendar.currentMonth && modelData.year === calendar.currentYear) return "#FFFFFF"
                                return "#D9000000"
                            }
                            anchors.centerIn: parent
                        }
                        
                        MouseArea {
                            id: dayMouseArea
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            enabled: modelData.isCurrentMonth
                            
                            onClicked: {
                                calendar.selectedDay = modelData.day
                                selectedDate = new Date(modelData.year, modelData.month - 1, modelData.day)
                                hasSelection = true
                                currentText = Qt.formatDate(selectedDate, "yyyy-MM-dd")
                                datePickerPopup.close()
                                dateSelected(selectedDate)
                            }
                        }
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
    onDatePickerOpenChanged: {
        if (datePickerOpen && !datePickerPopup.visible) {
            datePickerPopup.open()
        } else if (!datePickerOpen && datePickerPopup.visible) {
            datePickerPopup.close()
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
    function clearSelection() {
        hasSelection = false
        currentText = placeholderText
        calendar.selectedDay = -1
    }
    
    function setDate(date) {
        selectedDate = date
        hasSelection = true
        currentText = Qt.formatDate(date, "yyyy-MM-dd")
        calendar.currentYear = date.getFullYear()
        calendar.currentMonth = date.getMonth() + 1
        calendar.selectedDay = date.getDate()
        calendar.updateCalendar()
    }
    
    function getSelectedDate() {
        return hasSelection ? selectedDate : null
    }
    
    function reset() {
        // 清除选择状态
        hasSelection = false
        currentText = placeholderText
        calendar.selectedDay = -1
        
        // 重置到当前日期（今天）但不选择
        var today = new Date()
        calendar.currentYear = today.getFullYear()
        calendar.currentMonth = today.getMonth() + 1
        calendar.updateCalendar()
        
        // 关闭弹窗
        if (datePickerOpen) {
            datePickerPopup.close()
        }
    }
} 
