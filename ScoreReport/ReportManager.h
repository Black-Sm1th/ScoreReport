#ifndef REPORTMANAGER_H
#define REPORTMANAGER_H

#include <QObject>
#include <QString>
#include <QVariantList>
#include "CommonFunc.h"
#include "ApiManager.h"
class ReportManager : public QObject
{
    Q_OBJECT
        SINGLETON_CLASS(ReportManager)
        QUICK_PROPERTY(QVariantList, templateList)
        
signals:
    void templateSaveResult(bool success, const QString& message);
    void templateDeleteResult(bool success, const QString& message);
public:
    Q_INVOKABLE void refreshTemplate();
    Q_INVOKABLE void saveTemplate(const QString& templateId, const QVariantList& templateData);
    Q_INVOKABLE void deleteTemplate(const QString& templateId);
public slots:
    void onGetReportTemplateListResponse(bool success, const QString& message, const QJsonObject& data);
    void onSaveReportTemplateResponse(bool success, const QString& message, const QJsonObject& data);
    void onDeleteReportTemplateResponse(bool success, const QString& message, const QJsonObject& data);
private:
    ApiManager* m_apiManager;
};

#endif // REPORTMANAGER_H 