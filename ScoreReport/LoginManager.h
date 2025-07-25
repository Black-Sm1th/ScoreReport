#ifndef LOGINMANAGER_H
#define LOGINMANAGER_H

#include <QObject>
#include <QString>
#include <QDebug>
#include <QJsonObject>
#include <QSettings>
#include "CommonFunc.h"

class ApiManager;

class LoginManager : public QObject
{
    Q_OBJECT
    QUICK_PROPERTY(bool, isLoggedIn)
    QUICK_PROPERTY(QString, currentUserName)
    QUICK_PROPERTY(QString, currentUserAvatar)
    QUICK_PROPERTY(QString, savedUsername)
    QUICK_PROPERTY(QString, savedPassword)
    QUICK_PROPERTY(bool, rememberPassword)
    SINGLETON_CLASS(LoginManager)

public slots:
    Q_INVOKABLE bool login(const QString& username, const QString& password);
    Q_INVOKABLE void logout();
    Q_INVOKABLE void saveCredentials(const QString& username, const QString& password, bool remember);
    Q_INVOKABLE void loadSavedCredentials();
    Q_INVOKABLE void clearSavedCredentials();

    QString getUserId();

signals:
    void loginResult(bool success, const QString& message);
    void logoutSuccess();

private slots:
    void onLoginResponse(bool success, const QString& message, const QJsonObject& data);

private:
    QString currentUserId;
    ApiManager* m_apiManager;
    QSettings* m_settings;
};

#endif // LOGINMANAGER_H 