#include "LoginManager.h"
#include "ApiManager.h"
#include <QClipboard>
#include <QGuiApplication>
LoginManager::LoginManager(QObject* parent)
    : QObject(parent)
    , m_apiManager(nullptr)
    , m_settings(nullptr)
{
    setcurrentUserId("");
    setisLoggedIn(false);
    setcurrentUserName("");
    setcurrentUserAvatar("");
    setsavedUsername("");
    setsavedPassword("");
    setisChangingUser(false);
    setisAdding(false);
    setisRegistering(false);
    setrememberPassword(false);
    setuserList(QVariantList());
    setshowDialogOnTextSelection(true);  // 默认显示弹窗
    m_selector = new GlobalTextMonitor();
    connect(m_selector, &GlobalTextMonitor::textSelected,
        this, &LoginManager::onTextSelected);

    // 初始化QSettings
    m_settings = new QSettings("ScoreReport", "LoginCredentials", this);
    
    m_apiManager = GET_SINGLETON(ApiManager);
    connect(m_apiManager, &ApiManager::loginResponse,
        this, &LoginManager::onLoginResponse);
    connect(m_apiManager, &ApiManager::registerResponse,
        this, &LoginManager::onRegistResponse);
    // 启动时加载保存的凭据和用户列表
    loadSavedCredentials();
    loadUserList();
}

bool LoginManager::login(const QString& username, const QString& password)
{
    if (!m_apiManager) {
        qWarning() << "[LoginManager] ApiManager is null!";
        emit loginResult(false, "Internal error: ApiManager not available");
        return false;
    }
    
    // 使用ApiManager进行登录请求
    m_apiManager->loginUser(username, password);
    return true;
}

void LoginManager::onLoginResponse(bool success, const QString& message, const QJsonObject& data)
{   
    if (success) {
        QString respUser = data.value("userName").toString();
        QString respCurrentUserId = data.value("id").toString();
        QString userAvatar = data.value("userAvatar").toString();
        setcurrentUserId(respCurrentUserId);
        setcurrentUserAvatar(userAvatar);
        setcurrentUserName(respUser);
        setisLoggedIn(true);
        setisAdding(false);
        setisChangingUser(false);
        
        // 只有当弹窗设置为开启时才启动文本监控
        if (getshowDialogOnTextSelection()) {
            m_selector->startMonitoring();
        }
        // 添加用户到列表（这里需要从UI获取密码，暂时先用空字符串占位）
        // 实际的密码会在UI层的loginResult处理中调用addUserToList
    } else {
        setisLoggedIn(false);
        setcurrentUserName("");
        setcurrentUserAvatar("");
        setcurrentUserId("");
    }
    
    emit loginResult(success, message);
}

void LoginManager::logout()
{
    qDebug() << "[LoginManager] User logout";
    setisLoggedIn(false);
    setcurrentUserName("");
    setcurrentUserAvatar("");
    setcurrentUserId("");
    m_selector->stopMonitoring();
    emit logoutSuccess();
}

void LoginManager::saveCredentials(const QString& username, const QString& password, bool remember)
{
    if (!m_settings) {
        return;
    }
    
    setrememberPassword(remember);
    setsavedUsername(username);
    
    if (remember) {
        setsavedPassword(password);
        // 保存到QSettings
        m_settings->setValue("username", username);
        m_settings->setValue("password", password);
        m_settings->setValue("rememberPassword", true);
    } else {
        setsavedPassword("");
        // 只保存用户名，清除密码
        m_settings->setValue("username", username);
        m_settings->remove("password");
        m_settings->setValue("rememberPassword", false);
    }
    m_settings->sync();
    
    qDebug() << "[LoginManager] Credentials saved, remember password:" << remember;
}

void LoginManager::loadSavedCredentials()
{
    if (!m_settings) {
        return;
    }
    
    QString username = m_settings->value("username", "").toString();
    QString password = m_settings->value("password", "").toString();
    bool remember = m_settings->value("rememberPassword", false).toBool();
    bool showDialog = m_settings->value("showDialogOnTextSelection", true).toBool();
    
    setsavedUsername(username);
    setsavedPassword(remember ? password : "");
    setrememberPassword(remember);
    setshowDialogOnTextSelection(showDialog);
    
    qDebug() << "[LoginManager] Loaded saved credentials, username:" << username << "remember:" << remember << "showDialog:" << showDialog;
}


void LoginManager::addUserToList(const QString& username, const QString& password, const QString& userId, const QString& avatar)
{
    if (!m_settings || userId.isEmpty()) {
        return;
    }
    
    // 检查用户是否已经在列表中
    QVariantMap existingUser = findUserInList(userId);
    if (!existingUser.isEmpty()) {
        // 用户已存在，更新信息
        QVariantList currentList = getuserList();
        for (int i = 0; i < currentList.size(); ++i) {
            QVariantMap userMap = currentList[i].toMap();
            if (userMap.value("userId").toString() == userId) {
                userMap["username"] = username;
                userMap["password"] = password;
                userMap["avatar"] = avatar;
                currentList[i] = userMap;
                break;
            }
        }
        setuserList(currentList);
    } else {
        // 新用户，添加到列表
        QVariantMap userMap;
        userMap["username"] = username;
        userMap["password"] = password;
        userMap["userId"] = userId;
        userMap["avatar"] = avatar;
        
        QVariantList currentList = getuserList();
        currentList.append(userMap);
        setuserList(currentList);
    }
    
    // 保存到设置
    saveUserList();
    
    qDebug() << "[LoginManager] Added/Updated user in list:" << username << "userId:" << userId;
}

void LoginManager::removeUserFromList(const QString& userId)
{
    if (!m_settings || userId.isEmpty()) {
        return;
    }
    QVariantList currentList = getuserList();
    for (int i = 0; i < currentList.size(); ++i) {
        QVariantMap userMap = currentList[i].toMap();
        if (userMap.value("userId").toString() == userId) {
            currentList.removeAt(i);
            setuserList(currentList);
            saveUserList();
            qDebug() << "[LoginManager] Removed user from list, userId:" << userId;
            break;
        }
    }
}

bool LoginManager::registAccount(const QString& userAccount, const QString& userPassword, const QString& checkPassword)
{
    if (!m_apiManager) {
        qWarning() << "[LoginManager] ApiManager is null!";
        emit registResult(false, "Internal error: ApiManager not available");
        return false;
    }

    // 使用ApiManager进行登录请求
    m_apiManager->registerUser(userAccount, userPassword, checkPassword);
    return true;
}

void LoginManager::stopMonitoring()
{
    if (m_selector->isMonitoring()) {
        m_selector->stopMonitoring();
    }
    delete m_selector;
}

void LoginManager::copyToClipboard(const QString& text)
{
    QClipboard* clipboard = QGuiApplication::clipboard();
    clipboard->setText(text);
}

void LoginManager::onRegistResponse(bool success, const QString& message, const QJsonObject& data)
{
    emit registResult(success, message);
}

void LoginManager::onTextSelected(const QString& text)
{
    qDebug() << "text: " << text;
    
    // 获取当前鼠标位置
    QPoint mousePos = QCursor::pos();
    emit textSelectionDetected(text.trimmed(), mousePos.x(), mousePos.y());
}

void LoginManager::loadUserList()
{
    if (!m_settings) {
        return;
    }
    
    QVariantList loadedList = m_settings->value("userList", QVariantList()).toList();
    setuserList(loadedList);
    
    qDebug() << "[LoginManager] Loaded user list, count:" << loadedList.size();
}

void LoginManager::saveUserList()
{
    if (!m_settings) {
        return;
    }
    
    m_settings->setValue("userList", getuserList());
    m_settings->sync();
    
    qDebug() << "[LoginManager] Saved user list, count:" << getuserList().size();
}

QVariantMap LoginManager::findUserInList(const QString& userId)
{
    if (userId.isEmpty()) {
        return QVariantMap();
    }
    
    QVariantList currentList = getuserList();
    for (const QVariant& userVariant : currentList) {
        QVariantMap userMap = userVariant.toMap();
        if (userMap.value("userId").toString() == userId) {
            return userMap;
        }

    }
    
    return QVariantMap();
}

void LoginManager::saveShowDialogSetting(bool showDialog)
{
    if (!m_settings) {
        return;
    }
    
    bool oldSetting = getshowDialogOnTextSelection();
    setshowDialogOnTextSelection(showDialog);
    m_settings->setValue("showDialogOnTextSelection", showDialog);
    m_settings->sync();
    
    // 如果用户已登录且设置发生了变化，相应地启动或停止监控
    if (getisLoggedIn() && oldSetting != showDialog) {
        if (showDialog) {
            // 设置改为true，启动监控
            m_selector->startMonitoring();
            qDebug() << "[LoginManager] Started text monitoring due to setting change";
        } else {
            // 设置改为false，停止监控
            m_selector->stopMonitoring();
            qDebug() << "[LoginManager] Stopped text monitoring due to setting change";
        }
    }
}