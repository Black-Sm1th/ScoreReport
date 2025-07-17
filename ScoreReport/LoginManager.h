#ifndef LOGINMANAGER_H
#define LOGINMANAGER_H

#include <QObject>
#include <QString>
#include <QDebug>
class LoginManager : public QObject
{
    Q_OBJECT
        Q_PROPERTY(bool isLoggedIn READ isLoggedIn WRITE setIsLoggedIn NOTIFY isLoggedInChanged)
        Q_PROPERTY(QString username READ username WRITE setUsername NOTIFY usernameChanged)

public:
    explicit LoginManager(QObject* parent = nullptr);

    bool isLoggedIn() const;
    void setIsLoggedIn(bool loggedIn);

    QString username() const;
    void setUsername(const QString& username);

public slots:
    Q_INVOKABLE bool login(const QString& username, const QString& password);
    Q_INVOKABLE void logout();

signals:
    void isLoggedInChanged();
    void usernameChanged();
    void loginResult(bool success, const QString& message);

private:
    bool m_isLoggedIn;
    QString m_username;
};

#endif // LOGINMANAGER_H 