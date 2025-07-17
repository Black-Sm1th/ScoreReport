import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0

// 内容区域
Rectangle {
    width: parent.width
    height: loginForm.height
    color: "transparent"
    property var messageManager: null
    // 登录表单区域
    Rectangle {
        id: loginForm
        width: parent.width
        height: 292
        anchors.centerIn: parent

        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            y:32
            // 账号输入框
            Rectangle {
                width: 240
                height: 37
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#0A000000"
                radius: 8
                Text {
                    id: accountLabel
                    text: "账号"
                    font.family: "Alibaba PuHuiTi"
                    font.pixelSize: 16
                    color: "#D9000000"
                    anchors.left: parent.left
                    font.weight: Font.Bold
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 12
                }
                TextField {
                    id: accountInput
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.left: accountLabel.right
                    height: parent.height
                    width: 240 - accountLabel.width - 36
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: "Alibaba PuHuiTi"
                    font.pixelSize: 16
                    color: "#D9000000"
                    placeholderText: "请输入"
                    placeholderTextColor: "#40000000"
                    leftPadding: 0
                    rightPadding: 0
                    topPadding: 0
                    bottomPadding: 0
                    background: Rectangle {
                        color: "transparent"
                    }
                }
            }
            Rectangle{
                height: 16
                width: 240
                color: "transparent"
            }
            // 密码输入框
            Rectangle {
                id: passwordRec
                width: 240
                height: 37
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#0A000000"
                radius: 8
                Text {
                    id: passwordLabel
                    text: "密码"
                    font.family: "Alibaba PuHuiTi"
                    font.pixelSize: 16
                    color: "#D9000000"
                    anchors.left: parent.left
                    font.weight: Font.Bold
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 12
                }
                TextField {
                    id: passwordInput
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.left: passwordLabel.right
                    width: 240 - passwordLabel.width - 36 - 28
                    height: parent.height
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: "Alibaba PuHuiTi"
                    font.pixelSize: 16
                    echoMode: showPassword ? TextInput.Normal : TextInput.Password
                    color: "#D9000000"
                    placeholderText: "请输入"
                    placeholderTextColor: "#40000000"
                    property bool showPassword: false
                    leftPadding: 0
                    rightPadding: 0
                    topPadding: 0
                    bottomPadding: 0
                    background: Rectangle {
                        color: "transparent"
                    }
                }
                // 显示/隐藏密码按钮
                Button {
                    width: 16
                    height: 16
                    anchors.right: parent.right
                    anchors.rightMargin: 12
                    anchors.verticalCenter: parent.verticalCenter
                    background: Rectangle {
                        color: "transparent"
                    }
                    Image{
                        source: passwordInput.showPassword ? "qrc:/image/eyeSlash.png" : "qrc:/image/eye.png"
                        anchors.centerIn: parent
                    }
                    onClicked: passwordInput.showPassword = !passwordInput.showPassword
                }
            }

            Rectangle{
                height: 32
                width: 240
                color: "transparent"
            }
            // 记住账号复选框
            Rectangle {
                anchors.left: passwordRec.left
                height: 29
                width: 240
                color:"transparent"
                CheckBox {
                    id: rememberCheckBox
                    checked: true
                    width:16
                    height: 16
                    anchors.verticalCenter: parent.verticalCenter
                    indicator: Rectangle {
                        implicitWidth: 16
                        implicitHeight: 16
                        radius: 4
                        anchors.verticalCenter: parent.verticalCenter
                        border.color: rememberCheckBox.checked ? "#006BFF" : "#40000000"
                        border.width: 1
                        color: rememberCheckBox.checked ? "#006BFF" : "#ffffffff"

                        Image{
                            source: "qrc:/image/vector.png"
                            anchors.centerIn: parent
                            visible: rememberCheckBox.checked
                        }
                    }
                }

                Text {
                    font.family: "Alibaba PuHuiTi"
                    font.pixelSize: 16
                    color: "#D9000000"
                    anchors.leftMargin: 4
                    anchors.left: rememberCheckBox.right
                    font.weight: Font.Bold
                    text: "记住账号"
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Rectangle{
                height: 12
                width: 240
                color: "transparent"
            }

            // 登录按钮
            Button {
                width: 240
                height: 37
                anchors.left: passwordRec.left
                background: Rectangle {
                    color: parent.pressed ? "#0066cc" : (parent.hovered ? "#0080ff" : "#006BFF")
                    radius: 8
                }

                Text {
                    anchors.centerIn: parent
                    text: "登录"
                    font.family: "Alibaba PuHuiTi"
                    font.pixelSize: 16
                    font.bold: true
                    color: "#ffffff"
                }

                onClicked: {
                    if(accountInput.text === ""){
                        messageManager.warning("账号不能为空",2000)
                        return
                    }
                    if(passwordInput.text === ""){
                        messageManager.warning("密码不能为空",2000)
                        return
                    }
                    $loginManager.login(accountInput.text, passwordInput.text)
                }
            }
        }
    }
}
