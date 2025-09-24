#include "ReportManager.h"
#include <QJsonDocument>
#include <QJsonArray>
#include <QJsonObject>
#include <QDebug>
#include <QClipboard>
#include <QGuiApplication>
ReportManager::ReportManager(QObject *parent)
    : QObject(parent) 
{
    settemplateList(QVariantList());
    setresultList(QVariantList());
    m_apiManager = GET_SINGLETON(ApiManager);
    m_languageManager = GET_SINGLETON(LanguageManager);
    QObject::connect(m_apiManager, &ApiManager::getReportTemplateListResponse, this, &ReportManager::onGetReportTemplateListResponse);
    QObject::connect(m_apiManager, &ApiManager::saveReportTemplateResponse, this, &ReportManager::onSaveReportTemplateResponse);
    QObject::connect(m_apiManager, &ApiManager::deleteReportTemplateResponse, this, &ReportManager::onDeleteReportTemplateResponse);
    QObject::connect(m_apiManager, &ApiManager::generateQualityReportResponse, this, &ReportManager::onGenerateQualityReportResponse);
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
                QString templateName = templateItem.value("templateName").toString();
                // 解析template字段中的JSON字符串
                QJsonParseError parseError;
                QJsonDocument templateDoc = QJsonDocument::fromJson(templateJsonString.toUtf8(), &parseError);
                
                if (parseError.error == QJsonParseError::NoError) {
                    // 构建最终的数据结构
                    QVariantMap templateMap;
                    templateMap["id"] = id;
                    
                    // 支持新的JSON数组格式和旧的JSON对象格式
                    QVariantList templateContentList;
                    
                    if (templateDoc.isArray()) {
                        // 新格式：JSON数组，保持顺序
                        QJsonArray templateArray = templateDoc.array();
                        for (const QJsonValue& fieldValue : templateArray) {
                            if (fieldValue.isObject()) {
                                QJsonObject fieldObj = fieldValue.toObject();
                                QVariantMap fieldMap;
                                fieldMap["key"] = fieldObj.value("key").toString();
                                fieldMap["value"] = fieldObj.value("value").toString();
                                templateContentList.append(fieldMap);
                            }
                        }
                    } else if (templateDoc.isObject()) {
                        // 旧格式：JSON对象，为了向后兼容
                        QJsonObject templateContent = templateDoc.object();
                        for (auto it = templateContent.begin(); it != templateContent.end(); ++it) {
                            QVariantMap fieldMap;
                            fieldMap["key"] = it.key();
                            fieldMap["value"] = it.value().toString();
                            templateContentList.append(fieldMap);
                        }
                    }
                    
                    templateMap["template"] = templateContentList;
                    templateMap["templateName"] = templateName;
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
    emit templateListChanged();
}

void ReportManager::saveTemplate(const QString& templateId, const QString& templateName, const QVariantList& templateData)
{
    // 验证模板名称不能为空
    if (templateName.trimmed().isEmpty()) {
        qWarning() << "[ReportManager] 模板名称不能为空";
        emit templateSaveResult(false, "模板名称不能为空");
        return;
    }
    
    // 将QVariantList转换为JSON数组以保持字段顺序
    QJsonArray templateArray;
    
    for (const QVariant& item : templateData) {
        QVariantMap itemMap = item.toMap();
        QString key = itemMap.value("key").toString();
        QString value = itemMap.value("value").toString();
        
        if (!key.isEmpty()) {
            QJsonObject fieldObject;
            fieldObject["key"] = key;
            fieldObject["value"] = value;
            templateArray.append(fieldObject);
        }
    }
    
    // 将JSON数组转换为字符串
    QJsonDocument templateDoc(templateArray);
    QString templateContent = templateDoc.toJson(QJsonDocument::Compact);
    // 调用ApiManager的保存方法
    m_apiManager->saveReportTemplate(templateContent, templateName, templateId);
}

void ReportManager::onSaveReportTemplateResponse(bool success, const QString& message, const QJsonObject& data)
{
    if (success) {
        // 保存成功后刷新模板列表
        refreshTemplate();
        emit templateSaveResult(true, "模板保存成功");
    } else {
        qWarning() << "[ReportManager] 模板保存失败:" << message;
        emit templateSaveResult(false, message.isEmpty() ? "模板保存失败" : message);
    }
}

void ReportManager::deleteTemplate(const QString& templateId)
{
    if (templateId.isEmpty()) {
        qWarning() << "[ReportManager] 模板ID为空，无法删除";
        emit templateDeleteResult(false, "模板ID无效");
        return;
    }
    // 调用ApiManager的删除方法
    m_apiManager->deleteReportTemplate(templateId);
}

void ReportManager::onDeleteReportTemplateResponse(bool success, const QString& message, const QJsonObject& data)
{
    if (success) {
        // 删除成功后刷新模板列表
        refreshTemplate();
        emit templateDeleteResult(true, "模板删除成功");
    } else {
        qWarning() << "[ReportManager] 模板删除失败:" << message;
        emit templateDeleteResult(false, message.isEmpty() ? "模板删除失败" : message);
    }
}

void ReportManager::generateReport(const QString& query, const QVariantList& templateData)
{   
    // 为了API兼容性，发送JSON对象格式，但记录字段顺序
    QJsonObject templateObject;
    m_fieldOrder.clear(); // 清空之前的字段顺序
    
    for (const QVariant& item : templateData) {
        QVariantMap itemMap = item.toMap();
        QString key = itemMap.value("key").toString();
        QString value = itemMap.value("value").toString();
        
        if (!key.isEmpty()) {
            templateObject[key] = value;
            m_fieldOrder.append(key); // 记录字段顺序
        }
    }
    
    // 将JSON对象转换为字符串（保持API兼容性）
    QJsonDocument templateDoc(templateObject);
    QString templateContent = templateDoc.toJson(QJsonDocument::Compact);
    
    // 调用ApiManager的生成报告方法
    m_apiManager->generateQualityReport(query, templateContent, m_languageManager->currentLanguage());
}

void ReportManager::endAnalysis() {
    m_apiManager->abortRequestsByType("generate-quality-report");
}

void ReportManager::onGenerateQualityReportResponse(bool success, const QString& message, const QJsonObject& data)
{
    if (success) {     
        // 检查是否包含report字段
        if (data.contains("report")) {
            QJsonValue reportValue = data["report"];
            
            // 首先收集所有字段数据到临时Map中
            QVariantMap tempReportMap;
            
            if (reportValue.isObject()) {
                // JSON对象格式
                QJsonObject reportObj = reportValue.toObject();
                for (auto it = reportObj.begin(); it != reportObj.end(); ++it) {
                    tempReportMap[it.key()] = it.value().toVariant();
                }
            } else if (reportValue.isString()) {
                // JSON字符串格式
                QString reportString = reportValue.toString();
                QJsonParseError parseError;
                QJsonDocument reportDoc = QJsonDocument::fromJson(reportString.toUtf8(), &parseError);
                
                if (parseError.error == QJsonParseError::NoError && reportDoc.isObject()) {
                    QJsonObject reportObj = reportDoc.object();
                    for (auto it = reportObj.begin(); it != reportObj.end(); ++it) {
                        tempReportMap[it.key()] = it.value().toVariant();
                    }
                } else {
                    qWarning() << "[ReportManager] 解析report JSON字符串失败:" << parseError.errorString();
                }
            }
            
            // 根据记录的字段顺序重新排列结果
            QVariantList reportList;
            for (const QString& key : m_fieldOrder) {
                if (tempReportMap.contains(key)) {
                    QVariantMap fieldMap;
                    fieldMap["key"] = key;
                    fieldMap["value"] = tempReportMap[key];
                    reportList.append(fieldMap);
                }
            }
            
            // 添加任何不在原顺序中的额外字段（如果有的话）
            for (auto it = tempReportMap.begin(); it != tempReportMap.end(); ++it) {
                if (!m_fieldOrder.contains(it.key())) {
                    QVariantMap fieldMap;
                    fieldMap["key"] = it.key();
                    fieldMap["value"] = it.value();
                    reportList.append(fieldMap);
                }
            }
            
            // 设置resultList属性
            setresultList(reportList);
            emit reportGenerateResult(true);
        } else {
            qWarning() << "[ReportManager] 响应中没有report字段:" << data;
            emit reportGenerateResult(false);
        }
    } else {
        qWarning() << "[ReportManager] 报告生成失败:" << message;
        emit reportGenerateResult(false);
    }
}

void ReportManager::copyToClipboard(const QString& content)
{
    QClipboard* clipboard = QGuiApplication::clipboard();
    clipboard->setText(content);
}