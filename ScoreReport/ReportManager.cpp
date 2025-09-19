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
    setresultMap(QVariantMap());
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
    
    // 将QVariantList转换为JSON对象
    QJsonObject templateObject;
    
    for (const QVariant& item : templateData) {
        QVariantMap itemMap = item.toMap();
        QString key = itemMap.value("key").toString();
        QString value = itemMap.value("value").toString();
        
        if (!key.isEmpty()) {
            templateObject[key] = value;
        }
    }
    
    // 将JSON对象转换为字符串
    QJsonDocument templateDoc(templateObject);
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
    // 将QVariantList转换为JSON对象
    QJsonObject templateObject;
    
    for (const QVariant& item : templateData) {
        QVariantMap itemMap = item.toMap();
        QString key = itemMap.value("key").toString();
        QString value = itemMap.value("value").toString();
        
        if (!key.isEmpty()) {
            templateObject[key] = value;
        }
    }
    
    // 将JSON对象转换为字符串
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
            
            // 将report JSON转换为QVariantMap
            QVariantMap reportMap;
            
            if (reportValue.isObject()) {
                // 如果report是JSON对象，直接转换
                QJsonObject reportObj = reportValue.toObject();
                for (auto it = reportObj.begin(); it != reportObj.end(); ++it) {
                    reportMap[it.key()] = it.value().toVariant();
                }
            } else if (reportValue.isString()) {
                // 如果report是JSON字符串，先解析再转换
                QString reportString = reportValue.toString();
                QJsonParseError parseError;
                QJsonDocument reportDoc = QJsonDocument::fromJson(reportString.toUtf8(), &parseError);
                
                if (parseError.error == QJsonParseError::NoError && reportDoc.isObject()) {
                    QJsonObject reportObj = reportDoc.object();
                    for (auto it = reportObj.begin(); it != reportObj.end(); ++it) {
                        reportMap[it.key()] = it.value().toVariant();
                    }
                } else {
                    qWarning() << "[ReportManager] 解析report JSON字符串失败:" << parseError.errorString();
                }
            }
            
            // 设置resultMap属性
            setresultMap(reportMap);
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