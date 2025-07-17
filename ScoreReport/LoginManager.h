#ifndef LOGINMANAGER_H
#define LOGINMANAGER_H

#include <QObject>
#include <QString>
#include <QDebug>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>

class LoginManager : public QObject
{
    Q_OBJECT
        Q_PROPERTY(bool isLoggedIn READ isLoggedIn WRITE setIsLoggedIn NOTIFY isLoggedInChanged)
        Q_PROPERTY(QString currentUserName READ currentUserName WRITE setCurrentUserName NOTIFY currentUserNameChanged)

public:
    explicit LoginManager(QObject* parent = nullptr);

    bool isLoggedIn() const;
    void setIsLoggedIn(bool loggedIn);

    QString currentUserName() const;
    void setCurrentUserName(const QString& username);

public slots:
    Q_INVOKABLE bool login(const QString& username, const QString& password);
    Q_INVOKABLE void logout();

signals:
    void isLoggedInChanged();
    void currentUserNameChanged();
    void loginResult(bool success, const QString& message);
    void logoutSuccess();
private slots:
    void onNetworkReply(QNetworkReply* reply);

private:
    bool m_isLoggedIn;
    QString m_currentUserName;
    QNetworkAccessManager* m_networkMgr;
    bool usePublic = true; // 或者设置成构造参数
};

#endif // LOGINMANAGER_H 