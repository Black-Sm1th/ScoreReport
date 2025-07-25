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

    // 解析时间字符串
    QString createTimeStr = json.value("createTime").toString();
    QString updateTimeStr = json.value("updateTime").toString();

    m_createTime = QDateTime::fromString(createTimeStr, Qt::ISODate);
    m_updateTime = QDateTime::fromString(updateTimeStr, Qt::ISODate);
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
    settotalCount(0);
    setcurrentPage(1);
    setpageSize(500);
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
        emit updateCompleted(false, "ApiManager not available");
        return;
    }

    if (getisLoading()) {
        qDebug() << "[HistoryManager] Already loading, skip request";
        return;
    }

    setisLoading(true);
    setcurrentPage(1);

    // 调用API获取历史记录
    m_apiManager->getQualityList("", "", "", "", "", getcurrentPage(), getpageSize());
}

void HistoryManager::loadMore()
{
    if (!m_apiManager) {
        qWarning() << "[HistoryManager] ApiManager is null!";
        return;
    }

    if (getisLoading()) {
        qDebug() << "[HistoryManager] Already loading, skip request";
        return;
    }

    // 检查是否还有更多数据
    int totalPages = (gettotalCount() + getpageSize() - 1) / getpageSize();
    if (getcurrentPage() >= totalPages) {
        qDebug() << "[HistoryManager] No more data to load";
        return;
    }

    setisLoading(true);
    setcurrentPage(getcurrentPage() + 1);

    // 调用API获取下一页数据
    m_apiManager->getQualityList("", "", "", "", "", getcurrentPage(), getpageSize());
}

void HistoryManager::refresh()
{
    // 清空当前数据并重新加载
    clearRecords();
    updateList();
}

void HistoryManager::clearHistory()
{
    clearRecords();
    settotalCount(0);
    setcurrentPage(1);
    updateHistoryList();
    emit historyCleared();
}

void HistoryManager::copyToClipboard(const QString& content)
{
    QClipboard* clipboard = QGuiApplication::clipboard();
    clipboard->setText(content);
}

HistoryRecord* HistoryManager::getRecordById(const QString& id)
{
    for (HistoryRecord* record : m_records) {
        if (record && record->getId() == id) {
            return record;
        }
    }
    return nullptr;
}



void HistoryManager::onHistoryResponse(bool success, const QString& message, const QJsonObject& data)
{
    setisLoading(false);

    if (success) {
        // 如果是第一页，清空现有数据
        if (getcurrentPage() == 1) {
            clearRecords();
        }

        parseHistoryData(data);
        updateHistoryList();

        qDebug() << "[HistoryManager] History loaded successfully. Total records:" << m_records.size();
    }
    else {
        qWarning() << "[HistoryManager] Failed to load history:" << message;
    }

    emit updateCompleted(success, message);
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

void HistoryManager::clearRecords()
{
    // 清理内存中的记录对象
    for (HistoryRecord* record : m_records) {
        if (record) {
            record->deleteLater();
        }
    }
    m_records.clear();
}

void HistoryManager::parseHistoryData(const QJsonObject& data)
{
    // 解析分页信息
    settotalCount(data.value("total").toString().toInt());
    setcurrentPage(data.value("current").toString().toInt());
    setpageSize(data.value("size").toString().toInt());

    // 解析记录列表
    QJsonArray records = data.value("records").toArray();
    for (const QJsonValue& value : records) {
        QJsonObject recordObj = value.toObject();
        HistoryRecord* record = HistoryRecord::fromJson(recordObj, this);
        if (record) {
            m_records.append(record);
        }
    }

    qDebug() << "[HistoryManager] Parsed" << records.size() << "records. Total count:" << gettotalCount();
}