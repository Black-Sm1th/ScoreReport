import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import "./components"

Rectangle {
    id: renalView
    height: renalColumn.height
    width: parent.width
    color: "transparent"
    property var messageManager: null
    signal exitScore()

    // 省略号动画状态
    property int dotCount: 1
    
    // 缺失项选择状态跟踪
    property var selectedOptions: ({})
    property bool hasAllRequiredSelections: false

    Connections{
        target: $renalManager
        function onCheckFailed(){
            messageManager.warning("剪贴板为空，请先复制内容")
        }
        function onisAnalyzingChanged(){
            // 当开始新的分析时，重置所有选择状态
            if($renalManager.isAnalyzing){
                resetAllSelections()
            }
        }
        function onisCompletedChanged(){
            // 当分析完成时，重置所有选择状态以准备下次分析
            if($renalManager.isCompleted){
                resetAllSelections()
            }
        }
    }

    // 省略号动画定时器
    Timer {
        id: dotTimer
        interval: 500  // 每500ms切换一次
        running: $renalManager.isAnalyzing
        repeat: true
        onTriggered: {
            dotCount = (dotCount % 3) + 1
        }
    }

    // 生成省略号文本的函数
    function getDots() {
        var dots = ""
        for (var i = 0; i < dotCount; i++) {
            dots += "."
        }
        return dots
    }
    
    // 检查是否所有必需项都已选择
    function checkAllSelections() {
        var missingFields = $renalManager.missingFieldsList
        var allSelected = true
        
        for (var i = 0; i < missingFields.length; i++) {
            if (!selectedOptions[missingFields[i]]) {
                allSelected = false
                break
            }
        }
        
        hasAllRequiredSelections = allSelected
        
        // 如果所有选项都已选择，自动提交
        if (allSelected && missingFields.length > 0) {
            submitSelections()
        }
    }
    
    // 提交选择结果
    function submitSelections() {
        var missingFields = $renalManager.missingFieldsList
        var appendContent = ""
        
        // 根据选择的字段生成拼接字符串
        for (var i = 0; i < missingFields.length; i++) {
            var field = missingFields[i]
            var selection = selectedOptions[field]
            
            if (selection) {
                if (field === "R") {
                    appendContent += "肿瘤大小：" + selection.option
                } else if (field === "E") {
                    appendContent += "肿瘤外凸率：" + selection.option
                } else if (field === "N") {
                    appendContent += "肿瘤与肾窦及肾脏集合系统关系：" + selection.option
                } else if (field === "L") {
                    appendContent += "肿瘤沿肾脏纵轴位置：" + selection.option
                }
                
                if (i < missingFields.length - 1) {
                    appendContent += "\n"
                }
            }
        }
        
        $renalManager.submitContent(appendContent)
    }
    
    // 重置所有选择和UI状态
    function resetAllSelections() {
        selectedOptions = {}
        hasAllRequiredSelections = false
        
        // 重置所有选择组件的状态
        if (arterialRatioGroup) {
            arterialRatioGroup.selectedIndex = -1
            arterialRatioGroup.disabled = false
        }
        if (arterialRatioGroup2) {
            arterialRatioGroup2.selectedIndex = -1
            arterialRatioGroup2.disabled = false
        }
        if (arterialRatioGroup3) {
            arterialRatioGroup3.selectedIndex = -1
            arterialRatioGroup3.disabled = false
        }
        if (arterialRatioGroup4) {
            arterialRatioGroup4.selectedIndex = -1
            arterialRatioGroup4.disabled = false
        }
    }

    function resetValues(){
        resetAllSelections()
        $renalManager.endAnalysis()
    }

    Column {
        id: renalColumn
        spacing: 20
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        Column {
            width: parent.width
            leftPadding: 24
            rightPadding: 24
            spacing: 12
            TextArea {
                id: contentText
                leftPadding: 12
                rightPadding: 12
                topPadding: 12
                bottomPadding: 12
                text: $renalManager.clipboardContent
                font.family: "Alibaba PuHuiTi 3.0"
                font.pixelSize: 16

                color: "#D9000000"
                readOnly: true
                width: parent.width - 48
                wrapMode: TextArea.Wrap
                background: Rectangle {
                    color: "#F5F5F5"
                    radius: 12
                }
            }

            // 标题栏
            Rectangle {
                height: 32
                width: parent.width
                color: "transparent"

                Image {
                    id: cclsImage
                    anchors.verticalCenter: parent.verticalCenter
                    width: 32
                    height: 32
                    source: "qrc:/image/RENAL.png"
                }

                Text {
                    id: cclsInfo
                    anchors.left: cclsImage.right
                    anchors.leftMargin: 8
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.weight: Font.Bold
                    font.pixelSize: 16
                    color: "#D9000000"
                    anchors.verticalCenter: parent.verticalCenter
                    text: {
                        if($renalManager.isAnalyzing){
                            return "RENAL分析中" + getDots()
                        }
                        if($renalManager.isCompleted){
                            return "已完成RENAL分析！"
                        }else if(!$renalManager.isCompleted && $renalManager.inCompleteInfo){
                            return $renalManager.inCompleteInfo
                        }else{
                            return ""
                        }
                    }
                }
            }

            Rectangle {
                width:parent.width - 48
                height: incompleteInfo.height
                visible:!$renalManager.isAnalyzing && !$renalManager.isCompleted
                color: "#ECF3FF"
                radius: 8
                Column{
                    id: incompleteInfo
                    width: parent.width
                    leftPadding: 40
                    rightPadding: 12
                    topPadding: 14
                    bottomPadding: 14
                    Text {
                        font.family: "Alibaba PuHuiTi 3.0"
                        font.pixelSize: 16
                        width: parent.width - 52
                        wrapMode: Text.Wrap
                        color: "#D9000000"
                        text: $renalManager.inCompleteContent
                    }
                }
            }
            Column {
                width: parent.width - 48
                spacing: 12
                visible:!$renalManager.isAnalyzing && !$renalManager.isCompleted
                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible: $renalManager.missingFieldsList.indexOf("R") !== -1
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: "#D9000000"
                            text: qsTr("请选择肿瘤大小。")
                        }
                    }
                    TextButtonGroup {
                        id: arterialRatioGroup
                        width: parent.width
                        options: ["≤ 4mm", "4 ~ 7mm", "≥ 7mm"]
                        selectedIndex: -1
                        disabled: selectedOptions["R"] ? true : false
                        onSelectionChanged: {
                            if (index >= 0 && !selectedOptions["R"]) {
                                selectedOptions["R"] = { option: options[index], index: index }
                                selectedIndex = index
                                disabled = true
                                checkAllSelections()
                            }
                        }
                    }
                }

                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible:$renalManager.missingFieldsList.indexOf("E") !== -1
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: "#D9000000"
                            text: qsTr("请选择肿瘤的外凸率。")
                        }
                    }
                    TextButtonGroup {
                        id: arterialRatioGroup2
                        width: parent.width
                        options: ["0%", "＜ 50%", "≥ 50%"]
                        selectedIndex: -1
                        disabled: selectedOptions["E"] ? true : false
                        onSelectionChanged: {
                            if (index >= 0 && !selectedOptions["E"]) {
                                selectedOptions["E"] = { option: options[index], index: index }
                                selectedIndex = index
                                disabled = true
                                checkAllSelections()
                            }
                        }
                    }
                }

                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible:$renalManager.missingFieldsList.indexOf("N") !== -1
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: "#D9000000"
                            text: qsTr("请选择肿瘤与肾窦及肾脏集合系统之间的关系。")
                        }
                    }
                    TextButtonGroup {
                        id: arterialRatioGroup3
                        width: parent.width
                        options: ["≤ 4mm", "4 ~ 7mm", "≥ 7mm"]
                        selectedIndex: -1
                        disabled: selectedOptions["N"] ? true : false
                        onSelectionChanged: {
                            if (index >= 0 && !selectedOptions["N"]) {
                                selectedOptions["N"] = { option: options[index], index: index }
                                selectedIndex = index
                                disabled = true
                                checkAllSelections()
                            }
                        }
                    }
                }

                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible:$renalManager.missingFieldsList.indexOf("L") !== -1
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: "#D9000000"
                            text: qsTr("请选择肿瘤沿肾脏纵轴的位置。")
                        }
                    }
                    TextButtonGroup {
                        id: arterialRatioGroup4
                        width: parent.width
                        options: ["肾脏一极", "肾脏上或下极", "50%越过上或下极"]
                        selectedIndex: -1
                        disabled: selectedOptions["L"] ? true : false
                        onSelectionChanged: {
                            if (index >= 0 && !selectedOptions["L"]) {
                                selectedOptions["L"] = { option: options[index], index: index }
                                selectedIndex = index
                                disabled = true
                                checkAllSelections()
                            }
                        }
                    }
                }
            }
            Rectangle {
                width: parent.width - 48
                height: resultColumn.height
                visible:!$renalManager.isAnalyzing && $renalManager.isCompleted
                color: "#ECF3FF"
                radius: 8
                Column {
                    id: resultColumn
                    anchors.centerIn: parent
                    spacing: 4
                    width: parent.width
                    leftPadding: 18
                    rightPadding: 18
                    topPadding: 14
                    bottomPadding: 14
                    // 综合评分
                    Row {
                        height: 24
                        width: parent.width -36
                        Text {
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.weight: Font.Bold
                            font.pixelSize: 16
                            color: "#D9000000"
                            text: qsTr("RENAL评分：")
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.weight: Font.Bold
                            font.pixelSize: 16
                            color: "#D9000000"
                            text: $renalManager.renalScorer + "分"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Text {
                        font.family: "Alibaba PuHuiTi 3.0"
                        font.pixelSize: 16
                        wrapMode: Text.Wrap
                        width: parent.width - 36
                        text: $renalManager.renalResult
                        color: "#A6000000"
                    }
                    Rectangle{
                        height: 4
                        width: parent.width -36
                        color:"transparent"
                    }
                    Text{
                        id: sourceText
                        font.family: "Alibaba PuHuiTi 3.0"
                        font.pixelSize: 12
                        color: "#73000000"
                        text: $renalManager.sourceText
                    }
                }

            }
        }

        // 底部按钮栏
        Rectangle {
            height: 60
            width: parent.width
            anchors.horizontalCenter: parent.horizontalCenter
            color: "transparent"

            Rectangle {
                height: 1
                width: parent.width
                color: "#0F000000"
            }

            // 重置按钮 - 在有缺失项时显示
            CustomButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: stopBtn.left
                anchors.rightMargin: 12
                visible: !$renalManager.isAnalyzing && !$renalManager.isCompleted && $renalManager.missingFieldsList.length > 0
                text: qsTr("重置")
                width: 88
                height: 36
                radius: 4
                fontSize: 14
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                onClicked: {
                    resetAllSelections()
                }
            }

            CustomButton {
                id:stopBtn
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 24
                visible: $renalManager.isAnalyzing || (!$renalManager.isAnalyzing && !$renalManager.isCompleted)
                text: qsTr("终止")
                width: 88
                height: 36
                radius: 4
                fontSize: 14
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                onClicked: {
                    resetAllSelections()
                    $renalManager.endAnalysis()
                    exitScore()
                }
            }

            CustomButton {
                id: resetBtn
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 24
                visible: !$renalManager.isAnalyzing && $renalManager.isCompleted
                text: qsTr("粘贴并评分")
                width: 88
                height: 36
                radius: 4
                fontSize: 14
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                onClicked: {
                    resetAllSelections()
                    $renalManager.pasteAnalysis()
                }
            }

            CustomButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: resetBtn.right
                anchors.leftMargin: 12
                visible: !$renalManager.isAnalyzing && $renalManager.isCompleted
                text: qsTr("重选方案")
                width: 88
                height: 36
                radius: 4
                fontSize: 14
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                onClicked: {
                    resetAllSelections()
                    $renalManager.endAnalysis()
                    exitScore()
                }
            }

            CustomButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 24
                visible: !$renalManager.isAnalyzing && $renalManager.isCompleted
                text: qsTr("复制")
                width: 88
                height: 36
                radius: 4
                fontSize: 14
                backgroundColor: "#006BFF"
                textColor: "#FFFFFF"
                onClicked: {
                    $renalManager.copyToClipboard(text)
                    messageManager.success("复制成功")
                }
            }
        }
    }
}
