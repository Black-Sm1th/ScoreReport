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
#include <QSet>
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
     * @brief 获取TNM AI质量评分
     * @param userId 用户ID
     * @param content 待评分的内容
     * 
     * 发送TNM内容到AI服务进行质量评分，结果通过 tnmAiQualityScoreResponse 信号返回
     */
    void getTnmAiQualityScore(const QString& chatId, const QString& userId, const QString& content);
    
    /**
     * @brief 删除指定的聊天记录
     * @param chatId 要删除的聊天ID
     * 
     * 发送删除聊天请求到服务器，结果通过 deleteChatResponse 信号返回
     */
    void deleteChatById(const QString& chatId);
    
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

signals:
    /**
     * @brief 登录响应信号
     * @param success 是否登录成功
     * @param message 服务器返回的消息
     * @param data 用户数据（登录成功时包含用户信息）
     */
    void loginResponse(bool success, const QString& message, const QJsonObject& data);
    
    /**
     * @brief TNM AI质量评分响应信号
     * @param success 是否请求成功
     * @param message 服务器返回的消息
     * @param data 评分数据
     */
    void tnmAiQualityScoreResponse(bool success, const QString& message, const QJsonObject& data);
    
    /**
     * @brief 删除聊天响应信号
     * @param success 是否删除成功
     * @param message 服务器返回的消息
     * @param data 响应数据
     */
    void deleteChatResponse(bool success, const QString& message, const QJsonObject& data);
    
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

    // API地址常量
    const QString INTERNAL_BASE_URL = "http://192.168.1.2:9898/api";  ///< 内网API基础地址
    const QString PUBLIC_BASE_URL = "http://111.6.178.34:24603/api";   ///< 公网API基础地址
};

#endif // APIMANAGER_H