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
    // 信号
    signal exitScore()
    
    function resetValues(){

    }
    
    // 文件选择对话框
    FileDialog {
        id: fileDialog
        title: qsTr("选择要上传的文件")
        folder: shortcuts.documents
        nameFilters: [
            qsTr("所有文件 (*.*)"),
            qsTr("文档文件 (*.pdf *.doc *.docx *.txt)"),
            qsTr("图片文件 (*.png *.jpg *.jpeg *.gif)"),
        ]
        onAccepted: {
            var filePath = fileDialog.fileUrl.toString()
            // 移除 file:// 前缀 (Windows)
            if (Qt.platform.os === "windows" && filePath.startsWith("file:///")) {
                filePath = filePath.substring(8)
            } else if (filePath.startsWith("file://")) {
                filePath = filePath.substring(7)
            }
            $knowledgeManager.uploadFileToCurrentKnowledge(filePath)
        }
    }
    
    Column{
        id: knowledgeColumn
        width: parent.width
        spacing: 16
        ScrollView {
            id: scrollView
            height: 674
            width: parent.width
            clip: true
            
            Column{
                leftPadding: 24
                rightPadding: 24
                width: parent.width
                spacing: 12
                
                // 加载指示器
                Rectangle {
                    width: parent.width - 48
                    height: 120
                    color: "transparent"
                    visible: $knowledgeManager.isLoading
                    
                    BusyIndicator {
                        anchors.centerIn: parent
                        running: $knowledgeManager.isLoading
                    }
                    
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.top: parent.verticalCenter
                                anchors.topMargin: 30
                                text: qsTr("正在加载知识库列表...")
                                font.family: "Alibaba PuHuiTi 3.0"
                                font.pixelSize: 14
                                color: "#73000000"
                            }
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
                                    onClicked: {
                                        // 切换知识库的展开/收起状态
                                        $knowledgeManager.toggleKnowledgeExpansion(modelData.id)
                                    }
                                }
                                
                                // 悬停效果
                                Rectangle {
                                    anchors.fill: parent
                                    color: "#F5F5F5"
                                    radius: parent.radius
                                    opacity: mouseArea.containsMouse ? 0.8 : 0
                                    Behavior on opacity {
                                        NumberAnimation { duration: 200 }
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
                                            text: qsTr("上传文件")
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
                                                    font.pixelSize: 16
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
                                                        
                                                        Text {
                                                            text: qsTr("类型: ") + (modelData.fileType || qsTr("未知"))
                                                            font.family: "Alibaba PuHuiTi 3.0"
                                                            font.pixelSize: 12
                                                            color: "#40000000"
                                                        }
                                                        
                                                        Text {
                                                            text: qsTr("状态: ") + (modelData.status || qsTr("未知"))
                                                            font.family: "Alibaba PuHuiTi 3.0"
                                                            font.pixelSize: 12
                                                            color: modelData.status === "完成" ? "#009900" : "#40000000"
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
                                                    $knowledgeManager.deleteKnowledgeFile(modelData.id)
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
        }
    }
}
