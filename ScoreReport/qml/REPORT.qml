import QtQuick 2.15
import QtQuick.Controls 2.15
import "./components"

Rectangle {
    id: reportView
    height: reportColumn.height
    width: parent.width
    color: "transparent"
    property var messageManager: null
    signal exitScore()
    function resetValues(){
        tabswitcher.currentIndex = 0
        chooseTemplate.currentIndex = 0
        chooseTemplateDetail.currentIndex = 0
    }
    Connections{
        target: $reportManager
        function onTemplateListChanged(){
            var templateLists = []
            for (var i = 0; i < $reportManager.templateList.length; i++) {
                var template = $reportManager.templateList[i]
                templateLists.push({
                    value: template.id,
                    text: "模板" + (i + 1),
                    iconUrl: ""
                })
            }
            chooseTemplate.scoreTypes = templateLists
            chooseTemplateDetail.scoreTypes = templateLists
        }
    }
    Column{
        id: reportColumn
        width: parent.width
        leftPadding: 24
        rightPadding: 24
        spacing: 16
        TabSwitcher{
            id: tabswitcher
            tabTitles: ["报告", "设置模板"]
            currentIndex: 0
        }
        Column {
            width: parent.width - reportColumn.leftPadding - reportColumn.rightPadding
            visible: tabswitcher.currentIndex === 0
            spacing: 8
            Text {
                font.family: "Alibaba PuHuiTi 3.0"
                font.weight: Font.Normal
                font.pixelSize: 16
                color: "#D9000000"
                text: "输入报告："
            }
            MultiLineTextInput{
                width: parent.width
                height: 300
            }
            Row{
                height: 29
                Text {
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.weight: Font.Normal
                    font.pixelSize: 16
                    color: "#D9000000"
                    text: "选择模板："
                    anchors.verticalCenter: parent.verticalCenter
                }
                ScoreTypeDropdown{
                    id:chooseTemplate
                    anchors.verticalCenter: parent.verticalCenter
                    scoreTypes: []
                }
            }
        }
        Column{
            width: parent.width - reportColumn.leftPadding - reportColumn.rightPadding
            height: 630
            anchors.horizontalCenter: parent.horizontalCenter
            visible: tabswitcher.currentIndex === 1
            spacing: 16
            Rectangle {
                id: chooseTemplateRec
                height: 50
                width: parent.width
                radius: 12
                color: "#F5F5F5"
                Text {
                    id:chooseTemplateText
                    anchors.left: parent.left
                    anchors.leftMargin: 16
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.weight: Font.Normal
                    font.pixelSize: 16
                    color: "#D9000000"
                    text: "选择模板："
                    anchors.verticalCenter: parent.verticalCenter
                }
                ScoreTypeDropdown{
                    id:chooseTemplateDetail
                    anchors.left: chooseTemplateText.right
                    anchors.verticalCenter: parent.verticalCenter
                    scoreTypes: []
                }
                CustomButton{
                    id: deleteBtn
                    text: qsTr("删除模板")
                    width: 80
                    height: 29
                    borderWidth: 0
                    fontSize: 14
                    backgroundColor: "#FF5132"
                    textColor: "#ffffff"
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: {

                    }
                }
                CustomButton{
                    text: qsTr("新增模板")
                    fontSize: 14
                    width: 80
                    height: 29
                    borderWidth: 0
                    backgroundColor: "#006BFF"
                    textColor: "#ffffff"
                    anchors.right: deleteBtn.left
                    anchors.rightMargin: 8
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: {

                    }
                }
            }
            Rectangle{
                id: templateDetailRec
                height: parent.height - parent.spacing - chooseTemplateRec.height
                width: parent.width
                radius: 12
                color: "#F5F5F5"
                ScrollView {
                    id: scrollView
                    clip: true
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded
                    width: parent.width
                    height: parent.height
                    topPadding: 16
                    bottomPadding: 16
                    Column{
                        id:templateDetail
                        spacing: 8
                        width: parent.width
                        leftPadding: 16
                        rightPadding: 16
                        Repeater{
                            model: {
                                var items = []
                                if ($reportManager.templateList.length > 0 && chooseTemplateDetail.currentIndex < $reportManager.templateList.length) {
                                    var selectedTemplate = $reportManager.templateList[chooseTemplateDetail.currentIndex]
                                    if (selectedTemplate && selectedTemplate.template) {
                                        var templateData = selectedTemplate.template
                                        for (var key in templateData) {
                                            items.push({
                                                key: key,
                                                value: templateData[key] || ""
                                            })
                                        }
                                    }
                                }
                                return items
                            }
                            // 消息气泡
                            delegate: Row {
                                spacing: 8
                                height: detailCol.height
                                Column{
                                    id: detailCol
                                    width: (scrollView.width - 40) / 2
                                    spacing: 8
                                    Text {
                                        font.family: "Alibaba PuHuiTi 3.0"
                                        font.weight: Font.Normal
                                        font.pixelSize: 16
                                        color: "#D9000000"
                                        text: "词条名："
                                    }
                                    TextField {
                                        height: 37
                                        width: parent.width
                                        font.family: "Alibaba PuHuiTi 3.0"
                                        font.pixelSize: 16
                                        color: "#D9000000"
                                        selectByMouse: true
                                        placeholderText: qsTr("请输入")
                                        placeholderTextColor: "#40000000"
                                        text: modelData.key
                                    }
                                }
                                Column{
                                    width: (scrollView.width - 40) / 2
                                    spacing: 8
                                    Text {
                                        font.family: "Alibaba PuHuiTi 3.0"
                                        font.weight: Font.Normal
                                        font.pixelSize: 16
                                        color: "#D9000000"
                                        text: "词条描述："
                                    }
                                    TextField {
                                        height: 37
                                        width: parent.width
                                        font.family: "Alibaba PuHuiTi 3.0"
                                        font.pixelSize: 16
                                        color: "#D9000000"
                                        selectByMouse: true
                                        placeholderText: qsTr("请输入")
                                        placeholderTextColor: "#40000000"
                                        text: modelData.value
                                    }
                                }
                            }
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
                id:stopBtn
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 24
                text: qsTr("退出")
                width: 88
                height: 36
                radius: 4
                fontSize: 14
                borderWidth: 1
                borderColor: "#33006BFF"
                backgroundColor: "#1A006BFF"
                textColor: "#006BFF"
                onClicked: {
                    exitScore()
                }
            }
        }
    }
}
