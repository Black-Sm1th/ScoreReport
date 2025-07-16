import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
// 内容区域
Rectangle {
    width: parent.width
    height: contentArea.height  // 上下各20px边距
    color: "transparent"
    radius: 12

    Column {
        id: contentArea
        width: parent.width - 40  // 左右各20px边距
        anchors.horizontalCenter: parent.horizontalCenter
        anchors.top: parent.top
        spacing: 0
        // 标题和标签
        Row {
            width: parent.width
            height: 40

            Text {
                text: "请选择评分方案"
                font.pixelSize: 16
                color: "#2C2C2C"
                anchors.verticalCenter: parent.verticalCenter
            }

            Row {
                anchors.right: parent.right
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Rectangle {
                    width: 44
                    height: 24
                    color: "#E8F4FD"
                    radius: 12

                    Text {
                        anchors.centerIn: parent
                        text: "通用"
                        font.pixelSize: 12
                        color: "#1890FF"
                    }
                }

                Rectangle {
                    width: 32
                    height: 24
                    color: "#F5F5F5"
                    radius: 12

                    Text {
                        anchors.centerIn: parent
                        text: "肾"
                        font.pixelSize: 12
                        color: "#999999"
                    }
                }
            }
        }

        // 间距
        Item { height: 20 }

        // 评分方案网格
        Grid {
            width: parent.width
            columns: 3
            columnSpacing: 20
            rowSpacing: 20
            anchors.horizontalCenter: parent.horizontalCenter

            // 第一行
            ScoreOptionCard {
                iconColor: "#FFB800"
                title: "RENAL"
            }

            ScoreOptionCard {
                iconColor: "#8B7CFF"
                title: "CCLS"
            }

            ScoreOptionCard {
                iconColor: "#5DADE2"
                title: "TNM"
            }

            // 第二行
            ScoreOptionCard {
                iconColor: "#FFB800"
                title: "UCLS MRS"
            }

            ScoreOptionCard {
                iconColor: "#8B7CFF"
                title: "UCLS CTS"
            }

            ScoreOptionCard {
                iconColor: "#5DADE2"
                title: "BIOSNAK"
            }
        }
    }

    // 评分方案卡片组件
    component ScoreOptionCard: Rectangle {
        property string iconColor: "#FFB800"
        property string title: ""

        width: 146
        height: 110
        color: mouseArea2.containsMouse ? "#F8F9FA" : "#FAFAFA"
        radius: 8
        border.color: "#F0F0F0"
        border.width: 1

        Column {
            anchors.centerIn: parent
            spacing: 12

            Rectangle {
                width: 48
                height: 48
                color: iconColor
                radius: 12
                anchors.horizontalCenter: parent.horizontalCenter

                // 图标占位符
                Rectangle {
                    width: 24
                    height: 24
                    color: "white"
                    radius: 4
                    anchors.centerIn: parent
                }
            }

            Text {
                text: title
                font.pixelSize: 14
                color: "#2C2C2C"
                anchors.horizontalCenter: parent.horizontalCenter
            }
        }

        MouseArea {
            id: mouseArea2
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor

            onClicked: {
                console.log("选择了评分方案:", title)
                scoreDialog.visible = false
            }
        }
    }
}
