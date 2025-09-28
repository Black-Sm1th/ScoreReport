#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QJsonObject>
#include <QThread>
#include <QMutex>
#include "CommonFunc.h"

/**
 * @brief 文件读取线程类 - 在后台线程中读取文件内容
 */
class FileReaderThread1 : public QThread
{
    Q_OBJECT

public:
    explicit FileReaderThread1(const QString& filePath, const QString& fileName, QObject* parent = nullptr);

protected:
    void run() override;

signals:
    void progressChanged(int percentage);
    void readCompleted(const QString& filePath, const QString& content, bool success, const QString& errorMessage);

private:
    QString m_filePath;
    QString m_fileName;
    
    QString readTextFile(const QString& filePath);
    QString readDocxFile(const QString& filePath);
    QString readDocFile(const QString& filePath);
    QString readWordFileWithProgress(const QString& filePath, const QString& fallbackMessage);
    QString readImageFile(const QString& filePath);
    void emitProgress(int percentage);
};

/**
 * @brief 聊天管理器类 - 负责处理聊天功能
 *
 * 提供聊天消息管理和API调用功能，支持多实例
 */
class KnowledgeChatManager : public QObject
{
    Q_OBJECT

    /// @brief 消息列表，供QML绑定
    QUICK_PROPERTY(QVariantList, messages)

    /// @brief 是否正在发送消息
    QUICK_PROPERTY(bool, isSending)

    /// @brief 是否显示思考中状态
    QUICK_PROPERTY(bool, isThinking)

    /// @brief 是否有文件正在上传（读取中）
    QUICK_PROPERTY(bool, isUploading)

    /// @brief 当前聊天ID
    QUICK_PROPERTY(QString, currentChatId)

    /// @brief 最后一条用户消息
    QUICK_PROPERTY(QString, lastUserMessage)

    /// @brief 上传的文件列表
    QUICK_PROPERTY(QVariantList, files)

    /// @brief 最大文件数量
    QUICK_PROPERTY(int, maxFileCount)

    /// @brief 最大文件大小（字节）
    QUICK_PROPERTY(qint64, maxFileSize)
    
    /// @brief 文件读取进度信息
    QUICK_PROPERTY(QVariantMap, fileReadProgress)
    
    /// @brief 知识库列表
    QUICK_PROPERTY(QVariantList, knowledgeBaseList)
    
    /// @brief 选中的知识库ID列表
    QUICK_PROPERTY(QStringList, selectedKnowledgeBases)
    
    /// @brief 检索到的元数据列表
    QUICK_PROPERTY(QVariantList, retrievedMetadata)

public:
    explicit KnowledgeChatManager(QObject* parent = nullptr);

    // QML调用的方法
    Q_INVOKABLE void sendMessage(const QString& message);
    Q_INVOKABLE void resetWithWelcomeMessage();
    Q_INVOKABLE void regenerateLastResponse();
    Q_INVOKABLE void endAnalysis(bool clearfile);
    Q_INVOKABLE void copyToClipboard(const QString& content);
    Q_INVOKABLE QString getClipboardText();
    Q_INVOKABLE bool addFile(const QString& filePath);
    Q_INVOKABLE int addFiles(const QStringList& filePaths);
    Q_INVOKABLE bool removeFile(int index);
    Q_INVOKABLE void clearFiles();
    Q_INVOKABLE void loadKnowledgeBaseList();

    // 内部使用的私有方法
    QStringList getSelectedBuckets() const;

    // 内部使用的公有方法（不需要QML调用）
    qint64 getFileSize(const QString& filePath);
    QVariantMap getFileInfo(const QString& filePath);
    bool isValidFileFormat(const QString& filePath);
    bool isFileSizeValid(const QString& filePath);
    QString formatFileSize(qint64 bytes);
    QString getFileName(const QString& filePath);
    QString readFileContent(const QString& filePath);

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
    
    /**
     * @brief 处理文件读取进度变化
     * @param percentage 进度百分比
     */
    void onFileReadProgress(int percentage);
    
    /**
     * @brief 处理文件读取完成
     * @param filePath 文件路径
     * @param content 文件内容
     * @param success 是否成功
     * @param errorMessage 错误信息
     */
    void onFileReadCompleted(const QString& filePath, const QString& content, bool success, const QString& errorMessage);
    
    /**
     * @brief 处理获取知识库列表响应
     * @param success 是否成功
     * @param message 响应消息
     * @param data 知识库列表数据
     */
    void onKnowledgeBaseListResponse(bool success, const QString& message, const QJsonObject& data);
    
    /**
     * @brief 处理知识库流式聊天响应
     * @param data 接收到的数据块
     * @param chatId 会话ID
     */
    void onStreamKnowledgeChatResponse(const QString& data, const QString& chatId);
    
    /**
     * @brief 处理知识库流式聊天完成
     * @param success 是否成功
     * @param message 完成消息
     * @param chatId 会话ID
     */
    void onStreamKnowledgeChatFinished(bool success, const QString& message, const QString& chatId);
    
    /**
     * @brief 处理知识库聊天元数据接收
     * @param chatId 会话ID
     * @param retrievedMetadata 检索到的元数据列表
     */
    void onKnowledgeChatMetadataReceived(const QString& chatId, const QVariantList& retrievedMetadata);

signals:
    /**
     * @brief 文件操作结果信号
     * @param success 是否成功
     * @param message 操作消息
     * @param type 消息类型：success, warning, error, info
     */
    void fileOperationResult(const QString& message, const QString& type);
    
    /**
     * @brief 文件读取进度变化信号
     * @param filePath 文件路径
     * @param percentage 进度百分比
     */
    void fileReadProgressChanged(const QString& filePath, int percentage);
    
    /**
     * @brief 文件读取完成信号
     * @param filePath 文件路径
     * @param success 是否成功
     */
    void fileReadCompleted(const QString& filePath, bool success);

private:
    // 消息管理私有方法
    void addUserMessage(const QString& message);
    void addAiMessage(const QString& message);
    void addThinkingMessage();
    void removeThinkingMessage();
    void updateLastAiMessage(const QString& additionalText);
    QString buildMessageWithFiles(const QString& userMessage, const QVariantList& files);
    
    // 文件管理私有方法
    bool addFile(const QString& filePath, bool showMessage);
    QString validateFileForAdding(const QString& filePath, const QString& fileName);
    void startFileReadTask(const QString& filePath, const QString& fileName);
    void cleanupFileReadTask(const QString& filePath);
    void cleanupAllFileReadTasks();
    QString getFileContent(const QString& filePath);
    
    // 文件读取私有方法
    QString readDocxContent(const QString& filePath);
    QString readDocContent(const QString& filePath);
    QString readWordDocumentWithPowerShell(const QString& filePath, const QString& fallbackMessage);
    QString extractTextFromXml(const QString& xmlContent);
    
    // Word进程管理私有方法
    int cleanupHangingWordProcesses();
    void startDelayedWordProcessCleanup();

    // 私有成员变量
    QString m_currentAiMessage;                                 ///< 当前正在接收的AI消息内容
    QStringList m_supportedFormats;                             ///< 支持的文件格式列表
    QMap<QString, QString> m_fileContents;                      ///< 文件内容存储映射
    QMap<QString, FileReaderThread1*> m_activeReadTasks;         ///< 当前进行的文件读取线程映射
    QMutex m_mutex;                                             ///< 线程安全互斥锁
};

