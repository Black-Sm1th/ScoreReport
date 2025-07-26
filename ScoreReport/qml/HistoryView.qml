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
    function resetAllValue(){
        searchField.text = ""
    }
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
            Timer {
                id: debounceTimer
                interval: 300
                repeat: false
                onTriggered: {
                    $historyManager.searchText = searchField.text
                    if($loginManager.currentUserId !== ""){
                        $historyManager.updateList()
                    }
                }
            }
            Text {
                text: "历史记录"
                color: "#D9000000"
                font.family: "Alibaba PuHuiTi 3.0"
                font.weight: Font.Bold
                font.pixelSize: 16
                anchors.verticalCenter: parent.verticalCenter
            }
            Rectangle{
                width: 100
                height: 29
                color: "#0A000000"
                radius: 8
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                Image{
                    id: searchIco
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 4
                    source: "qrc:/image/search.png"
                }
                TextField{
                    id:searchField
                    height: 21
                    width: 100 - searchIco.width - 8 - 4
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: searchIco.right
                    anchors.leftMargin: 4
                    placeholderText: "搜索"
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.pixelSize: 14
                    leftPadding: 0
                    rightPadding: 0
                    topPadding: 0
                    bottomPadding: 0
                    selectByMouse: true
                    background: Rectangle {
                        color: "transparent"
                    }
                    onTextChanged: {
                        debounceTimer.restart()
                    }
                }
            }
        }
        
        // 历史记录列表
        Rectangle {
            width: parent.width - 24
            height: Math.min(scrollView.contentHeight, 700)
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
                        height: 255
                        visible: historyData.length === 0
                        Image {
                            source: "qrc:/image/nodata.png"
                            anchors.horizontalCenter: parent.horizontalCenter
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
                                    height: contentMouseArea.containsMouse || copyArea.containsMouse ? Math.max(80, contentRow.implicitHeight) : 80
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
                                                id:titleText
                                                text: modelData.title || ""
                                                color: "#D9000000"
                                                font.family: "Alibaba PuHuiTi 3.0"
                                                font.weight: Font.Bold
                                                font.pixelSize: 16
                                                elide: Text.ElideRight
                                                width: parent.width
                                            }
                                            
                                            Text {
                                                id: resultText
                                                text: modelData.result || ""
                                                color: "#73000000"
                                                font.family: "Alibaba PuHuiTi 3.0"
                                                font.pixelSize: 14
                                                width: parent.width
                                                elide: Text.ElideRight
                                                visible: modelData.result
                                                maximumLineCount: contentMouseArea.containsMouse || copyArea.containsMouse ? -1 : 1
                                                wrapMode: Text.Wrap
                                                
                                                Behavior on maximumLineCount {
                                                    NumberAnimation {
                                                        duration: 200
                                                        easing.type: Easing.OutQuad
                                                    }
                                                }
                                            }
                                            
                                            Item {
                                                width: parent.width
                                                height: 8
                                            }
                                            
                                            Text {
                                                id: sourceText
                                                text: getSourceText(modelData.type)
                                                color: "#40000000"
                                                font.family: "Alibaba PuHuiTi 3.0"
                                                font.pixelSize: 12
                                                width: parent.width
                                                elide: Text.ElideRight
                                                visible: contentMouseArea.containsMouse || copyArea.containsMouse
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
                                            id: copyBtn
                                            width: 28
                                            height: 28
                                            visible: contentMouseArea.containsMouse || copyArea.containsMouse
                                            color: copyArea.containsMouse ? "#1A006BFF" : "transparent"
                                            radius: 8
                                            Image{
                                                anchors.centerIn: parent
                                                source: "qrc:/image/copy.png"
                                            }
                                            MouseArea{
                                                id: copyArea
                                                anchors.fill: parent
                                                hoverEnabled: true
                                                cursorShape: Qt.PointingHandCursor
                                                onClicked: {
                                                    var text = titleText.text
                                                    if(resultText.text !== ""){
                                                        text += "\n"
                                                        text += resultText.text
                                                    }
                                                    text += "\n"
                                                    text += sourceText.text
                                                    $historyManager.copyToClipboard(text)
                                                    messageManager.success("已复制！")
                                                }
                                                onPressed: {
                                                    copyBtn.opacity = 0.8
                                                }
                                                onReleased: {
                                                    copyBtn.opacity = 1
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
            // 使用updateTime而不是createTime，并正确解析ISO时间格式
            var updateTime = parseISODateTime(record.updateTime)
            
            // 获取今天的开始时间（00:00:00）
            var todayStart = new Date(today.getFullYear(), today.getMonth(), today.getDate())
            var updateTimeStart = new Date(updateTime.getFullYear(), updateTime.getMonth(), updateTime.getDate())
            
            // 计算日期差（按天计算，不考虑具体时间）
            var daysDiff = Math.floor((todayStart - updateTimeStart) / (1000 * 60 * 60 * 24))

            var dateKey
            if (daysDiff === 0) {
                dateKey = "今天 " + Qt.formatDateTime(updateTime, "hh:mm")
            } else if (daysDiff === 1) {
                dateKey = "昨天 " + Qt.formatDateTime(updateTime, "hh:mm")
            } else if (daysDiff === 2) {
                dateKey = "前天 " + Qt.formatDateTime(updateTime, "hh:mm")
            } else if (daysDiff < 7) {
                dateKey = daysDiff + "天前"
            } else if (daysDiff < 30) {
                var weeks = Math.floor(daysDiff / 7)
                dateKey = weeks + "周前"
            } else {
                var months = Math.floor(daysDiff / 30)
                dateKey = months + "个月前"
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
    
    // 解析ISO时间格式
    function parseISODateTime(isoString) {
        if (!isoString) return new Date()
        
        try {
            // 处理ISO 8601格式：2025-07-25T01:38:49.000+00:00
            // 直接使用Date构造函数解析，会自动处理时区转换为本地时间
            var date = new Date(isoString)
            
            // 如果解析失败，尝试其他格式
            if (isNaN(date.getTime())) {
                // 尝试移除毫秒部分
                var withoutMs = isoString.replace(/\.\d{3}/, '')
                date = new Date(withoutMs)
            }
            
            if (isNaN(date.getTime())) {
                return new Date()
            }
            
            return date
        } catch (e) {
            return new Date()
        }
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
    
    // 获取源文本内容
    function getSourceText(type) {
        // 根据不同类型处理content内容
        switch(type) {
            case "CCLS":
                return $cclsScorer.sourceText
            case "RENAL":
                return $renalManager.sourceText
            case "TNM":
                return $tnmManager.sourceText
            case "UCLS MRS":
                return ""
            case "UCLS CTS":
                return ""
            case "BIOSNAK":
                return ""
            default:
                return ""
        }
    }
}
