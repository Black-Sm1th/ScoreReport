#include "ChatManager.h"
#include "ApiManager.h"
#include <QGuiApplication>
#include <QClipboard>
#include "LoginManager.h"
#include <QVariantMap>
#include <QDateTime>
#include <QJsonDocument>
#include <QJsonObject>
#include <QDebug>

ChatManager::ChatManager(QObject* parent)
    : QObject(parent)
    , m_isSending(false)
    , m_isThinking(false)
    , m_lastUserMessage("")
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
    
    QString trimmedMessage = message.trimmed();
    
    // 保存用户消息，用于再次生成功能
    setlastUserMessage(trimmedMessage);
    
    // 添加用户消息到界面
    addUserMessage(trimmedMessage);
    
    // 设置发送状态
    setisSending(true);
    setisThinking(true);
    m_currentAiMessage.clear();
    
    // 添加思考中的占位消息
    addThinkingMessage();
    
    // 获取用户ID
    auto* loginManager = GET_SINGLETON(LoginManager);
    QString userId = loginManager->getcurrentUserId();
    
    // 调用API发送消息
    auto* apiManager = GET_SINGLETON(ApiManager);
    apiManager->streamChat(trimmedMessage, userId, m_currentChatId);
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
    setisSending(false);
    setisThinking(false);
    setlastUserMessage("");
    
    // 添加欢迎消息
    addAiMessage(QString::fromUtf8("您好，我是您的AI辅助助手。请您随时提出问题，我将尽最大努力为您提供有价值的信息支持。"));
}

void ChatManager::regenerateLastResponse()
{
    if (getlastUserMessage().isEmpty() || m_isSending) {
        return;
    }
    
    // 移除最后一条AI消息（如果存在）
    QVariantList currentMessages = getmessages();
    if (!currentMessages.isEmpty()) {
        QVariantMap lastMessage = currentMessages.last().toMap();
        if (lastMessage["type"].toString() == "ai") {
            currentMessages.removeLast();
            setmessages(currentMessages);
        }
    }
    
    // 重新发送最后一条用户消息
    QString lastMessage = getlastUserMessage();
    
    // 设置发送状态
    setisSending(true);
    setisThinking(true);
    m_currentAiMessage.clear();
    
    // 添加思考中的占位消息
    addThinkingMessage();
    
    // 获取用户ID
    auto* loginManager = GET_SINGLETON(LoginManager);
    QString userId = loginManager->getcurrentUserId();
    
    // 调用API发送消息
    auto* apiManager = GET_SINGLETON(ApiManager);
    apiManager->streamChat(lastMessage, userId, m_currentChatId);
}

void ChatManager::onStreamChatResponse(const QString& data, const QString& chatId)
{
    // 检查是否是当前聊天的响应
    if (chatId != m_currentChatId) {
        return;
    }
    // 如果是第一次接收AI响应，移除思考状态并替换占位消息
    if (m_currentAiMessage.isEmpty()) {
        setisThinking(false);
        removeThinkingMessage();
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
    qDebug() << "[ChatManager] Chat finished";
    // 重置状态
    setisSending(false);
    setisThinking(false);
    
    if (!success) {
        // 如果失败，移除思考消息并添加错误消息
        removeThinkingMessage();
        addAiMessage(QString("抱歉，发生了错误：%1").arg(message));
    }
    
    // 如果当前AI消息为空，添加一个默认回复
    if (m_currentAiMessage.isEmpty()) {
        removeThinkingMessage();
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

void ChatManager::addThinkingMessage()
{
    QVariantMap thinkingMessage;
    thinkingMessage["type"] = "thinking";
    thinkingMessage["content"] = "思考中";
    thinkingMessage["timestamp"] = QDateTime::currentDateTime().toString("hh:mm");
    
    QVariantList currentMessages = getmessages();
    currentMessages.append(thinkingMessage);
    setmessages(currentMessages);
}

void ChatManager::removeThinkingMessage()
{
    QVariantList currentMessages = getmessages();
    
    // 从后往前查找并移除思考中消息
    for (int i = currentMessages.size() - 1; i >= 0; i--) {
        QVariantMap message = currentMessages[i].toMap();
        if (message["type"].toString() == "thinking") {
            currentMessages.removeAt(i);
            setmessages(currentMessages);
            break;
        }
    }
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

void ChatManager::endAnalysis()
{
    // 只中断当前ChatManager实例的流式聊天请求
    GET_SINGLETON(ApiManager)->abortStreamChatByChatId(m_currentChatId);
    m_currentAiMessage.clear();
    setisSending(false);
    setisThinking(false);
    QVariantList currentMessages = getmessages();
    if (!currentMessages.isEmpty() && currentMessages.last().toMap()["type"] == "thinking") {
        currentMessages.removeLast();
        QVariantMap interruptMessage;
        interruptMessage["type"] = "interrupt";
        interruptMessage["content"] = "消息已中断！";
        interruptMessage["timestamp"] = QDateTime::currentDateTime().toString("hh:mm");
        currentMessages.append(interruptMessage);
        setmessages(currentMessages);
    }
}

void ChatManager::copyToClipboard(const QString& content)
{
    QClipboard* clipboard = QGuiApplication::clipboard();
    clipboard->setText(content);
}
