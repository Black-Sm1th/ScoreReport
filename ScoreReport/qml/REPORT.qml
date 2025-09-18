import QtQuick 2.15
import QtQuick.Controls 2.15
import "./components"

Rectangle {
    id: reportView
    height: reportColumn.height
    width: parent.width
    color: "transparent"
    focus: true
    property var messageManager: null
    property bool isEdit: false
    property var originalTemplateData: []
    property var editableTemplateData: []
    property int pendingRemoveIndex: -1
    signal exitScore()
    function resetValues(){
        tabswitcher.currentIndex = 0
        chooseTemplate.currentIndex = 0
        chooseTemplateDetail.currentIndex = 0
        originalTemplateData = []
        editableTemplateData = []
        isEdit = false
    }
    
    function updateEditableData() {
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
        editableTemplateData = []  // 先清空以触发绑定更新
        editableTemplateData = items
        originalTemplateData = JSON.parse(JSON.stringify(items)) // 深拷贝
    }
    
    function restoreOriginalData() {
        // 取消时直接恢复到原始数据，不需要处理当前输入（我们要丢弃这些修改）
        editableTemplateData = []  // 先清空以触发绑定更新
        editableTemplateData = JSON.parse(JSON.stringify(originalTemplateData)) // 深拷贝恢复
    }
    
    function addNewEntry() {
        // 先让页面失去焦点，确保当前输入被保存
        reportView.forceActiveFocus()
        
        // 使用Timer延迟执行添加，确保onEditingFinished有时间触发
        addTimer.start()
    }
    
    function doActualAdd() {
        var newEntry = {
            key: "",
            value: ""
        }
        var newData = JSON.parse(JSON.stringify(editableTemplateData)) // 深拷贝当前数据
        newData.push(newEntry)
        editableTemplateData = []  // 先清空以触发绑定更新
        editableTemplateData = newData
    }
    
    function saveTemplateData() {
        // 先让页面失去焦点，这样会触发所有输入框的onEditingFinished事件
        reportView.forceActiveFocus()
        
        // 使用Timer延迟执行保存，确保onEditingFinished有时间触发
        saveTimer.start()
    }
    
    function doActualSave() {
        // 获取当前选中模板的ID
        var templateId = ""
        if ($reportManager.templateList.length > 0 && chooseTemplateDetail.currentIndex < $reportManager.templateList.length) {
            var selectedTemplate = $reportManager.templateList[chooseTemplateDetail.currentIndex]
            if (selectedTemplate && selectedTemplate.id) {
                templateId = selectedTemplate.id
            }
        }
        
        // 调用C++的保存方法
        $reportManager.saveTemplate(templateId, editableTemplateData)
        
        // 更新原始数据为当前编辑的数据
        originalTemplateData = JSON.parse(JSON.stringify(editableTemplateData))
        
        // 退出编辑模式
        isEdit = false
        
        console.log("正在保存模板数据，ID:", templateId)
    }
    
    Timer {
        id: saveTimer
        interval: 50  // 50ms延迟，足够让onEditingFinished触发
        repeat: false
        onTriggered: doActualSave()
    }
    
    Timer {
        id: addTimer
        interval: 50  // 50ms延迟，足够让onEditingFinished触发
        repeat: false
        onTriggered: doActualAdd()
    }
    
    Timer {
        id: removeTimer
        interval: 50  // 50ms延迟，足够让onEditingFinished触发
        repeat: false
        onTriggered: doActualRemove()
    }
    
    function removeEntry(entryIndex) {
        // 先让页面失去焦点，确保当前输入被保存
        reportView.forceActiveFocus()
        
        // 保存要删除的索引
        pendingRemoveIndex = entryIndex
        
        // 使用Timer延迟执行删除，确保onEditingFinished有时间触发
        removeTimer.start()
    }
    
    function doActualRemove() {
        if (pendingRemoveIndex >= 0) {
            var newData = JSON.parse(JSON.stringify(editableTemplateData)) // 深拷贝当前数据
            newData.splice(pendingRemoveIndex, 1) // 删除指定索引的项
            editableTemplateData = []  // 先清空以触发绑定更新
            editableTemplateData = newData
            pendingRemoveIndex = -1  // 重置索引
        }
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
            updateEditableData()
        }
        
        function onTemplateSaveResult(success, message){
            if (success) {
                messageManager.success("保存成功！")
            } else {
                messageManager.error("保存失败:" + message)
            }
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
                    enabled: !isEdit
                    scoreTypes: []
                    onCurrentIndexChanged: {
                        if (!isEdit) {
                            updateEditableData()
                        }
                    }
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
                    visible: !isEdit
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
                    visible: !isEdit
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
                            id: detailRepeater
                            model: editableTemplateData
                            // 消息气泡
                            delegate: Row {
                                spacing: 8
                                height: detailCol.height
                                Column{
                                    id: detailCol
                                    width: isEdit ? (scrollView.width - 100) / 2 : (scrollView.width - 40) / 2
                                    spacing: 8
                                    Text {
                                        font.family: "Alibaba PuHuiTi 3.0"
                                        font.weight: Font.Normal
                                        font.pixelSize: 16
                                        color: "#D9000000"
                                        text: "词条名："
                                    }
                                    SingleLineTextInput {
                                        inputHeight: 37
                                        inputWidth: parent.width
                                        fontSize: 16
                                        readOnly: !isEdit
                                        backgroundColor: "#ffffff"
                                        borderColor: "#E6EAF2"
                                        textColor: "#D9000000"
                                        placeholderText: qsTr("请输入")
                                        placeholderColor: "#40000000"
                                        text: modelData.key
                                        onEditingFinished: {
                                            if (isEdit && text !== modelData.key) {
                                                editableTemplateData[index].key = text
                                            }
                                        }
                                    }
                                }
                                Column{
                                    width: isEdit ? (scrollView.width - 100) / 2 : (scrollView.width - 40) / 2
                                    spacing: 8
                                    Text {
                                        font.family: "Alibaba PuHuiTi 3.0"
                                        font.weight: Font.Normal
                                        font.pixelSize: 16
                                        color: "#D9000000"
                                        text: "词条描述："
                                    }
                                    SingleLineTextInput {
                                        inputHeight: 37
                                        inputWidth: parent.width
                                        fontSize: 16
                                        readOnly: !isEdit
                                        borderColor: "#E6EAF2"
                                        backgroundColor: "#ffffff"
                                        textColor: "#D9000000"
                                        placeholderText: qsTr("请输入")
                                        placeholderColor: "#40000000"
                                        text: modelData.value
                                        onEditingFinished: {
                                            if (isEdit && text !== modelData.value) {
                                                editableTemplateData[index].value = text
                                            }
                                        }
                                    }
                                }
                                
                                // 删除按钮
                                CustomButton {
                                    anchors.bottom: parent.bottom
                                    text: qsTr("删除")
                                    width: 56
                                    height: 37
                                    fontSize: 14
                                    borderWidth: 0
                                    backgroundColor: "#FF5132"
                                    textColor: "#ffffff"
                                    visible: isEdit
                                    onClicked: {
                                        removeEntry(index)
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
                anchors.left: parent.left
                anchors.leftMargin: 24
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
                    resetValues()
                    exitScore()
                }
            }
            CustomButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 24
                text: qsTr("发送")
                width: 88
                visible: tabswitcher.currentIndex === 0
                height: 36
                radius: 4
                fontSize: 14
                borderWidth: 0
                backgroundColor: "#006BFF"
                onClicked: {

                }
            }
            CustomButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 24
                text: qsTr("编辑")
                width: 88
                visible: tabswitcher.currentIndex === 1 && !isEdit
                height: 36
                radius: 4
                fontSize: 14
                borderWidth: 0
                backgroundColor: "#006BFF"
                onClicked: {
                    updateEditableData()  // 重新加载当前数据作为编辑的起点
                    isEdit = true
                }
            }

            CustomButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: saveBtn.left
                anchors.rightMargin: 12
                text: qsTr("取消")
                width: 88
                visible: tabswitcher.currentIndex === 1 && isEdit
                height: 36
                radius: 4
                fontSize: 14
                borderWidth: 0
                backgroundColor: "#006BFF"
                onClicked: {
                    restoreOriginalData()  // 恢复到编辑前的数据
                    isEdit = false
                }
            }
            CustomButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: addBtn.left
                anchors.rightMargin: 12
                text: qsTr("取消")
                width: 88
                visible: tabswitcher.currentIndex === 1 && isEdit
                height: 36
                radius: 4
                fontSize: 14
                borderWidth: 0
                backgroundColor: "#006BFF"
                onClicked: {
                    restoreOriginalData()  // 恢复到编辑前的数据
                    isEdit = false
                }
            }
            CustomButton {
                id: addBtn
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: saveBtn.left
                anchors.rightMargin: 12
                text: qsTr("添加词条")
                width: 88
                visible: tabswitcher.currentIndex === 1 && isEdit
                height: 36
                radius: 4
                fontSize: 14
                borderWidth: 0
                backgroundColor: "#006BFF"
                onClicked: {
                    addNewEntry()
                }
            }
            CustomButton {
                id: saveBtn
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 24
                text: qsTr("保存")
                width: 88
                visible: tabswitcher.currentIndex === 1 && isEdit
                height: 36
                radius: 4
                fontSize: 14
                borderWidth: 0
                backgroundColor: "#006BFF"
                onClicked: {
                    saveTemplateData()
                }
            }
        }
    }
}
