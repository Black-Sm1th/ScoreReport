#ifndef TNMMANAGER_H
#define TNMMANAGER_H

#include <QObject>
#include <QClipboard>
#include <QGuiApplication>
#include <QJsonArray>
#include "CommonFunc.h"
#include "ApiManager.h"
#include "LoginManager.h"
#include "LanguageManager.h"
class TNMManager : public QObject
{
    Q_OBJECT
    QUICK_PROPERTY(QString, clipboardContent)
    QUICK_PROPERTY(bool, isAnalyzing)
    QUICK_PROPERTY(bool, isCompleted)
        QUICK_PROPERTY(QString, inCompleteInfo)
        QUICK_PROPERTY(QVariantList, tipList)
        QUICK_PROPERTY(QString, TNMConclusion)
        QUICK_PROPERTY(QString, inCompleteInfoDetail)
        QUICK_PROPERTY(QString, Stage)
        QUICK_PROPERTY(QString, TConclusion)
        QUICK_PROPERTY(QString, NConclusion)
        QUICK_PROPERTY(QString, MConclusion)
        QUICK_PROPERTY(QString, sourceText)
        // 癌种选择相关属性
        QUICK_PROPERTY(bool, isDetectingCancer)  // 是否正在检测癌种
        QUICK_PROPERTY(bool, showCancerSelection)  // 是否显示癌种选择界面
        QUICK_PROPERTY(QVariantList, cancerTypes)  // 可选癌种列表
        QUICK_PROPERTY(QString, selectedCancerType)  // 用户选择的癌种
    SINGLETON_CLASS(TNMManager)

public:
    Q_INVOKABLE bool checkClipboard();
    Q_INVOKABLE void startAnalysis();
    Q_INVOKABLE void endAnalysis();
    Q_INVOKABLE void submitContent(const QVariantList& inputContents);
    Q_INVOKABLE void pasteAnalysis();
    Q_INVOKABLE void copyToClipboard(); // 复制文本到剪贴板
    Q_INVOKABLE void selectCancerType(const QString& cancerType); // 选择癌种并开始TNM分析
    Q_INVOKABLE void skipCancerSelection(); // 跳过癌种选择，直接进行TNM分析
    void resetAllParams();

private slots:
    void onTnmAiQualityScoreResponse(bool success, const QString& message, const QJsonObject& data);
    void onCancerDiagnoseTypeResponse(bool success, const QString& message, const QJsonObject& data);

signals:
    void checkFailed();

private:
    QClipboard *m_clipboard;
    ApiManager* m_apiManager;
    LoginManager* m_loginManager;
    LanguageManager* m_languageManager;
    QString currentChatId;
    QString resultText;
};

#endif // TNMMANAGER_H 