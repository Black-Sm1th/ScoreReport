#ifndef LOGINMANAGER_H
#define LOGINMANAGER_H

#include <QObject>
#include <QString>
#include <QDebug>
#include <QJsonObject>

class ApiManager;

class LoginManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(bool isLoggedIn READ isLoggedIn WRITE setIsLoggedIn NOTIFY isLoggedInChanged)
    Q_PROPERTY(QString currentUserName READ currentUserName WRITE setCurrentUserName NOTIFY currentUserNameChanged)

public:
    explicit LoginManager(ApiManager* apiManager, QObject* parent = nullptr);

    bool isLoggedIn() const;
    void setIsLoggedIn(bool loggedIn);

    QString currentUserName() const;
    void setCurrentUserName(const QString& username);

public slots:
    Q_INVOKABLE bool login(const QString& username, const QString& password);
    Q_INVOKABLE void logout();

    QString getUserId();

signals:
    void isLoggedInChanged();
    void currentUserNameChanged();
    void loginResult(bool success, const QString& message);
    void logoutSuccess();

private slots:
    void onLoginResponse(bool success, const QString& message, const QJsonObject& data);

private:
    bool m_isLoggedIn;
    QString m_currentUserName;
    QString currentUserId;
    ApiManager* m_apiManager;
};

#endif // LOGINMANAGER_H 