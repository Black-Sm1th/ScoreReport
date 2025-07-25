#include "HistoryRecord.h"

HistoryRecord::HistoryRecord(QObject* parent)
    : QObject(parent)
{
    m_apiManager = GET_SINGLETON(ApiManager);
    QObject::connect(m_apiManager, &ApiManager::getQualityListResponse, this, &HistoryRecord::getQualityListResponse);
}

void HistoryRecord::updateList()
{
    m_apiManager->getQualityList();
}

void HistoryRecord::getQualityListResponse(bool success, const QString& message, const QJsonObject& data) {
    qDebug() << data;
    
}
