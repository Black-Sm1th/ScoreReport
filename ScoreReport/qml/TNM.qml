import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import "./components"

Rectangle {
    id: tnmView
    height: tnmColumn.height
    width: parent.width
    color: "transparent"
    property var messageManager: null
    signal exitScore()
    
    // 存储所有多行输入框的内容
    property var inputTexts: []
    
    // 重置所有输入框
    function resetAllInputs() {
        inputTexts = []
        for (var i = 0; i < $tnmManager.tipList.length; i++) {
            inputTexts[i] = ""
        }
        inputTextsChanged() // 手动触发更新
    }
    
    // 提交所有内容
    function submitAllContent() {
        var contents = []
        for (var i = 0; i < inputTexts.length; i++) {
            if (inputTexts[i] && inputTexts[i].trim() !== "") {
                contents.push(inputTexts[i].trim())
            }
        }
        $tnmManager.submitContent(contents)
    }
    
    // 省略号动画状态
    property int dotCount: 1
    
    Connections{
        target: $tnmManager
        function onCheckFailed(){
            messageManager.warning("剪贴板为空，请先复制内容")
        }
    }

    // 省略号动画定时器
    Timer {
        id: dotTimer
        interval: 500  // 每500ms切换一次
        running: $tnmManager.isAnalyzing
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
    
    Column {
        id: tnmColumn
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
                text: $tnmManager.clipboardContent
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
                    source: "qrc:/image/TNM.png"
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
                        if($tnmManager.isAnalyzing){
                            return "TNM分析中" + getDots()
                        }
                        if($tnmManager.isCompleted){
                            return "已完成TNM分析！"
                        }else if(!$tnmManager.isCompleted && $tnmManager.inCompleteInfo){
                            return $tnmManager.inCompleteInfo
                        }else{
                            return ""
                        }
                    }
                }
            }
            Repeater {
                model: $tnmManager.tipList.length
                delegate: Rectangle {
                    width:parent.width - 48
                    height: 52 + 12 + 148
                    visible:!$tnmManager.isAnalyzing && !$tnmManager.isCompleted
                    Rectangle{
                        color: "#ECF3FF"
                        radius: 8
                        width:parent.width
                        height: 52
                        Text{
                            id: tipText
                            elide: Text.ElideRight
                            wrapMode: Text.NoWrap
                            clip: true
                            width: parent.width - 36
                            anchors.left: parent.left
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 18
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: "#D9000000"
                            text: $tnmManager.tipList[index]
                            
                            property bool isTextTruncated: tipText.contentWidth > tipText.width
                            
                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                
                                ToolTip {
                                    id: textToolTip
                                    visible: parent.containsMouse && tipText.isTextTruncated
                                    text: $tnmManager.tipList[index]
                                    delay: 500  // 延迟500ms显示
                                    timeout: 5000  // 5秒后自动隐藏
                                    
                                    background: Rectangle {
                                        color: "#2D2D2D"
                                        radius: 6
                                        border.color: "#3A3A3A"
                                        border.width: 1
                                        
                                        DropShadow {
                                            anchors.fill: parent
                                            radius: 8
                                            samples: 16
                                            color: "#40000000"
                                            source: parent
                                        }
                                    }
                                    
                                    contentItem: Text {
                                        text: textToolTip.text
                                        font.family: "Alibaba PuHuiTi 3.0"
                                        font.pixelSize: 14
                                        color: "#FFFFFF"
                                        wrapMode: Text.Wrap
                                        maximumLineCount: 5
                                    }
                                }
                            }
                        }
                    }
                    MultiLineTextInput{
                        width: parent.width
                        height: 148
                        y:64
                        text: inputTexts[index] || ""
                        
                        Component.onCompleted: {
                            // 初始化数组
                            if (!inputTexts[index]) {
                                var newTexts = inputTexts.slice()
                                newTexts[index] = ""
                                inputTexts = newTexts
                            }
                        }
                        
                        onTextChanged: {
                            // 更新对应的数组项
                            var newTexts = inputTexts.slice()
                            newTexts[index] = text
                            inputTexts = newTexts
                        }
                    }
                }
            }
            Rectangle {
                width: parent.width - 48
                height: resultColumn.height
                visible:!$tnmManager.isAnalyzing && $tnmManager.isCompleted
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
                            text: "TNM分期："
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Text {
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.weight: Font.Bold
                            font.pixelSize: 16
                            color: "#D9000000"
                            text: $tnmManager.TNMConclusion
                            anchors.verticalCenter: parent.verticalCenter
                        }
                    }

                    Column {
                        id: resultText
                        width: parent.width -36
                        Text {
                            id:stageText
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: "#A6000000"
                            text: "临床分期：" + $tnmManager.Stage
                        }
                        Text {
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.weight: Font.Bold
                            font.pixelSize: 16
                            color: "#A6000000"
                            text: "T分期 （原发肿瘤）："
                        }
                        Row{
                            height: label1.height
                            width: parent.width
                            Rectangle{
                                height: 24
                                width: 24
                                color: "transparent"
                                Text{
                                    anchors.centerIn: parent
                                    text:"●"
                                    font.family: "Alibaba PuHuiTi 3.0"
                                    font.pixelSize: 6
                                    color: "#A6000000"
                                }
                            }
                            Text {
                                id:label1
                                font.family: "Alibaba PuHuiTi 3.0"
                                font.pixelSize: 16
                                color: "#A6000000"
                                width: parent.width - 24
                                wrapMode: Text.WrapAnywhere
                                text: $tnmManager.TConclusion
                            }
                        }
                        Text {
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.weight: Font.Bold
                            font.pixelSize: 16
                            color: "#A6000000"
                            text: "N分期 （区域淋巴结）："
                        }
                        Row{
                            height: label2.height
                            width: parent.width
                            Rectangle{
                                height: 24
                                width: 24
                                color: "transparent"
                                Text{
                                    anchors.centerIn: parent
                                    text:"●"
                                    font.family: "Alibaba PuHuiTi 3.0"
                                    font.pixelSize: 6
                                    color: "#A6000000"
                                }
                            }
                            Text {
                                id:label2
                                font.family: "Alibaba PuHuiTi 3.0"
                                font.pixelSize: 16
                                color: "#A6000000"
                                width: parent.width - 24
                                wrapMode: Text.WrapAnywhere
                                text: $tnmManager.NConclusion
                            }
                        }
                        Text {
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.weight: Font.Bold
                            font.pixelSize: 16
                            color: "#A6000000"
                            text: "M分期 （原发肿瘤）："
                        }
                        Row{
                            height: label3.height
                            width: parent.width
                            Rectangle{
                                height: 24
                                width: 24
                                color: "transparent"
                                Text{
                                    anchors.centerIn: parent
                                    text:"●"
                                    font.family: "Alibaba PuHuiTi 3.0"
                                    font.pixelSize: 6
                                    color: "#A6000000"
                                }
                            }
                            Text {
                                id:label3
                                font.family: "Alibaba PuHuiTi 3.0"
                                font.pixelSize: 16
                                color: "#A6000000"
                                width: parent.width - 24
                                wrapMode: Text.WrapAnywhere
                                text: $tnmManager.MConclusion
                            }
                        }
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
                        text: $tnmManager.sourceText
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
                anchors.right: parent.right
                anchors.rightMargin: 24
                visible: $tnmManager.isAnalyzing
                text: "终止"
                width: 88
                height: 36
                fontSize: 14
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                onClicked: {
                    $tnmManager.endAnalysis()
                    resetAllInputs()
                    exitScore()
                }
            }

            CustomButton {
                id: stopBtn
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 24
                visible: !$tnmManager.isAnalyzing && !$tnmManager.isCompleted
                text: "终止"
                width: 88
                height: 36
                fontSize: 14
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                onClicked: {
                    $tnmManager.endAnalysis()
                    resetAllInputs()
                    exitScore()
                }
            }

            CustomButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: stopBtn.right
                anchors.leftMargin: 12
                visible: !$tnmManager.isAnalyzing && !$tnmManager.isCompleted
                text: "重置"
                width: 88
                height: 36
                fontSize: 14
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                onClicked: {
                    resetAllInputs()
                }
            }

            CustomButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 24
                visible: !$tnmManager.isAnalyzing && !$tnmManager.isCompleted
                text: "提交"
                width: 88
                height: 36
                fontSize: 14
                backgroundColor: "#006BFF"
                textColor: "#FFFFFF"
                onClicked: {
                    submitAllContent()
                }
            }

            CustomButton {
                id: resetBtn
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 24
                visible: !$tnmManager.isAnalyzing && $tnmManager.isCompleted
                text: "粘贴并评分"
                width: 88
                height: 36
                fontSize: 14
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                onClicked: {
                    $tnmManager.pasteAnalysis()
                    resetAllInputs()
                }
            }

            CustomButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: resetBtn.right
                anchors.leftMargin: 12
                visible: !$tnmManager.isAnalyzing && $tnmManager.isCompleted
                text: "重选方案"
                width: 88
                height: 36
                fontSize: 14
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                onClicked: {
                    $tnmManager.endAnalysis()
                    resetAllInputs()
                    exitScore()
                }
            }

            CustomButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 24
                visible: !$tnmManager.isAnalyzing && $tnmManager.isCompleted
                text: "复制"
                width: 88
                height: 36
                fontSize: 14
                backgroundColor: "#006BFF"
                textColor: "#FFFFFF"
                onClicked: {
                    $tnmManager.copyToClipboard(text)
                    messageManager.success("复制成功")
                }
            }
        }
    }
}
