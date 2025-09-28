#include "KnowledgeManager.h"
#include "ApiManager.h"
#include <QJsonArray>
#include <QJsonObject>
#include <QVariantMap>
#include <QDebug>

/**
 * @brief 构造函数
 * @param parent 父对象指针
 * 
 * 初始化KnowledgeManager并连接ApiManager的响应信号
 */
KnowledgeManager::KnowledgeManager(QObject* parent)
	: QObject(parent)
{
    setisLoading(false);
    setknowledgeList(QVariantList());
    setisLoadingDetail(false);
    setcurrentKnowledgeDetail(QVariantMap());
    setexpandedKnowledgeId(QString());
    
    // 连接ApiManager的响应信号
    connect(GET_SINGLETON(ApiManager), &ApiManager::getKnowledgeBaseListResponse,
            this, &KnowledgeManager::onKnowledgeBaseListResponse);
    connect(GET_SINGLETON(ApiManager), &ApiManager::getKnowledgeBaseResponse,
            this, &KnowledgeManager::onKnowledgeBaseDetailResponse);
    connect(GET_SINGLETON(ApiManager), &ApiManager::uploadFileResponse,
            this, &KnowledgeManager::onFileUploadResponse);
    connect(GET_SINGLETON(ApiManager), &ApiManager::deleteKnowledgeBaseFilesResponse,
            this, &KnowledgeManager::onFileDeleteResponse);
}

/**
 * @brief 更新知识库列表
 * 
 * 调用ApiManager的getKnowledgeBaseList接口获取知识库数据。
 * 使用大页面大小(10000)来获取所有知识库数据。
 */
void KnowledgeManager::updateKnowledgeList()
{
    setisLoading(true);
    
    // 调用ApiManager获取知识库列表，使用大页面大小获取所有数据
    GET_SINGLETON(ApiManager)->getKnowledgeBaseList(1, 10000);
}

/**
 * @brief 处理知识库列表响应
 * @param success 请求是否成功
 * @param message 响应消息
 * @param data 响应数据
 * 
 * 解析API响应数据，提取records数组中的知识库信息，
 * 转换为QML可用的QVariantList格式并更新knowledgeList属性。
 */
void KnowledgeManager::onKnowledgeBaseListResponse(bool success, const QString& message, const QJsonObject& data)
{
    setisLoading(false);
    
    if (!success) {
        qWarning() << "[KnowledgeManager] Failed to get knowledge list:" << message;
        emit knowledgeListUpdated(false, message);
        return;
    } 
    QVariantList knowledgeItems;
    
    // 解析响应数据结构: data -> records (数组)
    if (data.contains("records") && data["records"].isArray()) {
        QJsonArray records = data["records"].toArray();
        
        for (const QJsonValue& recordValue : records) {
            if (recordValue.isObject()) {
                QJsonObject record = recordValue.toObject();
                
                // 创建知识库项目映射，包含QML需要的字段
                QVariantMap knowledgeItem;
                qDebug() << record["id"];
                knowledgeItem["id"] = record["id"].toString();  // 改为字符串格式
                knowledgeItem["name"] = record["name"].toString();
                knowledgeItem["description"] = record["description"].toString();
                knowledgeItem["userId"] = record["userId"].toInt();
                knowledgeItem["bucket"] = record["bucket"].toString();
                knowledgeItem["createTime"] = record["createTime"].toString();
                knowledgeItem["updateTime"] = record["updateTime"].toString();
                knowledgeItem["isDelete"] = record["isDelete"].toInt();
                
                knowledgeItems.append(knowledgeItem);
            }
        }
    }
    
    // 更新知识库列表属性
    setknowledgeList(knowledgeItems);
    
    // 发送更新完成信号
    emit knowledgeListUpdated(true, QString("成功获取 %1 个知识库").arg(knowledgeItems.size()));
}

/**
 * @brief 获取知识库详情（包含文件列表）
 * @param knowledgeId 知识库ID
 * 
 * 调用ApiManager的getKnowledgeBase接口获取指定知识库的详细信息和文件列表。
 */
void KnowledgeManager::getKnowledgeDetail(const QString& knowledgeId)
{
    setisLoadingDetail(true);
    
    // 调用ApiManager获取知识库详情
    GET_SINGLETON(ApiManager)->getKnowledgeBase(knowledgeId);
}

/**
 * @brief 切换知识库的展开/收起状态
 * @param knowledgeId 知识库ID
 * 
 * 如果当前已展开该知识库则收起，否则展开并获取详情。
 */
void KnowledgeManager::toggleKnowledgeExpansion(const QString& knowledgeId)
{
    if (getexpandedKnowledgeId() == knowledgeId) {
        // 如果当前已展开该知识库，则收起
        setexpandedKnowledgeId(QString());
        setcurrentKnowledgeDetail(QVariantMap());
    } else {
        // 如果没有展开或展开的是其他知识库，则展开当前知识库
        setexpandedKnowledgeId(knowledgeId);
        getKnowledgeDetail(knowledgeId);
    }
}

/**
 * @brief 处理知识库详情响应
 * @param success 请求是否成功
 * @param message 响应消息
 * @param data 响应数据
 * 
 * 解析API响应数据，提取知识库详情和文件列表信息，
 * 转换为QML可用的QVariantMap格式并更新currentKnowledgeDetail属性。
 */
void KnowledgeManager::onKnowledgeBaseDetailResponse(bool success, const QString& message, const QJsonObject& data)
{
    setisLoadingDetail(false);
    
    if (!success) {
        qWarning() << "[KnowledgeManager] Failed to get knowledge detail:" << message;
        emit knowledgeDetailUpdated(false, message, "-1");
        return;
    }
    
    qDebug() << "[KnowledgeManager] Received knowledge detail response";
    
    // 解析知识库详情数据
    QVariantMap knowledgeDetail;
    knowledgeDetail["id"] = data["id"].toString();  // 改为字符串格式
    knowledgeDetail["name"] = data["name"].toString();
    knowledgeDetail["description"] = data["description"].toString();
    knowledgeDetail["userId"] = data["userId"].toInt();
    knowledgeDetail["bucket"] = data["bucket"].toString();
    knowledgeDetail["createTime"] = data["createTime"].toString();
    knowledgeDetail["updateTime"] = data["updateTime"].toString();
    knowledgeDetail["isDelete"] = data["isDelete"].toInt();
    
    // 解析文件列表
    QVariantList fileList;
    if (data.contains("files") && data["files"].isArray()) {
        QJsonArray files = data["files"].toArray();
        
        for (const QJsonValue& fileValue : files) {
            if (fileValue.isObject()) {
                QJsonObject file = fileValue.toObject();
                
                QVariantMap fileItem;
                fileItem["id"] = file["id"].toString();  // 改为字符串格式
                fileItem["knowledgeBaseId"] = file["knowledgeBaseId"].toString();  // 改为字符串格式
                fileItem["fileName"] = file["fileName"].toString();
                fileItem["fileSize"] = file["fileSize"].toInt();
                fileItem["fileType"] = file["fileType"].toString();
                fileItem["status"] = file["status"].toString();
                fileItem["fileUrl"] = file["fileUrl"].toString();
                fileItem["createTime"] = file["createTime"].toString();
                fileItem["updateTime"] = file["updateTime"].toString();
                fileItem["isDelete"] = file["isDelete"].toInt();
                
                fileList.append(fileItem);
            }
        }
    }
    
    knowledgeDetail["files"] = fileList;
    
    // 更新当前知识库详情
    setcurrentKnowledgeDetail(knowledgeDetail);
    
    QString knowledgeId = data["id"].toString();  // 改为字符串格式
    // 发送更新完成信号
    emit knowledgeDetailUpdated(true, 
                               QString("成功获取知识库详情，包含 %1 个文件").arg(fileList.size()), 
                               knowledgeId);
}

/**
 * @brief 上传文件到当前展开的知识库
 * @param filePath 要上传的文件路径
 * 
 * 将文件上传到当前展开的知识库中，上传完成后自动刷新知识库详情。
 */
void KnowledgeManager::uploadFileToCurrentKnowledge(const QString& filePath)
{
    QString currentKnowledgeId = getexpandedKnowledgeId();
    if (currentKnowledgeId.isEmpty()) {
        qWarning() << "[KnowledgeManager] No knowledge base is currently expanded for file upload";
        emit fileUploadCompleted(false, "请先选择一个知识库");
        return;
    }
    
    // 调用ApiManager上传文件
    GET_SINGLETON(ApiManager)->uploadFileToKnowledgeBase(filePath, currentKnowledgeId);
}

/**
 * @brief 删除指定的知识库文件
 * @param fileId 要删除的文件ID
 * 
 * 从当前展开的知识库中删除指定文件，删除完成后自动刷新知识库详情。
 */
void KnowledgeManager::deleteKnowledgeFile(const QString& fileId)
{
    QString currentKnowledgeId = getexpandedKnowledgeId();
    if (currentKnowledgeId.isEmpty()) {
        qWarning() << "[KnowledgeManager] No knowledge base is currently expanded for file deletion";
        emit fileDeleteCompleted(false, "请先选择一个知识库");
        return;
    }
    // 调用ApiManager删除文件（批量删除接口，传入单个文件ID）
    QList<QString> fileIds;
    fileIds.append(fileId);
    GET_SINGLETON(ApiManager)->deleteKnowledgeBaseFiles(fileIds);
}

/**
 * @brief 处理文件上传响应
 * @param success 请求是否成功
 * @param message 响应消息
 * @param data 响应数据
 * 
 * 处理文件上传完成后的响应，成功时自动刷新当前知识库的详情。
 */
void KnowledgeManager::onFileUploadResponse(bool success, const QString& message, const QJsonObject& data)
{
    if (success) {
        // 上传成功后，自动刷新当前知识库详情
        QString currentKnowledgeId = getexpandedKnowledgeId();
        if (!currentKnowledgeId.isEmpty()) {
            getKnowledgeDetail(currentKnowledgeId);
        }
        
        emit fileUploadCompleted(true, "文件上传成功");
    } else {
        qWarning() << "[KnowledgeManager] File upload failed:" << message;
        emit fileUploadCompleted(false, message);
    }
}

/**
 * @brief 处理文件删除响应
 * @param success 请求是否成功
 * @param message 响应消息
 * @param data 响应数据
 * 
 * 处理文件删除完成后的响应，成功时自动刷新当前知识库的详情。
 */
void KnowledgeManager::onFileDeleteResponse(bool success, const QString& message, const QJsonObject& data)
{
    if (success) {
        // 删除成功后，自动刷新当前知识库详情
        QString currentKnowledgeId = getexpandedKnowledgeId();
        if (!currentKnowledgeId.isEmpty()) {
            getKnowledgeDetail(currentKnowledgeId);
        }
        
        emit fileDeleteCompleted(true, "文件删除成功");
    } else {
        qWarning() << "[KnowledgeManager] File delete failed:" << message;
        emit fileDeleteCompleted(false, message);
    }
}
