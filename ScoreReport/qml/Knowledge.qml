import QtQuick 2.15
import QtQuick.Controls 2.15
import QtQuick.Dialogs 1.3
import "./components"

Rectangle {
    id: knowledgeView
    height: knowledgeColumn.height
    width: parent.width
    color: "transparent"
    // 属性
    property var messageManager: null
    property var loadingDialog: null
    property var fileToDelete: null  // 存储要删除的文件信息
    property var knowledgeToDelete: null  // 存储要删除的知识库信息
    property bool isAddingKnowledge: false  // 是否处于添加知识库模式
    property bool isEditingKnowledge: false  // 是否处于编辑知识库模式
    property var knowledgeToEdit: null  // 存储要编辑的知识库信息
    property string selectedKnowledgeId: ""  // 当前选中的知识库ID
    // 信号
    signal exitScore()
    Timer {
        id: scrollToTop
        interval: 100
        onTriggered: {
            scrollView.contentItem.contentY = 0
        }
    }
    function resetValues(){
        isAddingKnowledge = false
        isEditingKnowledge = false
        selectedKnowledgeId = ""
        knowledgeToDelete = null
        knowledgeToEdit = null
        fileToDelete = null
        
        // 调用C++的重置函数，清空展开状态和详情
        $knowledgeManager.resetAllStates()
        
        // 清空输入框内容（如果存在）
        if (typeof nameInput !== 'undefined') {
            nameInput.text = ""
        }
        if (typeof descriptionInput !== 'undefined') {
            descriptionInput.text = ""
        }
        if (typeof editNameInput !== 'undefined') {
            editNameInput.text = ""
        }
        if (typeof editDescriptionInput !== 'undefined') {
            editDescriptionInput.text = ""
        }
    }
    
    // 文件选择对话框
    FileDialog {
        id: fileDialog
        title: qsTr("选择要上传的文件")
        folder: shortcuts.documents
        selectMultiple: true  // 启用多文件选择
        nameFilters: [
            qsTr("所有文件 (*.*)"),
            qsTr("文档文件 (*.pdf *.doc *.docx *.txt)"),
            qsTr("图片文件 (*.png *.jpg *.jpeg *.gif)"),
        ]
        onAccepted: {
            // 处理多个文件
            var filePaths = []
            for (var i = 0; i < fileDialog.fileUrls.length; i++) {
                var filePath = fileDialog.fileUrls[i].toString()
                // 移除 file:// 前缀 (Windows)
                if (Qt.platform.os === "windows" && filePath.startsWith("file:///")) {
                    filePath = filePath.substring(8)
                } else if (filePath.startsWith("file://")) {
                    filePath = filePath.substring(7)
                }
                filePaths.push(filePath)
            }
            // 批量上传文件
            $knowledgeManager.uploadMultipleFilesToCurrentKnowledge(filePaths)
        }
    }
    
    Connections {
        target: $knowledgeManager
        function onFileUploadCompleted(success, message) {
            if(success){
                messageManager.success("上传成功！")
            }else{
                messageManager.error(message)
            }
        }
        
        function onBatchUploadCompleted(successCount, totalCount, message) {
            if(successCount === totalCount){
                messageManager.success("批量上传完成！成功上传 " + successCount + " 个文件")
            }else if(successCount > 0){
                messageManager.warning("部分文件上传成功！成功上传 " + successCount + "/" + totalCount + " 个文件")
            }else{
                messageManager.error("批量上传失败：" + message)
            }
        }
        
        function onKnowledgeBaseCreateCompleted(success, message) {
            if(success){
                messageManager.success("知识库创建成功！")
                isAddingKnowledge = false  // 退出添加模式
                // 清空输入框
                nameInput.text = ""
                descriptionInput.text = ""
            }else{
                messageManager.error(message)
            }
        }
        
        function onKnowledgeBaseDeleteCompleted(success, message) {
            if(success){
                messageManager.success("知识库删除成功！")
                selectedKnowledgeId = ""  // 清空选中状态
            }else{
                messageManager.error(message)
            }
        }
        
        function onKnowledgeBaseEditCompleted(success, message) {
            if(success){
                messageManager.success("知识库编辑成功！")
                isEditingKnowledge = false  // 退出编辑模式
                // 清空编辑输入框
                editNameInput.text = ""
                editDescriptionInput.text = ""
                knowledgeToEdit = null
            }else{
                messageManager.error(message)
            }
        }

        function onIsLoadingChanged(){
            if($knowledgeManager.isLoading){
                loadingDialog.show()
            }else{
                loadingDialog.hide()
            }
        }
    }

    Column{
        id: knowledgeColumn
        width: parent.width
        spacing: 16
        Row{
            id: titleRow
            anchors.left: parent.left
            anchors.leftMargin: 24
            height: 28
            spacing: 8
            Text {
                id: titleText
                anchors.verticalCenter: parent.verticalCenter
                text: qsTr("知识库列表")
                font.family: "Alibaba PuHuiTi 3.0"
                font.pixelSize: 16
                font.weight: Font.Bold
                color: "#D9000000"
            }
            Rectangle{
             height: 1
             width: {
                 if (isAddingKnowledge || isEditingKnowledge) {
                     return knowledgeColumn.width - 48 - 24 - titleText.width - 112  // 保存和取消两个按钮
                 } else if (selectedKnowledgeId !== "") {
                     return knowledgeColumn.width - 48 - 32 - titleText.width - 168  // 删除、编辑和添加三个按钮
                 } else {
                     return knowledgeColumn.width - 48 - 16 - titleText.width - 56   // 只有添加按钮
                 }
             }
            }
            
            // 取消按钮（在添加或编辑模式下显示）
            CustomButton {
             id: cancelBtn
             text: qsTr("取消")
             width: 56
             height: 28
             fontSize: 14
             borderWidth: 1
             borderColor: "#33006BFF"
             backgroundColor: "#1A006BFF"
             textColor: "#006BFF"
             visible: isAddingKnowledge || isEditingKnowledge
             onClicked: {
                 if (isAddingKnowledge) {
                     isAddingKnowledge = false
                     // 清空添加输入框
                     nameInput.text = ""
                     descriptionInput.text = ""
                 } else if (isEditingKnowledge) {
                     isEditingKnowledge = false
                     // 清空编辑输入框
                     editNameInput.text = ""
                     editDescriptionInput.text = ""
                     knowledgeToEdit = null
                 }
             }
            }
            
            // 删除按钮（仅在选中知识库且非添加/编辑模式下显示）
            CustomButton {
                id: deleteBtn
                text: qsTr("删除")
                width: 56
                height: 28
                fontSize: 14
                borderWidth: 0
                backgroundColor: "#FF5132"
                textColor: "#ffffff"
                visible: !isAddingKnowledge && !isEditingKnowledge && selectedKnowledgeId !== ""
                onClicked: {
                // 找到要删除的知识库信息
                for (let i = 0; i < $knowledgeManager.knowledgeList.length; i++) {
                    if ($knowledgeManager.knowledgeList[i].id === selectedKnowledgeId) {
                        knowledgeToDelete = $knowledgeManager.knowledgeList[i]
                        break
                    }
                }
                // 显示删除知识库的确认对话框
                deleteKnowledgeConfirmDialog.show()
                }
            }
             
            // 编辑按钮（仅在选中知识库且非添加/编辑模式下显示）
            CustomButton {
                id: editBtn
                text: qsTr("编辑")
                width: 56
                height: 28
                fontSize: 14
                borderWidth: 0
                backgroundColor: "#006BFF"
                visible: !isAddingKnowledge && !isEditingKnowledge && selectedKnowledgeId !== ""
                onClicked: {
                 // 找到要编辑的知识库信息
                 for (let i = 0; i < $knowledgeManager.knowledgeList.length; i++) {
                     if ($knowledgeManager.knowledgeList[i].id === selectedKnowledgeId) {
                         knowledgeToEdit = $knowledgeManager.knowledgeList[i]
                         break
                     }
                 }

                 if (knowledgeToEdit) {
                     isEditingKnowledge = true

                     // 填充编辑表单
                     editNameInput.text = knowledgeToEdit.name || ""
                     editDescriptionInput.text = knowledgeToEdit.description || ""
                 }
                 scrollToTop.restart()
                }
            }
            
            // 添加/保存按钮
            CustomButton {
                id: addBtn
                text: {
                    if (isAddingKnowledge) {
                        return qsTr("保存")
                    } else if (isEditingKnowledge) {
                        return qsTr("保存")
                    } else {
                        return qsTr("添加")
                    }
                }
                width: 56
                height: 28
                fontSize: 14
                borderWidth: 0
                backgroundColor: "#006BFF"
                onClicked: {
                    if (isAddingKnowledge) {
                        // 保存逐辑
                        let name = nameInput.text.trim()
                        let description = descriptionInput.text.trim()
                        
                        if (name === "") {
                            messageManager.error("请输入知识库名称")
                            return
                        }
                        
                        $knowledgeManager.createKnowledgeBase(name, description)
                        // 不在这里清空输入框，等待服务器响应成功后再清空
                    } else if (isEditingKnowledge) {
                        // 编辑保存逻辑
                        let name = editNameInput.text.trim()
                        let description = editDescriptionInput.text.trim()
                        
                        if (name === "") {
                            messageManager.error("请输入知识库名称")
                            return
                        }
                        
                        if (knowledgeToEdit && knowledgeToEdit.id) {
                            $knowledgeManager.editKnowledgeBase(knowledgeToEdit.id, name, description)
                        }
                     } else {
                         // 添加逻辑 - 重置选择并收回详情
                         isAddingKnowledge = true
                         selectedKnowledgeId = ""  // 清空选中状态

                         // 调用C++的重置函数，收回展开的详情
                         $knowledgeManager.resetAllStates()
                        scrollToTop.restart()
                     }
                }
            }
        }
        ScrollView {
            id: scrollView
            height: 674 - titleRow.height - 16
            width: parent.width
            clip: true
            
            Column{
                leftPadding: 24
                rightPadding: 24
                width: parent.width
                spacing: 12
                
                // 添加知识库表单（仅在添加模式下显示）
                Rectangle {
                    id: addKnowledgeForm
                    width: parent.width - 48
                    height: isAddingKnowledge ? formColumn.height + 24 : 0
                    color: "#FFFFFF"
                    border.color: "#006BFF"
                    border.width: 2
                    radius: 8
                    visible: isAddingKnowledge
                    opacity: isAddingKnowledge ? 1 : 0
                    
                    Behavior on height {
                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 300 }
                    }
                    
                    Column {
                        id: formColumn
                        width: parent.width - 24
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 12
                        spacing: 16
                        
                        // 表单标题
                        Text {
                            text: qsTr("添加新知识库")
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 18
                            font.weight: Font.Bold
                            color: "#D9000000"
                        }
                        
                        // 知识库名称输入
                        Column {
                            width: parent.width
                            spacing: 8
                            Row{
                                height: nameText.height
                                Text {
                                    id: nameText
                                    text: qsTr("知识库名称")
                                    font.family: "Alibaba PuHuiTi 3.0"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: "#8C000000"
                                }
                                Text {
                                    text: qsTr("*")
                                    font.family: "Alibaba PuHuiTi 3.0"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: "red"
                                }
                            }

                            
                            SingleLineTextInput {
                                id: nameInput
                                inputWidth: parent.width
                                inputHeight: 42
                                placeholderText: qsTr("请输入知识库名称")
                                borderColor: "#E0E0E0"
                                focusedBorderColor: "#006BFF"
                                backgroundColor: "#FAFAFA"
                                fontSize: 14
                            }
                        }
                        
                        // 知识库描述输入
                        Column {
                            width: parent.width
                            spacing: 8
                            
                            Text {
                                text: qsTr("知识库描述")
                                font.family: "Alibaba PuHuiTi 3.0"
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                color: "#8C000000"
                            }
                            
                            MultiLineTextInput {
                                id: descriptionInput
                                inputWidth: parent.width
                                inputHeight: 80
                                placeholderText: qsTr("请输入知识库描述（可选）")
                                borderColor: "#E0E0E0"
                                focusedBorderColor: "#006BFF"
                                backgroundColor: "#FAFAFA"
                                fontSize: 14
                            }
                        }
                    }
                }
                
                // 编辑知识库表单（仅在编辑模式下显示）
                Rectangle {
                    id: editKnowledgeForm
                    width: parent.width - 48
                    height: isEditingKnowledge ? editFormColumn.height + 24 : 0
                    color: "#FFFFFF"
                    border.color: "#FF8C00"
                    border.width: 2
                    radius: 8
                    visible: isEditingKnowledge
                    opacity: isEditingKnowledge ? 1 : 0
                    
                    Behavior on height {
                        NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                    }
                    Behavior on opacity {
                        NumberAnimation { duration: 300 }
                    }
                    
                    Column {
                        id: editFormColumn
                        width: parent.width - 24
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.top: parent.top
                        anchors.topMargin: 12
                        spacing: 16
                        
                        // 表单标题
                        Text {
                            text: qsTr("编辑知识库")
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 18
                            font.weight: Font.Bold
                            color: "#D9000000"
                        }
                        
                        // 知识库名称输入
                        Column {
                            width: parent.width
                            spacing: 8
                            
                            Row{
                                height: nameText.height
                                Text {
                                    text: qsTr("知识库名称")
                                    font.family: "Alibaba PuHuiTi 3.0"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: "#8C000000"
                                }
                                Text {
                                    text: qsTr("*")
                                    font.family: "Alibaba PuHuiTi 3.0"
                                    font.pixelSize: 14
                                    font.weight: Font.Medium
                                    color: "red"
                                }
                            }
                            
                            SingleLineTextInput {
                                id: editNameInput
                                inputWidth: parent.width
                                inputHeight: 42
                                placeholderText: qsTr("请输入知识库名称")
                                borderColor: "#E0E0E0"
                                focusedBorderColor: "#FF8C00"
                                backgroundColor: "#FAFAFA"
                                fontSize: 14
                            }
                        }
                        
                        // 知识库描述输入
                        Column {
                            width: parent.width
                            spacing: 8
                            
                            Text {
                                text: qsTr("知识库描述")
                                font.family: "Alibaba PuHuiTi 3.0"
                                font.pixelSize: 14
                                font.weight: Font.Medium
                                color: "#8C000000"
                            }
                            
                            MultiLineTextInput {
                                id: editDescriptionInput
                                inputWidth: parent.width
                                inputHeight: 80
                                placeholderText: qsTr("请输入知识库描述（可选）")
                                borderColor: "#E0E0E0"
                                focusedBorderColor: "#FF8C00"
                                backgroundColor: "#FAFAFA"
                                fontSize: 14
                            }
                        }
                    }
                }
                
                // 加载指示器
                Rectangle {
                    width: parent.width - 48
                    height: 120
                    color: "transparent"
                    visible: $knowledgeManager.isLoading
                    
                    // BusyIndicator {
                    //     anchors.centerIn: parent
                    //     running: $knowledgeManager.isLoading
                    // }
                    
                            // Text {
                            //     anchors.horizontalCenter: parent.horizontalCenter
                            //     anchors.top: parent.verticalCenter
                            //     anchors.topMargin: 30
                            //     text: qsTr("正在加载知识库列表...")
                            //     font.family: "Alibaba PuHuiTi 3.0"
                            //     font.pixelSize: 14
                            //     color: "#73000000"
                            // }
                }
                
                // 空数据提示
                Rectangle {
                    width: parent.width - 48
                    height: 120
                    color: "transparent"
                    visible: !$knowledgeManager.isLoading && $knowledgeManager.knowledgeList.length === 0
                    
                    Column {
                        anchors.centerIn: parent
                        spacing: 10
                        
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: qsTr("暂无知识库")
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: "#D9000000"
                        }
                    }
                }
                
                // 知识库列表
                Repeater{
                    model: !$knowledgeManager.isLoading ? $knowledgeManager.knowledgeList : []
                    
                    delegate: Item {
                        width: parent.width - 48
                        height: knowledgeCard.height + (isExpanded ? fileListContainer.height : 0)
                        
                        property bool isExpanded: $knowledgeManager.expandedKnowledgeId === modelData.id
                        property bool isSelected: selectedKnowledgeId === modelData.id
                        
                        Column {
                            id: mainColumn
                            width: parent.width
                            spacing: 5
                            
                            // 主知识库卡片
                            Rectangle {
                                id: knowledgeCard
                                width: parent.width
                                height: Math.max(80, contentColumn.height + 20)
                                color: "#FFFFFF"
                                border.color: "#E5E5E5"
                                border.width: 1
                                radius: 8
                                
                                // 鼠标悬停效果
                                MouseArea {
                                    id: mouseArea
                                    anchors.fill: parent
                                    hoverEnabled: true
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        if (isAddingKnowledge || isEditingKnowledge) {
                                            // 在添加或编辑模式下不处理点击
                                            return
                                        }
                                        
                                        // 更新选中状态
                                        if (selectedKnowledgeId === modelData.id) {
                                            // 如果已经选中，则取消选中
                                            selectedKnowledgeId = ""
                                        } else {
                                            // 选中当前知识库
                                            selectedKnowledgeId = modelData.id
                                        }
                                        
                                        // 切换知识库的展开/收起状态
                                        $knowledgeManager.toggleKnowledgeExpansion(modelData.id)
                                    }
                                }
                                
                                // 悬停和选中效果
                                Rectangle {
                                    anchors.fill: parent
                                    color: isSelected ? "#E6F3FF" : "#F5F5F5"
                                    radius: parent.radius
                                    opacity: isSelected ? 0.8 : (mouseArea.containsMouse ? 0.6 : 0)
                                    Behavior on opacity {
                                        NumberAnimation { duration: 200 }
                                    }
                                    Behavior on color {
                                        ColorAnimation { duration: 200 }
                                    }
                                }
                                
                                Column {
                                    id: contentColumn
                                    anchors.left: parent.left
                                    anchors.right: expandIcon.left
                                    anchors.leftMargin: 16
                                    anchors.rightMargin: 10
                                    anchors.verticalCenter: parent.verticalCenter
                                    spacing: 8
                                    
                                    // 知识库名称
                                    Text {
                                        width: parent.width
                                        text: modelData.name || qsTr("未命名知识库")
                                        font.family: "Alibaba PuHuiTi 3.0"
                                        font.pixelSize: 16
                                        font.bold: true
                                        color: "#D9000000"
                                        wrapMode: Text.WordWrap
                                    }
                                    
                                    // 知识库描述
                                    Text {
                                        width: parent.width
                                        text: modelData.description || qsTr("暂无描述")
                                        font.family: "Alibaba PuHuiTi 3.0"
                                        font.pixelSize: 14
                                        color: "#73000000"
                                        wrapMode: Text.WordWrap
                                        maximumLineCount: 2
                                        elide: Text.ElideRight
                                    }
                                    
                                    // 创建时间
                                    Text {
                                        width: parent.width
                                        text: qsTr("创建时间: ") + (modelData.createTime || qsTr("未知"))
                                        font.family: "Alibaba PuHuiTi 3.0"
                                        font.pixelSize: 12
                                        color: "#40000000"
                                    }
                                }
                                
                                // 展开/收起图标
                                Text {
                                    id: expandIcon
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    anchors.rightMargin: 16
                                    text: isExpanded ? "▼" : "▶"
                                    font.family: "Alibaba PuHuiTi 3.0"
                                    font.pixelSize: 14
                                    color: "#73000000"
                                    
                                    Behavior on rotation {
                                        NumberAnimation { duration: 200 }
                                    }
                                }
                            }
                            
                            // 文件列表容器
                            Rectangle {
                                id: fileListContainer
                                width: parent.width
                                height: isExpanded ? (fileColumn.height + 20) : 0
                                color: "#F9F9F9"
                                border.color: "#E5E5E5"
                                border.width: isExpanded ? 1 : 0
                                radius: 8
                                visible: isExpanded
                                opacity: isExpanded ? 1 : 0
                                
                                Behavior on height {
                                    NumberAnimation { duration: 300; easing.type: Easing.OutCubic }
                                }
                                Behavior on opacity {
                                    NumberAnimation { duration: 300 }
                                }
                                
                                Column {
                                    id: fileColumn
                                    width: parent.width - 20
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    anchors.top: parent.top
                                    anchors.topMargin: 10
                                    spacing: 8
                                    
                                    // 加载指示器
                                    Rectangle {
                                        width: parent.width
                                        height: 40
                                        color: "transparent"
                                        visible: $knowledgeManager.isLoadingDetail
                                        
                                        Row {
                                            anchors.centerIn: parent
                                            spacing: 10
                                            
                                            BusyIndicator {
                                                width: 20
                                                height: 20
                                                running: $knowledgeManager.isLoadingDetail
                                            }
                                            
                                            Text {
                                                anchors.verticalCenter: parent.verticalCenter
                                                text: qsTr("正在加载文件列表...")
                                                font.family: "Alibaba PuHuiTi 3.0"
                                                font.pixelSize: 12
                                                color: "#73000000"
                                            }
                                        }
                                    }
                                    
                                    // 文件列表标题栏
                                    Rectangle {
                                        width: parent.width
                                        height: 35
                                        color: "transparent"
                                        visible: !$knowledgeManager.isLoadingDetail
                                        
                                        Text {
                                            anchors.left: parent.left
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: qsTr("文件列表")
                                            font.family: "Alibaba PuHuiTi 3.0"
                                            font.pixelSize: 16
                                            font.bold: true
                                            color: "#D9000000"
                                        }
                                        
                        CustomButton {
                            anchors.right: parent.right
                            anchors.verticalCenter: parent.verticalCenter
                            text: qsTr("批量上传")
                            width: 80
                            height: 28
                            radius: 4
                            fontSize: 12
                            borderWidth: 1
                            borderColor: "#33006BFF"
                            backgroundColor: "#1A006BFF"
                            textColor: "#006BFF"
                            onClicked: {
                                fileDialog.open()
                            }
                        }
                                    }
                                    
                                    // 文件列表
                                    Repeater {
                                        model: {
                                            if (!$knowledgeManager.isLoadingDetail && 
                                                isExpanded && 
                                                $knowledgeManager.currentKnowledgeDetail.files) {
                                                return $knowledgeManager.currentKnowledgeDetail.files
                                            }
                                            return []
                                        }
                                        
                                        delegate: Rectangle {
                                            width: parent.width
                                            height: 50
                                            color: "#FFFFFF"
                                            border.color: "#E0E0E0"
                                            border.width: 1
                                            radius: 4
                                            
                                            MouseArea {
                                                id: fileMouseArea
                                                anchors.fill: parent
                                                cursorShape: Qt.PointingHandCursor
                                                hoverEnabled: true
                                                onClicked: {
                                                    if (modelData.fileUrl) {
                                                        Qt.openUrlExternally(modelData.fileUrl)
                                                    }
                                                }
                                            }
                                            
                                            // 悬停效果
                                            Rectangle {
                                                anchors.fill: parent
                                                color: "#F0F8FF"
                                                radius: parent.radius
                                                opacity: fileMouseArea.containsMouse ? 0.6 : 0
                                                Behavior on opacity {
                                                    NumberAnimation { duration: 150 }
                                                }
                                            }
                                            
                                            Row {
                                                anchors.left: parent.left
                                                anchors.right: deleteButton.left
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.leftMargin: 12
                                                anchors.rightMargin: 8
                                                spacing: 10
                                                
                                                // 文件图标
                                                Text {
                                                    text: "📄"
                                                    font.pixelSize: 18
                                                    anchors.verticalCenter: parent.verticalCenter
                                                }
                                                
                                                // 文件信息
                                                Column {
                                                    anchors.verticalCenter: parent.verticalCenter
                                                    width: parent.width - 30
                                                    spacing: 2
                                                    
                                                    Text {
                                                        width: parent.width
                                                        text: modelData.fileName || qsTr("未知文件")
                                                        font.family: "Alibaba PuHuiTi 3.0"
                                                        font.pixelSize: 14
                                                        font.bold: true
                                                        color: "#D9000000"
                                                        elide: Text.ElideRight
                                                    }
                                                    
                                                    Row {
                                                        spacing: 15
                                                        
                                                        Text {
                                                            text: qsTr("大小: ") + (modelData.fileSize ? (modelData.fileSize / 1024).toFixed(1) + "KB" : qsTr("未知"))
                                                            font.family: "Alibaba PuHuiTi 3.0"
                                                            font.pixelSize: 12
                                                            color: "#40000000"
                                                        }
                                                    }
                                                }
                                            }
                                            
                                            // 删除按钮
                                            CustomButton {
                                                id: deleteButton
                                                anchors.right: parent.right
                                                anchors.verticalCenter: parent.verticalCenter
                                                anchors.rightMargin: 12
                                                text: qsTr("删除")
                                                width: 50
                                                height: 26
                                                radius: 4
                                                fontSize: 11
                                                borderWidth: 1
                                                borderColor: "#33FF4444"
                                                backgroundColor: "#1AFF4444"
                                                textColor: "#FF4444"
                                                onClicked: {
                                                    // 存储要删除的文件信息
                                                    fileToDelete = modelData
                                                    // 显示确认对话框
                                                    deleteConfirmDialog.show()
                                                }
                                            }
                                        }
                                    }
                                    
                                    // 无文件提示
                                    Text {
                                        width: parent.width
                                        height: 40
                                        text: qsTr("该知识库暂无文件")
                                        font.family: "Alibaba PuHuiTi 3.0"
                                        font.pixelSize: 14
                                        color: "#40000000"
                                        horizontalAlignment: Text.AlignHCenter
                                        verticalAlignment: Text.AlignVCenter
                                        visible: !$knowledgeManager.isLoadingDetail && 
                                                isExpanded && 
                                                $knowledgeManager.currentKnowledgeDetail.files && 
                                                $knowledgeManager.currentKnowledgeDetail.files.length === 0
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
                    resetValues()
                    exitScore()
                }
            }
        }
    }
    
    // 删除文件确认对话框
    ConfirmDialog {
        id: deleteConfirmDialog
        title: qsTr("删除文件")
        message: fileToDelete ? qsTr("确定要删除文件 \"%1\" 吗？").arg(fileToDelete.fileName || "") : qsTr("确定要删除这个文件吗？")
        confirmText: qsTr("删除")
        cancelText: qsTr("取消")
        confirmButtonColor: "#FF4444"  // 红色删除按钮
        
        onConfirmed: {
            if (fileToDelete && fileToDelete.id) {
                $knowledgeManager.deleteKnowledgeFile(fileToDelete.id)
                fileToDelete = null  // 清空文件信息
            }
        }
        
        onCancelled: {
            console.log("取消删除文件操作")
            fileToDelete = null  // 清空文件信息
        }
        
        onClosed: {
            fileToDelete = null  // 清空文件信息
        }
    }
    
    // 删除知识库确认对话框
    ConfirmDialog {
        id: deleteKnowledgeConfirmDialog
        title: qsTr("删除知识库")
        message: knowledgeToDelete ? qsTr("确定要删除知识库 \"%1\" 吗？").arg(knowledgeToDelete.name || "") : qsTr("确定要删除这个知识库吗？")
        confirmText: qsTr("删除")
        cancelText: qsTr("取消")
        confirmButtonColor: "#FF4444"  // 红色删除按钮
        dialogWidth: 450  // 适当增加宽度以适应更长的消息
        
        onConfirmed: {
            if (knowledgeToDelete && knowledgeToDelete.id) {
                console.log("确认删除知识库:", knowledgeToDelete.name, "ID:", knowledgeToDelete.id)
                $knowledgeManager.deleteKnowledgeBase(knowledgeToDelete.id)
                knowledgeToDelete = null  // 清空知识库信息
            }
        }
        
        onCancelled: {
            console.log("取消删除知识库操作")
            knowledgeToDelete = null  // 清空知识库信息
        }
        
        onClosed: {
            knowledgeToDelete = null  // 清空知识库信息
        }
    }
}
