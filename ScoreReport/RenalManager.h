#ifndef RENALMANAGER_H
#define RENALMANAGER_H

#include <QObject>
#include <QClipboard>
#include <QGuiApplication>
#include <QJsonArray>
#include "CommonFunc.h"
#include "ApiManager.h"
#include "LoginManager.h"

class RenalManager : public QObject
{
    Q_OBJECT
        QUICK_PROPERTY(QString, clipboardContent)
        QUICK_PROPERTY(bool, isAnalyzing)
        QUICK_PROPERTY(bool, isCompleted)
        QUICK_PROPERTY(QString, inCompleteInfo)
        QUICK_PROPERTY(QString, inCompleteContent)
        QUICK_PROPERTY(QString, renalScorer)
        QUICK_PROPERTY(QString, renalResult)
        QUICK_PROPERTY(QVariantList, missingFieldsList)
        QUICK_PROPERTY(QString, sourceText)
        SINGLETON_CLASS(RenalManager)

public:
    Q_INVOKABLE bool checkClipboard();
    Q_INVOKABLE void startAnalysis();
    Q_INVOKABLE void endAnalysis();
    Q_INVOKABLE void submitContent(const QString& inputContents);
    Q_INVOKABLE void pasteAnalysis();
    Q_INVOKABLE void copyToClipboard(); // 复制文本到剪贴板
    void resetAllParams();

private slots:
    void onRenalAiQualityScoreResponse(bool success, const QString& message, const QJsonObject& data);

signals:
    void checkFailed();

private:
    QClipboard* m_clipboard;
    ApiManager* m_apiManager;
    LoginManager* m_loginManager;
    QString currentChatId;
    QString resultText;
};

#endif // RENALMANAGER_H 