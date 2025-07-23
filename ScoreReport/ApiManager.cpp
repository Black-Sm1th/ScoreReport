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
    
    QNetworkReply* reply = m_networkManager->post(request, body);
    m_activeReplies.insert(reply);  // 跟踪活跃的请求
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
    
    QNetworkReply* reply = m_networkManager->get(request);
    m_activeReplies.insert(reply);  // 跟踪活跃的请求
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
void ApiManager::getTnmAiQualityScore(const QString& chatId, const QString& userId, const QString& content)
{
    QJsonObject requestData;
    requestData["userId"] = userId;
    requestData["chatId"] = chatId;
    requestData["type"] = "TNM";
    requestData["content"] = content;
    
    makePostRequest("/admin/Ai/get/aiQualityScore", requestData, "tnm-ai-score");
}

/**
 * @brief RENAL AI质量评分接口实现
 * @param userId 当前用户ID
 * @param content 需要评分的RENAL内容
 * 
 * 发送RENAL内容到AI服务进行质量评分。
 * 请求类型标记为 "renal-ai-score"，结果会通过 renalAiQualityScoreResponse 信号返回。
 */
void ApiManager::getRenalAiQualityScore(const QString& chatId, const QString& userId, const QString& content)
{
    QJsonObject requestData;
    requestData["userId"] = userId;
    requestData["chatId"] = chatId;
    requestData["type"] = "RENAL";
    requestData["content"] = content;
    
    makePostRequest("/admin/Ai/get/aiQualityScore", requestData, "renal-ai-score");
}

/**
 * @brief 删除聊天接口实现
 * @param chatId 要删除的聊天ID
 * 
 * 发送删除聊天请求到服务器的 /admin/Ai/delete/chat 端点。
 * 请求类型标记为 "delete-chat"，结果会通过 deleteChatResponse 信号返回。
 */
void ApiManager::deleteChatById(const QString& chatId)
{
    QJsonObject requestData;
    requestData["chatId"] = chatId;
    
    makePostRequest("/admin/Ai/delete/chat", requestData, "delete-chat");
}

/**
 * @brief 添加评测记录接口实现
 * @param type 类型
 * @param title 标题
 * @param content 内容
 * @param result 结果
 * @param chatId 会话ID（可选）
 * 
 * 发送添加评测记录请求到服务器的 /quality/add 端点。
 * 请求类型标记为 "add-quality-record"，结果会通过 addQualityRecordResponse 信号返回。
 */
void ApiManager::addQualityRecord(const QString& type, const QString& title, const QString& content, 
                                 const QString& result, const QString& chatId)
{
    QJsonObject requestData;
    requestData["type"] = type;
    requestData["title"] = title;
    requestData["content"] = content;
    requestData["result"] = result;
    
    // chatId为可选参数，只有在不为空时才添加
    if (!chatId.isEmpty()) {
        requestData["chatId"] = chatId;
    }
    
    makePostRequest("/quality/add", requestData, "add-quality-record");
}

/**
 * @brief 获取评测记录分页列表接口实现
 * @param type 类型筛选（可选）
 * @param title 标题筛选（可选）
 * @param content 内容筛选（可选）
 * @param result 结果筛选（可选）
 * @param dateTime 日期筛选（可选）
 * @param current 当前页码，默认1
 * @param pageSize 页面大小，默认10
 * 
 * 发送获取评测记录列表请求到服务器的 /quality/list 端点。
 * 请求类型标记为 "get-quality-list"，结果会通过 getQualityListResponse 信号返回。
 */
void ApiManager::getQualityList(const QString& type, const QString& title, const QString& content,
                               const QString& result, const QString& dateTime, 
                               int current, int pageSize)
{
    QJsonObject requestData;
    
    // 只有非空的可选参数才添加到请求中
    if (!type.isEmpty()) {
        requestData["type"] = type;
    }
    if (!title.isEmpty()) {
        requestData["title"] = title;
    }
    if (!content.isEmpty()) {
        requestData["content"] = content;
    }
    if (!result.isEmpty()) {
        requestData["result"] = result;
    }
    if (!dateTime.isEmpty()) {
        requestData["dateTime"] = dateTime;
    }
    
    requestData["current"] = current;
    requestData["pageSize"] = pageSize;
    
    makePostRequest("/quality/list", requestData, "get-quality-list");
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
    
    // 从活跃请求集合中移除
    m_activeReplies.remove(reply);
    
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
            } else if (requestType == "renal-ai-score") {
                emit renalAiQualityScoreResponse(success, message, data);
            } else if (requestType == "delete-chat") {
                emit deleteChatResponse(success, message, data);
            } else if (requestType == "add-quality-record") {
                emit addQualityRecordResponse(success, message, data);
            } else if (requestType == "get-quality-list") {
                emit getQualityListResponse(success, message, data);
            }
        }
    } else {
        // 网络请求失败，处理错误
        QString errorString = reply->errorString();
        qWarning() << "[ApiManager] Network error:" << errorString;
        
        // 检查是否是手动终止的请求
        if (reply->error() == QNetworkReply::OperationCanceledError) {
            qDebug() << "[ApiManager] Request was manually aborted:" << requestType;
            // 被终止的请求不发送错误信号，直接清理即可
        } else {
            // 根据请求类型发送错误响应
            if (requestType == "login") {
                emit loginResponse(false, errorString, QJsonObject());
            } else if (requestType == "test-connection") {
                emit connectionTestResult(false, errorString);
            } else if (requestType == "tnm-ai-score") {
                emit tnmAiQualityScoreResponse(false, errorString, QJsonObject());
            } else if (requestType == "renal-ai-score") {
                emit renalAiQualityScoreResponse(false, errorString, QJsonObject());
            } else if (requestType == "delete-chat") {
                emit deleteChatResponse(false, errorString, QJsonObject());
            } else if (requestType == "add-quality-record") {
                emit addQualityRecordResponse(false, errorString, QJsonObject());
            } else if (requestType == "get-quality-list") {
                emit getQualityListResponse(false, errorString, QJsonObject());
            } else {
                emit networkError(errorString);
            }
        }
    }
    
    // 清理网络回复对象，防止内存泄漏
    reply->deleteLater();
}

/**
 * @brief 终止所有正在进行的网络请求
 * 
 * 遍历所有活跃的请求并调用abort()方法终止它们。
 * 被终止的请求会触发OperationCanceledError，但不会发送错误信号。
 * 这个方法通常在用户取消操作或应用程序退出时调用。
 */
void ApiManager::abortAllRequests()
{
    qDebug() << "[ApiManager] Aborting all active requests, count:" << m_activeReplies.size();
    
    // 复制集合，因为abort()会触发finished信号，导致集合在遍历时被修改
    QSet<QNetworkReply*> repliesToAbort = m_activeReplies;
    
    for (QNetworkReply* reply : repliesToAbort) {
        if (reply && reply->isRunning()) {
            qDebug() << "[ApiManager] Aborting request to:" << reply->url().toString();
            reply->abort();
        }
    }
}

/**
 * @brief 终止指定类型的网络请求
 * @param requestType 要终止的请求类型（如 "login", "tnm-ai-score"）
 * 
 * 只终止匹配指定类型的活跃请求，允许对特定操作进行精确控制。
 * 例如：abortRequestsByType("login") 只会终止登录请求，其他请求继续执行。
 */
void ApiManager::abortRequestsByType(const QString& requestType)
{
    qDebug() << "[ApiManager] Aborting requests of type:" << requestType;
    
    // 复制集合避免遍历时修改
    QSet<QNetworkReply*> repliesToCheck = m_activeReplies;
    
    for (QNetworkReply* reply : repliesToCheck) {
        if (reply && reply->isRunning()) {
            QString replyType = QString::fromUtf8(reply->request().rawHeader("X-Request-Type"));
            if (replyType == requestType) {
                qDebug() << "[ApiManager] Aborting request:" << reply->url().toString() 
                         << "Type:" << replyType;
                reply->abort();
            }
        }
    }
}
