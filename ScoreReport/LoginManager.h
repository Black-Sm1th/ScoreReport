#ifndef LOGINMANAGER_H
#define LOGINMANAGER_H

#include <QObject>
#include <QString>
#include <QDebug>
#include <QJsonObject>
#include "CommonFunc.h"

class ApiManager;

class LoginManager : public QObject
{
    Q_OBJECT
    QUICK_PROPERTY(bool, isLoggedIn)
    QUICK_PROPERTY(QString, currentUserName)
        QUICK_PROPERTY(QString, currentUserAvatar)
    SINGLETON_CLASS(LoginManager)

public slots:
    Q_INVOKABLE bool login(const QString& username, const QString& password);
    Q_INVOKABLE void logout();

    QString getUserId();

signals:
    void loginResult(bool success, const QString& message);
    void logoutSuccess();

private slots:
    void onLoginResponse(bool success, const QString& message, const QJsonObject& data);

private:
    QString currentUserId;
    ApiManager* m_apiManager;
};

#endif // LOGINMANAGER_H 