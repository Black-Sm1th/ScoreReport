import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import "./components"

Rectangle {
    id: cclsaiView
    height: cclsaiColumn.height
    width: parent.width
    color: "transparent"
    signal exitScore()
    
    property int currentStep: 0      // 当前步骤 (0-5)
    property var messageManager: null
    
    // 评分参数
    property int t2Signal: -1        // 0:低信号 1:中信号 2:高信号
    property int enhancement: -1     // 0:轻度强化 1:中度强化 2:明显强化
    property int microFat: -1        // 0:无 1:有
    property int sei: -1             // 0:无 1:有
    property int ader: -1            // 0:无 1:有
    property int diffusionRestriction: -1 // 0:无 1:有
    
    property bool showResult: false
    
    Column {
        id: cclsaiColumn
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
                        id: cclsaiImage
                        anchors.verticalCenter: parent.verticalCenter
                        width: 32
                        height: 32
                        source: "qrc:/image/BIOSNAK.png"
                    }
                    
                    Text {
                        id: cclsaiInfo
                        anchors.left: cclsaiImage.right
                        anchors.leftMargin: 8
                        font.family: "Alibaba PuHuiTi 3.0"
                        font.weight: Font.Bold
                        font.pixelSize: 16
                        color: "#D9000000"
                        anchors.verticalCenter: parent.verticalCenter
                        text: showResult ? qsTr("已完成CCLS-AI评分！") : qsTr("CCLS-AI评分分析中，请填写以下信息")
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
                            text: "T2信号"
                        }
                    }
                    TextButtonGroup {
                        id: t2SignalGroup
                        width: parent.width
                        options: ["低信号", "中信号", "高信号"]
                        selectedIndex: cclsaiView.t2Signal
                        disabled: currentStep > 0
                        visible: currentStep === 0 || t2Signal >= 0
                        onSelectionChanged: {
                            cclsaiView.t2Signal = index
                            if (currentStep === 0) {
                                nextStep()
                            }
                        }
                    }
                }
                
                // 步骤2: 皮髓质期
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
                            text: "皮髓质期"
                        }
                    }
                    TextButtonGroup {
                        id: enhancementGroup
                        width: parent.width
                        options: ["轻度强化", "中度强化", "明显强化"]
                        selectedIndex: cclsaiView.enhancement
                        disabled: currentStep > 1
                        visible: currentStep === 1 || enhancement >= 0
                        onSelectionChanged: {
                            cclsaiView.enhancement = index
                            if (currentStep === 1) {
                                nextStep()
                            }
                        }
                    }
                }
                
                // 步骤3: 微观脂肪
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
                            text: "微观脂肪"
                        }
                    }
                    TextButtonGroup {
                        id: microFatGroup
                        width: parent.width
                        options: ["无", "有"]
                        selectedIndex: cclsaiView.microFat
                        disabled: currentStep > 2
                        visible: currentStep === 2 || microFat >= 0
                        onSelectionChanged: {
                            cclsaiView.microFat = index
                            if (currentStep === 2) {
                                nextStep()
                            }
                        }
                    }
                }
                
                // 步骤4: SEI
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
                            text: "SEI"
                        }
                    }
                    TextButtonGroup {
                        id: seiGroup
                        width: parent.width
                        options: ["无", "有"]
                        selectedIndex: cclsaiView.sei
                        disabled: currentStep > 3
                        visible: currentStep === 3 || sei >= 0
                        onSelectionChanged: {
                            cclsaiView.sei = index
                            if (currentStep === 3) {
                                nextStep()
                            }
                        }
                    }
                }
                
                // 步骤5: ADER≥1.5
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
                            text: "ADER≥1.5"
                        }
                    }
                    
                    TextButtonGroup {
                        id: aderGroup
                        width: parent.width
                        options: ["无", "有"]
                        selectedIndex: cclsaiView.ader
                        disabled: currentStep > 4
                        visible: currentStep === 4 || ader >= 0
                        onSelectionChanged: {
                            cclsaiView.ader = index
                            if (currentStep === 4) {
                                nextStep()
                            }
                        }
                    }
                }
                
                // 步骤6: 弥散受限
                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible: currentStep >= 5 && !showResult
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: currentStep === 5 ? "#006BFF" : "#D9000000"
                            text: "弥散受限"
                        }
                    }
                    
                    TextButtonGroup {
                        id: diffusionRestrictionGroup
                        width: parent.width
                        options: ["无", "有"]
                        selectedIndex: cclsaiView.diffusionRestriction
                        disabled: showResult
                        visible: currentStep === 5 || diffusionRestriction >= 0
                        onSelectionChanged: {
                            cclsaiView.diffusionRestriction = index
                            if (currentStep === 5) {
                                calculateFinalScore()
                            }
                        }
                    }
                }

                // 计算中提示
                Rectangle {
                    width: parent.width
                    height: 60
                    visible: $cclsAIScorer.calculating && !showResult
                    color: "#ECF3FF"
                    radius: 8
                    
                    Row {
                        anchors.centerIn: parent
                        spacing: 10
                        
                        AnimatedImage {
                            width: 32
                            height: 32
                            source: "qrc:/gif/loading.gif"
                            anchors.verticalCenter: parent.verticalCenter
                        }
                        
                        Text {
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 14
                            color: "#006BFF"
                            text: qsTr("AI计算中，请稍候...")
                            anchors.verticalCenter: parent.verticalCenter
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
                        
                        // 标题
                        Row {
                            height: 24
                            width: parent.width
                            Text {
                                font.weight: Font.Bold
                                font.family: "Alibaba PuHuiTi 3.0"
                                font.pixelSize: 16
                                color: "#D9000000"
                                text: qsTr("CCLS-AI评分结果")
                                anchors.verticalCenter: parent.verticalCenter
                            }
                        }

                        // CCLS概率
                        Text {
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: "#A6000000"
                            text: "CCLS：" + $cclsAIScorer.cclsResult
                        }

                        // CCRCC概率
                        Text {
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: "#A6000000"
                            text: "CCRCC：" + $cclsAIScorer.ccrccResult
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
                            text: $cclsAIScorer.sourceText
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
                    cclsaiView.exitScore()
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
                    cclsaiView.exitScore()
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
                    $cclsAIScorer.copyToClipboard()
                    messageManager.success("已复制！")
                }
            }
        }
    }
    
    Component.onCompleted: {
        // 监听计算完成信号
        $cclsAIScorer.calculationFinished.connect(function(success, errorMessage) {
            if (success) {
                showResult = true
            } else {
                messageManager.error("计算失败：" + errorMessage)
                // 可以选择重置或保持当前状态
            }
        })
    }
    
    function nextStep() {
        // 没有需要跳过的步骤，直接进入下一步
        currentStep++
        
        // 如果所有步骤都完成了，自动计算分数
        if (currentStep > 5) {
            calculateFinalScore()
        }
    }
    
    function calculateFinalScore() {
        // 调用AI计算
        $cclsAIScorer.calculateKidney(
            t2Signal,
            enhancement,
            microFat,
            sei,
            ader,
            diffusionRestriction
        )
    }
    
    function resetValues() {
        t2Signal = -1
        enhancement = -1
        microFat = -1
        sei = -1
        ader = -1
        diffusionRestriction = -1
        currentStep = 0
        showResult = false
        
        // 重置所有按钮组
        t2SignalGroup.selectedIndex = -1
        enhancementGroup.selectedIndex = -1
        microFatGroup.selectedIndex = -1
        seiGroup.selectedIndex = -1
        aderGroup.selectedIndex = -1
        diffusionRestrictionGroup.selectedIndex = -1
    }
}
