#include "LoginManager.h"

LoginManager::LoginManager(QObject* parent)
    : QObject(parent)
    , m_isLoggedIn(true)  // 默认已登录
    , m_username("测试用户")
{
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

QString LoginManager::username() const
{
    return m_username;
}

void LoginManager::setUsername(const QString& username)
{
    if (m_username != username) {
        m_username = username;
        emit usernameChanged();
    }
}

bool LoginManager::login(const QString& username, const QString& password)
{
    // 简单的登录验证逻辑
    if (username.length() >= 3 && password.length() >= 3) {
        setUsername(username);
        setIsLoggedIn(true);
        emit loginResult(true, "登录成功");
        return true;
    }
    else {
        emit loginResult(false, "用户名和密码至少需要3个字符");
        return false;
    }
}

void LoginManager::logout()
{
    setIsLoggedIn(false);
    setUsername("");
}