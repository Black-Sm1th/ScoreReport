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
    property bool isNewTemplate: false
    property int newTemplateIndex: -1
    property bool isGenerating: false
    property int dotCount: 1
    property bool isShowResult: false
    property string currentTemplateName: ""
    signal exitScore()
    function resetValues(){
        tabswitcher.currentIndex = 0
        chooseTemplate.currentIndex = 0
        chooseTemplateDetail.currentIndex = 0
        originalTemplateData = []
        editableTemplateData = []
        isEdit = false
        isNewTemplate = false
        isShowResult = false
        newTemplateIndex = -1
        isGenerating = false
        currentTemplateName = ""
        reportInput.text = ""
        reportView.forceActiveFocus()
    }
    
    function updateEditableData() {
        var items = []
        currentTemplateName = ""
        
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
                // 设置当前模板名称
                currentTemplateName = selectedTemplate.templateName || ""
            }
        }
        editableTemplateData = []  // 先清空以触发绑定更新
        editableTemplateData = items
        originalTemplateData = JSON.parse(JSON.stringify(items)) // 深拷贝
    }
    
    function restoreOriginalData() {
        if (isNewTemplate) {
            // 如果是新模板，从前端删除它
            removeNewTemplateFromFrontend()
        } else {
            // 取消时直接恢复到原始数据，不需要处理当前输入（我们要丢弃这些修改）
            editableTemplateData = []  // 先清空以触发绑定更新
            editableTemplateData = JSON.parse(JSON.stringify(originalTemplateData)) // 深拷贝恢复
            
            // 还原模板名称
            if ($reportManager.templateList.length > 0 && chooseTemplateDetail.currentIndex < $reportManager.templateList.length) {
                var selectedTemplate = $reportManager.templateList[chooseTemplateDetail.currentIndex]
                if (selectedTemplate) {
                    currentTemplateName = selectedTemplate.templateName || ""
                }
            }
        }
        isEdit = false
    }
    
    function removeNewTemplateFromFrontend() {
        // 重新构建模板列表（排除新模板）
        var templateLists = []
        for (var i = 0; i < $reportManager.templateList.length; i++) {
            var template = $reportManager.templateList[i]
            templateLists.push({
                value: template.id,
                text: template.templateName,
                iconUrl: ""
            })
        }
        
        // 先重置索引避免越界
        chooseTemplate.currentIndex = -1
        chooseTemplateDetail.currentIndex = -1
        
        // 两个下拉框都恢复到原始模板列表
        chooseTemplate.scoreTypes = templateLists
        chooseTemplateDetail.scoreTypes = templateLists
        
        // 切换到第一个模板（如果有的话）
        if (templateLists.length > 0) {
            chooseTemplate.currentIndex = 0
            chooseTemplateDetail.currentIndex = 0
            updateEditableData()
        } else {
            editableTemplateData = []
        }
        
        // 重置新模板状态
        isNewTemplate = false
        newTemplateIndex = -1
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
        
        if (isNewTemplate) {
            // 新模板不传ID，让后端生成新ID
            templateId = ""
        } else {
            // 现有模板使用原有ID
            if ($reportManager.templateList.length > 0 && chooseTemplateDetail.currentIndex < $reportManager.templateList.length) {
                var selectedTemplate = $reportManager.templateList[chooseTemplateDetail.currentIndex]
                if (selectedTemplate && selectedTemplate.id) {
                    templateId = selectedTemplate.id
                }
            }
        }
        
        // 验证模板名称不能为空
        var templateName = currentTemplateName.trim()
        if (templateName === "") {
            messageManager.warning("模板名称不能为空")
            return
        }
        
        // 调用C++的保存方法
        $reportManager.saveTemplate(templateId, templateName, editableTemplateData)
        
        // 更新原始数据为当前编辑的数据
        originalTemplateData = JSON.parse(JSON.stringify(editableTemplateData))
        
        // 退出编辑模式
        isEdit = false
        
        // 重置新模板状态（保存成功后会在onTemplateSaveResult中处理）
    }
    ConfirmDialog {
        id: confirmDialog
        onConfirmed: {
            executeDeleteTemplate()
        }
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
    
    function createNewTemplate() {
        // 创建一个新的模板对象
        var newTemplate = {
            id: "new_template_" + Date.now(), // 临时ID
            templateName: "", // 默认模板名称
            template: {
                "词条名1": "词条描述1"  // 默认添加一个词条
            }
        }
        
        // 设置当前模板名称
        currentTemplateName = ""
        
        // 将新模板添加到现有模板列表
        var currentTemplateList = JSON.parse(JSON.stringify($reportManager.templateList))
        currentTemplateList.push(newTemplate)
        
        // 更新下拉框选项
        var templateLists = []
        for (var i = 0; i < currentTemplateList.length; i++) {
            var template = currentTemplateList[i]
            templateLists.push({
                value: template.id,
                text: template.templateName,
                iconUrl: ""
            })
        }
        
        // 报告页面的下拉框不包含新模板（未保存的模板不应该在报告页面显示）
        var reportTemplateList = []
        for (var j = 0; j < $reportManager.templateList.length; j++) {
            var reportTemplate = $reportManager.templateList[j]
            reportTemplateList.push({
                value: reportTemplate.id,
                text: reportTemplate.templateName,
                iconUrl: ""
            })
        }
        
        // 设置新模板状态
        isNewTemplate = true
        newTemplateIndex = currentTemplateList.length - 1
        
        // 先重置索引避免越界
        chooseTemplate.currentIndex = -1
        chooseTemplateDetail.currentIndex = -1
        
        // 然后更新数组
        chooseTemplate.scoreTypes = reportTemplateList
        chooseTemplateDetail.scoreTypes = templateLists
        
        // 最后设置正确的索引
        chooseTemplateDetail.currentIndex = newTemplateIndex
        // 报告页面保持-1，因为新模板不在其列表中
        
        // 设置编辑模式
        isEdit = true
        
        // 初始化编辑数据（一个默认词条）
        editableTemplateData = [
            {
                key: "词条名1",
                value: "词条描述1"
            }
        ]
        originalTemplateData = JSON.parse(JSON.stringify(editableTemplateData))
    }
    
    function confirmDeleteTemplate() {
        // 检查是否有选中的模板
        if ($reportManager.templateList.length === 0 || chooseTemplateDetail.currentIndex < 0) {
            messageManager.warning("没有可删除的模板")
            return
        }
        
        var selectedTemplate = $reportManager.templateList[chooseTemplateDetail.currentIndex]
        if (!selectedTemplate || !selectedTemplate.id) {
            messageManager.warning("模板信息无效")
            return
        }
        
        // 配置确认对话框
        confirmDialog.title = "删除模板"
        var templateName = selectedTemplate.templateName || ("模板" + (chooseTemplateDetail.currentIndex + 1))
        confirmDialog.message = "确定要删除 \"" + templateName + "\" 吗？"
        
        // 显示确认对话框
        confirmDialog.show()
    }
    
    function executeDeleteTemplate() {
        var selectedTemplate = $reportManager.templateList[chooseTemplateDetail.currentIndex]
        if (selectedTemplate && selectedTemplate.id) {
            $reportManager.deleteTemplate(selectedTemplate.id)
        }
    }
    
    function generateStructuredReport() {
        // 获取输入的报告内容
        var query = reportInput.text.trim()
        if (query === "") {
            messageManager.warning("请输入报告内容")
            return
        }
        
        // 检查是否选择了模板
        if (chooseTemplate.currentIndex < 0 || $reportManager.templateList.length === 0) {
            messageManager.warning("请选择一个模板")
            return
        }
        
        // 获取当前选择的模板数据
        var selectedTemplate = $reportManager.templateList[chooseTemplate.currentIndex]
        if (!selectedTemplate || !selectedTemplate.template) {
            messageManager.warning("模板数据无效")
            return
        }
        
        // 将模板转换为QVariantList格式
        var templateData = []
        var templateContent = selectedTemplate.template
        for (var key in templateContent) {
            templateData.push({
                key: key,
                value: templateContent[key] || ""
            })
        }
        // 调用C++生成报告方法
        isGenerating = true
        $reportManager.generateReport(query, templateData)
    }
    
    function handleTemplateIndexAfterDelete() {
        // 获取删除后的模板列表长度
        var templateCount = $reportManager.templateList.length
        
        if (templateCount === 0) {
            // 没有模板了，先重置索引
            chooseTemplate.currentIndex = -1
            chooseTemplateDetail.currentIndex = -1
            editableTemplateData = []
            originalTemplateData = []
        } else {
            // 还有模板，智能选择索引
            var newIndex = 0
            
            // 如果当前索引超出范围，选择最后一个
            if (chooseTemplateDetail.currentIndex >= templateCount) {
                newIndex = templateCount - 1
            } else {
                // 否则保持当前索引（删除后会自动调整到合适位置）
                newIndex = Math.max(0, Math.min(chooseTemplateDetail.currentIndex, templateCount - 1))
            }
            
            // 先重置索引避免越界
            chooseTemplate.currentIndex = -1
            chooseTemplateDetail.currentIndex = -1
            
            // 然后同步更新两个下拉框的索引
            chooseTemplate.currentIndex = newIndex
            chooseTemplateDetail.currentIndex = newIndex
            
            // 更新编辑数据
            updateEditableData()
        }
    }

    Timer {
        id: dotTimer
        interval: 500  // 每500ms切换一次
        running: isGenerating
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
    
    // 收集所有当前输入框的文本内容
    function collectAllCurrentTexts() {
        var allTexts = {}
        var repeater = resultRepeater
        if (repeater) {
            for (var i = 0; i < repeater.count; i++) {
                var item = repeater.itemAt(i)
                if (item && item.children && item.children.length > 0) {
                    var resultCol = item.children[0]  // Column
                    if (resultCol && resultCol.children && resultCol.children.length > 1) {
                        var textInput = resultCol.children[1]  // MultiLineTextInput
                        if (textInput && textInput.text !== undefined) {
                            // 获取对应的key，现在从$reportManager.resultMap获取
                            var keys = Object.keys($reportManager.resultMap)
                            if (i < keys.length) {
                                var key = keys[i]
                                allTexts[key] = textInput.text
                            }
                        }
                    }
                }
            }
        }
        return allTexts
    }

    Connections{
        target: $reportManager
        function onTemplateListChanged(){
            var templateLists = []
            for (var i = 0; i < $reportManager.templateList.length; i++) {
                var template = $reportManager.templateList[i]
                templateLists.push({
                    value: template.id,
                    text: template.templateName,
                    iconUrl: ""
                })
            }
            
            // 保存当前索引
            var oldChooseIndex = chooseTemplate.currentIndex
            var oldDetailIndex = chooseTemplateDetail.currentIndex
            
            // 先重置索引避免越界
            chooseTemplate.currentIndex = -1
            chooseTemplateDetail.currentIndex = -1
            
            // 更新两个下拉框（正常情况下都是相同的模板列表）
            chooseTemplate.scoreTypes = templateLists
            chooseTemplateDetail.scoreTypes = templateLists
            
            // 恢复有效的索引
            if (templateLists.length > 0) {
                var newChooseIndex = Math.min(Math.max(0, oldChooseIndex), templateLists.length - 1)
                var newDetailIndex = Math.min(Math.max(0, oldDetailIndex), templateLists.length - 1)
                
                chooseTemplate.currentIndex = newChooseIndex
                chooseTemplateDetail.currentIndex = newDetailIndex
            }
            
            // 只有不是新模板状态时才更新数据
            if (!isNewTemplate) {
                updateEditableData()
            }
        }
        
        function onTemplateSaveResult(success, message){
            if (success) {
                messageManager.success("保存成功！")
                // 保存成功后重置新模板状态
                if (isNewTemplate) {
                    isNewTemplate = false
                    newTemplateIndex = -1
                    // 保存成功后，新模板变成正式模板，同步两个下拉框的索引
                    chooseTemplate.currentIndex = chooseTemplateDetail.currentIndex
                }
            } else {
                messageManager.error("保存失败:" + message)
            }
        }
        
        function onTemplateDeleteResult(success, message){
            if (success) {
                messageManager.success("删除成功！")
                // 删除成功后智能调整索引
                handleTemplateIndexAfterDelete()
            } else {
                messageManager.error("删除失败:" + message)
            }
        }
        
        function onReportGenerateResult(success){
            if(success){
                reportInput.text = ""
                isShowResult = true
            }else{
                messageManager.error("生成报告失败！")
                isShowResult = false
            }
            isGenerating = false
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
            visible: tabswitcher.currentIndex === 0 && !isShowResult
            spacing: 8
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
                    enabled: !isGenerating
                    onCurrentIndexChanged: {
                        // 在报告页面切换模板时，同步到设置页面（仅在非编辑和非新模板状态下）
                        if (!isEdit && !isNewTemplate && chooseTemplateDetail.currentIndex !== currentIndex) {
                            chooseTemplateDetail.currentIndex = currentIndex
                        }
                    }
                }
            }


            Text {
                font.family: "Alibaba PuHuiTi 3.0"
                font.weight: isGenerating ? Font.Bold : Font.Normal
                font.pixelSize: 16
                color: "#D9000000"
                text: !isGenerating ? "请输入报告：" : "生成中" + getDots()
            }
            MultiLineTextInput{
                id: reportInput
                inputWidth: parent.width
                inputHeight: 300
                readOnly: isGenerating
                placeholderText: "请输入您的报告内容..."
            }
        }

        Column {
            width: parent.width - reportColumn.leftPadding - reportColumn.rightPadding
            visible: tabswitcher.currentIndex === 0 && isShowResult
            height: 630
            spacing: 8
            Text {
                id:resultText
                font.family: "Alibaba PuHuiTi 3.0"
                font.weight: Font.Bold
                font.pixelSize: 16
                color: "#D9000000"
                text: "结构化报告结果:"
            }
            Rectangle{
                width: parent.width
                height: parent.height - 8 - resultText.height
                color: "#F5F5F5"
                radius: 12
                ScrollView {
                    clip: true
                    ScrollBar.vertical.policy: ScrollBar.AsNeeded
                    anchors.fill: parent
                    Column {
                        id: rangeResultCol
                        spacing: 16
                        width: parent.width
                        padding: 16
                            Repeater {
                            id: resultRepeater
                            model: {
                                var items = []
                                if ($reportManager.resultMap && typeof $reportManager.resultMap === 'object') {
                                    for (var key in $reportManager.resultMap) {
                                        if ($reportManager.resultMap.hasOwnProperty(key)) {
                                            items.push({
                                                key: key,
                                                value: $reportManager.resultMap[key] || ""
                                            })
                                        }
                                    }
                                }
                                return items
                            }
                            
                            delegate: Row {
                                id: resultRow
                                height: resultCol.height
                                spacing: 16
                                Column{
                                    id:resultCol
                                    width: 364
                                    spacing: 8
                                    Text {
                                        font.family: "Alibaba PuHuiTi 3.0"
                                        font.weight: Font.Normal
                                        font.pixelSize: 16
                                        color: "#D9000000"
                                        text: modelData.key + ":"
                                    }
                                    MultiLineTextInput{
                                        id: textInput
                                        inputWidth: parent.width
                                        inputHeight: 80
                                        backgroundColor: "#ffffff"
                                        readOnly: false
                                        placeholderText: ""
                                        text: (modelData.value && modelData.value.toString().trim() !== "") ? modelData.value.toString() : "无内容"
                                    }
                                }
                                CustomButton {
                                    id: copyBtn
                                    text: "复制"
                                    width: 60
                                    height: 28
                                    fontSize: 14
                                    borderWidth: 0
                                    anchors.bottom: parent.bottom
                                    radius: 4
                                    backgroundColor: "#006BFF"
                                    onClicked: {
                                        // 直接从当前输入框获取文本内容
                                        var valueToProcess = textInput.text
                                        if (valueToProcess === null || valueToProcess === undefined) {
                                            valueToProcess = ""
                                        } else {
                                            valueToProcess = valueToProcess.toString()
                                        }
                                        $reportManager.copyToClipboard(valueToProcess)
                                        messageManager.success("已复制")
                                    }
                                }
                            }
                        }
                    }
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
                    text: isEdit ? "模板名称：" : "选择模板："
                    anchors.verticalCenter: parent.verticalCenter
                }
                
                // 编辑模式下显示文本输入框
                SingleLineTextInput{
                    id: templateNameInput
                    inputWidth: 120
                    inputHeight: 29
                    backgroundColor: "#ffffff"
                    borderColor: "#E6EAF2"
                    fontSize: 14
                    anchors.left: chooseTemplateText.right
                    anchors.verticalCenter: parent.verticalCenter
                    visible: isEdit
                    text: currentTemplateName
                    placeholderText: "请输入模板名称"
                    onEditingFinished: {
                        currentTemplateName = text
                    }
                }
                
                // 非编辑模式下显示下拉框
                ScoreTypeDropdown{
                    id:chooseTemplateDetail
                    anchors.left: chooseTemplateText.right
                    anchors.verticalCenter: parent.verticalCenter
                    enabled: !isEdit
                    visible: !isEdit
                    scoreTypes: []
                    onCurrentIndexChanged: {
                        if (!isEdit && !isNewTemplate) {
                            updateEditableData()
                            // 同步到报告页面的下拉框
                            if (chooseTemplate.currentIndex !== currentIndex) {
                                chooseTemplate.currentIndex = currentIndex
                            }
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
                    visible: !isEdit && !isNewTemplate && chooseTemplateDetail.currentIndex >= 0
                    anchors.right: parent.right
                    anchors.rightMargin: 16
                    anchors.verticalCenter: parent.verticalCenter
                    onClicked: {
                        confirmDeleteTemplate()
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
                        createNewTemplate()
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
                                    width: isEdit ? (scrollView.width - 104) / 2 : (scrollView.width - 40) / 2
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
                                    width: isEdit ? (scrollView.width - 104) / 2 : (scrollView.width - 40) / 2
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
                    $reportManager.endAnalysis()
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
                visible: tabswitcher.currentIndex === 0 && !isGenerating && !isShowResult
                enabled: chooseTemplate.currentIndex >= 0 && $reportManager.templateList.length > 0
                height: 36
                radius: 4
                fontSize: 14
                borderWidth: 0
                backgroundColor: enabled ? "#006BFF" : "#CCCCCC"
                onClicked: {
                    reportView.forceActiveFocus()
                    generateStructuredReport()
                }
            }

            CustomButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 24
                text: qsTr("取消")
                width: 88
                visible: tabswitcher.currentIndex === 0 && isGenerating && !isShowResult
                height: 36
                radius: 4
                fontSize: 14
                borderWidth: 0
                backgroundColor: "#006BFF"
                onClicked: {
                    reportView.forceActiveFocus()
                    $reportManager.endAnalysis()
                    isGenerating = false
                }
            }

            CustomButton {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: copyAll.left
                anchors.rightMargin: 12
                text: qsTr("返回")
                width: 88
                visible: tabswitcher.currentIndex === 0 && !isGenerating && isShowResult
                height: 36
                radius: 4
                fontSize: 14
                borderWidth: 0
                backgroundColor: "#006BFF"
                onClicked: {
                    isShowResult = false
                }
            }

            CustomButton {
                id: copyAll
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 24
                text: qsTr("复制全部")
                width: 88
                visible: tabswitcher.currentIndex === 0 && !isGenerating && isShowResult
                height: 36
                radius: 4
                fontSize: 14
                borderWidth: 0
                backgroundColor: "#006BFF"
                onClicked: {
                    // 直接收集所有输入框的当前文本
                    var allTexts = collectAllCurrentTexts()
                    
                    var string = ""
                    for (var key in allTexts) {
                        if (allTexts.hasOwnProperty(key)) {
                            string += (key + "：\n" + allTexts[key] + "\n")
                        }
                    }
                    $reportManager.copyToClipboard(string)
                    messageManager.success("已复制全部内容")
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
                    reportView.forceActiveFocus()
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

