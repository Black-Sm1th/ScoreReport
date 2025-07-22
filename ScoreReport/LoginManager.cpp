#include "LoginManager.h"
#include "ApiManager.h"

LoginManager::LoginManager(QObject* parent)
    : QObject(parent)
    , currentUserId("")
    , m_apiManager(nullptr)
{
    setisLoggedIn(false);
    setcurrentUserName("");
    m_apiManager = GET_SINGLETON(ApiManager);
    connect(m_apiManager, &ApiManager::loginResponse,
        this, &LoginManager::onLoginResponse);
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
    currentUserId = "";
    emit logoutSuccess();
}

QString LoginManager::getUserId()
{
    return currentUserId;
}
