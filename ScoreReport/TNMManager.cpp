#include "TNMManager.h"

#include <QDebug>

TNMManager::TNMManager(QObject *parent)
    : QObject(parent)
    , m_clipboard(QGuiApplication::clipboard())
    , m_apiManager(nullptr)
    , m_loginManager(nullptr)
{
    m_apiManager = GET_SINGLETON(ApiManager);
    m_loginManager = GET_SINGLETON(LoginManager);
    setisAnalyzing(false);
    setclipboardContent("");
}

bool TNMManager::checkClipboard()
{
    QString content = m_clipboard->text().trimmed();
    
    if (content.isEmpty()) {
        return false;
    }
    setclipboardContent(content);
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
    
    setisAnalyzing(true);
    m_apiManager->getTnmAiQualityScore(userId, getclipboardContent());
}

void TNMManager::onTnmAiQualityScoreResponse(bool success, const QString& message, const QJsonObject& data)
{
    setisAnalyzing(false);
    
    if (success) {
        qDebug() << "[TNMManager] TNM analysis completed successfully:" << message;
        qDebug() << "[TNMManager] Response data:" << data;
    } else {
        qWarning() << "[TNMManager] TNM analysis failed:" << message;
    }
    
    emit analysisCompleted(success, message);
}