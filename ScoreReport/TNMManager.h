#ifndef TNMMANAGER_H
#define TNMMANAGER_H

#include <QObject>
#include <QClipboard>
#include <QGuiApplication>
#include "CommonFunc.h"
#include "ApiManager.h"
#include "LoginManager.h"

class TNMManager : public QObject
{
    Q_OBJECT
    QUICK_PROPERTY(QString, clipboardContent)
    QUICK_PROPERTY(bool, isAnalyzing)
    SINGLETON_CLASS(TNMManager)

public:
    Q_INVOKABLE bool checkClipboard();
    Q_INVOKABLE void startAnalysis();

signals:
    void analysisCompleted(bool success, const QString& message);

private slots:
    void onTnmAiQualityScoreResponse(bool success, const QString& message, const QJsonObject& data);

private:
    QClipboard *m_clipboard;
    ApiManager* m_apiManager;
    LoginManager* m_loginManager;
};

#endif // TNMMANAGER_H 