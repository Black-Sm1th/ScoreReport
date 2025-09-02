#pragma once

#include <QObject>
#include <QString>
#include <QVariantList>
#include <QJsonObject>
#include "CommonFunc.h"

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
    Q_INVOKABLE void endAnalysis();

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

signals:
    /**
     * @brief 文件操作结果信号
     * @param success 是否成功
     * @param message 操作消息
     * @param type 消息类型：success, warning, error, info
     */
    void fileOperationResult(const QString& message, const QString& type);

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
};

