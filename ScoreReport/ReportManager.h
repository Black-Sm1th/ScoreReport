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
public:
    Q_INVOKABLE void refreshTemplate();
public slots:
    void onGetReportTemplateListResponse(bool success, const QString& message, const QJsonObject& data);
private:
    ApiManager* m_apiManager;
};

#endif // REPORTMANAGER_H 