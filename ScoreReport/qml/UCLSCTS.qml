import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import "./components"

Rectangle {
    id: uclsctsView
    height: uclsctsColumn.height
    width: parent.width
    color: "transparent"
    signal exitScore()
    
    property int currentStep: 0      // 当前步骤 (0-8)
    property int currentScore: 0
    property var messageManager: null
    
    // 评分参数
    property int nonEnhancedAttenuation: -1     // 不强化区域衰减量绝对值小于45HU
    property int maxEnhancementPhase: -1        // 在皮髓质期病变强化程度最高
    property int absoluteEnhancement: -1        // 绝对强化
    property int relativeEnhancement: -1        // 皮髓质期相对强化
    property int heterogeneousEnhancement: -1   // 非均匀强化
    property int irregularShape: -1             // 不规则外形
    property int neovascularity: -1             // 新生血管
    property int dystrophicCalcification: -1    // 营养不良性钙化
    property int splittingSign: -1              // 劈裂征
    
    property bool showResult: false
    
    Column {
        id: uclsctsColumn
        spacing: 20
        width: parent.width
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        
        ScrollView {
            height: 900
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width - 48
            clip: true
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
                        id: uclsctsImage
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        height: 32
                        source: "qrc:/image/UCLS-CTS.png"
                    }
                    
                    Text {
                        id: uclsctsInfo
                        anchors.left: uclsctsImage.right
                        anchors.leftMargin: 8
                        font.family: "Alibaba PuHuiTi 3.0"
                        font.weight: Font.Bold
                        font.pixelSize: 16
                        color: "#D9000000"
                        anchors.verticalCenter: parent.verticalCenter
                        text: showResult ? qsTr("已完成UCLS CTS评分！") : qsTr("UCLS CTS评分分析中，请填写以下信息")
                    }
                }
                
                // 定量特征标题
                Rectangle {
                    height: 32
                    width: parent.width
                    color: "transparent"
                    visible: currentStep >= 0 && !showResult
                    Image {
                        id: uclsctsQuantityImage
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        height: 32
                        source: "qrc:/image/UCLS-CTS.png"
                    }

                    Text {
                        id: uclsctsQuantityInfo
                        anchors.left: uclsctsQuantityImage.right
                        anchors.leftMargin: 8
                        font.family: "Alibaba PuHuiTi 3.0"
                        font.weight: Font.Bold
                        font.pixelSize: 16
                        color: "#D9000000"
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("定量特征分析中")
                    }
                }
                
                // 步骤1: 不强化区域衰减量绝对值小于45HU
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
                            text: qsTr("不强化区域衰减量绝对值小于45HU")
                        }
                    }
                    TextButtonGroup {
                        id: nonEnhancedAttenuationGroup
                        width: parent.width
                        options: ["是", "否"]
                        selectedIndex: uclsctsView.nonEnhancedAttenuation
                        disabled: currentStep > 0 && !showResult
                        visible: currentStep === 0 || nonEnhancedAttenuation >= 0
                        onSelectionChanged: {
                            uclsctsView.nonEnhancedAttenuation = index
                            if (currentStep === 0) {
                                nextStep()
                            }
                        }
                    }
                }
                
                // 步骤2: 在皮髓质期病变强化程度最高
                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible: currentStep >= 1 && $uclsctsScorer.needsOption(1, nonEnhancedAttenuation, maxEnhancementPhase, heterogeneousEnhancement, irregularShape, neovascularity) && !showResult
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: currentStep === 1 ? "#006BFF" : "#D9000000"
                            text: qsTr("在皮髓质期病变强化程度最高")
                        }
                    }
                    TextButtonGroup {
                        id: maxEnhancementPhaseGroup
                        width: parent.width
                        options: ["是", "否"]
                        selectedIndex: uclsctsView.maxEnhancementPhase
                        disabled: currentStep > 1 && !showResult
                        visible: currentStep === 1 || maxEnhancementPhase >= 0
                        onSelectionChanged: {
                            uclsctsView.maxEnhancementPhase = index
                            if (currentStep === 1) {
                                nextStep()
                            }
                        }
                    }
                }
                
                // 步骤3: 绝对强化
                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible: currentStep >= 2 && !showResult
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: currentStep === 2 ? "#006BFF" : "#D9000000"
                            text: qsTr("绝对强化（皮髓质期病变ROI-实质期病变ROI）")
                        }
                    }
                    TextButtonGroup {
                        id: absoluteEnhancementGroup
                        width: parent.width
                        options: [">50", "25-50", "<25"]
                        selectedIndex: uclsctsView.absoluteEnhancement
                        disabled: currentStep > 2 && !showResult
                        visible: currentStep === 2 || absoluteEnhancement >= 0
                        onSelectionChanged: {
                            uclsctsView.absoluteEnhancement = index
                            if (currentStep === 2) {
                                nextStep()
                            }
                        }
                    }
                }
                
                // 步骤4: 皮髓质期相对强化
                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible: currentStep >= 3 && !showResult
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: currentStep === 3 ? "#006BFF" : "#D9000000"
                            text: qsTr("皮髓质期相对强化")
                        }
                    }
                    TextButtonGroup {
                        id: relativeEnhancementGroup
                        width: parent.width
                        options: ["<0", "1-10", "10-20", ">20"]
                        selectedIndex: uclsctsView.relativeEnhancement
                        disabled: currentStep > 3 && !showResult
                        visible: currentStep === 3 || relativeEnhancement >= 0
                        onSelectionChanged: {
                            uclsctsView.relativeEnhancement = index
                            if (currentStep === 3) {
                                nextStep()
                            }
                        }
                    }
                }
                
                // 定量特征标题
                Rectangle {
                    height: 32
                    width: parent.width
                    color: "transparent"
                    visible: currentStep >= 4 && !showResult
                    Image {
                        id: uclsctsQuanlityImage
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        height: 32
                        source: "qrc:/image/UCLS-CTS.png"
                    }

                    Text {
                        id: uclsctsQuanlityInfo
                        anchors.left: uclsctsQuanlityImage.right
                        anchors.leftMargin: 8
                        font.family: "Alibaba PuHuiTi 3.0"
                        font.weight: Font.Bold
                        font.pixelSize: 16
                        color: "#D9000000"
                        anchors.verticalCenter: parent.verticalCenter
                        text: qsTr("定量特征分析中")
                    }
                }
                
                // 步骤5: 非均匀强化
                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible: currentStep >= 4 && !showResult
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: currentStep === 4 ? "#006BFF" : "#D9000000"
                            text: qsTr("非均匀强化：实性强化区域伴有囊性/坏死性非强化区域")
                        }
                    }
                    TextButtonGroup {
                        id: heterogeneousEnhancementGroup
                        width: parent.width
                        options: ["是", "否"]
                        selectedIndex: uclsctsView.heterogeneousEnhancement
                        disabled: currentStep > 4 && !showResult
                        visible: currentStep === 4 || heterogeneousEnhancement >= 0
                        onSelectionChanged: {
                            uclsctsView.heterogeneousEnhancement = index
                            if (currentStep === 4) {
                                nextStep()
                            }
                        }
                    }
                }
                
                // 步骤6: 不规则外形
                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible: currentStep >= 5 && $uclsctsScorer.needsOption(5, nonEnhancedAttenuation, maxEnhancementPhase, heterogeneousEnhancement, irregularShape, neovascularity) && !showResult
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: currentStep === 5 ? "#006BFF" : "#D9000000"
                            text: qsTr("不规则外形")
                        }
                    }
                    TextButtonGroup {
                        id: irregularShapeGroup
                        width: parent.width
                        options: ["是", "否"]
                        selectedIndex: uclsctsView.irregularShape
                        disabled: currentStep > 5 && !showResult
                        visible: currentStep === 5 || irregularShape >= 0
                        onSelectionChanged: {
                            uclsctsView.irregularShape = index
                            if (currentStep === 5) {
                                nextStep()
                            }
                        }
                    }
                }
                
                // 步骤7: 新生血管
                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible: currentStep >= 6 && $uclsctsScorer.needsOption(6, nonEnhancedAttenuation, maxEnhancementPhase, heterogeneousEnhancement, irregularShape, neovascularity) && !showResult
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: currentStep === 6 ? "#006BFF" : "#D9000000"
                            text: qsTr("新生血管：受累肾脏附近肾筋膜有不规则和未命名的血管")
                        }
                    }
                    TextButtonGroup {
                        id: neovascularityGroup
                        width: parent.width
                        options: ["是", "否"]
                        selectedIndex: uclsctsView.neovascularity
                        disabled: currentStep > 6 && !showResult
                        visible: currentStep === 6 || neovascularity >= 0
                        onSelectionChanged: {
                            uclsctsView.neovascularity = index
                            if (currentStep === 6) {
                                nextStep()
                            }
                        }
                    }
                }
                
                // 步骤8: 营养不良性钙化
                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible: currentStep >= 7 && $uclsctsScorer.needsOption(7, nonEnhancedAttenuation, maxEnhancementPhase, heterogeneousEnhancement, irregularShape, neovascularity) && !showResult
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: currentStep === 7 ? "#006BFF" : "#D9000000"
                            text: qsTr("营养不良性钙化")
                        }
                    }
                    TextButtonGroup {
                        id: dystrophicCalcificationGroup
                        width: parent.width
                        options: ["是", "否"]
                        selectedIndex: uclsctsView.dystrophicCalcification
                        disabled: currentStep > 7 && !showResult
                        visible: currentStep === 7 || dystrophicCalcification >= 0
                        onSelectionChanged: {
                            uclsctsView.dystrophicCalcification = index
                            if (currentStep === 7) {
                                nextStep()
                            }
                        }
                    }
                }
                
                // 步骤9: 劈裂征
                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible: currentStep >= 8 && !showResult
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: currentStep === 8 ? "#006BFF" : "#D9000000"
                            text: qsTr("劈裂征")
                        }
                    }
                    
                    TextButtonGroup {
                        id: splittingSignGroup
                        width: parent.width
                        options: ["是", "否"]
                        selectedIndex: uclsctsView.splittingSign
                        disabled: showResult
                        visible: currentStep === 8 || splittingSign >= 0
                        onSelectionChanged: {
                            uclsctsView.splittingSign = index
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
                                text: "UCLS CTS评分："
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

                        Rectangle{
                            height: 4
                            width: parent.width - 36
                            color:"transparent"
                        }

                        Text {
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 12
                            color: "#73000000"
                            text: $uclsctsScorer.sourceText
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
                text: qsTr("终止")
                width: 88
                height: 36
                radius: 4
                fontSize: 14
                visible: !showResult
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                onClicked: {
                    resetValues()
                    uclsctsView.exitScore()
                }
            }
            
            CustomButton {
                id: resetBtn
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 24
                text: qsTr("重置")
                width: 88
                height: 36
                radius: 4
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
                text: qsTr("再次评分")
                width: 88
                height: 36
                radius: 4
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
                text: qsTr("重选方案")
                width: 88
                height: 36
                radius: 4
                visible: showResult
                fontSize: 14
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                onClicked: {
                    resetValues()
                    uclsctsView.exitScore()
                }
            }

            CustomButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 24
                text: qsTr("复制")
                width: 88
                height: 36
                radius: 4
                visible: showResult
                fontSize: 14
                borderWidth: 0
                backgroundColor: "#006BFF"
                onClicked: {
                    $uclsctsScorer.copyToClipboard()
                    messageManager.success("已复制！")
                }
            }
        }
    }
    
    function nextStep() {
        // 跳过不需要的步骤
        do {
            currentStep++
        } while (currentStep <= 8 && !$uclsctsScorer.needsOption(currentStep, nonEnhancedAttenuation, maxEnhancementPhase, heterogeneousEnhancement, irregularShape, neovascularity))
        
        // 如果所有必要步骤都完成了，自动计算分数
        if (currentStep > 8 || !$uclsctsScorer.needsOption(currentStep, nonEnhancedAttenuation, maxEnhancementPhase, heterogeneousEnhancement, irregularShape, neovascularity)) {
            calculateFinalScore()
        }
    }
    
    function calculateFinalScore() {
        currentScore = $uclsctsScorer.calculateScore(
                    nonEnhancedAttenuation === -1 ? 1 : nonEnhancedAttenuation,
                    maxEnhancementPhase === -1 ? 1 : maxEnhancementPhase,
                    absoluteEnhancement === -1 ? 2 : absoluteEnhancement,
                    relativeEnhancement === -1 ? 0 : relativeEnhancement,
                    heterogeneousEnhancement === -1 ? 1 : heterogeneousEnhancement,
                    irregularShape === -1 ? 1 : irregularShape,
                    neovascularity === -1 ? 1 : neovascularity,
                    dystrophicCalcification === -1 ? 1 : dystrophicCalcification,
                    splittingSign === -1 ? 1 : splittingSign
                    )
        $uclsctsScorer.finishScore(currentScore)
        showResult = true
    }
    
    function resetValues() {
        nonEnhancedAttenuation = -1
        maxEnhancementPhase = -1
        absoluteEnhancement = -1
        relativeEnhancement = -1
        heterogeneousEnhancement = -1
        irregularShape = -1
        neovascularity = -1
        dystrophicCalcification = -1
        splittingSign = -1
        currentScore = 0
        currentStep = 0
        showResult = false
        
        // 重置所有按钮组
        nonEnhancedAttenuationGroup.selectedIndex = -1
        maxEnhancementPhaseGroup.selectedIndex = -1
        absoluteEnhancementGroup.selectedIndex = -1
        relativeEnhancementGroup.selectedIndex = -1
        heterogeneousEnhancementGroup.selectedIndex = -1
        irregularShapeGroup.selectedIndex = -1
        neovascularityGroup.selectedIndex = -1
        dystrophicCalcificationGroup.selectedIndex = -1
        splittingSignGroup.selectedIndex = -1
    }
} 
