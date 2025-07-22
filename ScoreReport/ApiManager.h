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
#include "CommonFunc.h"

class ApiManager : public QObject
{
    Q_OBJECT
    QUICK_PROPERTY(bool, usePublicNetwork)
    SINGLETON_CLASS(ApiManager)

public:
    void loginUser(const QString& username, const QString& password);
    void getTnmAiQualityScore(const QString& userId, const QString& content);

signals:
    void loginResponse(bool success, const QString& message, const QJsonObject& data);
    void tnmAiQualityScoreResponse(bool success, const QString& message, const QJsonObject& data);
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

    // API地址常量
    const QString INTERNAL_BASE_URL = "http://192.168.1.2:9898/api";
    const QString PUBLIC_BASE_URL = "http://111.6.178.34:9205/api";
};

#endif // APIMANAGER_H