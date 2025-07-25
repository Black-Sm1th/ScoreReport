#include "CommonFunc.h"
#include "ApiManager.h"
#include "CommonFunc.h"
#include <QObject>

class HistoryRecord : public QObject
{
    Q_OBJECT
        SINGLETON_CLASS(HistoryRecord)
public:
    Q_INVOKABLE void updateList();

public slots:
    void getQualityListResponse(bool success, const QString& message, const QJsonObject& data);
private:
    ApiManager* m_apiManager;
};