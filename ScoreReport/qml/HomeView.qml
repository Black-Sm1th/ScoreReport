import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import "./components"
// 内容区域
Rectangle {
    width: parent.width
    height: contentArea.height
    color: "transparent"
    radius: 12
    // 消息管理器引用属性
    signal currentPageChanged(int index)
    property var messageManager: null

    Column {
        id: contentArea
        width: parent.width - 48  // 左右各20px边距
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        // 标题和标签
        Row {
            width: parent.width
            height: 32
            Text {
                id:chooseText
                text: qsTr("看看我能帮您做哪些吧？")
                color: "#000000"
                font.family: "Alibaba PuHuiTi 3.0"
                font.weight: Font.Bold
                font.pixelSize: 16
                anchors.verticalCenter: parent.verticalCenter
            }
            // Rectangle{
            //     height: 32
            //     width:parent.width - chooseText.width - tabSwitcher.width
            // }
            // TabSwitcher {
            //     id: tabSwitcher
            //     anchors.verticalCenter: parent.verticalCenter
            // }
        }

        // 间距
        Rectangle {
            height: 16
            width: parent.width
        }

        // 带动画的内容容器
        Rectangle {
            id: contentContainer
            width: parent.width
            height: 240  // 固定高度以容纳两行卡片
            color: "transparent"
            clip: true
            
            // 滑动内容区域
            Rectangle {
                id: slidingContent
                width: parent.width * 2  // 两个页面的宽度
                height: parent.height
                color: "transparent"
                x: 0
                
                // 通用页面 (index 0)
                Grid {
                    id: generalGrid
                    width: contentContainer.width
                    height: parent.height
                    columns: 3
                    columnSpacing: 12
                    rowSpacing: 12
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    
                    ScoreOptionCard {
                        title: "设备管理知识库"
                        backgroundColor: "#F7FCFB"
                        iconUrl: "qrc:/image/CCLS.png"
                    }
                    ScoreOptionCard {
                        title: "设备管理知识库问答"
                        backgroundColor: "#F8FAFF"
                        iconUrl: "qrc:/image/CHAT.png"
                    }
                    // ScoreOptionCard {
                    //     title: "结构化管家"
                    //     backgroundColor: "#F8FAFF"
                    //     iconUrl: "qrc:/image/BIOSNAK.png"
                    // }

                    ScoreOptionCard {
                        title: "智能问答"
                        backgroundColor: "#F8FAFF"
                        iconUrl: "qrc:/image/BIOSNAK.png"
                    }
                }
                
                // // 肾脏页面 (index 1)
                // Grid {
                //     id: kidneyGrid
                //     width: contentContainer.width
                //     height: parent.height
                //     columns: 3
                //     columnSpacing: 12
                //     rowSpacing: 12
                //     anchors.left: parent.left
                //     anchors.leftMargin: contentContainer.width + (width - (3 * ((width - 24) / 3) + 24)) / 2  // 第二页位置 + 居中对齐
                //     anchors.verticalCenter: parent.verticalCenter

                //     // 第一行
                //     ScoreOptionCard {
                //         title: "RENAL"
                //         backgroundColor: "#F8FAFF"
                //         iconUrl: "qrc:/image/RENAL.png"
                //     }

                //     ScoreOptionCard {
                //         title: "CCLS"
                //         backgroundColor: "#F7FCFB"
                //         iconUrl: "qrc:/image/CCLS.png"
                //     }

                //     ScoreOptionCard {
                //         title: "TNM"
                //         backgroundColor: "#FFFAF8"
                //         iconUrl: "qrc:/image/TNM.png"
                //     }

                //     // 第二行
                //     ScoreOptionCard {
                //         title: "UCLS MRS"
                //         backgroundColor: "#FFFBF2"
                //         iconUrl: "qrc:/image/UCLS-MRS.png"
                //     }

                //     ScoreOptionCard {
                //         title: "UCLS CTS"
                //         backgroundColor: "#F8F7FF"
                //         iconUrl: "qrc:/image/UCLS-CTS.png"
                //     }

                //     ScoreOptionCard {
                //         title: "BIOSNAK"
                //         backgroundColor: "#F8FAFF"
                //         iconUrl: "qrc:/image/BIOSNAK.png"
                //     }
                // }
            }
        }
        // 分隔线
        Rectangle {
            width: parent.width
            height: 24
            color: "transparent"
        }
    }
    // 评分方案卡片组件
    component ScoreOptionCard: Rectangle {
        property string iconUrl: ""
        property string backgroundColor: ""
        property string title: ""

        width: (520 - 48 - 24) / 3
        height: 114
        color: backgroundColor
        opacity: mouseArea2.containsMouse ? 0.8 : 1
        radius: 8
        border.color: "#E6EAF2"
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: 10
            Image{
                anchors.horizontalCenter: parent.horizontalCenter
                source: iconUrl
            }

            Text {
                text: title
                font.family: "Alibaba PuHuiTi 3.0"
                font.pixelSize: 16
                color: "#D9000000"
                anchors.horizontalCenter: parent.horizontalCenter
            }

        }

        MouseArea {
            id: mouseArea2
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: {
                if(title === "CCLS"){
                    currentPageChanged(1)
                }else if(title === "TNM" || title === "实体瘤分期(TNM)"){
                    if($tnmManager.checkClipboard()){
                        currentPageChanged(2) // TNM页面索引
                        $tnmManager.startAnalysis()
                    }else{
                        messageManager.warning(qsTr("剪贴板为空，请先复制内容"))
                    }
                }else if(title === "RENAL"){
                    if($renalManager.checkClipboard()){
                        currentPageChanged(0) // TNM页面索引
                        $renalManager.startAnalysis()
                    }else{
                        messageManager.warning(qsTr("剪贴板为空，请先复制内容"))
                    }
                }
                else if(title === "智能问答"){
                    currentPageChanged(6)
                }
                else if(title === "UCLS MRS"){
                    currentPageChanged(3)
                }
                else if(title === "UCLS CTS"){
                    currentPageChanged(4)
                }
                else if(title === "结构化管家"){
                    $reportManager.refreshTemplate()
                    currentPageChanged(7)
                }
                else if(title === "设备管理知识库"){
                    $knowledgeManager.updateKnowledgeList()
                    currentPageChanged(8)
                }
                else if(title === "设备管理知识库问答"){
                    $knowledgeChatManager.loadKnowledgeBaseList()
                    currentPageChanged(9)
                }
                else{
                    messageManager.warning(qsTr("该功能暂未开放"))
                }
            }
        }
    }
}
