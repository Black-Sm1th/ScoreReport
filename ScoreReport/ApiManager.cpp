#include "ApiManager.h"

// 定义API地址常量
const QString ApiManager::INTERNAL_BASE_URL = "http://192.168.1.2:9898/api";
const QString ApiManager::PUBLIC_BASE_URL = "http://111.6.178.34:9205/api";

ApiManager::ApiManager(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
    , m_usePublicNetwork(true)  // 默认使用公网
{
    connect(m_networkManager, &QNetworkAccessManager::finished,
            this, &ApiManager::onNetworkReply);
}

bool ApiManager::usePublicNetwork() const
{
    return m_usePublicNetwork;
}

void ApiManager::setUsePublicNetwork(bool usePublic)
{
    if (m_usePublicNetwork != usePublic) {
        m_usePublicNetwork = usePublic;
        emit usePublicNetworkChanged();
        qDebug() << "[ApiManager] Switched to" << (usePublic ? "public" : "internal") << "network";
    }
}

QString ApiManager::getBaseUrl() const
{
    return m_usePublicNetwork ? PUBLIC_BASE_URL : INTERNAL_BASE_URL;
}

QNetworkRequest ApiManager::createRequest(const QString& endpoint) const
{
    QUrl url(getBaseUrl() + endpoint);
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("User-Agent", "ScoreReport/1.0");
    
    qDebug() << "[ApiManager] Creating request to:" << url.toString();
    return request;
}

void ApiManager::makePostRequest(const QString& endpoint, const QJsonObject& data, const QString& requestType)
{
    QNetworkRequest request = createRequest(endpoint);
    
    // 添加请求类型标识，用于在回复中区分不同的请求
    if (!requestType.isEmpty()) {
        request.setRawHeader("X-Request-Type", requestType.toUtf8());
    }
    
    QByteArray body = QJsonDocument(data).toJson();
    qDebug() << "[ApiManager] POST request body:" << body;
    
    m_networkManager->post(request, body);
}

void ApiManager::makeGetRequest(const QString& endpoint, const QString& requestType)
{
    QNetworkRequest request = createRequest(endpoint);
    
    if (!requestType.isEmpty()) {
        request.setRawHeader("X-Request-Type", requestType.toUtf8());
    }
    
    m_networkManager->get(request);
}

void ApiManager::loginUser(const QString& username, const QString& password)
{
    qDebug() << "[ApiManager] Starting login for user:" << username;
    
    QJsonObject loginData;
    loginData["userAccount"] = username;
    loginData["userPassword"] = password;
    
    makePostRequest("/admin/user/login", loginData, "login");
}

void ApiManager::onNetworkReply(QNetworkReply* reply)
{
    QString requestType = QString::fromUtf8(reply->request().rawHeader("X-Request-Type"));
    QUrl replyUrl = reply->url();
    
    qDebug() << "[ApiManager] Reply received from:" << replyUrl.toString() 
             << "Type:" << requestType;
    
    if (reply->error() == QNetworkReply::NoError) {
        QByteArray responseData = reply->readAll();
        qDebug() << "[ApiManager] Response data:" << responseData;
        
        QJsonDocument doc = QJsonDocument::fromJson(responseData);
        if (!doc.isObject()) {
            qWarning() << "[ApiManager] Invalid JSON response";
            emit networkError("Invalid server response");
        } else {
            QJsonObject responseObj = doc.object();
            int code = responseObj.value("code").toInt();
            QString message = responseObj.value("message").toString();
            QJsonObject data = responseObj.value("data").toObject();
            bool success = (code == 0);
            
            qDebug() << "[ApiManager] Response - Code:" << code 
                     << "Success:" << success 
                     << "Message:" << message;
            
            // 根据请求类型分发响应
            if (requestType == "login") {
                emit loginResponse(success, message, data);
            } else if (requestType == "test-connection") {
                emit connectionTestResult(success, message);
            }
        }
    } else {
        QString errorString = reply->errorString();
        qWarning() << "[ApiManager] Network error:" << errorString;
        
        if (requestType == "login") {
            emit loginResponse(false, errorString, QJsonObject());
        } else if (requestType == "test-connection") {
            emit connectionTestResult(false, errorString);
        } else {
            emit networkError(errorString);
        }
    }
    
    reply->deleteLater();
}
