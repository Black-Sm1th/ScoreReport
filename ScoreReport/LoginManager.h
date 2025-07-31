#ifndef LOGINMANAGER_H
#define LOGINMANAGER_H

#include <QObject>
#include <QString>
#include <QDebug>
#include <QJsonObject>
#include <QSettings>
#include <QVariantList>
#include <QVariantMap>
#include "CommonFunc.h"
#include "GlobalTextMonitor.h"
class ApiManager;

class LoginManager : public QObject
{
    Q_OBJECT
    QUICK_PROPERTY(bool, isLoggedIn)
    QUICK_PROPERTY(QString, currentUserId)
    QUICK_PROPERTY(QString, currentUserName)
    QUICK_PROPERTY(QString, currentUserAvatar)
    QUICK_PROPERTY(QString, savedUsername)
    QUICK_PROPERTY(QString, savedPassword)
    QUICK_PROPERTY(bool, rememberPassword)
    QUICK_PROPERTY(QVariantList, userList)
    QUICK_PROPERTY(bool, isChangingUser)
    QUICK_PROPERTY(bool, isAdding)
    QUICK_PROPERTY(bool, isRegistering)
    SINGLETON_CLASS(LoginManager)

public slots:
    Q_INVOKABLE bool login(const QString& username, const QString& password);
    Q_INVOKABLE void logout();
    Q_INVOKABLE void saveCredentials(const QString& username, const QString& password, bool remember);
    Q_INVOKABLE void loadSavedCredentials();
    Q_INVOKABLE void addUserToList(const QString& username, const QString& password, const QString& userId, const QString& avatar);
    Q_INVOKABLE void removeUserFromList(const QString& userId);
    Q_INVOKABLE bool registAccount(const QString& userAccount, const QString& userPassword, const QString& checkPassword);
signals:
    void loginResult(bool success, const QString& message);
    void logoutSuccess();
    void registResult(bool success, const QString& message);

private slots:
    void onRegistResponse(bool success, const QString& message, const QJsonObject& data);
    void onLoginResponse(bool success, const QString& message, const QJsonObject& data);
    void onTextSelected(const QString& text);
private:
    void loadUserList();
    void saveUserList();
    QVariantMap findUserInList(const QString& userId);
    GlobalTextMonitor* m_selector;
    ApiManager* m_apiManager;
    QSettings* m_settings;
};

#endif // LOGINMANAGER_H 