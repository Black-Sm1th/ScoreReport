#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QJsonObject>
#include "CommonFunc.h"

/**
 * @brief 聊天管理器类 - 负责处理聊天功能
 * 
 * 这是一个单例类，提供聊天消息管理和API调用功能
 */
class ChatManager : public QObject
{
    Q_OBJECT
    
    /// @brief 消息列表，供QML绑定
    QUICK_PROPERTY(QVariantList, messages)
    
    /// @brief 是否正在发送消息
    QUICK_PROPERTY(bool, isSending)
    
    /// @brief 当前聊天ID
    QUICK_PROPERTY(QString, currentChatId)
    
    SINGLETON_CLASS(ChatManager)

public:
    /**
     * @brief 发送消息
     * @param message 要发送的消息内容
     */
    Q_INVOKABLE void sendMessage(const QString& message);
    
    /**
     * @brief 清空聊天记录
     */
    Q_INVOKABLE void clearMessages();
    
    /**
     * @brief 重置聊天并添加欢迎消息
     */
    Q_INVOKABLE void resetWithWelcomeMessage();

private slots:
    /**
     * @brief 处理流式聊天响应
     * @param data 接收到的数据块
     * @param chatId 会话ID
     */
    void onStreamChatResponse(const QString& data, const QString& chatId);
    
    /**
     * @brief 处理流式聊天完成
     * @param success 是否成功
     * @param message 完成消息
     * @param chatId 会话ID
     */
    void onStreamChatFinished(bool success, const QString& message, const QString& chatId);

private:
    /**
     * @brief 添加用户消息到列表
     * @param message 消息内容
     */
    void addUserMessage(const QString& message);
    
    /**
     * @brief 添加AI消息到列表
     * @param message 消息内容
     */
    void addAiMessage(const QString& message);
    
    /**
     * @brief 更新最后一条AI消息
     * @param additionalText 要追加的文本
     */
    void updateLastAiMessage(const QString& additionalText);
    
    /// @brief 当前正在接收的AI消息内容
    QString m_currentAiMessage;
    
    /// @brief 是否正在接收AI消息
    bool m_isReceivingAi;
};

