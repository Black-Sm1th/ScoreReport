#pragma once
#include <QObject>
#include <QString>
#include <QVariantList>
#include <QJsonObject>
#include <QThread>
#include <QMutex>
#include "CommonFunc.h"

class DiagnosisResultManager : public QObject
{
    Q_OBJECT
        SINGLETON_CLASS(DiagnosisResultManager)
        QUICK_PROPERTY(QString, originalMessages)

        QUICK_PROPERTY(QString, responseMessages)

        /// @brief 是否正在发送消息
        QUICK_PROPERTY(bool, isSending)

        /// @brief 当前聊天ID
        QUICK_PROPERTY(QString, currentChatId)

public:
    // QML调用的方法
    Q_INVOKABLE void sendMessage(const QString& message);
    Q_INVOKABLE void endAnalysis();
    Q_INVOKABLE void copyToClipboard(int index);

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
    void rollToBottom();
private:
    QString m_resultText;
    QString m_allText;
    QString m_promptMessage;
};

