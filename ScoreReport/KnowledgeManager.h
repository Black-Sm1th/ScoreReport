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
     * @brief 删除指定的知识库文件
     * @param fileId 要删除的文件ID
     * 
     * 从当前展开的知识库中删除指定文件
     */
    Q_INVOKABLE void deleteKnowledgeFile(const QString& fileId);

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
     * @brief 文件删除完成信号
     * @param success 是否删除成功
     * @param message 结果消息
     */
    void fileDeleteCompleted(bool success, const QString& message);

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
};

