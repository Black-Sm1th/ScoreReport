#include "KnowledgeManager.h"
#include "ApiManager.h"
#include "LoginManager.h"
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
    connect(GET_SINGLETON(ApiManager), &ApiManager::createKnowledgeBaseResponse,
        this, &KnowledgeManager::onCreateKnowledgeBaseResponse);
    connect(GET_SINGLETON(ApiManager), &ApiManager::deleteKnowledgeBaseResponse,
        this, &KnowledgeManager::onDeleteKnowledgeBaseResponse);
    connect(GET_SINGLETON(ApiManager), &ApiManager::updateKnowledgeBaseResponse,
        this, &KnowledgeManager::onUpdateKnowledgeBaseResponse);
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
    }
    else {
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
                fileItem["fileSize"] = file["fileSize"].toString().toLong();
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

    // 获取当前用户ID
    auto* loginManager = GET_SINGLETON(LoginManager);
    QString userId = loginManager->getcurrentUserId();

    if (userId.isEmpty() || userId == "-1") {
        qWarning() << "[KnowledgeManager] User not logged in or invalid user ID";
        emit fileUploadCompleted(false, "请先登录");
        return;
    }

    // 调用ApiManager上传文件
    GET_SINGLETON(ApiManager)->uploadFileToKnowledgeBase(filePath, currentKnowledgeId, userId);

    qDebug() << "[KnowledgeManager] Uploading file:" << filePath
        << "to knowledge base:" << currentKnowledgeId;
}

/**
 * @brief 批量上传文件到当前展开的知识库
 * @param filePaths 要上传的文件路径列表
 *
 * 将多个文件逐个上传到当前展开的知识库中，通过计数器跟踪上传进度。
 */
void KnowledgeManager::uploadMultipleFilesToCurrentKnowledge(const QStringList& filePaths)
{
    if (filePaths.isEmpty()) {
        qWarning() << "[KnowledgeManager] No files to upload";
        emit batchUploadCompleted(0, 0, "没有选择文件");
        return;
    }

    QString currentKnowledgeId = getexpandedKnowledgeId();
    if (currentKnowledgeId.isEmpty()) {
        qWarning() << "[KnowledgeManager] No knowledge base is currently expanded for file upload";
        emit batchUploadCompleted(0, filePaths.size(), "请先选择一个知识库");
        return;
    }

    // 获取当前用户ID
    auto* loginManager = GET_SINGLETON(LoginManager);
    QString userId = loginManager->getcurrentUserId();

    if (userId.isEmpty() || userId == "-1") {
        qWarning() << "[KnowledgeManager] User not logged in or invalid user ID";
        emit batchUploadCompleted(0, filePaths.size(), "请先登录");
        return;
    }

    // 初始化批量上传状态
    m_totalUploadCount = filePaths.size();
    m_successUploadCount = 0;
    m_completedUploadCount = 0;

    qDebug() << "[KnowledgeManager] Starting batch upload of" << m_totalUploadCount << "files to knowledge base:" << currentKnowledgeId;

    // 逐个上传文件
    for (const QString& filePath : filePaths) {
        GET_SINGLETON(ApiManager)->uploadFileToKnowledgeBase(filePath, currentKnowledgeId, userId);
    }
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
 * 如果在批量上传模式下，会更新计数器并在所有文件完成时发送批量上传信号。
 */
void KnowledgeManager::onFileUploadResponse(bool success, const QString& message, const QJsonObject& data)
{
    // 检查是否处于批量上传模式
    if (m_totalUploadCount > 0) {
        // 批量上传模式
        m_completedUploadCount++;
        if (success) {
            m_successUploadCount++;
        }

        qDebug() << "[KnowledgeManager] Batch upload progress:" << m_completedUploadCount << "/" << m_totalUploadCount
            << "Success count:" << m_successUploadCount;

        // 检查是否所有文件都已上传完成
        if (m_completedUploadCount >= m_totalUploadCount) {
            // 批量上传完成，刷新知识库详情
            QString currentKnowledgeId = getexpandedKnowledgeId();
            if (!currentKnowledgeId.isEmpty()) {
                getKnowledgeDetail(currentKnowledgeId);
            }

            // 发送批量上传完成信号
            QString batchMessage = QString("完成批量上传：成功 %1/%2 个文件")
                .arg(m_successUploadCount).arg(m_totalUploadCount);
            emit batchUploadCompleted(m_successUploadCount, m_totalUploadCount, batchMessage);

            // 重置批量上传状态
            m_totalUploadCount = 0;
            m_successUploadCount = 0;
            m_completedUploadCount = 0;

            qDebug() << "[KnowledgeManager] Batch upload completed:" << batchMessage;
        }
    }
    else {
        // 单文件上传模式
        if (success) {
            // 上传成功后，自动刷新当前知识库详情
            QString currentKnowledgeId = getexpandedKnowledgeId();
            if (!currentKnowledgeId.isEmpty()) {
                getKnowledgeDetail(currentKnowledgeId);
            }

            emit fileUploadCompleted(true, "文件上传成功");
            qDebug() << "[KnowledgeManager] File upload successful";
        }
        else {
            qWarning() << "[KnowledgeManager] File upload failed:" << message;
            emit fileUploadCompleted(false, message);
        }
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
    }
    else {
        qWarning() << "[KnowledgeManager] File delete failed:" << message;
        emit fileDeleteCompleted(false, message);
    }
}

/**
 * @brief 创建新的知识库
 * @param name 知识库名称
 * @param description 知识库描述
 *
 * 调用ApiManager的createKnowledgeBase接口创建新的知识库。
 * 创建完成后自动刷新知识库列表。
 */
void KnowledgeManager::createKnowledgeBase(const QString& name, const QString& description)
{
    if (name.isEmpty()) {
        qWarning() << "[KnowledgeManager] Knowledge base name cannot be empty";
        emit knowledgeBaseCreateCompleted(false, "知识库名称不能为空");
        return;
    }

    // 调用ApiManager创建知识库
    GET_SINGLETON(ApiManager)->createKnowledgeBase(name, description);

    qDebug() << "[KnowledgeManager] Creating knowledge base:" << name;
}

/**
 * @brief 删除指定的知识库
 * @param knowledgeId 要删除的知识库ID
 *
 * 调用ApiManager的deleteKnowledgeBase接口删除指定的知识库。
 * 删除完成后自动刷新知识库列表。
 */
void KnowledgeManager::deleteKnowledgeBase(const QString& knowledgeId)
{
    if (knowledgeId.isEmpty()) {
        qWarning() << "[KnowledgeManager] Knowledge base ID cannot be empty";
        emit knowledgeBaseDeleteCompleted(false, "知识库ID不能为空");
        return;
    }

    // 调用ApiManager删除知识库
    GET_SINGLETON(ApiManager)->deleteKnowledgeBase(knowledgeId);
}

/**
 * @brief 处理知识库创建响应
 * @param success 请求是否成功
 * @param message 响应消息
 * @param data 响应数据
 *
 * 处理知识库创建完成后的响应，成功时自动刷新知识库列表。
 */
void KnowledgeManager::onCreateKnowledgeBaseResponse(bool success, const QString& message, const QJsonObject& data)
{
    if (success) {
        // 创建成功后，自动刷新知识库列表
        updateKnowledgeList();

        emit knowledgeBaseCreateCompleted(true, "知识库创建成功");
        qDebug() << "[KnowledgeManager] Knowledge base created successfully";
    }
    else {
        qWarning() << "[KnowledgeManager] Knowledge base creation failed:" << message;
        emit knowledgeBaseCreateCompleted(false, message);
    }
}

/**
 * @brief 处理知识库删除响应
 * @param success 请求是否成功
 * @param message 响应消息
 * @param data 响应数据
 *
 * 处理知识库删除完成后的响应，成功时自动刷新知识库列表。
 */
void KnowledgeManager::onDeleteKnowledgeBaseResponse(bool success, const QString& message, const QJsonObject& data)
{
    if (success) {
        // 删除成功后，清空展开状态并刷新知识库列表
        setexpandedKnowledgeId(QString());
        setcurrentKnowledgeDetail(QVariantMap());
        updateKnowledgeList();

        emit knowledgeBaseDeleteCompleted(true, "知识库删除成功");
        qDebug() << "[KnowledgeManager] Knowledge base deleted successfully";
    }
    else {
        qWarning() << "[KnowledgeManager] Knowledge base deletion failed:" << message;
        emit knowledgeBaseDeleteCompleted(false, message);
    }
}

/**
 * @brief 重置所有状态
 *
 * 清空展开的知识库ID和详情数据，用于页面重置或退出。
 * 这个函数会清空所有的展开状态和详情数据。
 */
void KnowledgeManager::resetAllStates()
{
    // 清空展开的知识库ID
    setexpandedKnowledgeId(QString());

    // 清空当前知识库详情
    setcurrentKnowledgeDetail(QVariantMap());

    qDebug() << "[KnowledgeManager] All states have been reset";
}

/**
 * @brief 编辑知识库
 * @param knowledgeId 知识库ID
 * @param name 新的知识库名称
 * @param description 新的知识库描述
 *
 * 调用ApiManager的updateKnowledgeBase接口更新指定的知识库。
 * 更新完成后自动刷新知识库列表。
 */
void KnowledgeManager::editKnowledgeBase(const QString& knowledgeId, const QString& name, const QString& description)
{
    if (knowledgeId.isEmpty()) {
        qWarning() << "[KnowledgeManager] Knowledge base ID cannot be empty for editing";
        emit knowledgeBaseEditCompleted(false, "知识库ID不能为空");
        return;
    }

    if (name.isEmpty()) {
        qWarning() << "[KnowledgeManager] Knowledge base name cannot be empty";
        emit knowledgeBaseEditCompleted(false, "知识库名称不能为空");
        return;
    }

    // 调用ApiManager更新知识库
    GET_SINGLETON(ApiManager)->updateKnowledgeBase(knowledgeId, name, description);

    qDebug() << "[KnowledgeManager] Editing knowledge base:" << knowledgeId << "with name:" << name;
}

/**
 * @brief 处理知识库更新响应
 * @param success 请求是否成功
 * @param message 响应消息
 * @param data 响应数据
 *
 * 处理知识库编辑完成后的响应，成功时自动刷新知识库列表。
 */
void KnowledgeManager::onUpdateKnowledgeBaseResponse(bool success, const QString& message, const QJsonObject& data)
{
    if (success) {
        // 更新成功后，自动刷新知识库列表
        updateKnowledgeList();

        emit knowledgeBaseEditCompleted(true, "知识库编辑成功");
        qDebug() << "[KnowledgeManager] Knowledge base updated successfully";
    }
    else {
        qWarning() << "[KnowledgeManager] Knowledge base update failed:" << message;
        emit knowledgeBaseEditCompleted(false, message);
    }
}
