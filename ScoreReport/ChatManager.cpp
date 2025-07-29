#include "ChatManager.h"
#include "ApiManager.h"
#include "LoginManager.h"
#include <QVariantMap>
#include <QDateTime>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDebug>

ChatManager::ChatManager(QObject* parent)
    : QObject(parent)
    , m_isSending(false)
    , m_isReceivingAi(false)
{
    // 连接ApiManager的信号
    auto* apiManager = GET_SINGLETON(ApiManager);
    connect(apiManager, &ApiManager::streamChatResponse, 
            this, &ChatManager::onStreamChatResponse);
    connect(apiManager, &ApiManager::streamChatFinished, 
            this, &ChatManager::onStreamChatFinished);
    
    // 初始化聊天ID
    m_currentChatId = CommonFunc::generateNumericUUID();
}

void ChatManager::sendMessage(const QString& message)
{
    if (message.trimmed().isEmpty() || m_isSending) {
        return;
    }
    
    // 添加用户消息到界面
    addUserMessage(message.trimmed());
    
    // 设置发送状态
    setisSending(true);
    m_isReceivingAi = true;
    m_currentAiMessage.clear();
    
    // 获取用户ID
    auto* loginManager = GET_SINGLETON(LoginManager);
    QString userId = loginManager->getcurrentUserId();
    
    // 调用API发送消息
    auto* apiManager = GET_SINGLETON(ApiManager);
    apiManager->streamChat(message.trimmed(), userId, m_currentChatId);
}

void ChatManager::clearMessages()
{
    QVariantList emptyList;
    setmessages(emptyList);
    
    // 重新生成聊天ID
    m_currentChatId = CommonFunc::generateNumericUUID();
    setcurrentChatId(m_currentChatId);
    
    // 重置状态
    m_currentAiMessage.clear();
    m_isReceivingAi = false;
    setisSending(false);
}

void ChatManager::resetWithWelcomeMessage()
{
    // 先清空所有消息和重置状态
    QVariantList emptyList;
    setmessages(emptyList);
    
    // 重新生成聊天ID
    m_currentChatId = CommonFunc::generateNumericUUID();
    setcurrentChatId(m_currentChatId);
    
    // 重置状态
    m_currentAiMessage.clear();
    m_isReceivingAi = false;
    setisSending(false);
    
    // 添加欢迎消息
    addAiMessage(QString::fromLocal8Bit("您好，我是您的AI辅助助手。请您随时提出问题，我将尽最大努力为您提供有价值的信息支持。"));
}

void ChatManager::onStreamChatResponse(const QString& data, const QString& chatId)
{
    // 检查是否是当前聊天的响应
    if (chatId != m_currentChatId) {
        return;
    }
    
    // 如果是第一次接收AI响应，添加AI消息
    if (m_currentAiMessage.isEmpty()) {
        addAiMessage(data);
        m_currentAiMessage = data;
    } else {
        // 否则更新最后一条AI消息
        m_currentAiMessage += data;
        updateLastAiMessage(data);
    }
}

void ChatManager::onStreamChatFinished(bool success, const QString& message, const QString& chatId)
{
    // 检查是否是当前聊天的响应
    if (chatId != m_currentChatId) {
        return;
    }
    
    // 重置状态
    setisSending(false);
    m_isReceivingAi = false;
    
    if (!success) {
        // 如果失败，添加错误消息
        addAiMessage(QString("抱歉，发生了错误：%1").arg(message));
    }
    
    // 如果当前AI消息为空，添加一个默认回复
    if (m_currentAiMessage.isEmpty()) {
        addAiMessage("抱歉，我无法回复您的消息。");
    }
    
    m_currentAiMessage.clear();
}

void ChatManager::addUserMessage(const QString& message)
{
    QVariantMap userMessage;
    userMessage["type"] = "user";
    userMessage["content"] = message;
    userMessage["timestamp"] = QDateTime::currentDateTime().toString("hh:mm");
    
    QVariantList currentMessages = getmessages();
    currentMessages.append(userMessage);
    setmessages(currentMessages);
}

void ChatManager::addAiMessage(const QString& message)
{
    QVariantMap aiMessage;
    aiMessage["type"] = "ai";
    aiMessage["content"] = message;
    aiMessage["timestamp"] = QDateTime::currentDateTime().toString("hh:mm");
    
    QVariantList currentMessages = getmessages();
    currentMessages.append(aiMessage);
    setmessages(currentMessages);
}

void ChatManager::updateLastAiMessage(const QString& additionalText)
{
    QVariantList currentMessages = getmessages();
    if (currentMessages.isEmpty()) {
        return;
    }
    
    // 获取最后一条消息
    QVariantMap lastMessage = currentMessages.last().toMap();
    if (lastMessage["type"].toString() == "ai") {
        // 更新内容
        QString currentContent = lastMessage["content"].toString();
        lastMessage["content"] = currentContent + additionalText;
        
        // 替换最后一条消息
        currentMessages.removeLast();
        currentMessages.append(lastMessage);
        setmessages(currentMessages);
    }
}
