#ifndef REPORTMANAGER_H
#define REPORTMANAGER_H

#include <QObject>
#include <QString>
#include <QVariantList>

#include "CommonFunc.h"
#include "LanguageManager.h"
#include "ApiManager.h"
class ReportManager : public QObject
{
    Q_OBJECT
        SINGLETON_CLASS(ReportManager)
        QUICK_PROPERTY(QVariantList, templateList)
        QUICK_PROPERTY(QVariantMap, resultMap)
        
signals:
    void templateSaveResult(bool success, const QString& message);
    void templateDeleteResult(bool success, const QString& message);
    void reportGenerateResult(bool success);
public:
    Q_INVOKABLE void refreshTemplate();
    Q_INVOKABLE void saveTemplate(const QString& templateId, const QVariantList& templateData);
    Q_INVOKABLE void deleteTemplate(const QString& templateId);
    Q_INVOKABLE void generateReport(const QString& query, const QVariantList& templateData);
    Q_INVOKABLE void endAnalysis();
    Q_INVOKABLE void copyToClipboard(const QString& content);
public slots:
    void onGetReportTemplateListResponse(bool success, const QString& message, const QJsonObject& data);
    void onSaveReportTemplateResponse(bool success, const QString& message, const QJsonObject& data);
    void onDeleteReportTemplateResponse(bool success, const QString& message, const QJsonObject& data);
    void onGenerateQualityReportResponse(bool success, const QString& message, const QJsonObject& data);
private:
    ApiManager* m_apiManager;
    LanguageManager* m_languageManager;
};

#endif // REPORTMANAGER_H 