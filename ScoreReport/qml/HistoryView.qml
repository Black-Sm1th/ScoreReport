import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import "./components"

// 历史记录界面
Rectangle {
    width: parent.width
    height: Math.min(contentColumn.height, 762)
    property var messageManager: null
    signal toScorer()
    color: "transparent"
    
    property var historyData: $historyManager.historyList || []
    
    // 监听历史数据变化
    Connections {
        target: $historyManager
        function onHistoryListChanged() {
            historyData = $historyManager.historyList || []
        }
    }
    
    Column {
        id: contentColumn
        width: parent.width
        leftPadding: 24
        spacing: 8
        
        // 标题栏
        Rectangle {
            id: titleRec
            height: 29
            width: parent.width - 48
            color: "transparent"
            Text {
                text: "历史记录"
                color: "#D9000000"
                font.family: "Alibaba PuHuiTi 3.0"
                font.weight: Font.Bold
                font.pixelSize: 16
                anchors.verticalCenter: parent.verticalCenter
            }
        }
        
        // 历史记录列表
        Rectangle {
            width: parent.width - 24
            height: Math.min(scrollView.contentHeight + 32, 700)
            color: "transparent"
            
            ScrollView {
                id: scrollView
                anchors.fill: parent
                contentWidth: width
                contentHeight: historyColumn.height
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AsNeeded
                
                Column {
                    id: historyColumn
                    width: scrollView.width
                    spacing: 8
                    rightPadding: 24
                    // 空状态
                    Column {
                        width: parent.width - 24
                        spacing: 16
                        topPadding: 40
                        bottomPadding: 40
                        visible: historyData.length === 0
                        
                        Rectangle {
                            height: 111
                            width: 111
                            color: "#D9D9D9"
                            anchors.horizontalCenter: parent.horizontalCenter
                            radius: 8
                        }
                        
                        Text {
                            text: "您还没有历史记录，请先进行评分~"
                            color: "#73000000"
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            anchors.horizontalCenter: parent.horizontalCenter
                        }
                        
                        CustomButton {
                            text: "前往评分"
                            width: 88
                            height: 36
                            backgroundColor: "#006BFF"
                            textColor: "#ffffff"
                            fontSize: 14
                            buttonRadius: 4
                            borderWidth: 0
                            anchors.horizontalCenter: parent.horizontalCenter
                            onClicked: {
                                toScorer()
                            }
                        }
                    }
                    
                    // 历史记录列表
                    Repeater {
                        model: getGroupedHistory()
                        delegate: Column {
                            width: parent.width - 24
                            spacing: 8
                            visible: historyData.length > 0
                            // 日期分组标题
                            Text {
                                text: modelData.dateText
                                color: "#73000000"
                                font.family: "Alibaba PuHuiTi 3.0"
                                font.pixelSize: 14
                            }
                            
                            // 该日期下的记录
                            Repeater {
                                model: modelData.records
                                delegate: Rectangle {
                                    width: parent.width
                                    height: contentMouseArea.containsMouse ? Math.max(80, contentRow.implicitHeight) : 80
                                    color: getTypeColor(modelData.type)
                                    border.color: "#E6EAF2"
                                    radius: 8
                                    Behavior on height {
                                        NumberAnimation {
                                            duration: 200
                                            easing.type: Easing.OutQuad
                                        }
                                    }
                                    Behavior on color {
                                        ColorAnimation {
                                            duration: 150
                                        }
                                    }

                                    MouseArea {
                                        id: contentMouseArea
                                        anchors.fill: parent
                                        hoverEnabled: true
                                    }
                                    
                                    Row {
                                        id: contentRow
                                        anchors.fill: parent
                                        leftPadding: 16
                                        rightPadding: 16
                                        topPadding: 16
                                        bottomPadding: 16
                                        spacing: 12
                                        
                                        // 类型图标
                                        Rectangle {
                                            width: 48
                                            height: 48
                                            Image {
                                                anchors.fill: parent
                                                source: getTypeIcon(modelData.type)
                                            }
                                        }
                                        
                                        // 内容区域
                                        Column {
                                            width: parent.width - 48 - 32 - 28 - 24 // 减去图标、按钮、间距
                                            spacing: 4
                                            
                                            Text {
                                                text: modelData.title || ""
                                                color: "#D9000000"
                                                font.family: "Alibaba PuHuiTi 3.0"
                                                font.weight: Font.Medium
                                                font.pixelSize: 14
                                                elide: Text.ElideRight
                                                width: parent.width
                                            }
                                            
                                            Text {
                                                id: resultText
                                                text: modelData.result || "暂无结果"
                                                color: "#73000000"
                                                font.family: "Alibaba PuHuiTi 3.0"
                                                font.pixelSize: 12
                                                width: parent.width
                                                elide: Text.ElideRight
                                                maximumLineCount: contentMouseArea.containsMouse ? -1 : 1
                                                wrapMode: Text.Wrap
                                                
                                                Behavior on maximumLineCount {
                                                    NumberAnimation {
                                                        duration: 200
                                                        easing.type: Easing.OutQuad
                                                    }
                                                }
                                            }
                                        }
                                        
                                        // 操作按钮
                                        Rectangle {
                                            width: 28
                                            height: 28
                                            color: "#006BFF"
                                            radius: 12
                                            
                                            Text {
                                                text: "•"
                                                color: "white"
                                                font.pixelSize: 16
                                                anchors.centerIn: parent
                                            }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }

        Rectangle{
             width: parent.width - 24
             height: 16
             color: "transparent"
        }
    }
    
    // 获取分组后的历史记录
    function getGroupedHistory() {
        if (!historyData || historyData.length === 0) return []
        
        var groups = {}
        var today = new Date()
        
        for (var i = 0; i < historyData.length; i++) {
            var record = historyData[i]
            var createTime = new Date(record.createTime)
            var daysDiff = Math.floor((today - createTime) / (1000 * 60 * 60 * 24))
            
            var dateKey
            if (daysDiff === 0) {
                dateKey = "今天 " + Qt.formatDateTime(createTime, "hh:mm")
            } else if (daysDiff === 1) {
                dateKey = "1天前"
            } else if (daysDiff < 7) {
                dateKey = daysDiff + "天前"
            } else if (daysDiff < 30) {
                dateKey = Math.floor(daysDiff / 7) + "周前"
            } else {
                dateKey = Math.floor(daysDiff / 30) + "个月前"
            }
            
            if (!groups[dateKey]) {
                groups[dateKey] = []
            }
            groups[dateKey].push(record)
        }
        
        var result = []
        var isFirst = true
        for (var key in groups) {
            result.push({
                dateText: key,
                records: groups[key],
                isFirst: isFirst
            })
            isFirst = false
        }
        
        return result
    }
    
    // 获取类型颜色
    function getTypeColor(type) {
        switch(type) {
            case "CCLS": return "#F8FAFF"
            case "RENAL": return "#F7FCFB"
            case "TNM": return "#FFFAF8"
            case "UCLS MRS": return "#FFFBF2"
            case "UCLS CTS": return "#F8F7FF"
            case "BIOSNAK": return "#F8FAFF"
            default: return "transparent"
        }
    }
    
    // 获取类型图标
    function getTypeIcon(type) {
        switch(type) {
        case "CCLS": return "qrc:/image/RENAL.png"
        case "RENAL": return "qrc:/image/CCLS.png"
        case "TNM": return "qrc:/image/TNM.png"
        case "UCLS MRS": return "qrc:/image/UCLS-MRS.png"
        case "UCLS CTS": return "qrc:/image/UCLS-CTS.png"
        case "BIOSNAK": return "qrc:/image/BIOSNAK.png"
        default: return ""
        }
    }
}
