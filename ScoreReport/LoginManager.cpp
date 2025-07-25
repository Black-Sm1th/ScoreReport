#include "LoginManager.h"
#include "ApiManager.h"

LoginManager::LoginManager(QObject* parent)
    : QObject(parent)
    , currentUserId("")
    , m_apiManager(nullptr)
    , m_settings(nullptr)
{
    setisLoggedIn(false);
    setcurrentUserName("");
    setcurrentUserAvatar("");
    setsavedUsername("");
    setsavedPassword("");
    setrememberPassword(false);
    
    // 初始化QSettings
    m_settings = new QSettings("ScoreReport", "LoginCredentials", this);
    
    m_apiManager = GET_SINGLETON(ApiManager);
    connect(m_apiManager, &ApiManager::loginResponse,
        this, &LoginManager::onLoginResponse);
    
    // 启动时加载保存的凭据
    loadSavedCredentials();
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
        currentUserId = data.value("id").toString();
        setcurrentUserAvatar(data.value("userAvatar").toString());
        setcurrentUserName(respUser);
        setisLoggedIn(true);
    } else {
        setisLoggedIn(false);
        setcurrentUserName("");
    }
    
    emit loginResult(success, message);
}

void LoginManager::logout()
{
    qDebug() << "[LoginManager] User logout";
    setisLoggedIn(false);
    setcurrentUserName("");
    setcurrentUserAvatar("");
    currentUserId = "";
    emit logoutSuccess();
}

QString LoginManager::getUserId()
{
    return currentUserId;
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
