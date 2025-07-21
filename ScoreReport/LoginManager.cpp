#include "LoginManager.h"
#include "ApiManager.h"

LoginManager::LoginManager(ApiManager* apiManager, QObject* parent)
    : QObject(parent)
    , m_isLoggedIn(false)
    , m_currentUserName("")
    , currentUserId(-1)
    , m_apiManager(apiManager)
{
    // 连接ApiManager的登录响应信号
    connect(m_apiManager, &ApiManager::loginResponse,
            this, &LoginManager::onLoginResponse);
}

bool LoginManager::isLoggedIn() const
{
    return m_isLoggedIn;
}

void LoginManager::setIsLoggedIn(bool loggedIn)
{
    if (m_isLoggedIn != loggedIn) {
        m_isLoggedIn = loggedIn;
        emit isLoggedInChanged();
    }
}

QString LoginManager::currentUserName() const
{
    return m_currentUserName;
}

void LoginManager::setCurrentUserName(const QString& currentUserName)
{
    if (m_currentUserName != currentUserName) {
        m_currentUserName = currentUserName;
        emit currentUserNameChanged();
    }
}

bool LoginManager::login(const QString& username, const QString& password)
{
    qDebug() << "[LoginManager] Starting login for user:" << username;
    
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
    qDebug() << "[LoginManager] Login response - Success:" << success << "Message:" << message;
    
    if (success) {
        QString respUser = data.value("userName").toString();
        currentUserId = data.value("id").toString();
        qDebug() << "[LoginManager] Login successful - Username:" << respUser << "UserID:" << currentUserId;
        
        setCurrentUserName(respUser);
        setIsLoggedIn(true);
    } else {
        setIsLoggedIn(false);
    }
    
    emit loginResult(success, message);
}

void LoginManager::logout()
{
    qDebug() << "[LoginManager] User logout";
    setIsLoggedIn(false);
    setCurrentUserName("");
    currentUserId = -1;
    emit logoutSuccess();
}

QString LoginManager::getUserId()
{
    return currentUserId;
}
