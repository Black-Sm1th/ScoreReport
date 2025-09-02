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
#include <QFileInfo>

ChatManager::ChatManager(QObject* parent)
    : QObject(parent)
    , m_isSending(false)
    , m_isThinking(false)
    , m_lastUserMessage("")
    , m_maxFileCount(3)
    , m_maxFileSize(10 * 1024 * 1024) // 10MB
{
    // 连接ApiManager的信号
    auto* apiManager = GET_SINGLETON(ApiManager);
    connect(apiManager, &ApiManager::streamChatResponse,
            this, &ChatManager::onStreamChatResponse);
    connect(apiManager, &ApiManager::streamChatFinished,
            this, &ChatManager::onStreamChatFinished);

    // 初始化聊天ID
    m_currentChatId = CommonFunc::generateNumericUUID();
    
    // 初始化支持的文件格式
    m_supportedFormats << "pdf" << "txt" << "doc" << "docx" 
                       << "jpg" << "jpeg" << "png" << "bmp" << "gif";
    
    // 初始化文件列表
    QVariantList emptyFiles;
    setfiles(emptyFiles);
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
    
    // 清空文件列表
    clearFiles();
    
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

QString ChatManager::getClipboardText()
{
    QClipboard* clipboard = QGuiApplication::clipboard();
    return clipboard->text();
}

qint64 ChatManager::getFileSize(const QString& filePath)
{
    QFileInfo fileInfo(filePath);
    if (fileInfo.exists() && fileInfo.isFile()) {
        return fileInfo.size();
    }
    return -1; // 文件不存在或不是文件
}

bool ChatManager::addFile(const QString& filePath)
{
    return addFile(filePath, true);
}

bool ChatManager::addFile(const QString& filePath, bool showMessage)
{
    QString fileName = getFileName(filePath);
    
    // 检查文件数量限制
    if (getfiles().size() >= getmaxFileCount()) {
        if (showMessage) {
            emit fileOperationResult(QString("无法添加 %1 ：最多只能上传%2个文件").arg(fileName).arg(getmaxFileCount()), "error");
        }
        return false;
    }
    
    // 检查文件格式
    if (!isValidFileFormat(filePath)) {
        if (showMessage) {
            emit fileOperationResult(QString("无法添加 %1 ：不支持的文件格式").arg(fileName), "error");
        }
        return false;
    }
    
    // 检查文件大小
    if (!isFileSizeValid(filePath)) {
        if (showMessage) {
            emit fileOperationResult(QString("无法添加 %1 ：文件大小超过%2限制").arg(fileName).arg(formatFileSize(getmaxFileSize())), "error");
        }
        return false;
    }
    
    // 检查文件是否已存在
    QVariantList currentFiles = getfiles();
    for (const auto& file : currentFiles) {
        QVariantMap fileMap = file.toMap();
        if (fileMap["path"].toString() == filePath) {
            if (showMessage) {
                emit fileOperationResult(QString("无法添加 %1 ：文件已存在").arg(fileName), "error");
            }
            return false;
        }
    }
    
    // 创建文件信息对象
    QVariantMap fileInfo = getFileInfo(filePath);
    
    // 添加到列表
    currentFiles.append(fileInfo);
    setfiles(currentFiles);
    
    if (showMessage) {
        emit fileOperationResult(QString("文件已添加: %1").arg(fileName), "success");
    }
    return true;
}

bool ChatManager::removeFile(int index)
{
    QVariantList currentFiles = getfiles();
    if (index < 0 || index >= currentFiles.size()) {
        return false;
    }
    
    currentFiles.removeAt(index);
    setfiles(currentFiles);
    emit fileOperationResult(QString::fromUtf8("文件已移除！"), "success");
    return true;
}

void ChatManager::clearFiles()
{
    QVariantList emptyFiles;
    setfiles(emptyFiles);
}

QVariantMap ChatManager::getFileInfo(const QString& filePath)
{
    QVariantMap fileInfo;
    QFileInfo info(filePath);
    
    fileInfo["path"] = filePath;
    fileInfo["name"] = getFileName(filePath);
    fileInfo["size"] = getFileSize(filePath);
    fileInfo["formattedSize"] = formatFileSize(getFileSize(filePath));
    fileInfo["extension"] = info.suffix().toUpper();
    fileInfo["exists"] = info.exists();
    
    return fileInfo;
}

bool ChatManager::isValidFileFormat(const QString& filePath)
{
    QFileInfo info(filePath);
    QString extension = info.suffix().toLower();
    return m_supportedFormats.contains(extension);
}

bool ChatManager::isFileSizeValid(const QString& filePath)
{
    qint64 fileSize = getFileSize(filePath);
    if (fileSize == -1) {
        // 无法获取文件大小时，允许添加但给出警告
        return true;
    }
    return fileSize <= getmaxFileSize();
}

QString ChatManager::formatFileSize(qint64 bytes)
{
    if (bytes <= 0) return "0 字节";
    
    const qint64 k = 1024;
    const QStringList sizes = {"字节", "KB", "MB", "GB"};
    int i = 0;
    
    double size = bytes;
    while (size >= k && i < sizes.size() - 1) {
        size /= k;
        i++;
    }
    
    if (i == 0) {
        return QString("%1%2").arg(static_cast<int>(size)).arg(sizes[i]);
    } else {
        return QString("%1%2").arg(size, 0, 'f', 1).arg(sizes[i]);
    }
}

QString ChatManager::getFileName(const QString& filePath)
{
    QFileInfo info(filePath);
    return info.fileName();
}

int ChatManager::addFiles(const QStringList& filePaths)
{
    int addedCount = 0;
    int skipCount = 0;
    for (const QString& filePath : filePaths) {
        // 检查是否已达到最大文件数量
        if (getfiles().size() >= getmaxFileCount()) {
            skipCount = filePaths.size() - addedCount;
            break;
        }
        
        // 批量添加时不显示单个文件的成功消息
        if (addFile(filePath, false)) {
            addedCount++;
        }
    }
    
    // 显示汇总信息（仅多文件时）
    if (filePaths.size() > 1) {
        QString summary = "";
        QString msgType = "warning";
        if (addedCount > 0) {
            summary += QString("成功添加 %1 个文件").arg(addedCount);
            msgType = "success";
        }
        
        if (skipCount > 0) {
            if (!summary.isEmpty()) summary += "，";
            summary += QString("超出文件数量限制，已忽略 %1 个文件").arg(skipCount);
            msgType = "warning";
        }
        
        if (!summary.isEmpty()) {
            emit fileOperationResult(summary, msgType);
        }
    }
    
    return addedCount;
}