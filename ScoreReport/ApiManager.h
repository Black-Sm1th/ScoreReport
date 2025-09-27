#ifndef APIMANAGER_H
#define APIMANAGER_H

#include <QObject>
#include <QString>
#include <QNetworkAccessManager>
#include <QNetworkRequest>
#include <QNetworkReply>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>
#include <QSet>
#include <QList>
#include <QHttpMultiPart>
#include <QHttpPart>
#include <QFile>
#include <QFileInfo>
#include <QMimeDatabase>
#include <QMimeType>
#include "CommonFunc.h"

/**
 * @brief API管理器类 - 负责处理所有网络API请求
 * 
 * 这是一个单例类，提供统一的网络请求接口，支持用户登录和TNM AI评分等功能。
 * 支持内网和公网两种网络环境的自动切换。
 * 
 * 主要功能：
 * - 用户登录验证
 * - TNM AI质量评分请求
 * - 网络连接测试
 * - 统一的错误处理和响应分发
 */
class ApiManager : public QObject
{
    Q_OBJECT
    
    /// @brief 是否使用公网，true=公网，false=内网
    QUICK_PROPERTY(bool, usePublicNetwork)
    
    SINGLETON_CLASS(ApiManager)

public:
    /**
     * @brief 用户登录请求
     * @param username 用户账号
     * @param password 用户密码
     * 
     * 发送登录请求到服务器，结果通过 loginResponse 信号返回
     */
    void loginUser(const QString& username, const QString& password);
    
    /**
     * @brief 用户注册请求
     * @param userAccount 用户账号
     * @param userPassword 用户密码
     * @param checkPassword 确认密码
     * 
     * 发送注册请求到服务器，结果通过 registerResponse 信号返回
     */
    void registerUser(const QString& userAccount, const QString& userPassword, const QString& checkPassword);
    
    /**
     * @brief 获取TNM AI质量评分
     * @param userId 用户ID
     * @param content 待评分的内容
     * 
     * 发送TNM内容到AI服务进行质量评分，结果通过 tnmAiQualityScoreResponse 信号返回
     */
    void getTnmAiQualityScore(const QString& chatId, const QString& userId, const QString& content, const QString& language, const QString& diagnoseType = "renal_tumor");
    
    /**
     * @brief 获取RENAL AI质量评分
     * @param userId 用户ID
     * @param content 待评分的内容
     * 
     * 发送RENAL内容到AI服务进行质量评分，结果通过 renalAiQualityScoreResponse 信号返回
     */
    void getRenalAiQualityScore(const QString& chatId, const QString& userId, const QString& content, const QString& language);
    
    /**
     * @brief 流式AI问答接口
     * @param query 问题内容
     * @param userId 用户ID
     * @param chatId 会话ID（可选，首次不传）
     * 
     * 发送流式问答请求到AI服务，结果通过 streamChatResponse 和 streamChatFinished 信号返回
     */
    void streamChat(const QString& query, const QString& userId, const QString& chatId = "");
    
    /**
     * @brief 删除指定的聊天记录
     * @param chatId 要删除的聊天ID
     * 
     * 发送删除聊天请求到服务器，结果通过 deleteChatResponse 信号返回
     */
    void deleteChatById(const QString& chatId);
    
    /**
     * @brief 添加评测记录
     * @param type 类型
     * @param title 标题
     * @param content 内容
     * @param result 结果
     * @param chatId 会话ID（可选）
     * 
     * 发送添加评测记录请求到服务器，结果通过 addQualityRecordResponse 信号返回
     */
    void addQualityRecord(const QString& type, const QString& title, const QString& content, 
                         const QString& result, const QString& chatId = "");
    
    /**
     * @brief 获取评测记录分页列表
     * @param type 类型筛选（可选）
     * @param title 标题筛选（可选）
     * @param content 内容筛选（可选）
     * @param result 结果筛选（可选）
     * @param dateTime 日期筛选（可选）
     * @param current 当前页码，默认1
     * @param pageSize 页面大小，默认10
     * 
     * 发送获取评测记录列表请求到服务器，结果通过 getQualityListResponse 信号返回
     */
    void getQualityList(const QString& type = "", const QString& title = "", const QString& content = "",
                       const QString& result = "", const QString& dateTime = "", 
                       int current = 1, int pageSize = 10);
    
    /**
     * @brief 获取癌症肿瘤分类信息
     * @param content 待分析的内容
     * @param language 语言设置（zh或en）
     * 
     * 发送癌症肿瘤分类请求到AI服务，结果通过 cancerDiagnoseTypeResponse 信号返回
     */
    void getCancerDiagnoseType(const QString& content, const QString& language);
    
    /**
     * @brief 保存报告模板
     * @param templateContent 模板内容（JSON字符串）
     * @param templateName 模板名称
     * @param templateId 模板ID（可选，用于更新现有模板）
     * 
     * 发送保存模板请求到服务器，结果通过 saveReportTemplateResponse 信号返回
     */
    void saveReportTemplate(const QString& templateContent, const QString& templateName, const QString& templateId = "");
    
    /**
     * @brief 删除报告模板
     * @param templateId 要删除的模板ID
     * 
     * 发送删除模板请求到服务器，结果通过 deleteReportTemplateResponse 信号返回
     */
    void deleteReportTemplate(const QString& templateId);
    
    /**
     * @brief 生成质控报告
     * @param query 查询文本
     * @param templateContent 模板内容（JSON字符串）
     * @param language 语言设置（zh或en）
     * 
     * 发送生成质控报告请求到服务器，结果通过 generateQualityReportResponse 信号返回
     */
    void generateQualityReport(const QString& query, const QString& templateContent, const QString& language);
    
    /**
     * @brief 获取用户创建的模板列表
     * 
     * 发送获取模板列表请求到服务器，结果通过 getReportTemplateListResponse 信号返回
     */
    void getReportTemplateList();
    
    /**
     * @brief 上传文件到知识库
     * @param filePath 要上传的文件路径
     * @param knowledgeBaseId 知识库ID
     * 
     * 发送文件上传请求到服务器，结果通过 uploadFileResponse 信号返回
     */
    void uploadFileToKnowledgeBase(const QString& filePath, int knowledgeBaseId);
    
    /**
     * @brief 创建知识库
     * @param name 知识库名称（可选）
     * @param description 知识库描述（可选）
     * 
     * 发送创建知识库请求到服务器，结果通过 createKnowledgeBaseResponse 信号返回
     */
    void createKnowledgeBase(const QString& name = "", const QString& description = "");
    
    /**
     * @brief 删除知识库
     * @param id 知识库ID
     * 
     * 发送删除知识库请求到服务器，结果通过 deleteKnowledgeBaseResponse 信号返回
     */
    void deleteKnowledgeBase(int id);
    
    /**
     * @brief 更新知识库
     * @param id 知识库ID（可选）
     * @param name 知识库名称（可选）
     * @param description 知识库描述（可选）
     * 
     * 发送更新知识库请求到服务器，结果通过 updateKnowledgeBaseResponse 信号返回
     */
    void updateKnowledgeBase(int id = -1, const QString& name = "", const QString& description = "");
    
    /**
     * @brief 根据ID获取知识库详情（包含文件信息）
     * @param id 知识库ID
     * 
     * 发送获取知识库详情请求到服务器，结果通过 getKnowledgeBaseResponse 信号返回
     */
    void getKnowledgeBase(int id);
    
    /**
     * @brief 分页获取知识库列表
     * @param current 当前页码，默认1
     * @param pageSize 页面大小，默认10
     * @param sortField 排序字段（可选）
     * @param sortOrder 排序顺序，默认"descend"
     * @param id 知识库ID筛选（可选）
     * @param name 知识库名称筛选（可选）
     * @param userId 用户ID筛选（可选）
     * 
     * 发送获取知识库列表请求到服务器，结果通过 getKnowledgeBaseListResponse 信号返回
     */
    void getKnowledgeBaseList(int current = 1, int pageSize = 10000, const QString& sortField = "",
                             const QString& sortOrder = "descend", int id = -1, 
                             const QString& name = "", int userId = -1);
    
    /**
     * @brief 批量删除知识库文件
     * @param ids 要删除的文件ID列表
     * 
     * 发送批量删除知识库文件请求到服务器，结果通过 deleteKnowledgeBaseFilesResponse 信号返回
     */
    void deleteKnowledgeBaseFiles(const QList<int>& ids);
    
    /**
     * @brief 终止所有正在进行的网络请求
     * 
     * 立即终止所有活跃的POST/GET请求，已发送的请求会被中断。
     * 被终止的请求不会触发对应的响应信号。
     */
    void abortAllRequests();
    
    /**
     * @brief 终止指定类型的网络请求
     * @param requestType 要终止的请求类型（如 "login", "tnm-ai-score"）
     *
     * 只终止匹配指定类型的活跃请求，其他请求继续执行。
     */
    void abortRequestsByType(const QString& requestType);

    /**
     * @brief 终止指定chatId的流式聊天请求
     * @param chatId 要终止的聊天会话ID
     *
     * 只终止匹配指定chatId的流式聊天请求，其他聊天会话继续执行。
     */
    void abortStreamChatByChatId(const QString& chatId);

signals:
    /**
     * @brief 登录响应信号
     * @param success 是否登录成功
     * @param message 服务器返回的消息
     * @param data 用户数据（登录成功时包含用户信息）
     */
    void loginResponse(bool success, const QString& message, const QJsonObject& data);
    
    /**
     * @brief 注册响应信号
     * @param success 是否注册成功
     * @param message 服务器返回的消息
     * @param data 用户数据（注册成功时包含用户信息）
     */
    void registerResponse(bool success, const QString& message, const QJsonObject& data);

    /**
     * @brief TNM AI质量评分响应信号
     * @param success 是否请求成功
     * @param message 服务器返回的消息
     * @param data 评分数据
     */
    void tnmAiQualityScoreResponse(bool success, const QString& message, const QJsonObject& data);
    
    /**
     * @brief RENAL AI质量评分响应信号
     * @param success 是否请求成功
     * @param message 服务器返回的消息
     * @param data 评分数据
     */
    void renalAiQualityScoreResponse(bool success, const QString& message, const QJsonObject& data);
    
    /**
     * @brief 流式聊天数据接收信号
     * @param data 接收到的流式数据块
     * @param chatId 会话ID
     * 
     * 当接收到流式聊天数据时发出此信号，data为每次接收到的数据块
     */
    void streamChatResponse(const QString& data, const QString& chatId);
    
    /**
     * @brief 流式聊天完成信号
     * @param success 是否成功完成
     * @param message 完成消息
     * @param chatId 会话ID
     * 
     * 当流式聊天结束时发出此信号
     */
    void streamChatFinished(bool success, const QString& message, const QString& chatId);
    
    /**
     * @brief 删除聊天响应信号
     * @param success 是否删除成功
     * @param message 服务器返回的消息
     * @param data 响应数据
     */
    void deleteChatResponse(bool success, const QString& message, const QJsonObject& data);
    
    /**
     * @brief 添加评测记录响应信号
     * @param success 是否添加成功
     * @param message 服务器返回的消息
     * @param data 响应数据
     */
    void addQualityRecordResponse(bool success, const QString& message, const QJsonObject& data);
    
    /**
     * @brief 获取评测记录列表响应信号
     * @param success 是否请求成功
     * @param message 服务器返回的消息
     * @param data 列表数据
     */
    void getQualityListResponse(bool success, const QString& message, const QJsonObject& data);
    
    /**
     * @brief 癌症肿瘤分类响应信号
     * @param success 是否请求成功
     * @param message 服务器返回的消息
     * @param data 分类数据
     */
    void cancerDiagnoseTypeResponse(bool success, const QString& message, const QJsonObject& data);
    
    /**
     * @brief 保存报告模板响应信号
     * @param success 是否保存成功
     * @param message 服务器返回的消息
     * @param data 响应数据
     */
    void saveReportTemplateResponse(bool success, const QString& message, const QJsonObject& data);
    
    /**
     * @brief 删除报告模板响应信号
     * @param success 是否删除成功
     * @param message 服务器返回的消息
     * @param data 响应数据
     */
    void deleteReportTemplateResponse(bool success, const QString& message, const QJsonObject& data);
    
    /**
     * @brief 生成质控报告响应信号
     * @param success 是否生成成功
     * @param message 服务器返回的消息
     * @param data 报告数据
     */
    void generateQualityReportResponse(bool success, const QString& message, const QJsonObject& data);
    
    /**
     * @brief 获取报告模板列表响应信号
     * @param success 是否请求成功
     * @param message 服务器返回的消息
     * @param data 模板列表数据
     */
    void getReportTemplateListResponse(bool success, const QString& message, const QJsonObject& data);
    
    /**
     * @brief 文件上传响应信号
     * @param success 是否上传成功
     * @param message 服务器返回的消息
     * @param data 上传结果数据
     */
    void uploadFileResponse(bool success, const QString& message, const QJsonObject& data);
    
    /**
     * @brief 创建知识库响应信号
     * @param success 是否创建成功
     * @param message 服务器返回的消息
     * @param data 创建结果数据
     */
    void createKnowledgeBaseResponse(bool success, const QString& message, const QJsonObject& data);
    
    /**
     * @brief 删除知识库响应信号
     * @param success 是否删除成功
     * @param message 服务器返回的消息
     * @param data 删除结果数据
     */
    void deleteKnowledgeBaseResponse(bool success, const QString& message, const QJsonObject& data);
    
    /**
     * @brief 更新知识库响应信号
     * @param success 是否更新成功
     * @param message 服务器返回的消息
     * @param data 更新结果数据
     */
    void updateKnowledgeBaseResponse(bool success, const QString& message, const QJsonObject& data);
    
    /**
     * @brief 获取知识库详情响应信号
     * @param success 是否获取成功
     * @param message 服务器返回的消息
     * @param data 知识库详情数据
     */
    void getKnowledgeBaseResponse(bool success, const QString& message, const QJsonObject& data);
    
    /**
     * @brief 获取知识库列表响应信号
     * @param success 是否获取成功
     * @param message 服务器返回的消息
     * @param data 知识库列表数据
     */
    void getKnowledgeBaseListResponse(bool success, const QString& message, const QJsonObject& data);
    
    /**
     * @brief 批量删除知识库文件响应信号
     * @param success 是否删除成功
     * @param message 服务器返回的消息
     * @param data 删除结果数据
     */
    void deleteKnowledgeBaseFilesResponse(bool success, const QString& message, const QJsonObject& data);
    
    /**
     * @brief 网络错误信号
     * @param error 错误描述
     */
    void networkError(const QString& error);
    
    /**
     * @brief 连接测试结果信号
     * @param success 连接是否成功
     * @param message 测试结果消息
     */
    void connectionTestResult(bool success, const QString& message);

private slots:
    /**
     * @brief 网络请求完成的槽函数
     * @param reply 网络回复对象
     * 
     * 统一处理所有网络请求的响应，根据请求类型分发到对应的信号
     */
    void onNetworkReply(QNetworkReply* reply);
    
    /**
     * @brief 流式数据就绪槽函数
     * 
     * 当流式聊天接口有新数据可读时调用，处理分块接收的数据
     */
    void onStreamDataReady();

private:
    /**
     * @brief 获取当前使用的基础URL
     * @return 根据usePublicNetwork属性返回对应的API基础地址
     */
    QString getBaseUrl() const;
    
    /**
     * @brief 创建网络请求对象
     * @param endpoint API端点路径
     * @return 配置好的QNetworkRequest对象
     */
    QNetworkRequest createRequest(const QString& endpoint) const;
    
    /**
     * @brief 发送POST请求
     * @param endpoint API端点路径
     * @param data 请求数据（JSON格式）
     * @param requestType 请求类型标识，用于响应时区分不同请求
     */
    void makePostRequest(const QString& endpoint, const QJsonObject& data, const QString& requestType = "");
    
    /**
     * @brief 发送GET请求
     * @param endpoint API端点路径
     * @param requestType 请求类型标识，用于响应时区分不同请求
     */
    void makeGetRequest(const QString& endpoint, const QString& requestType = "");

    /// @brief Qt网络访问管理器，负责实际的网络请求
    QNetworkAccessManager* m_networkManager;
    
    /// @brief 跟踪所有活跃的网络请求，用于终止操作
    QSet<QNetworkReply*> m_activeReplies;
    
    /// @brief 跟踪流式聊天请求的chatId映射，用于在接收数据时识别会话
    QMap<QNetworkReply*, QString> m_streamChatIds;
    
    /// @brief 跟踪每个流式聊天请求的不完整SSE数据缓冲区
    QMap<QNetworkReply*, QString> m_streamDataBuffers;

    // API地址常量
    const QString INTERNAL_BASE_URL = "http://192.168.1.2:9898/api";  ///< 内网API基础地址
    const QString PUBLIC_BASE_URL = "http://111.6.178.34:24603/api";   ///< 公网API基础地址
};

#endif // APIMANAGER_H