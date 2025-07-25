import QtQuick 2.9
import QtQuick.Window 2.2
import QtQuick.Controls 2.2
import QtQuick.Dialogs 1.2
import QtGraphicalEffects 1.0
import "./components"
// 内容区域
Rectangle {
    width: parent.width
    height: loginForm.height
    color: "transparent"
    property var messageManager: null

    // 添加键盘焦点支持
    focus: true
    Keys.onReturnPressed: {
        if (!$loginManager.isLoggedIn) {
            loginButton.clicked()
        }
    }
    Keys.onEnterPressed: {
        if (!$loginManager.isLoggedIn) {
            loginButton.clicked()
        }
    }

    Connections{
        target: $loginManager
        function onLoginResult(success,message){
            if(success){
                messageManager.success("登录成功！")
            }else{
                messageManager.error(message)
            }
        }
        function onLogoutSuccess(){
            messageManager.success("已退出登录账号！")
        }
    }

    // 登录表单区域
    Rectangle {
        id: loginForm
        width: parent.width
        height: 292 + 24
        color: "transparent"
        anchors.centerIn: parent
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            visible: !$loginManager.isLoggedIn
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
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.pixelSize: 16
                    color: "#D9000000"
                    anchors.left: parent.left
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
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.pixelSize: 16
                    color: "#D9000000"
                    selectByMouse: true
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
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.pixelSize: 16
                    color: "#D9000000"
                    anchors.left: parent.left
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
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.pixelSize: 16
                    selectByMouse: true
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
                        source: passwordInput.showPassword ? "qrc:/image/eye.png" : "qrc:/image/eyeSlash.png"
                        anchors.centerIn: parent
                    }
                    MouseArea{
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: passwordInput.showPassword = !passwordInput.showPassword
                    }
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

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: rememberCheckBox.checked = !rememberCheckBox.checked
                        }
                    }
                }

                Text {
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.pixelSize: 16
                    color: "#D9000000"
                    anchors.leftMargin: 4
                    anchors.left: rememberCheckBox.right
                    text: "记住账号"
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rememberCheckBox.checked = !rememberCheckBox.checked
                    }
                }
            }

            Rectangle{
                height: 12
                width: 240
                color: "transparent"
            }
            CustomButton{
                id: loginButton
                text: "登录"
                width: 240
                height: 37
                borderWidth: 0
                backgroundColor: "#006BFF"
                textColor: "#ffffff"
                anchors.left: passwordRec.left
                onClicked: {
                    if(accountInput.text === ""){
                        messageManager.warning("账号不能为空")
                        return
                    }
                    if(passwordInput.text === ""){
                        messageManager.warning("密码不能为空")
                        return
                    }
                    $loginManager.login(accountInput.text, passwordInput.text)
                }
            }
        }
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            visible: $loginManager.isLoggedIn
            y:22.5
            Rectangle {
                width: 56
                height: 56
                anchors.horizontalCenter: parent.horizontalCenter
                color: "transparent"
                
                Image {
                    id: avatarImage
                    anchors.fill: parent
                    source: $loginManager.currentUserAvatar ? $loginManager.currentUserAvatar : "qrc:/image/loginHead.png"
                    fillMode: Image.PreserveAspectCrop
                    visible: false
                }
                
                Rectangle {
                    id: maskRect
                    anchors.fill: parent
                    radius: 100
                    visible: false
                }
                
                OpacityMask {
                    anchors.fill: parent
                    source: avatarImage
                    maskSource: maskRect
                }
            }

            Rectangle{
                height: 16
                width: 240
                color: "transparent"
            }

            // 账号输入框
            Rectangle {
                id: inputRec
                width: 240
                height: 37
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#0A000000"
                radius: 8
                Text {
                    id: accountText
                    text: "账号"
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.pixelSize: 16
                    color: "#D9000000"
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 12
                }
                Text {
                    id: accountName
                    text: $loginManager.currentUserName
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.left: accountText.right
                    width: 240 - accountText.width - 36
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.pixelSize: 16
                    color: "#D9000000"
                }
            }

            Rectangle{
                height: 32
                width: 240
                color: "transparent"
            }

            // 记住账号复选框
            Rectangle {
                anchors.left: inputRec.left
                height: 29
                width: 240
                color:"transparent"
                CheckBox {
                    id: clearCheckBox
                    checked: true
                    width:16
                    height: 16
                    anchors.verticalCenter: parent.verticalCenter
                    indicator: Rectangle {
                        implicitWidth: 16
                        implicitHeight: 16
                        radius: 4
                        anchors.verticalCenter: parent.verticalCenter
                        border.color: clearCheckBox.checked ? "#006BFF" : "#40000000"
                        border.width: 1
                        color: clearCheckBox.checked ? "#006BFF" : "#ffffffff"

                        Image{
                            source: "qrc:/image/vector.png"
                            anchors.centerIn: parent
                            visible: clearCheckBox.checked
                        }

                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: clearCheckBox.checked = !clearCheckBox.checked
                        }
                    }
                }

                Text {
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.pixelSize: 16
                    color: "#D9000000"
                    anchors.leftMargin: 4
                    anchors.left: clearCheckBox.right
                    text: "清除历史记录"
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: clearCheckBox.checked = !clearCheckBox.checked
                    }
                }
            }

            Rectangle{
                height: 12
                width: 240
                color: "transparent"
            }

            Row{
                anchors.left: inputRec.left
                spacing: 12

                CustomButton{
                    text: "退出账号"
                    width: 228 / 2
                    height: 37
                    borderWidth: 0
                    backgroundColor: "#FF5132"
                    textColor: "#ffffff"
                    onClicked: {
                        $loginManager.logout()
                    }
                }
                CustomButton{
                    text: "切换账号"
                    width: 228 / 2
                    height: 37
                    borderWidth: 0
                    backgroundColor: "#006BFF"
                    textColor: "#ffffff"
                    onClicked: {

                    }
                }
            }
        }
    }
}
