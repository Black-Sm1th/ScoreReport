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
    
    property int currentStep: 0      // 当前步骤 (0-6)
    property int currentScore: 0
    property string detailedDiagnosis: ""
    property var messageManager: null
    
    // 评分参数
    property int macroFat: -1               // 0:有 1:无
    property int microFat: -1               // 0:有 1:无  
    property int t2Signal: -1               // 0:高 1:低
    property int arterialRatio1: -1         // 0:>100 1:≤100 (动脉强化比)
    property int arterialIndex: -1          // 0:≥5 1:<5 (相对动脉增强比)
    property int delayedIndex: -1           // 0:≥125 1:<125 (延迟增强指数)
    property int ader1: -1                  // 0:>1.5 1:≤1.5 (ADER)
    
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
                        text: showResult ? qsTr("已完成UCLS MRS评分！") : qsTr("UCLS MRS评分分析中，请填写以下信息")
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
                            text: qsTr("宏观脂肪")
                        }
                    }
                    TextButtonGroup {
                        id: macroFatGroup
                        width: parent.width
                        options: [qsTr("有"), qsTr("无")]
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
                            text: qsTr("微脂肪")
                        }
                    }
                    TextButtonGroup {
                        id: microFatGroup
                        width: parent.width
                        options: [qsTr("有"), qsTr("无")]
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
                            text: qsTr("T2信号强度")
                        }
                    }
                    TextButtonGroup {
                        id: t2SignalGroup
                        width: parent.width
                        // 有微脂肪时显示"高"和"低"，无微脂肪时显示"高或等"和"低"
                        options: microFat === 0 ? [qsTr("高"), qsTr("低")] : [qsTr("高或等"), qsTr("低")]
                        selectedIndex: {
                            if (uclsmrsView.t2Signal === -1) return -1
                            if (microFat === 0) {
                                // 有微脂肪时：0=高显示为0，2=低显示为1
                                return uclsmrsView.t2Signal === 0 ? 0 : 1
                            } else {
                                // 无微脂肪时：0或1=高或等显示为0，2=低显示为1
                                return (uclsmrsView.t2Signal === 0 || uclsmrsView.t2Signal === 1) ? 0 : 1
                            }
                        }
                        disabled: currentStep > 2 && !showResult
                        visible: currentStep === 2 || t2Signal >= 0
                        onSelectionChanged: {
                            if (microFat === 0) {
                                // 有微脂肪时：0=高，1=低
                                uclsmrsView.t2Signal = index === 0 ? 0 : 2  // 0=高，2=低
                            } else {
                                // 无微脂肪时：0=高或等，1=低
                                // 这里将"高或等"映射为高信号(0)，因为在评分逻辑中高或等都是同样处理的
                                uclsmrsView.t2Signal = index === 0 ? 0 : 2  // 0=高或等，2=低
                            }
                            if (currentStep === 2) {
                                nextStep()
                            }
                        }
                    }
                }
                
                // 步骤3: 动脉强化比选择 (仅无微脂肪时显示)
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
                            text: qsTr("动脉强化比(病灶CM-病灶平扫期)/病灶平扫期")
                        }
                    }
                    TextButtonGroup {
                        id: arterialRatio1Group
                        width: parent.width
                        options: [qsTr("> 100"), qsTr("≤ 100")]
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
                
                // 步骤4: 相对动脉增强比选择 (仅高T2且动脉强化比>100时显示)
                Column {
                    width: parent.width - 40
                    spacing: 10
                    leftPadding: 40
                    visible: currentStep >= 4 && $uclsmrsManager.needsOption(macroFat, microFat, t2Signal, 4, arterialRatio1) && !showResult
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: currentStep === 4 ? "#006BFF" : "#D9000000"
                            text: qsTr("相对动脉增强比(病灶CM-皮质CM)/皮质CM")
                        }
                    }
                    TextButtonGroup {
                        id: arterialIndexGroup
                        width: parent.width
                        options: ["≥ -5", "< -5"]
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
                    visible: currentStep >= 5 && $uclsmrsManager.needsOption(macroFat, microFat, t2Signal, 5, arterialRatio1, arterialIndex) && !showResult
                    Rectangle{
                        height: 24
                        width:parent.width
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: currentStep === 5 ? "#006BFF" : "#D9000000"
                            text: qsTr("延迟增强指数(病灶排泄期-病灶平扫期)/病灶平扫期")
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
                
                // 步骤6: ADER选择 (仅低T2信号时显示)
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
                            text: qsTr("ADER(病灶皮髓质期-病灶平扫期)/(病灶排泄期-病灶平扫期)")
                        }
                    }
                    TextButtonGroup {
                        id: ader1Group
                        width: parent.width
                        options: [qsTr("> 1.5"), qsTr("≤ 1.5")]
                        selectedIndex: uclsmrsView.ader1
                        disabled: showResult
                        visible: currentStep === 6 || ader1 >= 0
                        onSelectionChanged: {
                            uclsmrsView.ader1 = index
                            if (currentStep === 6) {
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
                                text: qsTr("UCLS MRS评分：")
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
                            text: {
                                var text = ""
                                if(currentScore === 1){
                                    text = qsTr("肯定良性。")
                                }else if(currentScore === 2){
                                    text = qsTr("可能良性。")
                                }else if(currentScore === 3){
                                    text = qsTr("不确定。")
                                }else if(currentScore === 4){
                                    text = qsTr("可能恶性。")
                                }else if(currentScore === 5){
                                    text = qsTr("肯定ccRCC。")
                                }
                                return detailedDiagnosis + "，" + text
                            }
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
                text: qsTr("终止")
                width: 88
                height: 36
                fontSize: 14
                radius: 4
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
                    uclsmrsView.exitScore()
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
                    $uclsmrsManager.copyToClipboard()
                    messageManager.success(qsTr("已复制！"))
                }
            }
        }
    }
    
    function nextStep() {
        // 如果有微脂肪，在T2信号选择后直接计算分数
        if (macroFat == 1 && microFat == 0 && currentStep == 2) {
            calculateFinalScore()
            return
        }
        
        // 跳过不需要的步骤
        do {
            currentStep++
        } while (currentStep <= 6 && !$uclsmrsManager.needsOption(macroFat, microFat, t2Signal, currentStep, arterialRatio1, arterialIndex))
        
        // 如果所有必要步骤都完成了，自动计算分数
        if (currentStep > 6 || !$uclsmrsManager.needsOption(macroFat, microFat, t2Signal, currentStep, arterialRatio1, arterialIndex)) {
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
                    0, // arterialRatio2 不再使用
                    0  // ader2 不再使用
                    )
        detailedDiagnosis = $uclsmrsManager.getDetailedDiagnosis(
                    macroFat,
                    microFat === -1 ? 1 : microFat,
                    t2Signal === -1 ? 0 : t2Signal,
                    arterialRatio1 === -1 ? 1 : arterialRatio1,
                    arterialIndex === -1 ? 1 : arterialIndex,
                    delayedIndex === -1 ? 1 : delayedIndex,
                    ader1 === -1 ? 1 : ader1,
                    0, // arterialRatio2 不再使用
                    0  // ader2 不再使用
                    )
        $uclsmrsManager.finishScore(currentScore, detailedDiagnosis)
        showResult = true
    }
    
    function resetValues() {
        // 重置所有评分参数
        macroFat = -1
        microFat = -1
        t2Signal = -1
        arterialRatio1 = -1
        arterialIndex = -1
        delayedIndex = -1
        ader1 = -1
        
        // 重置界面状态
        currentScore = 0
        detailedDiagnosis = ""
        currentStep = 0
        showResult = false

        // 重置所有按钮组的选择状态
        // 注意：需要在下一帧重置，避免绑定冲突
        Qt.callLater(function() {
            macroFatGroup.selectedIndex = -1
            microFatGroup.selectedIndex = -1
            // t2SignalGroup会通过绑定自动更新，但需要确保正确重置
            t2SignalGroup.selectedIndex = -1
            arterialRatio1Group.selectedIndex = -1
            arterialIndexGroup.selectedIndex = -1
            delayedIndexGroup.selectedIndex = -1
            ader1Group.selectedIndex = -1
        })
    }
}
