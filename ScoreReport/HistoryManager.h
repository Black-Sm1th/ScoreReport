#ifndef HISTORYMANAGER_H
#define HISTORYMANAGER_H

#include <QObject>
#include <QString>
#include <QJsonObject>
#include <QJsonArray>
#include <QVariantList>
#include <QDateTime>
#include "CommonFunc.h"

class ApiManager;

// 历史记录数据类
class HistoryRecord : public QObject
{
    Q_OBJECT
        Q_PROPERTY(QString id READ getId CONSTANT)
        Q_PROPERTY(QString userId READ getUserId CONSTANT)
        Q_PROPERTY(QString type READ getType CONSTANT)
        Q_PROPERTY(QString title READ getTitle CONSTANT)
        Q_PROPERTY(QString chatId READ getChatId CONSTANT)
        Q_PROPERTY(QString content READ getContent CONSTANT)
        Q_PROPERTY(QString result READ getResult CONSTANT)
        Q_PROPERTY(QDateTime createTime READ getCreateTime CONSTANT)
        Q_PROPERTY(QDateTime updateTime READ getUpdateTime CONSTANT)
        Q_PROPERTY(int isDelete READ getIsDelete CONSTANT)

public:
    explicit HistoryRecord(QObject* parent = nullptr);
    explicit HistoryRecord(const QJsonObject& json, QObject* parent = nullptr);

    // Getter方法
    QString getId() const { return m_id; }
    QString getUserId() const { return m_userId; }
    QString getType() const { return m_type; }
    QString getTitle() const { return m_title; }
    QString getChatId() const { return m_chatId; }
    QString getContent() const { return m_content; }
    QString getResult() const { return m_result; }
    QDateTime getCreateTime() const { return m_createTime; }
    QDateTime getUpdateTime() const { return m_updateTime; }
    int getIsDelete() const { return m_isDelete; }

    // 转换为QVariantMap用于QML
    QVariantMap toVariantMap() const;

    // 从JSON对象创建
    static HistoryRecord* fromJson(const QJsonObject& json, QObject* parent = nullptr);

private:
    QString m_id;
    QString m_userId;
    QString m_type;
    QString m_title;
    QString m_chatId;
    QString m_content;
    QString m_result;
    QDateTime m_createTime;
    QDateTime m_updateTime;
    int m_isDelete;
};

// 历史记录管理类
class HistoryManager : public QObject
{
    Q_OBJECT
        QUICK_PROPERTY(QVariantList, historyList)
        QUICK_PROPERTY(bool, isLoading)
        QUICK_PROPERTY(int, totalCount)
        QUICK_PROPERTY(int, currentPage)
        QUICK_PROPERTY(int, pageSize)
        SINGLETON_CLASS(HistoryManager)

public slots:
    // QML调用的方法
    Q_INVOKABLE void updateList();
    Q_INVOKABLE void loadMore();
    Q_INVOKABLE void refresh();
    Q_INVOKABLE void clearHistory();
    Q_INVOKABLE void copyToClipboard(const QString& content);
    Q_INVOKABLE HistoryRecord* getRecordById(const QString& id);

signals:
    void updateCompleted(bool success, const QString& message);
    void historyCleared();

private slots:
    void onHistoryResponse(bool success, const QString& message, const QJsonObject& data);

private:
    ApiManager* m_apiManager;
    QList<HistoryRecord*> m_records;

    // 更新QML可访问的历史记录列表
    void updateHistoryList();

    // 清理内存中的记录
    void clearRecords();

    // 解析服务器响应的历史记录数据
    void parseHistoryData(const QJsonObject& data);
};

#endif // HISTORYMANAGER_H 