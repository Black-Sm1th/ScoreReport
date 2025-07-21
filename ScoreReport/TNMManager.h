#ifndef TNMMANAGER_H
#define TNMMANAGER_H

#include <QObject>
#include <QClipboard>
#include <QGuiApplication>

class ApiManager;
class LoginManager;

class TNMManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString clipboardContent READ clipboardContent NOTIFY clipboardContentChanged)
    Q_PROPERTY(bool isAnalyzing READ isAnalyzing NOTIFY isAnalyzingChanged)

public:
    explicit TNMManager(QObject *parent = nullptr);
    
    void setApiManager(ApiManager* apiManager);
    void setLoginManager(LoginManager* loginManager);

    QString clipboardContent() const;
    bool isAnalyzing() const;

    Q_INVOKABLE bool checkClipboard();
    Q_INVOKABLE void startAnalysis();

signals:
    void clipboardContentChanged();
    void isAnalyzingChanged();
    void analysisCompleted(bool success, const QString& message);

private slots:
    void onTnmAiQualityScoreResponse(bool success, const QString& message, const QJsonObject& data);

private:
    void setIsAnalyzing(bool analyzing);
    
    QClipboard *m_clipboard;
    QString m_clipboardContent;
    bool m_isAnalyzing;
    ApiManager* m_apiManager;
    LoginManager* m_loginManager;
};

#endif // TNMMANAGER_H 