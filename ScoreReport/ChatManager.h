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
class FileReaderThread : public QThread
{
    Q_OBJECT

public:
    explicit FileReaderThread(const QString& filePath, const QString& fileName, QObject* parent = nullptr);

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
    QString readImageFile(const QString& filePath);
    void emitProgress(int percentage);
};

/**
 * @brief 聊天管理器类 - 负责处理聊天功能
 *
 * 提供聊天消息管理和API调用功能，支持多实例
 */
class ChatManager : public QObject
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

public:
    explicit ChatManager(QObject* parent = nullptr);

public:
    /**
     * @brief 发送消息
     * @param message 要发送的消息内容
     */
    Q_INVOKABLE void sendMessage(const QString& message);
    
    /**
     * @brief 重置聊天并添加欢迎消息
     */
    Q_INVOKABLE void resetWithWelcomeMessage();
    
    /**
     * @brief 再次生成最后一条AI回复
     */
    Q_INVOKABLE void regenerateLastResponse();

    Q_INVOKABLE void copyToClipboard(const QString& content);
    Q_INVOKABLE QString getClipboardText();
    Q_INVOKABLE qint64 getFileSize(const QString& filePath);
    Q_INVOKABLE void endAnalysis(bool clearfile);

    /**
     * @brief 添加文件到列表
     * @param filePath 文件路径
     * @return 是否添加成功
     */
    Q_INVOKABLE bool addFile(const QString& filePath);

    
    /**
     * @brief 从列表中移除文件
     * @param index 文件索引
     * @return 是否移除成功
     */
    Q_INVOKABLE bool removeFile(int index);
    
    /**
     * @brief 清空文件列表
     */
    Q_INVOKABLE void clearFiles();
    
    /**
     * @brief 获取文件信息
     * @param filePath 文件路径
     * @return 文件信息对象
     */
    Q_INVOKABLE QVariantMap getFileInfo(const QString& filePath);
    
    /**
     * @brief 验证文件格式是否支持
     * @param filePath 文件路径
     * @return 是否支持
     */
    Q_INVOKABLE bool isValidFileFormat(const QString& filePath);
    
    /**
     * @brief 验证文件大小是否有效
     * @param filePath 文件路径
     * @return 是否有效
     */
    Q_INVOKABLE bool isFileSizeValid(const QString& filePath);
    
    /**
     * @brief 格式化文件大小
     * @param bytes 字节数
     * @return 格式化后的字符串
     */
    Q_INVOKABLE QString formatFileSize(qint64 bytes);
    
    /**
     * @brief 获取文件名（不含路径）
     * @param filePath 文件路径
     * @return 文件名
     */
    Q_INVOKABLE QString getFileName(const QString& filePath);
    
    /**
     * @brief 批量添加文件
     * @param filePaths 文件路径列表
     * @return 成功添加的文件数量
     */
    Q_INVOKABLE int addFiles(const QStringList& filePaths);

    /**
     * @brief 读取文件内容
     * @param filePath 文件路径
     * @return 文件文本内容，如果读取失败返回空字符串
     */
    Q_INVOKABLE QString readFileContent(const QString& filePath);

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
     * @brief 添加思考中消息
     */
    void addThinkingMessage();

    /**
     * @brief 移除思考中消息
     */
    void removeThinkingMessage();
    
    /**
     * @brief 更新最后一条AI消息
     * @param additionalText 要追加的文本
     */
    void updateLastAiMessage(const QString& additionalText);
    
    /**
     * @brief 添加文件到列表（内部重载）
     * @param filePath 文件路径
     * @param showMessage 是否显示操作消息
     * @return 是否添加成功
     */
    bool addFile(const QString& filePath, bool showMessage);

    /// @brief 当前正在接收的AI消息内容
    QString m_currentAiMessage;
    
    /// @brief 支持的文件格式列表
    QStringList m_supportedFormats;
    
    /// @brief 文件内容存储映射 (文件路径 -> 文件内容)
    QMap<QString, QString> m_fileContents;
    
    /// @brief 当前正在进行的文件读取线程映射 (文件路径 -> 线程指针)
    QMap<QString, FileReaderThread*> m_activeReadTasks;
    
    /// @brief 线程安全互斥锁
    QMutex m_mutex;
    
    /**
     * @brief 读取DOCX文件内容
     * @param filePath 文件路径
     * @return 文档文本内容
     */
    QString readDocxContent(QString filePath);
    
    /**
     * @brief 读取DOC文件内容
     * @param filePath 文件路径
     * @return 文档文本内容
     */
    QString readDocContent(QString filePath);
    
    /**
     * @brief 从XML中提取文本内容
     * @param xmlContent XML内容
     * @return 提取的文本
     */
    QString extractTextFromXml(const QString& xmlContent);
    
    /**
     * @brief 启动文件读取任务
     * @param filePath 文件路径
     * @param fileName 文件名
     */
    void startFileReadTask(const QString& filePath, const QString& fileName);
    
    /**
     * @brief 清理文件读取任务
     * @param filePath 文件路径
     */
    void cleanupFileReadTask(const QString& filePath);
    
    /**
     * @brief 清理所有文件读取任务
     */
    void cleanupAllFileReadTasks();
    
    /**
     * @brief 获取文件已读取的内容
     * @param filePath 文件路径
     * @return 文件内容，如果未读取则返回空字符串
     */
    QString getFileContent(const QString& filePath);
};

