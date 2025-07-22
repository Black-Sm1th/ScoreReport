#include "ApiManager.h"

/**
 * @brief 构造函数
 * @param parent 父对象指针
 * 
 * 初始化网络管理器并设置默认网络环境为公网。
 * 连接网络管理器的finished信号到响应处理槽函数。
 */
ApiManager::ApiManager(QObject *parent)
    : QObject(parent)
    , m_networkManager(new QNetworkAccessManager(this))
{
    setusePublicNetwork(true);  // 默认使用公网
    connect(m_networkManager, &QNetworkAccessManager::finished,
            this, &ApiManager::onNetworkReply);
}

/**
 * @brief 获取当前使用的基础URL
 * @return QString 返回内网或公网的API基础地址
 * 
 * 根据usePublicNetwork属性的值决定使用哪个网络环境。
 * true: 使用公网地址 (111.6.178.34:9205)
 * false: 使用内网地址 (192.168.1.2:9898)
 */
QString ApiManager::getBaseUrl() const
{
    return getusePublicNetwork() ? PUBLIC_BASE_URL : INTERNAL_BASE_URL;
}

/**
 * @brief 创建标准化的网络请求对象
 * @param endpoint API端点路径（如 "/admin/user/login"）
 * @return QNetworkRequest 配置好的请求对象
 * 
 * 设置统一的请求头信息：
 * - Content-Type: application/json
 * - User-Agent: ScoreReport/1.0
 * - 完整的请求URL = baseUrl + endpoint
 */
QNetworkRequest ApiManager::createRequest(const QString& endpoint) const
{
    QUrl url(getBaseUrl() + endpoint);
    QNetworkRequest request(url);
    request.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");
    request.setRawHeader("User-Agent", "ScoreReport/1.0");
    
    qDebug() << "[ApiManager] Creating request to:" << url.toString();
    return request;
}

/**
 * @brief 发送POST请求的通用方法
 * @param endpoint API端点路径
 * @param data 要发送的JSON数据
 * @param requestType 请求类型标识，用于在响应时区分不同的请求
 * 
 * 将JSON数据序列化为字节数组并发送POST请求。
 * requestType会被添加到请求头中，便于在onNetworkReply中识别响应类型。
 */
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

/**
 * @brief 发送GET请求的通用方法
 * @param endpoint API端点路径
 * @param requestType 请求类型标识
 * 
 * 发送GET请求，主要用于查询操作。
 */
void ApiManager::makeGetRequest(const QString& endpoint, const QString& requestType)
{
    QNetworkRequest request = createRequest(endpoint);
    
    if (!requestType.isEmpty()) {
        request.setRawHeader("X-Request-Type", requestType.toUtf8());
    }
    
    m_networkManager->get(request);
}

/**
 * @brief 用户登录接口实现
 * @param username 用户账号
 * @param password 用户密码
 * 
 * 构造登录请求数据并发送到服务器的 /admin/user/login 端点。
 * 请求类型标记为 "login"，结果会通过 loginResponse 信号返回。
 */
void ApiManager::loginUser(const QString& username, const QString& password)
{
    QJsonObject loginData;
    loginData["userAccount"] = username;
    loginData["userPassword"] = password;
    
    makePostRequest("/admin/user/login", loginData, "login");
}

/**
 * @brief TNM AI质量评分接口实现
 * @param userId 当前用户ID
 * @param content 需要评分的TNM内容
 * 
 * 发送TNM内容到AI服务进行质量评分。
 * 请求类型标记为 "tnm-ai-score"，结果会通过 tnmAiQualityScoreResponse 信号返回。
 */
void ApiManager::getTnmAiQualityScore(const QString& userId, const QString& content)
{
    QJsonObject requestData;
    requestData["userId"] = userId;
    requestData["type"] = "TNM";
    requestData["content"] = content;
    
    makePostRequest("/admin/Ai/get/aiQualityScore", requestData, "tnm-ai-score");
}

/**
 * @brief 网络请求响应的统一处理函数
 * @param reply 网络回复对象
 * 
 * 这是所有网络请求的统一响应处理入口，主要功能：
 * 1. 从请求头中获取请求类型标识
 * 2. 检查网络错误
 * 3. 解析JSON响应数据
 * 4. 根据请求类型分发到对应的信号
 * 5. 清理回复对象
 * 
 * API响应格式：
 * {
 *   "code": 0,        // 0表示成功，非0表示失败
 *   "message": "",    // 消息描述
 *   "data": {}        // 具体数据
 * }
 */
void ApiManager::onNetworkReply(QNetworkReply* reply)
{
    QString requestType = QString::fromUtf8(reply->request().rawHeader("X-Request-Type"));
    QUrl replyUrl = reply->url();
    
    qDebug() << "[ApiManager] Reply received from:" << replyUrl.toString() 
             << "Type:" << requestType;
    
    if (reply->error() == QNetworkReply::NoError) {
        // 网络请求成功，解析响应数据
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
            bool success = (code == 0);  // 服务器约定：code为0表示成功
 
            // 根据请求类型分发响应到对应的信号
            if (requestType == "login") {
                emit loginResponse(success, message, data);
            } else if (requestType == "test-connection") {
                emit connectionTestResult(success, message);
            } else if (requestType == "tnm-ai-score") {
                emit tnmAiQualityScoreResponse(success, message, data);
            }
        }
    } else {
        // 网络请求失败，处理错误
        QString errorString = reply->errorString();
        qWarning() << "[ApiManager] Network error:" << errorString;
        
        // 根据请求类型发送错误响应
        if (requestType == "login") {
            emit loginResponse(false, errorString, QJsonObject());
        } else if (requestType == "test-connection") {
            emit connectionTestResult(false, errorString);
        } else if (requestType == "tnm-ai-score") {
            emit tnmAiQualityScoreResponse(false, errorString, QJsonObject());
        } else {
            emit networkError(errorString);
        }
    }
    
    // 清理网络回复对象，防止内存泄漏
    reply->deleteLater();
}
