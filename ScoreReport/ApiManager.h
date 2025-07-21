#ifndef APIMANAGER_H
#define APIMANAGER_H

#include <QObject>
#include <QString>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDebug>

class ApiManager : public QObject
{
    Q_OBJECT
        Q_PROPERTY(bool usePublicNetwork READ usePublicNetwork WRITE setUsePublicNetwork NOTIFY usePublicNetworkChanged)

public:
    explicit ApiManager(QObject* parent = nullptr);

    bool usePublicNetwork() const;
    void setUsePublicNetwork(bool usePublic);

    // API方法
    void loginUser(const QString& username, const QString& password);

signals:
    void usePublicNetworkChanged();
    void loginResponse(bool success, const QString& message, const QJsonObject& data);
    void networkError(const QString& error);
    void connectionTestResult(bool success, const QString& message);

private slots:
    void onNetworkReply(QNetworkReply* reply);

private:
    QString getBaseUrl() const;
    QNetworkRequest createRequest(const QString& endpoint) const;
    void makePostRequest(const QString& endpoint, const QJsonObject& data, const QString& requestType = "");
    void makeGetRequest(const QString& endpoint, const QString& requestType = "");

    QNetworkAccessManager* m_networkManager;
    bool m_usePublicNetwork;

    // API地址常量
    static const QString INTERNAL_BASE_URL;
    static const QString PUBLIC_BASE_URL;
};

#endif // APIMANAGER_H