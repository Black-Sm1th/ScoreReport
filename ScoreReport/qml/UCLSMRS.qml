import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import "./components"

Rectangle {
    id: uclsmrsView
    height: uclsmrsColumn.height
    width: parent.width
    color: "transparent"
    signal exitScore()
    
    property int currentStep: 0      // 当前步骤 (0-8)
    property int currentScore: 0
    property string detailedDiagnosis: ""
    property var messageManager: null
    
    // 评分参数
    property int macroFat: -1               // 0:有 1:无
    property int microFat: -1               // 0:有 1:无  
    property int t2Signal: -1               // 0:高 1:低
    property int arterialRatio1: -1         // 0:>100 1:≤100
    property int arterialIndex: -1          // 0:≥5 1:<5
    property int delayedIndex: -1           // 0:≥125 1:<125
    property int ader1: -1                  // 0:>1.5 1:≤1.5
    property int arterialRatio2: -1         // 0:>100 1:≤100
    property int ader2: -1                  // 0:>1.5 1:≤1.5
    
    property bool showResult: false
    
    Column {
        id: uclsmrsColumn
        spacing: 20
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        
        Rectangle {
            height: 674
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 48
            
            Column {
                id: contentColumn
                anchors.fill: parent
                spacing: 12
                
                // 标题栏
                Rectangle {
                    height: 32
                    width: parent.width
                    color: "transparent"
                    
                    Image {
                        id: uclsmrsImage
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        height: 32
                        source: "qrc:/image/UCLS-MRS.png"
                    }
                    
                    Text {
                        id: uclsmrsInfo
                        anchors.left: uclsmrsImage.right
                        anchors.leftMargin: 8
                        font.family: "Alibaba PuHuiTi 3.0"
                        font.weight: Font.Bold
                        font.pixelSize: 16
                        color: "#D9000000"
                        anchors.verticalCenter: parent.verticalCenter
                        text: showResult ? qsTr("已完成UCLS-MRS评分！") : qsTr("UCLS-MRS评分分析中，请填写以下信息")
                    }
                }
                
                // 步骤0: 宏观脂肪选择
                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible: currentStep >= 0 && !showResult
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text{
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: currentStep === 0 ? "#006BFF" : "#D9000000"
                            text: "宏观脂肪"
                        }
                    }
                    TextButtonGroup {
                        id: macroFatGroup
                        width: parent.width
                        options: ["有", "无"]
                        selectedIndex: uclsmrsView.macroFat
                        disabled: currentStep > 0 && !showResult
                        visible: currentStep === 0 || macroFat >= 0
                        onSelectionChanged: {
                            uclsmrsView.macroFat = index
                            if (currentStep === 0) {
                                nextStep()
                            }
                        }
                    }
                }
                
                // 步骤1: 微脂肪选择
                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible: currentStep >= 1 && $uclsmrsManager.needsOption(macroFat, microFat, t2Signal, 1) && !showResult
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: currentStep === 1 ? "#006BFF" : "#D9000000"
                            text: "微脂肪"
                        }
                    }
                    TextButtonGroup {
                        id: microFatGroup
                        width: parent.width
                        options: ["有", "无"]
                        selectedIndex: uclsmrsView.microFat
                        disabled: currentStep > 1 && !showResult
                        visible: currentStep === 1 || microFat >= 0
                        onSelectionChanged: {
                            uclsmrsView.microFat = index
                            if (currentStep === 1) {
                                nextStep()
                            }
                        }
                    }
                }
                
                // 步骤2: T2信号强度选择
                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible: currentStep >= 2 && $uclsmrsManager.needsOption(macroFat, microFat, t2Signal, 2) && !showResult
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: currentStep === 2 ? "#006BFF" : "#D9000000"
                            text: "T2信号强度"
                        }
                    }
                    TextButtonGroup {
                        id: t2SignalGroup
                        width: parent.width
                        options: ["高或等", "低"]
                        selectedIndex: uclsmrsView.t2Signal
                        disabled: currentStep > 2 && !showResult
                        visible: currentStep === 2 || t2Signal >= 0
                        onSelectionChanged: {
                            uclsmrsView.t2Signal = index
                            if (currentStep === 2) {
                                nextStep()
                            }
                        }
                    }
                }
                
                // 步骤3: 相对动脉强化比1选择 (T2高信号路径)
                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible: currentStep >= 3 && $uclsmrsManager.needsOption(macroFat, microFat, t2Signal, 3) && !showResult
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: currentStep === 3 ? "#006BFF" : "#D9000000"
                            text: "相对动脉强化比"
                        }
                    }
                    TextButtonGroup {
                        id: arterialRatio1Group
                        width: parent.width
                        options: ["> 100", "≤ 100"]
                        selectedIndex: uclsmrsView.arterialRatio1
                        disabled: currentStep > 3 && !showResult
                        visible: currentStep === 3 || arterialRatio1 >= 0
                        onSelectionChanged: {
                            uclsmrsView.arterialRatio1 = index
                            if (currentStep === 3) {
                                nextStep()
                            }
                        }
                    }
                }
                
                // 步骤4: 相对动脉增强指数选择
                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible: currentStep >= 4 && $uclsmrsManager.needsOption(macroFat, microFat, t2Signal, 4) && !showResult
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: currentStep === 4 ? "#006BFF" : "#D9000000"
                            text: "相对动脉增强指数"
                        }
                    }
                    TextButtonGroup {
                        id: arterialIndexGroup
                        width: parent.width
                        options: ["≥ 5", "< 5"]
                        selectedIndex: uclsmrsView.arterialIndex
                        disabled: currentStep > 4 && !showResult
                        visible: currentStep === 4 || arterialIndex >= 0
                        onSelectionChanged: {
                            uclsmrsView.arterialIndex = index
                            if (currentStep === 4) {
                                nextStep()
                            }
                        }
                    }
                }
                
                // 步骤5: 延迟增强指数选择
                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible: currentStep >= 5 && $uclsmrsManager.needsOption(macroFat, microFat, t2Signal, 5) && !showResult
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: currentStep === 5 ? "#006BFF" : "#D9000000"
                            text: "延迟增强指数"
                        }
                    }
                    TextButtonGroup {
                        id: delayedIndexGroup
                        width: parent.width
                        options: ["≥ 125", "< 125"]
                        selectedIndex: uclsmrsView.delayedIndex
                        disabled: currentStep > 5 && !showResult
                        visible: currentStep === 5 || delayedIndex >= 0
                        onSelectionChanged: {
                            uclsmrsView.delayedIndex = index
                            if (currentStep === 5) {
                                nextStep()
                            }
                        }
                    }
                }
                
                // 步骤6: ADER1选择 (T2高信号路径)
                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible: currentStep >= 6 && $uclsmrsManager.needsOption(macroFat, microFat, t2Signal, 6) && !showResult
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: currentStep === 6 ? "#006BFF" : "#D9000000"
                            text: "ADER"
                        }
                    }
                    TextButtonGroup {
                        id: ader1Group
                        width: parent.width
                        options: ["> 1.5", "≤ 1.5"]
                        selectedIndex: uclsmrsView.ader1
                        disabled: currentStep > 6 && !showResult
                        visible: currentStep === 6 || ader1 >= 0
                        onSelectionChanged: {
                            uclsmrsView.ader1 = index
                            if (currentStep === 6) {
                                nextStep()
                            }
                        }
                    }
                }
                
                // 步骤7: 相对动脉强化比2选择 (T2低信号路径)
                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible: currentStep >= 7 && $uclsmrsManager.needsOption(macroFat, microFat, t2Signal, 7) && !showResult
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: currentStep === 7 ? "#006BFF" : "#D9000000"
                            text: "相对动脉强化比"
                        }
                    }
                    TextButtonGroup {
                        id: arterialRatio2Group
                        width: parent.width
                        options: ["> 100", "≤ 100"]
                        selectedIndex: uclsmrsView.arterialRatio2
                        disabled: currentStep > 7 && !showResult
                        visible: currentStep === 7 || arterialRatio2 >= 0
                        onSelectionChanged: {
                            uclsmrsView.arterialRatio2 = index
                            if (currentStep === 7) {
                                nextStep()
                            }
                        }
                    }
                }
                
                // 步骤8: ADER2选择 (T2低信号路径)
                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible: currentStep >= 8 && $uclsmrsManager.needsOption(macroFat, microFat, t2Signal, 8) && !showResult
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: currentStep === 8 ? "#006BFF" : "#D9000000"
                            text: "ADER"
                        }
                    }
                    TextButtonGroup {
                        id: ader2Group
                        width: parent.width
                        options: ["> 1.5", "≤ 1.5"]
                        selectedIndex: uclsmrsView.ader2
                        disabled: showResult
                        visible: currentStep === 8 || ader2 >= 0
                        onSelectionChanged: {
                            uclsmrsView.ader2 = index
                            if (currentStep === 8) {
                                calculateFinalScore()
                            }
                        }
                    }
                }

                // 结果显示区域
                Rectangle {
                    width: parent.width
                    height: resultColumn.height
                    visible: showResult
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
                            width: parent.width
                            Text {
                                id: totalScore
                                font.weight: Font.Bold
                                font.family: "Alibaba PuHuiTi 3.0"
                                font.pixelSize: 16
                                color: "#D9000000"
                                text: "UCLS-MRS评分："
                                anchors.verticalCenter: parent.verticalCenter
                            }
                            
                            Text {
                                font.family: "Alibaba PuHuiTi 3.0"
                                font.weight: Font.Bold
                                font.pixelSize: 16
                                color: "#D9000000"
                                text: currentScore + "分"
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // 疑似病症
                        Text {
                            anchors.bottom: totalScore.bottom
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            visible: detailedDiagnosis !== ""
                            color: "#A6000000"
                            text: "符合" + detailedDiagnosis + "典型特征"
                        }

                        Rectangle{
                            height: 4
                            width: parent.width - 36
                            color:"transparent"
                        }

                        Text {
                            anchors.bottom: totalScore.bottom
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 12
                            color: "#73000000"
                            text: $uclsmrsManager.sourceText
                        }
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
            
            CustomButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: resetBtn.left
                anchors.rightMargin: 12
                text: "终止"
                width: 44
                height: 36
                fontSize: 14
                visible: !showResult
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                onClicked: {
                    resetValues()
                    uclsmrsView.exitScore()
                }
            }
            
            CustomButton {
                id: resetBtn
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 24
                text: "重置"
                width: 72
                height: 36
                visible: !showResult
                fontSize: 14
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                onClicked: {
                    resetValues()
                }
            }

            CustomButton {
                id: rescore
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 24
                text: "再次评分"
                width: 72
                height: 36
                visible: showResult
                fontSize: 14
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                onClicked: {
                    resetValues()
                }
            }

            CustomButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: rescore.right
                anchors.leftMargin: 12
                text: "重选方案"
                width: 72
                height: 36
                visible: showResult
                fontSize: 14
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                onClicked: {
                    resetValues()
                    uclsmrsView.exitScore()
                }
            }

            CustomButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 24
                text: "复制"
                width: 72
                height: 36
                visible: showResult
                fontSize: 14
                borderWidth: 0
                backgroundColor: "#006BFF"
                onClicked: {
                    $uclsmrsManager.copyToClipboard()
                    messageManager.success("已复制！")
                }
            }
        }
    }
    
    function nextStep() {
        // 跳过不需要的步骤
        do {
            currentStep++
        } while (currentStep <= 8 && !$uclsmrsManager.needsOption(macroFat, microFat, t2Signal, currentStep))
        
        // 如果所有必要步骤都完成了，自动计算分数
        if (currentStep > 8 || !$uclsmrsManager.needsOption(macroFat, microFat, t2Signal, currentStep)) {
            calculateFinalScore()
        }
    }
    
    function calculateFinalScore() {
        currentScore = $uclsmrsManager.calculateScore(
                    macroFat,
                    microFat === -1 ? 1 : microFat,
                    t2Signal === -1 ? 0 : t2Signal,
                    arterialRatio1 === -1 ? 1 : arterialRatio1,
                    arterialIndex === -1 ? 1 : arterialIndex,
                    delayedIndex === -1 ? 1 : delayedIndex,
                    ader1 === -1 ? 1 : ader1,
                    arterialRatio2 === -1 ? 1 : arterialRatio2,
                    ader2 === -1 ? 1 : ader2
                    )
        detailedDiagnosis = $uclsmrsManager.getDetailedDiagnosis(
                    macroFat,
                    microFat === -1 ? 1 : microFat,
                    t2Signal === -1 ? 0 : t2Signal,
                    arterialRatio1 === -1 ? 1 : arterialRatio1,
                    arterialIndex === -1 ? 1 : arterialIndex,
                    delayedIndex === -1 ? 1 : delayedIndex,
                    ader1 === -1 ? 1 : ader1,
                    arterialRatio2 === -1 ? 1 : arterialRatio2,
                    ader2 === -1 ? 1 : ader2
                    )
        $uclsmrsManager.finishScore(currentScore, detailedDiagnosis)
        showResult = true
    }
    
    function resetValues() {
        macroFat = -1
        microFat = -1
        t2Signal = -1
        arterialRatio1 = -1
        arterialIndex = -1
        delayedIndex = -1
        ader1 = -1
        arterialRatio2 = -1
        ader2 = -1
        currentScore = 0
        detailedDiagnosis = ""
        currentStep = 0
        showResult = false
        
        // 重置所有按钮组
        macroFatGroup.selectedIndex = -1
        microFatGroup.selectedIndex = -1
        t2SignalGroup.selectedIndex = -1
        arterialRatio1Group.selectedIndex = -1
        arterialIndexGroup.selectedIndex = -1
        delayedIndexGroup.selectedIndex = -1
        ader1Group.selectedIndex = -1
        arterialRatio2Group.selectedIndex = -1
        ader2Group.selectedIndex = -1
    }
}
