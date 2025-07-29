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
                text: "请选择评分方案"
                color: "#000000"
                font.family: "Alibaba PuHuiTi 3.0"
                font.weight: Font.Bold
                font.pixelSize: 16
                anchors.verticalCenter: parent.verticalCenter
            }

            TabSwitcher {
                id: tabSwitcher
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
            }
        }

        // 间距
        Rectangle {
            height: 16
            width: parent.width
        }

        // 评分方案网格
        Grid {
            width: parent.width
            columns: 3
            columnSpacing: 12
            rowSpacing: 12
            visible: tabSwitcher.currentIndex === 1
            anchors.horizontalCenter: parent.horizontalCenter

            // 第一行
            ScoreOptionCard {
                title: "RENAL"
                backgroundColor: "#F8FAFF"
                iconUrl: "qrc:/image/RENAL.png"
            }

            ScoreOptionCard {
                title: "CCLS"
                backgroundColor: "#F7FCFB"
                iconUrl: "qrc:/image/CCLS.png"
            }

            ScoreOptionCard {
                title: "TNM"
                backgroundColor: "#FFFAF8"
                iconUrl: "qrc:/image/TNM.png"
            }

            // 第二行
            ScoreOptionCard {
                title: "UCLS MRS"
                backgroundColor: "#FFFBF2"
                iconUrl: "qrc:/image/UCLS-MRS.png"
            }

            ScoreOptionCard {
                title: "UCLS CTS"
                backgroundColor: "#F8F7FF"
                iconUrl: "qrc:/image/UCLS-CTS.png"
            }

            ScoreOptionCard {
                title: "BIOSNAK"
                backgroundColor: "#F8FAFF"
                iconUrl: "qrc:/image/BIOSNAK.png"
            }
        }

        Grid {
            width: parent.width
            columns: 3
            columnSpacing: 12
            rowSpacing: 12
            visible: tabSwitcher.currentIndex === 0
            anchors.horizontalCenter: parent.horizontalCenter
            ScoreOptionCard {
                title: "TNM"
                backgroundColor: "#FFFAF8"
                iconUrl: "qrc:/image/TNM.png"
            }
            ScoreOptionCard {
                title: "CHAT"
                backgroundColor: "#F8FAFF"
                iconUrl: "qrc:/image/CHAT.png"
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
                }else if(title === "TNM"){
                    if($tnmManager.checkClipboard()){
                        currentPageChanged(2) // TNM页面索引
                        $tnmManager.startAnalysis()
                    }else{
                        messageManager.warning("剪贴板为空，请先复制内容")
                    }
                }else if(title === "RENAL"){
                    if($renalManager.checkClipboard()){
                        currentPageChanged(0) // TNM页面索引
                        $renalManager.startAnalysis()
                    }else{
                        messageManager.warning("剪贴板为空，请先复制内容")
                    }
                }
                else if(title === "CHAT"){
                    currentPageChanged(6)
                }
                // else if(title === "UCLS MRS"){
                //     currentPageChanged(3)
                // }
                else{
                    messageManager.warning("该功能暂未开放")
                }
            }
        }
    }
}
