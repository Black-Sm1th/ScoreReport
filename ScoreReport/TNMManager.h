#ifndef TNMMANAGER_H
#define TNMMANAGER_H

#include <QObject>
#include <QClipboard>
#include <QGuiApplication>
#include <QJsonArray>
#include "CommonFunc.h"
#include "ApiManager.h"
#include "LoginManager.h"

class TNMManager : public QObject
{
    Q_OBJECT
    QUICK_PROPERTY(QString, clipboardContent)
    QUICK_PROPERTY(bool, isAnalyzing)
    QUICK_PROPERTY(bool, isCompleted)
        QUICK_PROPERTY(QString, inCompleteInfo)
        QUICK_PROPERTY(QVariantList, tipList)
    SINGLETON_CLASS(TNMManager)

public:
    Q_INVOKABLE bool checkClipboard();
    Q_INVOKABLE void startAnalysis();
    Q_INVOKABLE void endAnalysis();
    void resetAllParams();

private slots:
    void onTnmAiQualityScoreResponse(bool success, const QString& message, const QJsonObject& data);

private:
    QClipboard *m_clipboard;
    ApiManager* m_apiManager;
    LoginManager* m_loginManager;
};

#endif // TNMMANAGER_H 