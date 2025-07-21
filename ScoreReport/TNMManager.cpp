#include "TNMManager.h"
#include "ApiManager.h"
#include "LoginManager.h"
#include <QDebug>

TNMManager::TNMManager(QObject *parent)
    : QObject(parent)
    , m_clipboard(QGuiApplication::clipboard())
    , m_isAnalyzing(false)
    , m_apiManager(nullptr)
    , m_loginManager(nullptr)
{

}

void TNMManager::setApiManager(ApiManager* apiManager)
{
    m_apiManager = apiManager;
    if (m_apiManager) {
        connect(m_apiManager, &ApiManager::tnmAiQualityScoreResponse,
                this, &TNMManager::onTnmAiQualityScoreResponse);
    }
}

void TNMManager::setLoginManager(LoginManager* loginManager)
{
    m_loginManager = loginManager;
}

QString TNMManager::clipboardContent() const
{
    return m_clipboardContent;
}

bool TNMManager::isAnalyzing() const
{
    return m_isAnalyzing;
}

void TNMManager::setIsAnalyzing(bool analyzing)
{
    if (m_isAnalyzing != analyzing) {
        m_isAnalyzing = analyzing;
        emit isAnalyzingChanged();
    }
}

bool TNMManager::checkClipboard()
{
    QString content = m_clipboard->text().trimmed();
    
    if (content.isEmpty()) {
        return false;
    }
    m_clipboardContent = content;
    emit clipboardContentChanged();
    return true;
}

void TNMManager::startAnalysis()
{
    // 获取当前登录用户的ID
    QString userId = m_loginManager->getUserId();
    if (userId.isEmpty() || userId == "-1") {
        emit analysisCompleted(false, "User not logged in");
        return;
    }
    
    qDebug() << "[TNMManager] Starting analysis for user:" << userId << "with content length:" << m_clipboardContent.length();
    
    setIsAnalyzing(true);
    m_apiManager->getTnmAiQualityScore(userId, m_clipboardContent);
}

void TNMManager::onTnmAiQualityScoreResponse(bool success, const QString& message, const QJsonObject& data)
{
    setIsAnalyzing(false);
    
    if (success) {
        qDebug() << "[TNMManager] TNM analysis completed successfully:" << message;
        qDebug() << "[TNMManager] Response data:" << data;
    } else {
        qWarning() << "[TNMManager] TNM analysis failed:" << message;
    }
    
    emit analysisCompleted(success, message);
}