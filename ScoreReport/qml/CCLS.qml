import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import "./components"

Rectangle {
    id: cclsView
    height: cclsColumn.height
    width: parent.width
    color: "transparent"
    signal exitScore()
    
    property int currentStep: 0      // 当前步骤 (0-5)
    property int currentScore: 0
    property string detailedDiagnosis: ""
    property var messageManager: null
    // 评分参数
    property int t2Signal: -1        // 0:高信号 1:等信号 2:低信号
    property int enhancement: -1     // 0:明显强化 1:中度强化 2:轻度强化
    property int microFat: -1        // 0:否 1:是
    property int segmentalReversal: -1 // 0:是 1:否
    property int arterialRatio: -1   // 0:否 1:是 (动脉期/延迟期强化比≥1.5)
    property int diffusionRestriction: -1 // 0:否 1:是 (明显/均匀弥散受限)
    
    property bool showResult: false
    
    Column {
        id: cclsColumn
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
                        id: cclsImage
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        height: 32
                        source: "qrc:/image/CCLS.png"
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
                        text: showResult ? qsTr("已完成CCLS评分！") : qsTr("CCLS评分分析中，请填写以下信息")
                    }
                }
                
                // 步骤1: T2信号选择
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
                            text: "T2信号（相对肾皮质）"
                        }
                    }
                    TextButtonGroup {
                        id: t2SignalGroup
                        width: parent.width
                        options: ["高信号", "等信号", "低信号"]
                        selectedIndex: cclsView.t2Signal
                        disabled: currentStep > 0 && !showResult
                        visible: currentStep === 0 || t2Signal >= 0
                        onSelectionChanged: {
                            cclsView.t2Signal = index
                            if (currentStep === 0) {
                                nextStep()
                            }
                        }
                    }
                }
                
                // 步骤2: 皮髓质期强化程度选择
                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible: currentStep >= 1 && !showResult
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: currentStep === 1 ? "#006BFF" : "#D9000000"
                            text: "皮髓质期强化程度（相对肾皮质）"
                        }
                    }
                    TextButtonGroup {
                        id: enhancementGroup
                        width: parent.width
                        options: ["明显强化", "中度强化", "轻度强化"]
                        selectedIndex: cclsView.enhancement
                        disabled: currentStep > 1 && !showResult
                        visible: currentStep === 1 || enhancement >= 0
                        onSelectionChanged: {
                            cclsView.enhancement = index
                            if (currentStep === 1) {
                                nextStep()
                            }
                        }
                    }
                }
                
                // 步骤3: 微观脂肪选择
                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible: currentStep >= 2 && $cclsScorer.needsOption(t2Signal, enhancement, 2, microFat) && !showResult
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: currentStep === 2 ? "#006BFF" : "#D9000000"
                            text: "微观脂肪"
                        }
                    }
                    TextButtonGroup {
                        id: microFatGroup
                        width: parent.width
                        options: ["是", "否"]
                        selectedIndex: cclsView.microFat
                        disabled: currentStep > 2 && !showResult
                        visible: currentStep === 2 || microFat >= 0
                        onSelectionChanged: {
                            cclsView.microFat = index
                            if (currentStep === 2) {
                                nextStep()
                            }
                        }
                    }
                }
                
                // 步骤4: 节段性强化反转选择
                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible: currentStep >= 3 && $cclsScorer.needsOption(t2Signal, enhancement, 3, microFat) && !showResult
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: currentStep === 3 ? "#006BFF" : "#D9000000"
                            text: "节段性强化反转"
                        }
                    }
                    TextButtonGroup {
                        id: segmentalReversalGroup
                        width: parent.width
                        options: ["是", "否"]
                        selectedIndex: cclsView.segmentalReversal
                        disabled: currentStep > 3 && !showResult
                        visible: currentStep === 3 || segmentalReversal >= 0
                        onSelectionChanged: {
                            cclsView.segmentalReversal = index
                            if (currentStep === 3) {
                                nextStep()
                            }
                        }
                    }
                }
                
                // 步骤5: 动脉期/延迟期强化比≥1.5
                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible: currentStep >= 4 && $cclsScorer.needsOption(t2Signal, enhancement, 4, microFat) && !showResult
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: currentStep === 4 ? "#006BFF" : "#D9000000"
                            text: "动脉期/延迟期强化比≥1.5"
                        }
                    }
                    
                    TextButtonGroup {
                        id: arterialRatioGroup
                        width: parent.width
                        options: ["是", "否"]
                        selectedIndex: cclsView.arterialRatio
                        disabled: currentStep > 4 && !showResult
                        visible: currentStep === 4 || arterialRatio >= 0
                        onSelectionChanged: {
                            cclsView.arterialRatio = index
                            if (currentStep === 4) {
                                nextStep()
                            }
                        }
                    }
                }
                
                // 步骤6: 明显/均匀弥散受限
                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible: currentStep >= 5 && $cclsScorer.needsOption(t2Signal, enhancement, 5, microFat) && !showResult
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: currentStep === 5 ? "#006BFF" : "#D9000000"
                            text: "明显/均匀弥散受限"
                        }
                    }
                    
                    TextButtonGroup {
                        id: diffusionRestrictionGroup
                        width: parent.width
                        options: ["是", "否"]
                        selectedIndex: cclsView.diffusionRestriction
                        disabled: showResult
                        visible: currentStep === 5 || diffusionRestriction >= 0
                        onSelectionChanged: {
                            cclsView.diffusionRestriction = index
                            if (currentStep === 5) {
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
                                text: "CCLS评分："
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
                            text: $cclsScorer.sourceText
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
                    cclsView.exitScore()
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
                    cclsView.exitScore()
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
                    $cclsScorer.copyToClipboard()
                    messageManager.success("已复制！")
                }
            }
        }
    }
    
    function nextStep() {
        // 跳过不需要的步骤
        do {
            currentStep++
        } while (currentStep <= 5 && !$cclsScorer.needsOption(t2Signal, enhancement, currentStep, microFat))
        
        // 如果所有必要步骤都完成了，自动计算分数
        if (currentStep > 5 || !$cclsScorer.needsOption(t2Signal, enhancement, currentStep, microFat)) {
            calculateFinalScore()
        }
    }
    
    function calculateFinalScore() {
        currentScore = $cclsScorer.calculateScore(
                    t2Signal,
                    enhancement,
                    microFat === -1 ? 1 : microFat,         // 默认为"否"(1)
                    segmentalReversal === -1 ? 1 : segmentalReversal,  // 默认为"否"(1)
                    arterialRatio === -1 ? 1 : arterialRatio,          // 默认为"否"(1)
                    diffusionRestriction === -1 ? 1 : diffusionRestriction  // 默认为"否"(1)
                    )
        detailedDiagnosis = $cclsScorer.getDetailedDiagnosis(
                    t2Signal,
                    enhancement,
                    microFat === -1 ? 1 : microFat,
                    segmentalReversal === -1 ? 1 : segmentalReversal,
                    arterialRatio === -1 ? 1 : arterialRatio,
                    diffusionRestriction === -1 ? 1 : diffusionRestriction
                    )
        $cclsScorer.finishScore(currentScore, detailedDiagnosis)
        showResult = true
    }
    
    function resetValues() {
        t2Signal = -1
        enhancement = -1
        microFat = -1
        segmentalReversal = -1
        arterialRatio = -1
        diffusionRestriction = -1
        currentScore = 0
        detailedDiagnosis = ""
        currentStep = 0
        showResult = false
        
        // 重置所有按钮组
        t2SignalGroup.selectedIndex = -1
        enhancementGroup.selectedIndex = -1
        microFatGroup.selectedIndex = -1
        segmentalReversalGroup.selectedIndex = -1
        arterialRatioGroup.selectedIndex = -1
        diffusionRestrictionGroup.selectedIndex = -1
    }
}
