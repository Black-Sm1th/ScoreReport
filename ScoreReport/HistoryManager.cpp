#include "HistoryManager.h"
#include "ApiManager.h"
#include <QJsonDocument>
#include <QVariantMap>
#include <QClipboard>
#include <QGuiApplication>
// HistoryRecord实现
HistoryRecord::HistoryRecord(QObject* parent)
    : QObject(parent)
    , m_isDelete(0)
{
}

HistoryRecord::HistoryRecord(const QJsonObject& json, QObject* parent)
    : QObject(parent)
{
    m_id = json.value("id").toString();
    m_userId = json.value("userId").toString();
    m_type = json.value("type").toString();
    m_title = json.value("title").toString();
    m_chatId = json.value("chatId").toString();
    m_content = json.value("content").toString();
    m_result = json.value("result").toString();
    m_isDelete = json.value("isDelete").toInt();

    // 解析时间字符串 - 服务器返回的是东八区时间格式 "yyyy-MM-DD hh:mm:ss"
    QString createTimeStr = json.value("createTime").toString();
    QString updateTimeStr = json.value("updateTime").toString();

    m_createTime = QDateTime::fromString(createTimeStr, "yyyy-MM-dd HH:mm:ss");
    m_updateTime = QDateTime::fromString(updateTimeStr, "yyyy-MM-dd HH:mm:ss");
}

QVariantMap HistoryRecord::toVariantMap() const
{
    QVariantMap map;
    map["id"] = m_id;
    map["userId"] = m_userId;
    map["type"] = m_type;
    map["title"] = m_title;
    map["chatId"] = m_chatId;
    map["content"] = m_content;
    map["result"] = m_result;
    map["createTime"] = m_createTime.toString(Qt::ISODate);
    map["updateTime"] = m_updateTime.toString(Qt::ISODate);
    map["isDelete"] = m_isDelete;
    return map;
}

HistoryRecord* HistoryRecord::fromJson(const QJsonObject& json, QObject* parent)
{
    return new HistoryRecord(json, parent);
}

// HistoryManager实现
HistoryManager::HistoryManager(QObject* parent)
    : QObject(parent)
    , m_apiManager(nullptr)
{
    // 初始化属性
    setisLoading(false);
    setsearchText("");
    setsearchType("");
    setsearchDate("");
    sethistoryList(QVariantList());

    // 获取ApiManager单例并连接信号
    m_apiManager = GET_SINGLETON(ApiManager);
    if (m_apiManager) {
        connect(m_apiManager, &ApiManager::getQualityListResponse,
            this, &HistoryManager::onHistoryResponse);
    }
    else {
        qWarning() << "[HistoryManager] Failed to get ApiManager instance!";
    }
}

void HistoryManager::updateList()
{
    if (!m_apiManager) {
        qWarning() << "[HistoryManager] ApiManager is null!";
        return;
    }

    if (getisLoading()) {
        qDebug() << "[HistoryManager] Already loading, skip request";
        return;
    }

    setisLoading(true);

    // 调用API获取历史记录，使用固定的分页参数
    m_apiManager->getQualityList(getsearchType(), "", "", getsearchText(), getsearchDate(), 1, 500);
}

void HistoryManager::copyToClipboard(const QString& content)
{
    QClipboard* clipboard = QGuiApplication::clipboard();
    clipboard->setText(content);
}

void HistoryManager::onHistoryResponse(bool success, const QString& message, const QJsonObject& data)
{
    setisLoading(false);

    if (success) {
        // 清空现有数据
        for (HistoryRecord* record : m_records) {
            if (record) {
                record->deleteLater();
            }
        }
        m_records.clear();

        parseHistoryData(data);
        updateHistoryList();

        qDebug() << "[HistoryManager] History loaded successfully. Total records:" << m_records.size();
    }
    else {
        qWarning() << "[HistoryManager] Failed to load history:" << message;
    }
}

void HistoryManager::updateHistoryList()
{
    QVariantList list;
    for (HistoryRecord* record : m_records) {
        if (record) {
            list.append(record->toVariantMap());
        }
    }
    sethistoryList(list);
}

void HistoryManager::parseHistoryData(const QJsonObject& data)
{
    // 解析记录列表
    QJsonArray records = data.value("records").toArray();
    for (const QJsonValue& value : records) {
        QJsonObject recordObj = value.toObject();
        HistoryRecord* record = HistoryRecord::fromJson(recordObj, this);
        if (record) {
            m_records.append(record);
        }
    }

    qDebug() << "[HistoryManager] Parsed" << records.size() << "records.";
}