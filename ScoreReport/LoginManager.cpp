#include "LoginManager.h"
#include "ApiManager.h"

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
    setrememberPassword(false);
    setuserList(QVariantList());
    
    // 初始化QSettings
    m_settings = new QSettings("ScoreReport", "LoginCredentials", this);
    
    m_apiManager = GET_SINGLETON(ApiManager);
    connect(m_apiManager, &ApiManager::loginResponse,
        this, &LoginManager::onLoginResponse);
    
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
    
    setsavedUsername(username);
    setsavedPassword(remember ? password : "");
    setrememberPassword(remember);
    
    qDebug() << "[LoginManager] Loaded saved credentials, username:" << username << "remember:" << remember;
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
