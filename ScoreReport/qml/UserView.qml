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
        if ((!$loginManager.isLoggedIn || ($loginManager.isChangingUser && $loginManager.isAdding)) && !$loginManager.isRegistering) {
            loginButton.clicked()
        }else if((!$loginManager.isLoggedIn || ($loginManager.isChangingUser && $loginManager.isAdding)) && $loginManager.isRegistering){
            registButton.clicked()
        }
    }
    Keys.onEnterPressed: {
        if ((!$loginManager.isLoggedIn || ($loginManager.isChangingUser && $loginManager.isAdding)) && !$loginManager.isRegistering) {
            loginButton.clicked()
        }else if((!$loginManager.isLoggedIn || ($loginManager.isChangingUser && $loginManager.isAdding)) && $loginManager.isRegistering){
            registButton.clicked()
        }
    }

    Connections{
        target: $loginManager
        function onLoginResult(success,message){
            if(success){
                // 登录成功时保存凭据（用于记住密码功能）
                $loginManager.saveCredentials(accountInput.text, passwordInput.text, rememberCheckBox.checked)
                // 登录成功时添加用户到列表（不管是否记住密码都添加）
                $loginManager.addUserToList(accountInput.text, passwordInput.text, $loginManager.currentUserId, $loginManager.currentUserAvatar)
                messageManager.success(qsTr("登录成功！"))
            }else{
                messageManager.error(qsTr(message))
            }
        }
        function onLogoutSuccess(){

        }
        function onRegistResult(success,message){
            if(success){
                $loginManager.isRegistering = false
                accountInput.text = accountInputRegist.text
                passwordInput.text = ""
                accountInputRegist.text = ""
                passwordInputRegist.text = ""
                surepasswordInputRegist.text = ""
                messageManager.success(qsTr("注册成功！"))
            }else{
                messageManager.error(qsTr(message))
            }
        }
    }

    // 组件加载完成后自动填充保存的凭据
    Component.onCompleted: {
        loadSavedCredentials()
    }

    function loadSavedCredentials() {
        accountInput.text = $loginManager.savedUsername
        passwordInput.text = $loginManager.savedPassword
        rememberCheckBox.checked = $loginManager.rememberPassword
    }

    // 登录表单区域
    Rectangle {
        id: loginForm
        width: parent.width
        height: 292 + 24
        color: "transparent"
        anchors.centerIn: parent
        //登录界面
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            visible: (!$loginManager.isLoggedIn || ($loginManager.isChangingUser && $loginManager.isAdding)) && !$loginManager.isRegistering
            y:32
            Text {
                text: qsTr("登录账号")
                font.family: "Alibaba PuHuiTi 3.0"
                font.pixelSize: 16
                color: "#D9000000"
                font.weight: Font.Bold
                 anchors.left: passwordRec.left
            }
            Rectangle{
                height: 20
                width: 240
                color: "transparent"
            }
            // 账号输入框
            Rectangle {
                width: 240
                height: 37
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#0A000000"
                radius: 8
                Text {
                    id: accountLabel
                    text: qsTr("账号")
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
                    placeholderText: qsTr("请输入")
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
                height: 12
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
                    text: qsTr("密码")
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
                    placeholderText: qsTr("请输入")
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
                height: 20
                width: 240
                color: "transparent"
            }

            Rectangle{
                height: 37
                width: 240
                color: "transparent"
                anchors.left: passwordRec.left
                CustomButton{
                    id: returnButton
                    text: qsTr("返回")
                    visible: $loginManager.isChangingUser && $loginManager.isAdding
                    width: 114
                    height: 37
                    borderWidth: 0
                    backgroundColor: "#F5F5F5"
                    textColor: "#73000000"
                    anchors.left: parent.left
                    onClicked: {
                        $loginManager.isAdding = false
                    }
                }

                CustomButton{
                    id: loginButton
                    text: qsTr("登录")
                    width: $loginManager.isChangingUser && $loginManager.isAdding ? 114 : 240
                    height: 37
                    borderWidth: 0
                    backgroundColor: "#006BFF"
                    textColor: "#ffffff"
                    anchors.right: parent.right
                    onClicked: {
                        if(accountInput.text === ""){
                            messageManager.warning(qsTr("账号不能为空"))
                            return
                        }
                        if(passwordInput.text === ""){
                            messageManager.warning(qsTr("密码不能为空"))
                            return
                        }
                        if($loginManager.currentUserId !== ""){
                            $loginManager.logout()
                        }
                        $loginManager.login(accountInput.text, passwordInput.text)
                    }
                }
            }

            Rectangle{
                height: 12
                width: 240
                color: "transparent"
            }

            // 记住密码复选框
            Rectangle {
                anchors.left: passwordRec.left
                height: 29
                width: 240
                color:"transparent"
                CheckBox {
                    id: rememberCheckBox
                    checked: false
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
                    text: qsTr("记住密码")
                    anchors.verticalCenter: parent.verticalCenter

                    MouseArea {
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: rememberCheckBox.checked = !rememberCheckBox.checked
                    }
                }

                CustomButton{
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: parent.right
                    width: 63
                    height: 29
                    border.width: 0
                    backgroundColor: "transparent"
                    textColor: "#006BFF"
                    hoverTextColor: "#D9006BFF"
                    text: qsTr("注册账号")
                    fontSize: 16
                    onClicked: {
                        $loginManager.isRegistering = true
                    }
                }
            }
        }
        //登录后用户界面
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            visible: $loginManager.isLoggedIn && !$loginManager.isChangingUser && !$loginManager.isAdding && !$loginManager.isRegistering
            y:43
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
                    text: qsTr("账号")
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

            // // 记住账号复选框
            // Rectangle {
            //     anchors.left: inputRec.left
            //     height: 29
            //     width: 240
            //     color:"transparent"
            //     CheckBox {
            //         id: clearCheckBox
            //         checked: true
            //         width:16
            //         height: 16
            //         anchors.verticalCenter: parent.verticalCenter
            //         indicator: Rectangle {
            //             implicitWidth: 16
            //             implicitHeight: 16
            //             radius: 4
            //             anchors.verticalCenter: parent.verticalCenter
            //             border.color: clearCheckBox.checked ? "#006BFF" : "#40000000"
            //             border.width: 1
            //             color: clearCheckBox.checked ? "#006BFF" : "#ffffffff"

            //             Image{
            //                 source: "qrc:/image/vector.png"
            //                 anchors.centerIn: parent
            //                 visible: clearCheckBox.checked
            //             }

            //             MouseArea {
            //                 anchors.fill: parent
            //                 cursorShape: Qt.PointingHandCursor
            //                 onClicked: clearCheckBox.checked = !clearCheckBox.checked
            //             }
            //         }
            //     }

            //     Text {
            //         font.family: "Alibaba PuHuiTi 3.0"
            //         font.pixelSize: 16
            //         color: "#D9000000"
            //         anchors.leftMargin: 4
            //         anchors.left: clearCheckBox.right
            //         text: "清除历史记录"
            //         anchors.verticalCenter: parent.verticalCenter

            //         MouseArea {
            //             anchors.fill: parent
            //             cursorShape: Qt.PointingHandCursor
            //             onClicked: clearCheckBox.checked = !clearCheckBox.checked
            //         }
            //     }
            // }

            // Rectangle{
            //     height: 12
            //     width: 240
            //     color: "transparent"
            // }

            Row{
                anchors.left: inputRec.left
                spacing: 12

                CustomButton{
                    text: qsTr("退出账号")
                    width: 228 / 2
                    height: 37
                    borderWidth: 0
                    backgroundColor: "#FF5132"
                    textColor: "#ffffff"
                    onClicked: {
                        $loginManager.removeUserFromList($loginManager.currentUserId)
                        $loginManager.logout()
                        messageManager.success(qsTr("已退出登录账号！"))
                    }
                }
                CustomButton{
                    text: qsTr("切换账号")
                    width: 228 / 2
                    height: 37
                    borderWidth: 0
                    backgroundColor: "#006BFF"
                    textColor: "#ffffff"
                    onClicked: {
                        $loginManager.isChangingUser = true
                    }
                }
            }
        }
        //切换用户界面
        Rectangle {
            height: 292
            width: parent.width
            visible: $loginManager.isLoggedIn && $loginManager.isChangingUser && !$loginManager.isAdding && !$loginManager.isRegistering
            color: "transparent"
            ScrollView {
                id: scrollView
                width: 312
                height: parent.height
                anchors.horizontalCenter: parent.horizontalCenter
                clip: true
                ScrollBar.vertical.policy: ScrollBar.AlwaysOff
                Column{
                    width: 312
                    spacing: 12
                    Repeater {
                        model: $loginManager.userList.length
                        delegate: Rectangle {
                            width: 312
                            height: 64
                            radius: 8
                            color: "#0A000000"
                            MouseArea{
                                id: userArea
                                hoverEnabled: true
                                anchors.fill: parent
                            }
                            Rectangle {
                                id: userAvatar
                                width: 40
                                height: 40
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.leftMargin: 12
                                anchors.left: parent.left
                                color: "transparent"
                                Image {
                                    id: userAvatarImage
                                    anchors.fill: parent
                                    source: $loginManager.userList[index].avatar
                                    fillMode: Image.PreserveAspectCrop
                                    visible: false
                                }
                                Rectangle {
                                    id: userMaskRect
                                    anchors.fill: parent
                                    radius: 100
                                    visible: false
                                }

                                OpacityMask {
                                    anchors.fill: parent
                                    source: userAvatarImage
                                    maskSource: userMaskRect
                                }
                            }
                            Text{
                                anchors.verticalCenter: parent.verticalCenter
                                font.family: "Alibaba PuHuiTi 3.0"
                                font.pixelSize: 16
                                color: "#D9000000"
                                anchors.left: userAvatar.right
                                anchors.leftMargin: 12
                                text: $loginManager.userList[index].username
                            }
                            Row {
                                height: 22
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                visible: $loginManager.userList[index].userId === $loginManager.currentUserId
                                spacing: 4
                                Text{
                                    anchors.verticalCenter: parent.verticalCenter
                                    text:"●"
                                    font.family: "Alibaba PuHuiTi 3.0"
                                    font.pixelSize: 8
                                    color: "#35C14A"
                                }
                                Text{
                                    anchors.verticalCenter: parent.verticalCenter
                                    text:qsTr("当前登录")
                                    font.family: "Alibaba PuHuiTi 3.0"
                                    font.pixelSize: 12
                                    color: "#73000000"
                                }
                            }
                            Rectangle {
                                height: 22
                                width: switchImage.width + 4 + switchText.width
                                anchors.verticalCenter: parent.verticalCenter
                                anchors.right: parent.right
                                anchors.rightMargin: 12
                                color: "transparent"
                                visible: $loginManager.userList[index].userId !== $loginManager.currentUserId && (userArea.containsMouse || changeArea.containsMouse)
                                Image{
                                    id:switchImage
                                    anchors.left: parent.left
                                    anchors.verticalCenter: parent.verticalCenter
                                    source: "qrc:/image/arrowSwap.png"
                                }
                                Text{
                                    id:switchText
                                    anchors.right: parent.right
                                    anchors.verticalCenter: parent.verticalCenter
                                    text:qsTr("切换")
                                    font.family: "Alibaba PuHuiTi 3.0"
                                    font.pixelSize: 12
                                    color: "#006BFF"
                                }
                                MouseArea{
                                    id: changeArea
                                    hoverEnabled: true
                                    anchors.fill: parent
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        accountInput.text = $loginManager.userList[index].username
                                        passwordInput.text = $loginManager.userList[index].password
                                        $loginManager.logout()
                                        $loginManager.login($loginManager.userList[index].username, $loginManager.userList[index].password)
                                    }
                                }
                            }
                        }
                    }
                    Rectangle {
                        width: 312
                        height: 64
                        radius: 8
                        color: "#0A000000"
                        Rectangle {
                            id:addBtn
                            width: 40
                            height: 40
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.leftMargin: 12
                            anchors.left: parent.left
                            color: "#0F000000"
                            opacity: addArea.containsMouse ? "0.8" : "1"
                            radius: 100
                            Image {
                                source: "qrc:/image/add.png"
                                anchors.centerIn: parent
                            }
                            MouseArea{
                                id: addArea
                                hoverEnabled: true
                                anchors.fill: parent
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    $loginManager.isAdding = true;
                                }
                            }
                        }
                        Text{
                            anchors.verticalCenter: parent.verticalCenter
                            anchors.left: addBtn.right
                            anchors.leftMargin: 12
                            text:qsTr("添加账号")
                            font.family: "Alibaba PuHuiTi 3.0"
                            font.pixelSize: 16
                            color: "#D9000000"
                        }
                    }
                }
            }
        }
        //注册界面
        Column {
            anchors.horizontalCenter: parent.horizontalCenter
            width: parent.width
            visible: (!$loginManager.isLoggedIn || ($loginManager.isChangingUser && $loginManager.isAdding)) && $loginManager.isRegistering
            Text {
                text: qsTr("注册账号")
                font.family: "Alibaba PuHuiTi 3.0"
                font.pixelSize: 16
                color: "#D9000000"
                font.weight: Font.Bold
                anchors.left: passwordRecRegist.left
            }
            Rectangle{
                height: 20
                width: 240
                color: "transparent"
            }
            // 账号输入框
            Rectangle {
                width: 240
                height: 37
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#0A000000"
                radius: 8
                Text {
                    id: accountLabelRegist
                    text: qsTr("账号")
                    width: surepasswordLabelRegist.width
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.pixelSize: 16
                    color: "#D9000000"
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 12
                }
                TextField {
                    id: accountInputRegist
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.left: accountLabelRegist.right
                    height: parent.height
                    width: 240 - accountLabelRegist.width - 36
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.pixelSize: 16
                    color: "#D9000000"
                    selectByMouse: true
                    placeholderText: qsTr("请输入")
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
                height: 12
                width: 240
                color: "transparent"
            }
            // 密码输入框
            Rectangle {
                id: passwordRecRegist
                width: 240
                height: 37
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#0A000000"
                radius: 8
                Text {
                    id: passwordLabelRegist
                    text: qsTr("密码")
                    width: surepasswordLabelRegist.width
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.pixelSize: 16
                    color: "#D9000000"
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 12
                }
                TextField {
                    id: passwordInputRegist
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.left: passwordLabelRegist.right
                    width: 240 - passwordLabelRegist.width - 36 - 28
                    height: parent.height
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.pixelSize: 16
                    selectByMouse: true
                    echoMode: showPassword ? TextInput.Normal : TextInput.Password
                    color: "#D9000000"
                    placeholderText: qsTr("请输入")
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
                        source: passwordInputRegist.showPassword ? "qrc:/image/eye.png" : "qrc:/image/eyeSlash.png"
                        anchors.centerIn: parent
                    }
                    MouseArea{
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: passwordInputRegist.showPassword = !passwordInputRegist.showPassword
                    }
                }
            }
            Rectangle{
                height: 12
                width: 240
                color: "transparent"
            }
            // 确认输入框
            Rectangle {
                id: surepasswordRecRegist
                width: 240
                height: 37
                anchors.horizontalCenter: parent.horizontalCenter
                color: "#0A000000"
                radius: 8
                Text {
                    id: surepasswordLabelRegist
                    text: qsTr("确认密码")
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.pixelSize: 16
                    color: "#D9000000"
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.leftMargin: 12
                }
                TextField {
                    id: surepasswordInputRegist
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    anchors.left: surepasswordLabelRegist.right
                    width: 240 - surepasswordLabelRegist.width - 36 - 28
                    height: parent.height
                    anchors.verticalCenter: parent.verticalCenter
                    font.family: "Alibaba PuHuiTi 3.0"
                    font.pixelSize: 16
                    selectByMouse: true
                    echoMode: showPassword ? TextInput.Normal : TextInput.Password
                    color: "#D9000000"
                    placeholderText: qsTr("请输入")
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
                        source: surepasswordInputRegist.showPassword ? "qrc:/image/eye.png" : "qrc:/image/eyeSlash.png"
                        anchors.centerIn: parent
                    }
                    MouseArea{
                        anchors.fill: parent
                        cursorShape: Qt.PointingHandCursor
                        onClicked: surepasswordInputRegist.showPassword = !surepasswordInputRegist.showPassword
                    }
                }
            }
            Rectangle{
                height: 20
                width: 240
                color: "transparent"
            }

            Rectangle{
                height: 37
                width: 240
                color: "transparent"
                anchors.left: surepasswordRecRegist.left

                CustomButton{
                    id: registButton
                    text: qsTr("注册")
                    width: 240
                    height: 37
                    borderWidth: 0
                    backgroundColor: "#006BFF"
                    textColor: "#ffffff"
                    anchors.right: parent.right
                    onClicked: {
                        if(accountInputRegist.text === ""){
                            messageManager.warning(qsTr("账号不能为空"))
                            return
                        }
                        if(passwordInputRegist.text === ""){
                            messageManager.warning(qsTr("密码不能为空"))
                            return
                        }
                        if(surepasswordInputRegist.text === ""){
                            messageManager.warning(qsTr("确认密码不能为空"))
                            return
                        }
                        $loginManager.registAccount(accountInputRegist.text, passwordInputRegist.text, surepasswordInputRegist.text)
                    }
                }
            }
            Rectangle{
                height: 12
                width: 240
                color: "transparent"
            }
            CustomButton{
                anchors.horizontalCenter: parent.horizontalCenter
                width: 63
                height: 29
                border.width: 0
                backgroundColor: "transparent"
                textColor: "#006BFF"
                hoverTextColor: "#D9006BFF"
                text: qsTr("登录账号")
                fontSize: 16
                onClicked: {
                    $loginManager.isRegistering = false
                }
            }
        }
    }
}
