#include "ReportManager.h"
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QDebug>

ReportManager::ReportManager(QObject *parent)
    : QObject(parent) 
{
    settemplateList(QVariantList());
    m_apiManager = GET_SINGLETON(ApiManager);
    QObject::connect(m_apiManager, &ApiManager::getReportTemplateListResponse, this, &ReportManager::onGetReportTemplateListResponse);
}

void ReportManager::refreshTemplate()
{
    m_apiManager->getReportTemplateList();
}

void ReportManager::onGetReportTemplateListResponse(bool success, const QString& message, const QJsonObject& data) 
{
    if (!success) {
        qWarning() << "[ReportManager] 获取模板列表失败:" << message;
        return;
    }
    
    // 清空现有的模板列表
    QVariantList newTemplateList;
    
    // 检查data是否为数组，或者包含data数组字段
    QJsonArray templateArray;
    if (data.contains("data") && data["data"].isArray()) {
        // 如果data对象包含"data"数组字段
        templateArray = data["data"].toArray();
    } else {
        // 如果data本身就是数组，需要从原始响应中获取
        // 这里我们需要重新处理，因为ApiManager传递的data可能不正确
        qDebug() << "[ReportManager] data字段结构:" << data;
        return;
    }
    
    if (!templateArray.isEmpty()) {
        
        for (const QJsonValue& value : templateArray) {
            if (value.isObject()) {
                QJsonObject templateItem = value.toObject();
                
                // 提取id和template字段
                QString id = templateItem.value("id").toString();
                QString templateJsonString = templateItem.value("template").toString();
                
                // 解析template字段中的JSON字符串
                QJsonParseError parseError;
                QJsonDocument templateDoc = QJsonDocument::fromJson(templateJsonString.toUtf8(), &parseError);
                
                if (parseError.error == QJsonParseError::NoError && templateDoc.isObject()) {
                    QJsonObject templateContent = templateDoc.object();
                    
                    // 构建最终的数据结构
                    QVariantMap templateMap;
                    templateMap["id"] = id;
                    
                    // 将template内容转换为QVariantMap
                    QVariantMap templateContentMap;
                    for (auto it = templateContent.begin(); it != templateContent.end(); ++it) {
                        templateContentMap[it.key()] = it.value().toString();
                    }
                    templateMap["template"] = templateContentMap;
                    
                    // 添加到列表中
                    newTemplateList.append(templateMap);
                } else {
                    qWarning() << "[ReportManager] 解析模板JSON失败:" << parseError.errorString();
                }
            }
        }
    }
    
    // 更新属性
    settemplateList(newTemplateList);
}
