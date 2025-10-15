#include "KnowledgeChatManager.h"
#include "ApiManager.h"
#include "LoginManager.h"
#include <QDateTime>
#include <QDebug>
#include <QDir>
#include <QFileInfo>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QMutexLocker>
#include <QProcess>
#include <QString>
#include <QTemporaryDir>
#include <QTextStream>
#include <QThread>
#include <QVariantMap>
#include <QXmlStreamReader>
#include <QClipboard>
#include <QGuiApplication>
#include <QtConcurrent/QtConcurrent>
#include <QTimer>
#include <QRegularExpression>

namespace {
    // 配置常量
    constexpr int DEFAULT_MAX_FILE_COUNT = 3;                    ///< 默认最大文件数量
    constexpr qint64 DEFAULT_MAX_FILE_SIZE = 10 * 1024 * 1024;   ///< 默认最大文件大小 (10MB)
    constexpr int THREAD_WAIT_TIMEOUT = 3000;                    ///< 线程等待超时时间 (毫秒)
    constexpr int POWERSHELL_TIMEOUT = 30000;                    ///< PowerShell执行超时时间 (毫秒)
    constexpr int PROGRESS_ANIMATION_DELAY = 50;                 ///< 进度动画延迟 (毫秒)

    // 文件读取相关常量
    const QStringList SUPPORTED_TEXT_FORMATS = { "txt", "doc", "docx" };
    const QStringList SUPPORTED_IMAGE_FORMATS = { "jpg", "jpeg", "png", "bmp", "gif" };
}

KnowledgeChatManager::KnowledgeChatManager(QObject* parent)
    : QObject(parent)
    , m_isSending(false)
    , m_isThinking(false)
    , m_isUploading(false)
    , m_lastUserMessage("")
    , m_maxFileCount(DEFAULT_MAX_FILE_COUNT)
    , m_maxFileSize(DEFAULT_MAX_FILE_SIZE)
{
    // 连接API管理器的信号
    auto* apiManager = GET_SINGLETON(ApiManager);
    connect(apiManager, &ApiManager::streamChatResponse,
        this, &KnowledgeChatManager::onStreamChatResponse);
    connect(apiManager, &ApiManager::streamChatFinished,
        this, &KnowledgeChatManager::onStreamChatFinished);
    connect(apiManager, &ApiManager::getKnowledgeBaseListResponse,
        this, &KnowledgeChatManager::onKnowledgeBaseListResponse);
    connect(apiManager, &ApiManager::streamKnowledgeChatResponse,
        this, &KnowledgeChatManager::onStreamKnowledgeChatResponse);
    connect(apiManager, &ApiManager::streamKnowledgeChatFinished,
        this, &KnowledgeChatManager::onStreamKnowledgeChatFinished);
    connect(apiManager, &ApiManager::knowledgeChatMetadataReceived,
        this, &KnowledgeChatManager::onKnowledgeChatMetadataReceived);

    // 初始化聊天会话ID
    m_currentChatId = CommonFunc::generateNumericUUID();

    // 初始化支持的文件格式
    m_supportedFormats = SUPPORTED_TEXT_FORMATS + SUPPORTED_IMAGE_FORMATS;

    // 初始化属性
    setfiles(QVariantList());
    setfileReadProgress(QVariantMap());
    setknowledgeBaseList(QVariantList());
    setselectedKnowledgeBases(QStringList());
    setretrievedMetadata(QVariantList());
}

void KnowledgeChatManager::sendMessage(const QString& message)
{
    if (message.trimmed().isEmpty() || m_isSending) {
        return;
    }

    QString trimmedMessage = message.trimmed();
    QString fullMessage = trimmedMessage;

    // 处理文件附件
    QVariantList currentFiles = getfiles();
    if (!currentFiles.isEmpty()) {
        fullMessage = buildMessageWithFiles(trimmedMessage, currentFiles);
        clearFiles(); // 发送后清空文件列表
    }

    // 保存消息用于重新生成
    setlastUserMessage(fullMessage);

    // 添加用户消息到界面（显示原始消息）
    addUserMessage(trimmedMessage);

    // 设置发送状态
    setisSending(true);
    setisThinking(true);
    m_currentAiMessage.clear();

    // 清空之前的元数据
    setretrievedMetadata(QVariantList());

    // 显示思考状态
    addThinkingMessage();

    // 发送到API
    auto* loginManager = GET_SINGLETON(LoginManager);
    QString userId = loginManager->getcurrentUserId();

    auto* apiManager = GET_SINGLETON(ApiManager);

    // 使用知识库流式聊天接口
    QStringList selectedBuckets = getSelectedBuckets();
    QString language = "zh"; // 默认中文，可以根据需要调整

    apiManager->streamKnowledgeChat(fullMessage, userId, language, selectedBuckets, m_currentChatId);
}

void KnowledgeChatManager::resetWithWelcomeMessage()
{
    // 清空消息列表
    setmessages(QVariantList());
    setknowledgeBaseList(QVariantList());
    setselectedKnowledgeBases(QStringList());
    setretrievedMetadata(QVariantList());
    // 重新生成会话ID
    m_currentChatId = CommonFunc::generateNumericUUID();
    setcurrentChatId(m_currentChatId);

    // 重置所有状态
    m_currentAiMessage.clear();
    setisSending(false);
    setisThinking(false);
    setlastUserMessage("");

    // 清空文件（会自动清理读取任务）
    clearFiles();
}

void KnowledgeChatManager::regenerateLastResponse()
{
    if (getlastUserMessage().isEmpty() || m_isSending) {
        return;
    }

    // 移除最后一条AI消息
    QVariantList currentMessages = getmessages();
    if (!currentMessages.isEmpty()) {
        QVariantMap lastMessage = currentMessages.last().toMap();
        if (lastMessage["type"].toString() == "ai") {
            currentMessages.removeLast();
            setmessages(currentMessages);
        }
    }

    // 重新发送最后一条消息
    QString lastMessage = getlastUserMessage();

    // 设置状态
    setisSending(true);
    setisThinking(true);
    m_currentAiMessage.clear();

    addThinkingMessage();

    // 发送API请求
    auto* loginManager = GET_SINGLETON(LoginManager);
    QString userId = loginManager->getcurrentUserId();

    auto* apiManager = GET_SINGLETON(ApiManager);

    // 使用知识库流式聊天接口
    QStringList selectedBuckets = getSelectedBuckets();
    QString language = "zh"; // 默认中文，可以根据需要调整

    apiManager->streamKnowledgeChat(lastMessage, userId, language, selectedBuckets, m_currentChatId);
}

void KnowledgeChatManager::endAnalysis(bool clearfile)
{
    // 中断当前聊天
    GET_SINGLETON(ApiManager)->abortStreamChatByChatId(m_currentChatId);

    // 取消所有文件上传（读取）任务（确保不在持锁状态下等待线程）
    if (clearfile) {
        clearFiles();
    }

    // 重置状态
    m_currentAiMessage.clear();
    setisSending(false);
    setisThinking(false);

    // 替换思考消息为中断消息
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

void KnowledgeChatManager::addUserMessage(const QString& message)
{
    QVariantMap userMessage;
    userMessage["type"] = "user";
    userMessage["content"] = message;
    userMessage["timestamp"] = QDateTime::currentDateTime().toString("hh:mm");

    QVariantList currentMessages = getmessages();
    currentMessages.append(userMessage);
    setmessages(currentMessages);
}

void KnowledgeChatManager::addAiMessage(const QString& message)
{
    QVariantMap aiMessage;
    aiMessage["type"] = "ai";
    aiMessage["content"] = message;
    aiMessage["timestamp"] = QDateTime::currentDateTime().toString("hh:mm");

    QVariantList currentMessages = getmessages();
    currentMessages.append(aiMessage);
    setmessages(currentMessages);
}

void KnowledgeChatManager::addThinkingMessage()
{
    QVariantMap thinkingMessage;
    thinkingMessage["type"] = "thinking";
    thinkingMessage["content"] = "查询中";
    thinkingMessage["timestamp"] = QDateTime::currentDateTime().toString("hh:mm");

    QVariantList currentMessages = getmessages();
    currentMessages.append(thinkingMessage);
    setmessages(currentMessages);
}

void KnowledgeChatManager::removeThinkingMessage()
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

void KnowledgeChatManager::updateLastAiMessage(const QString& additionalText)
{
    QVariantList currentMessages = getmessages();
    if (currentMessages.isEmpty()) {
        return;
    }

    QVariantMap lastMessage = currentMessages.last().toMap();
    if (lastMessage["type"].toString() == "ai") {
        // 追加内容
        QString currentContent = lastMessage["content"].toString();
        lastMessage["content"] = currentContent + additionalText;

        // 更新消息列表
        currentMessages.removeLast();
        currentMessages.append(lastMessage);
        setmessages(currentMessages);
    }
}

QString KnowledgeChatManager::buildMessageWithFiles(const QString& userMessage, const QVariantList& files)
{
    QStringList fileContents;

    for (const auto& file : files) {
        QVariantMap fileMap = file.toMap();
        QString filePath = fileMap["path"].toString();
        QString fileName = fileMap["name"].toString();

        // 优先使用已缓存的文件内容
        QString content = getFileContent(filePath);
        if (content.isEmpty()) {
            // 备用：同步读取
            content = readFileContent(filePath);
        }

        if (!content.isEmpty()) {
            QString extension = QFileInfo(filePath).suffix().toLower();
            if (SUPPORTED_TEXT_FORMATS.contains(extension)) {
                fileContents << QString("【文件：%1】\n%2").arg(fileName, content);
            }
            else {
                fileContents << content;
            }
        }
    }

    return fileContents.isEmpty() ? userMessage :
        fileContents.join("\n\n") + "\n\n【用户问题】\n" + userMessage;
}

QString KnowledgeChatManager::validateFileForAdding(const QString& filePath, const QString& fileName)
{
    // 验证文件数量限制
    if (getfiles().size() >= getmaxFileCount()) {
        return QString("无法添加 %1：最多只能上传%2个文件").arg(fileName).arg(getmaxFileCount());
    }

    // 验证文件格式
    if (!isValidFileFormat(filePath)) {
        return QString("无法添加 %1：不支持的文件格式").arg(fileName);
    }

    // 验证文件大小
    if (!isFileSizeValid(filePath)) {
        return QString("无法添加 %1：文件大小超过%2限制").arg(fileName).arg(formatFileSize(getmaxFileSize()));
    }

    // 检查文件是否已存在
    QVariantList currentFiles = getfiles();
    for (const auto& file : currentFiles) {
        QVariantMap fileMap = file.toMap();
        if (fileMap["path"].toString() == filePath) {
            return QString("无法添加 %1：文件已存在").arg(fileName);
        }
    }

    return QString(); // 验证通过，返回空字符串
}

void KnowledgeChatManager::onStreamChatResponse(const QString& data, const QString& chatId)
{
    // 验证是否为当前会话
    if (chatId != m_currentChatId) {
        return;
    }

    if (m_currentAiMessage.isEmpty()) {
        // 第一次接收响应：移除思考状态
        setisThinking(false);
        removeThinkingMessage();
        addAiMessage(data);
        m_currentAiMessage = data;
    }
    else {
        // 追加响应内容
        m_currentAiMessage += data;
        updateLastAiMessage(data);
    }
}

void KnowledgeChatManager::onStreamChatFinished(bool success, const QString& message, const QString& chatId)
{
    // 验证是否为当前会话
    if (chatId != m_currentChatId) {
        return;
    }

    qDebug() << "[KnowledgeChatManager] Chat finished, success:" << success;

    // 重置状态
    setisSending(false);
    setisThinking(false);

    if (!success) {
        // 处理错误情况
        removeThinkingMessage();
        addAiMessage(QString("抱歉，发生了错误：%1").arg(message));
    }

    // 处理空响应
    if (m_currentAiMessage.isEmpty()) {
        removeThinkingMessage();
        addAiMessage("抱歉，我无法回复您的消息。");
    }

    m_currentAiMessage.clear();
}

bool KnowledgeChatManager::addFile(const QString& filePath)
{
    return addFile(filePath, true);
}

bool KnowledgeChatManager::addFile(const QString& filePath, bool showMessage)
{
    QString fileName = getFileName(filePath);

    // 验证文件是否可以添加
    QString errorMessage = validateFileForAdding(filePath, fileName);
    if (!errorMessage.isEmpty()) {
        if (showMessage) {
            emit fileOperationResult(errorMessage, "error");
        }
        return false;
    }

    // 添加文件到列表
    QVariantList currentFiles = getfiles();
    QVariantMap fileInfo = getFileInfo(filePath);
    currentFiles.append(fileInfo);
    setfiles(currentFiles);

    // 启动异步读取任务
    startFileReadTask(filePath, fileName);
    return true;
}

int KnowledgeChatManager::addFiles(const QStringList& filePaths)
{
    int addedCount = 0;
    int skipCount = 0;

    for (const QString& filePath : filePaths) {
        if (getfiles().size() >= getmaxFileCount()) {
            skipCount = filePaths.size() - addedCount;
            break;
        }

        if (addFile(filePath, false)) {
            addedCount++;
        }
    }

    // 显示批量操作结果
    if (filePaths.size() > 1) {
        QString summary;
        QString msgType = "info";

        if (skipCount > 0) {
            if (!summary.isEmpty()) summary += "，";
            summary += QString("超出文件数量限制，已忽略 %1 个文件").arg(skipCount);
            msgType = "warning";
        }

        if (!summary.isEmpty()) {
            emit fileOperationResult(summary, msgType);
        }
    }

    qDebug() << "[KnowledgeChatManager] Batch add files: added" << addedCount << "skipped" << skipCount;
    return addedCount;
}

bool KnowledgeChatManager::removeFile(int index)
{
    QVariantList currentFiles = getfiles();
    if (index < 0 || index >= currentFiles.size()) {
        return false;
    }

    // 获取文件信息
    QVariantMap fileMap = currentFiles[index].toMap();
    QString filePath = fileMap["path"].toString();

    // 清理相关资源
    cleanupFileReadTask(filePath);

    {
        QMutexLocker locker(&m_mutex);
        m_fileContents.remove(filePath);
    }

    // 从列表中移除
    currentFiles.removeAt(index);
    setfiles(currentFiles);

    emit fileOperationResult(QString::fromUtf8("文件已移除！"), "warning");

    qDebug() << "[KnowledgeChatManager] File removed at index:" << index;
    return true;
}

void KnowledgeChatManager::clearFiles()
{
    // 清理所有读取任务
    cleanupAllFileReadTasks();

    // 清空文件内容缓存
    {
        QMutexLocker locker(&m_mutex);
        m_fileContents.clear();
    }

    // 清空文件列表
    setfiles(QVariantList());
}

void KnowledgeChatManager::copyToClipboard(const QString& content)
{
    QClipboard* clipboard = QGuiApplication::clipboard();
    clipboard->setText(content);
}

QString KnowledgeChatManager::getClipboardText()
{
    QClipboard* clipboard = QGuiApplication::clipboard();
    return clipboard->text();
}

qint64 KnowledgeChatManager::getFileSize(const QString& filePath)
{
    QFileInfo fileInfo(filePath);
    if (fileInfo.exists() && fileInfo.isFile()) {
        return fileInfo.size();
    }
    return -1;
}

QVariantMap KnowledgeChatManager::getFileInfo(const QString& filePath)
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

bool KnowledgeChatManager::isValidFileFormat(const QString& filePath)
{
    QFileInfo info(filePath);
    QString extension = info.suffix().toLower();
    return m_supportedFormats.contains(extension);
}

bool KnowledgeChatManager::isFileSizeValid(const QString& filePath)
{
    qint64 fileSize = getFileSize(filePath);
    if (fileSize == -1) {
        return true; // 无法获取大小时允许添加
    }
    return fileSize <= getmaxFileSize();
}

QString KnowledgeChatManager::formatFileSize(qint64 bytes)
{
    if (bytes <= 0) return "0 字节";

    const qint64 k = 1024;
    const QStringList sizes = { "字节", "KB", "MB", "GB" };
    int i = 0;

    double size = bytes;
    while (size >= k && i < sizes.size() - 1) {
        size /= k;
        i++;
    }

    if (i == 0) {
        return QString("%1%2").arg(static_cast<int>(size)).arg(sizes[i]);
    }
    else {
        return QString("%1%2").arg(size, 0, 'f', 1).arg(sizes[i]);
    }
}

QString KnowledgeChatManager::getFileName(const QString& filePath)
{
    QFileInfo info(filePath);
    return info.fileName();
}

QString KnowledgeChatManager::readFileContent(const QString& filePath)
{
    QFileInfo fileInfo(filePath);

    if (!fileInfo.exists() || !fileInfo.isFile()) {
        qDebug() << "[KnowledgeChatManager] File does not exist:" << filePath;
        return QString();
    }

    QString extension = fileInfo.suffix().toLower();

    // 根据文件类型选择读取方法
    if (extension == "txt") {
        // 读取纯文本文件
        QFile file(filePath);
        if (file.open(QIODevice::ReadOnly | QIODevice::Text)) {
            QTextStream stream(&file);
            stream.setCodec("UTF-8");
            QString content = stream.readAll();
            file.close();
            return content;
        }
        else {
            qDebug() << "[KnowledgeChatManager] Failed to open txt file:" << filePath;
            return QString();
        }
    }
    else if (extension == "docx") {
        return readDocxContent(filePath);
    }
    else if (extension == "doc") {
        return readDocContent(filePath);
    }
    else if (extension == "jpg" || extension == "jpeg" || extension == "png" ||
        extension == "bmp" || extension == "gif") {
        return QString("[图片文件: %1]").arg(fileInfo.fileName());
    }

    return QString(); // 不支持的格式
}


QString KnowledgeChatManager::readDocxContent(const QString& filePath)
{
    return readWordDocumentWithPowerShell(filePath, "DOCX文档: %1 - 内容读取需要Microsoft Word");
}

QString KnowledgeChatManager::readDocContent(const QString& filePath)
{
    return readWordDocumentWithPowerShell(filePath, "DOC文档: %1 - 内容读取需要Microsoft Word，建议转换为DOCX格式");
}

QString KnowledgeChatManager::readWordDocumentWithPowerShell(const QString& filePath, const QString& fallbackMessage)
{
    QFileInfo fileInfo(filePath);

    QString psScript = QString(
        "$word = New-Object -ComObject Word.Application; "
        "$word.Visible = $false; "
        "$doc = $word.Documents.Open(\"%1\"); "
        "$text = $doc.Content.Text; "
        "$doc.Close(); "
        "$word.Quit(); "
        "$text"
    ).arg(QString(filePath).replace("/", "\\"));

    QProcess process;
    process.start("powershell", QStringList() << "-Command" << psScript);
    process.waitForFinished(POWERSHELL_TIMEOUT);

    if (process.exitCode() == 0) {
        QString content = QString::fromUtf8(process.readAllStandardOutput()).trimmed();
        if (!content.isEmpty()) {
            return content;
        }
    }

    qDebug() << "[KnowledgeChatManager] PowerShell method failed for" << fileInfo.suffix();
    return QString("[%1]").arg(fallbackMessage.arg(fileInfo.fileName()));
}

QString KnowledgeChatManager::extractTextFromXml(const QString& xmlContent)
{
    QXmlStreamReader xml(xmlContent);
    QString text;

    while (!xml.atEnd()) {
        xml.readNext();
        if (xml.isCharacters()) {
            text += xml.text().toString();
        }
    }

    return text.simplified();
}


// FileReaderThread
FileReaderThread1::FileReaderThread1(const QString& filePath, const QString& fileName, QObject* parent)
    : QThread(parent), m_filePath(filePath), m_fileName(fileName)
{
}

void FileReaderThread1::run()
{
    QString content;
    bool success = false;
    QString errorMessage;

    try {
        QFileInfo fileInfo(m_filePath);

        // 验证文件存在性
        if (!fileInfo.exists() || !fileInfo.isFile()) {
            errorMessage = QString("文件不存在: %1").arg(m_fileName);
            emit readCompleted(m_filePath, content, success, errorMessage);
            return;
        }
        if (isInterruptionRequested()) {
            emit readCompleted(m_filePath, QString(), false, QString());
            return;
        }
        emitProgress(10);

        QString extension = fileInfo.suffix().toLower();

        // 根据文件类型读取
        if (extension == "txt") {
            content = readTextFile(m_filePath);
            success = !content.isNull();
        }
        else if (extension == "docx") {
            content = readDocxFile(m_filePath);
            success = !content.isEmpty();
        }
        else if (extension == "doc") {
            content = readDocFile(m_filePath);
            success = !content.isEmpty();
        }
        else if (extension == "jpg" || extension == "jpeg" || extension == "png" ||
            extension == "bmp" || extension == "gif") {
            content = readImageFile(m_filePath);
            success = true;
        }
        else {
            errorMessage = QString("不支持的文件格式: %1").arg(extension);
        }

        if (isInterruptionRequested()) {
            emit readCompleted(m_filePath, QString(), false, QString());
            return;
        }

        emitProgress(100);

        if (!success && errorMessage.isEmpty()) {
            errorMessage = QString("读取文件失败: %1").arg(m_fileName);
        }

    }
    catch (const std::exception& e) {
        errorMessage = QString("读取文件时发生异常: %1").arg(e.what());
    }
    catch (...) {
        errorMessage = QString("读取文件时发生未知错误: %1").arg(m_fileName);
    }

    emit readCompleted(m_filePath, content, success, errorMessage);
}

QString FileReaderThread1::readTextFile(const QString& filePath)
{
    emitProgress(30);
    if (isInterruptionRequested()) return QString();

    QFile file(filePath);
    if (!file.open(QIODevice::ReadOnly | QIODevice::Text)) {
        return QString();
    }

    emitProgress(50);

    QTextStream stream(&file);
    stream.setCodec("UTF-8");
    QString content = stream.readAll();
    file.close();

    emitProgress(90);
    return content;
}

QString FileReaderThread1::readDocxFile(const QString& filePath)
{
    return readWordFileWithProgress(filePath, "DOCX文档: %1 - 内容读取需要Microsoft Word");
}

QString FileReaderThread1::readDocFile(const QString& filePath)
{
    return readWordFileWithProgress(filePath, "DOC文档: %1 - 内容读取需要Microsoft Word，建议转换为DOCX格式");
}

QString FileReaderThread1::readWordFileWithProgress(const QString& filePath, const QString& fallbackMessage)
{
    emitProgress(30);
    if (isInterruptionRequested()) return QString();

    QFileInfo fileInfo(filePath);
    QString psScript = QString(
        "$word = New-Object -ComObject Word.Application; "
        "$word.Visible = $false; "
        "$doc = $word.Documents.Open(\"%1\"); "
        "$text = $doc.Content.Text; "
        "$doc.Close(); "
        "$word.Quit(); "
        "$text"
    ).arg(QString(filePath).replace("/", "\\"));

    emitProgress(60);

    QProcess process;
    process.start("powershell", QStringList() << "-Command" << psScript);

    int waited = 0;
    const int step = 100;
    while (!process.waitForFinished(step)) {
        waited += step;
        if (isInterruptionRequested()) {
            process.kill();
            process.waitForFinished(3000);
            return QString();
        }
        if (waited >= POWERSHELL_TIMEOUT) {
            break;
        }
    }

    emitProgress(90);

    if (process.exitCode() == 0) {
        QString content = QString::fromUtf8(process.readAllStandardOutput()).trimmed();
        if (!content.isEmpty()) {
            return content;
        }
    }

    return QString("[%1]").arg(fallbackMessage.arg(fileInfo.fileName()));
}

QString FileReaderThread1::readImageFile(const QString& filePath)
{
    emitProgress(50);

    QFileInfo fileInfo(filePath);

    emitProgress(90);

    return QString("[图片文件: %1]").arg(fileInfo.fileName());
}

void FileReaderThread1::emitProgress(int percentage)
{
    if (isInterruptionRequested()) return;
    emit progressChanged(percentage);

    if (percentage < 100) {
        msleep(PROGRESS_ANIMATION_DELAY);
    }
}

// KnowledgeChatManager
void KnowledgeChatManager::startFileReadTask(const QString& filePath, const QString& fileName)
{
    QMutexLocker locker(&m_mutex);

    // 清理已存在的相同任务
    if (m_activeReadTasks.contains(filePath)) {
        cleanupFileReadTask(filePath);
    }

    // 创建新的读取线程
    FileReaderThread1* thread = new FileReaderThread1(filePath, fileName, this);

    // 连接信号
    connect(thread, &FileReaderThread1::progressChanged,
        this, &KnowledgeChatManager::onFileReadProgress);
    connect(thread, &FileReaderThread1::readCompleted,
        this, &KnowledgeChatManager::onFileReadCompleted);
    connect(thread, &QThread::finished,
        thread, &QObject::deleteLater);

    // 注册任务
    m_activeReadTasks[filePath] = thread;

    // 标记上传状态
    setisUploading(true);

    // 初始化进度
    QVariantMap progressInfo = getfileReadProgress();
    QVariantMap fileProgress;
    fileProgress["percentage"] = 0;
    fileProgress["fileName"] = fileName;
    fileProgress["isReading"] = true;
    progressInfo[filePath] = fileProgress;
    setfileReadProgress(progressInfo);

    // 启动线程
    thread->start();

    qDebug() << "[KnowledgeChatManager] Started file read task for:" << fileName;
}

void KnowledgeChatManager::cleanupFileReadTask(const QString& filePath)
{
    // 先在锁内获取线程指针，避免持锁等待
    FileReaderThread1* thread = nullptr;
    {
        QMutexLocker locker(&m_mutex);
        if (m_activeReadTasks.contains(filePath)) {
            thread = m_activeReadTasks[filePath];
        }
    }

    // 在线程外部执行等待，避免发生互斥锁死锁
    if (thread) {
        thread->requestInterruption();
        // 不再调用 terminate，避免潜在死锁和资源泄漏
        if (!thread->wait(THREAD_WAIT_TIMEOUT)) {
            // 超时则尽量让线程自行退出
        }
    }

    bool noTasksRemaining = false;
    {
        QMutexLocker locker(&m_mutex);
        if (m_activeReadTasks.contains(filePath)) {
            m_activeReadTasks.remove(filePath);
        }
        // 清理进度信息
        QVariantMap progressInfo = getfileReadProgress();
        progressInfo.remove(filePath);
        setfileReadProgress(progressInfo);
        noTasksRemaining = m_activeReadTasks.isEmpty();
    }

    if (noTasksRemaining) {
        setisUploading(false);
    }
}

void KnowledgeChatManager::cleanupAllFileReadTasks()
{
    // 先复制任务列表，避免在持锁状态下递归锁
    QStringList filePaths;
    bool hasWordDocs = false;
    {
        QMutexLocker locker(&m_mutex);
        filePaths = m_activeReadTasks.keys();

        // 检查是否有Word文档在读取中
        for (const QString& filePath : filePaths) {
            QFileInfo fileInfo(filePath);
            QString extension = fileInfo.suffix().toLower();
            if (extension == "doc" || extension == "docx") {
                hasWordDocs = true;
                break;
            }
        }
    }

    for (const QString& fp : filePaths) {
        cleanupFileReadTask(fp);
    }

    setfileReadProgress(QVariantMap());
    setisUploading(false);

    // 如果有Word文档任务被清理，启动延迟Word进程清理
    if (hasWordDocs) {
        qDebug() << "[KnowledgeChatManager] Word document tasks were cleaned up, starting delayed Word process cleanup";
        startDelayedWordProcessCleanup();
    }
}

QString KnowledgeChatManager::getFileContent(const QString& filePath)
{
    QMutexLocker locker(&m_mutex);
    return m_fileContents.value(filePath, QString());
}

void KnowledgeChatManager::onFileReadProgress(int percentage)
{
    FileReaderThread1* senderThread = qobject_cast<FileReaderThread1*>(sender());
    if (!senderThread) return;

    // 查找对应的文件路径
    QString filePath;
    {
        QMutexLocker locker(&m_mutex);
        for (auto it = m_activeReadTasks.begin(); it != m_activeReadTasks.end(); ++it) {
            if (it.value() == senderThread) {
                filePath = it.key();
                break;
            }
        }
    }

    if (!filePath.isEmpty()) {
        // 更新进度
        QVariantMap progressInfo = getfileReadProgress();
        if (progressInfo.contains(filePath)) {
            QVariantMap fileProgress = progressInfo[filePath].toMap();
            fileProgress["percentage"] = percentage;
            progressInfo[filePath] = fileProgress;
            setfileReadProgress(progressInfo);
        }

        emit fileReadProgressChanged(filePath, percentage);
    }
}

void KnowledgeChatManager::onFileReadCompleted(const QString& filePath, const QString& content, bool success, const QString& errorMessage)
{
    {
        QMutexLocker locker(&m_mutex);

        // 存储文件内容（如果未被取消）
        if (success && !content.isEmpty()) {
            m_fileContents[filePath] = content;
            qDebug() << "[KnowledgeChatManager] File content stored for:" << filePath;
        }
        else {
            qDebug() << "[KnowledgeChatManager] File read finished with status:" << (success ? "success" : "failed") << filePath << errorMessage;
        }

        // 清理任务
        if (m_activeReadTasks.contains(filePath)) {
            m_activeReadTasks.remove(filePath);
        }
    }

    // 更新进度状态
    QVariantMap progressInfo = getfileReadProgress();
    if (progressInfo.contains(filePath)) {
        QVariantMap fileProgress = progressInfo[filePath].toMap();
        fileProgress["percentage"] = 100;
        fileProgress["isReading"] = false;
        fileProgress["success"] = success;
        if (!success) {
            fileProgress["errorMessage"] = errorMessage;
        }
        progressInfo[filePath] = fileProgress;
        setfileReadProgress(progressInfo);
    }

    // 发出完成信号
    emit fileReadCompleted(filePath, success);

    // 显示结果消息
    if (!success && !errorMessage.isEmpty()) {
        emit fileOperationResult(errorMessage, "error");
    }
    else if (success) {
        QString fileName = QFileInfo(filePath).fileName();
        emit fileOperationResult(QString("文件 %1 读取完成").arg(fileName), "success");
    }

    bool noTasksRemaining = false;
    {
        QMutexLocker locker(&m_mutex);
        noTasksRemaining = m_activeReadTasks.isEmpty();
    }
    if (noTasksRemaining) {
        setisUploading(false);
    }
}

void KnowledgeChatManager::startDelayedWordProcessCleanup()
{
    // 在后台线程中执行延迟清理
    QtConcurrent::run([this]() {
        // 延迟2秒后开始清理
        QThread::msleep(2000);

        // 执行多次清理确保所有进程都被清除
        for (int attempt = 1; attempt <= 3; ++attempt) {
            qDebug() << "[KnowledgeChatManager] Word cleanup attempt" << attempt << "of 3";

            int processCount = cleanupHangingWordProcesses();

            if (processCount == 0) {
                qDebug() << "[KnowledgeChatManager] No more Word processes to clean, stopping";
                break;
            }

            // 如果还有进程，等待1秒后再次尝试
            if (attempt < 3) {
                QThread::msleep(1000);
            }
        }

        qDebug() << "[KnowledgeChatManager] Delayed Word process cleanup completed";
        });
}

int KnowledgeChatManager::cleanupHangingWordProcesses()
{
    // 使用PowerShell查找并终止没有可见窗口的Word进程
    // 这些通常是COM自动化进程，不会影响用户正在使用的Word实例
    QProcess process;

    QString psScript =
        "try { "
        "$processCount = 0; "
        // 查找没有主窗口标题的Word进程（COM自动化进程）
        "Get-Process -Name WINWORD -ErrorAction SilentlyContinue | "
        "Where-Object { "
        "($_.MainWindowTitle -eq '' -or $_.MainWindowTitle -eq $null) -and "
        "$_.ProcessName -eq 'WINWORD' "
        "} | "
        "ForEach-Object { "
        "try { "
        "Write-Output \"Found hanging Word process: PID $($_.Id)\"; "
        "Stop-Process -Id $_.Id -Force; "
        "Write-Output \"Successfully terminated Word process: PID $($_.Id)\"; "
        "$processCount++; "
        "} catch { "
        "Write-Output \"Failed to terminate Word process: PID $($_.Id) - $($_.Exception.Message)\"; "
        "} "
        "}; "
        "Write-Output \"PROCESS_COUNT:$processCount\"; "
        "} catch { "
        "Write-Output \"Error during Word process cleanup: $($_.Exception.Message)\"; "
        "}";

    process.start("powershell", QStringList() << "-Command" << psScript);

    int cleanedProcessCount = 0;

    // 等待最多10秒完成清理
    if (process.waitForFinished(10000)) {
        QString output = QString::fromUtf8(process.readAllStandardOutput());
        QString errorOutput = QString::fromUtf8(process.readAllStandardError());

        if (!output.trimmed().isEmpty()) {
            qDebug() << "[KnowledgeChatManager] Word cleanup output:" << output;

            // 提取清理的进程数量
            QRegularExpression re("PROCESS_COUNT:(\\d+)");
            QRegularExpressionMatch match = re.match(output);
            if (match.hasMatch()) {
                cleanedProcessCount = match.captured(1).toInt();
            }
        }

        if (!errorOutput.trimmed().isEmpty()) {
            qDebug() << "[KnowledgeChatManager] Word cleanup errors:" << errorOutput;
        }

        if (process.exitCode() == 0) {
            qDebug() << "[KnowledgeChatManager] Word process cleanup completed successfully, cleaned" << cleanedProcessCount << "processes";
        }
        else {
            qDebug() << "[KnowledgeChatManager] Word process cleanup completed with exit code:" << process.exitCode();
        }
    }
    else {
        qDebug() << "[KnowledgeChatManager] Word process cleanup timed out";
        process.kill(); // 强制终止PowerShell进程
    }

    return cleanedProcessCount;
}

void KnowledgeChatManager::loadKnowledgeBaseList()
{
    auto* apiManager = GET_SINGLETON(ApiManager);
    apiManager->getKnowledgeBaseList();
    qDebug() << "[KnowledgeChatManager] Loading knowledge base list";
}

void KnowledgeChatManager::onKnowledgeBaseListResponse(bool success, const QString& message, const QJsonObject& data)
{
    qDebug() << "[KnowledgeChatManager] Knowledge base list response - success:" << success << "message:" << message;

    if (success && data.contains("records")) {
        QJsonArray records = data["records"].toArray();
        QVariantList knowledgeList;

        for (const QJsonValue& value : records) {
            QJsonObject kb = value.toObject();
            QVariantMap kbInfo;
            kbInfo["id"] = kb["id"].toString();
            kbInfo["name"] = kb["name"].toString();
            kbInfo["bucket"] = kb["bucket"].toString(); // 添加bucket字段
            kbInfo["description"] = kb["description"].toString();
            kbInfo["createTime"] = kb["createTime"].toString();
            kbInfo["updateTime"] = kb["updateTime"].toString();
            kbInfo["userId"] = kb["userId"].toString();
            kbInfo["selected"] = false; // 初始状态为未选中
            knowledgeList.append(kbInfo);
        }

        setknowledgeBaseList(knowledgeList);
        qDebug() << "[KnowledgeChatManager] Successfully loaded" << knowledgeList.size() << "knowledge bases";
    }
    else {
        qDebug() << "[KnowledgeChatManager] Failed to load knowledge base list:" << message;
        setknowledgeBaseList(QVariantList()); // 清空列表
    }
}

void KnowledgeChatManager::onStreamKnowledgeChatResponse(const QString& data, const QString& chatId)
{
    // 验证是否为当前会话
    if (chatId != m_currentChatId) {
        return;
    }

    if (m_currentAiMessage.isEmpty()) {
        // 第一次接收响应：移除思考状态
        setisThinking(false);
        removeThinkingMessage();
        addAiMessage(data);
        m_currentAiMessage = data;
    }
    else {
        // 追加响应内容
        m_currentAiMessage += data;
        updateLastAiMessage(data);
    }
}

void KnowledgeChatManager::onStreamKnowledgeChatFinished(bool success, const QString& message, const QString& chatId)
{
    // 验证是否为当前会话
    if (chatId != m_currentChatId) {
        return;
    }

    qDebug() << "[KnowledgeChatManager] Knowledge chat finished, success:" << success;

    // 重置状态
    setisSending(false);
    setisThinking(false);

    if (!success) {
        // 处理错误情况
        removeThinkingMessage();
        addAiMessage(QString("抱歉，发生了错误：%1").arg(message));
    }

    // 处理空响应
    if (m_currentAiMessage.isEmpty()) {
        removeThinkingMessage();
        addAiMessage("抱歉，我无法回复您的消息。");
    }

    m_currentAiMessage.clear();
}

QStringList KnowledgeChatManager::getSelectedBuckets() const
{
    QStringList selectedIds = getselectedKnowledgeBases();
    QStringList buckets;
    QVariantList knowledgeList = getknowledgeBaseList();

    // 根据选中的ID找到对应的bucket值
    for (const QString& selectedId : selectedIds) {
        for (const QVariant& item : knowledgeList) {
            QVariantMap kbMap = item.toMap();
            if (kbMap["id"].toString() == selectedId) {
                QString bucket = kbMap["bucket"].toString();
                if (!bucket.isEmpty()) {
                    buckets.append(bucket);
                }
                break;
            }
        }
    }
    return buckets;
}

void KnowledgeChatManager::onKnowledgeChatMetadataReceived(const QString& chatId, const QVariantList& retrievedMetadata)
{
    // 验证是否为当前会话
    if (chatId != m_currentChatId) {
        return;
    }

    // 存储检索到的元数据
    setretrievedMetadata(retrievedMetadata);

    qDebug() << "[KnowledgeChatManager] Retrieved metadata received for chat:" << chatId
        << "Items count:" << retrievedMetadata.size();

    // 打印详细元数据信息（调试用）
    for (int i = 0; i < retrievedMetadata.size(); ++i) {
        QVariantMap metaMap = retrievedMetadata[i].toMap();
        qDebug() << "  [" << i << "] File:" << metaMap["file_name"].toString()
            << "Pages:" << metaMap["page_numbers"].toList()
            << "Retriever:" << metaMap["retriever_name"].toString();
    }
}