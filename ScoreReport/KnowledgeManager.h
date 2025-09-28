#pragma once
#include "CommonFunc.h"
#include <QJsonArray>
#include <QVariantList>

class KnowledgeManager : public QObject
{
    Q_OBJECT
    SINGLETON_CLASS(KnowledgeManager)
    
    /// @brief 知识库列表数据，每个元素包含id, name, description等字段
    QUICK_PROPERTY(QVariantList, knowledgeList)
    
    /// @brief 是否正在加载列表数据
    QUICK_PROPERTY(bool, isLoading)
    
    /// @brief 当前展开的知识库详情数据（包含文件列表）
    QUICK_PROPERTY(QVariantMap, currentKnowledgeDetail)
    
    /// @brief 是否正在加载详情数据
    QUICK_PROPERTY(bool, isLoadingDetail)
    
    /// @brief 当前展开显示详情的知识库ID，空字符串表示没有展开的
    QUICK_PROPERTY(QString, expandedKnowledgeId)

public:
    /**
     * @brief 更新知识库列表
     * 
     * 调用API接口获取知识库列表数据，更新knowledgeList属性
     */
    Q_INVOKABLE void updateKnowledgeList();
    
    /**
     * @brief 获取知识库详情（包含文件列表）
     * @param knowledgeId 知识库ID
     * 
     * 调用API接口获取指定知识库的详细信息和文件列表
     */
    Q_INVOKABLE void getKnowledgeDetail(const QString& knowledgeId);
    
    /**
     * @brief 切换知识库的展开/收起状态
     * @param knowledgeId 知识库ID
     * 
     * 如果当前已展开该知识库则收起，否则展开并获取详情
     */
    Q_INVOKABLE void toggleKnowledgeExpansion(const QString& knowledgeId);
    
    /**
     * @brief 上传文件到当前展开的知识库
     * @param filePath 要上传的文件路径
     * 
     * 将文件上传到当前展开的知识库中
     */
    Q_INVOKABLE void uploadFileToCurrentKnowledge(const QString& filePath);
    
    /**
     * @brief 批量上传文件到当前展开的知识库
     * @param filePaths 要上传的文件路径列表
     * 
     * 将多个文件批量上传到当前展开的知识库中
     */
    Q_INVOKABLE void uploadMultipleFilesToCurrentKnowledge(const QStringList& filePaths);
    
    /**
     * @brief 删除指定的知识库文件
     * @param fileId 要删除的文件ID
     * 
     * 从当前展开的知识库中删除指定文件
     */
    Q_INVOKABLE void deleteKnowledgeFile(const QString& fileId);
    
    /**
     * @brief 创建新的知识库
     * @param name 知识库名称
     * @param description 知识库描述
     * 
     * 创建一个新的知识库
     */
    Q_INVOKABLE void createKnowledgeBase(const QString& name, const QString& description);
    
    /**
     * @brief 删除指定的知识库
     * @param knowledgeId 要删除的知识库ID
     * 
     * 删除指定的知识库
     */
    Q_INVOKABLE void deleteKnowledgeBase(const QString& knowledgeId);
    
    /**
     * @brief 重置所有状态
     * 
     * 清空展开的知识库ID和详情数据，用于页面重置或退出
     */
    Q_INVOKABLE void resetAllStates();
    
    /**
     * @brief 编辑知识库
     * @param knowledgeId 知识库ID
     * @param name 新的知识库名称
     * @param description 新的知识库描述
     * 
     * 更新指定知识库的名称和描述
     */
    Q_INVOKABLE void editKnowledgeBase(const QString& knowledgeId, const QString& name, const QString& description);

signals:
    /**
     * @brief 知识库列表更新完成信号
     * @param success 是否成功获取数据
     * @param message 结果消息
     */
    void knowledgeListUpdated(bool success, const QString& message);
    
    /**
     * @brief 知识库详情获取完成信号
     * @param success 是否成功获取数据
     * @param message 结果消息
     * @param knowledgeId 知识库ID
     */
    void knowledgeDetailUpdated(bool success, const QString& message, const QString& knowledgeId);
    
    /**
     * @brief 文件上传完成信号
     * @param success 是否上传成功
     * @param message 结果消息
     */
    void fileUploadCompleted(bool success, const QString& message);
    
    /**
     * @brief 批量上传完成信号
     * @param successCount 成功上传的文件数量
     * @param totalCount 总文件数量
     * @param message 结果消息
     */
    void batchUploadCompleted(int successCount, int totalCount, const QString& message);
    
    /**
     * @brief 文件删除完成信号
     * @param success 是否删除成功
     * @param message 结果消息
     */
    void fileDeleteCompleted(bool success, const QString& message);
    
    /**
     * @brief 知识库创建完成信号
     * @param success 是否创建成功
     * @param message 结果消息
     */
    void knowledgeBaseCreateCompleted(bool success, const QString& message);
    
    /**
     * @brief 知识库删除完成信号
     * @param success 是否删除成功
     * @param message 结果消息
     */
    void knowledgeBaseDeleteCompleted(bool success, const QString& message);
    
    /**
     * @brief 知识库编辑完成信号
     * @param success 是否编辑成功
     * @param message 结果消息
     */
    void knowledgeBaseEditCompleted(bool success, const QString& message);

private:
    // 批量上传状态跟踪
    int m_totalUploadCount = 0;      // 总上传文件数量
    int m_successUploadCount = 0;    // 成功上传文件数量
    int m_completedUploadCount = 0;  // 完成上传文件数量（成功+失败）

private slots:
    /**
     * @brief 处理知识库列表响应
     * @param success 请求是否成功
     * @param message 响应消息
     * @param data 响应数据
     */
    void onKnowledgeBaseListResponse(bool success, const QString& message, const QJsonObject& data);
    
    /**
     * @brief 处理知识库详情响应
     * @param success 请求是否成功
     * @param message 响应消息
     * @param data 响应数据
     */
    void onKnowledgeBaseDetailResponse(bool success, const QString& message, const QJsonObject& data);
    
    /**
     * @brief 处理文件上传响应
     * @param success 请求是否成功
     * @param message 响应消息
     * @param data 响应数据
     */
    void onFileUploadResponse(bool success, const QString& message, const QJsonObject& data);
    
    /**
     * @brief 处理文件删除响应
     * @param success 请求是否成功
     * @param message 响应消息
     * @param data 响应数据
     */
    void onFileDeleteResponse(bool success, const QString& message, const QJsonObject& data);
    
    /**
     * @brief 处理知识库创建响应
     * @param success 请求是否成功
     * @param message 响应消息
     * @param data 响应数据
     */
    void onCreateKnowledgeBaseResponse(bool success, const QString& message, const QJsonObject& data);
    
    /**
     * @brief 处理知识库删除响应
     * @param success 请求是否成功
     * @param message 响应消息
     * @param data 响应数据
     */
    void onDeleteKnowledgeBaseResponse(bool success, const QString& message, const QJsonObject& data);
    
    /**
     * @brief 处理知识库更新响应
     * @param success 请求是否成功
     * @param message 响应消息
     * @param data 响应数据
     */
    void onUpdateKnowledgeBaseResponse(bool success, const QString& message, const QJsonObject& data);
};

