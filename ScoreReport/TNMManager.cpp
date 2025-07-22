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
    QObject::connect(m_apiManager, &ApiManager::tnmAiQualityScoreResponse, this, &TNMManager::onTnmAiQualityScoreResponse);
    setisAnalyzing(false);
    setisCompleted(false);
    setclipboardContent("");
    setinCompleteInfo("");
    settipList(QVariantList());
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
        return;
    }
    setisAnalyzing(true);
    m_apiManager->getTnmAiQualityScore(userId, getclipboardContent());
}

void TNMManager::endAnalysis()
{
    resetAllParams();
    m_apiManager->abortRequestsByType("tnm-ai-score");
}

void TNMManager::resetAllParams()
{
    setisCompleted(false);
    setisAnalyzing(false);
    setclipboardContent("");
    setinCompleteInfo("");
    settipList(QVariantList());
}

void TNMManager::onTnmAiQualityScoreResponse(bool success, const QString& message, const QJsonObject& data)
{
    setisAnalyzing(false);
    
    if (success) {
        qDebug() << "[TNMManager] Response data:" << data;
        QJsonObject detailData = data.value("data").toObject();
        QString status = detailData.value("status").toString();
        if (status == "success") {
            setisCompleted(true);
            setinCompleteInfo("");
        }
        else{
            QString info = detailData.value("message").toString();
            QJsonArray tips = detailData.value("tips").toArray();
            QVariantList list;
            for (const QJsonValue& value : tips) {
                list.append(value.toString());  // 转成 QVariantMap
            }
            settipList(list);
            setinCompleteInfo(info);
            setisCompleted(false);
        }
    } else {
        qWarning() << "[TNMManager] TNM analysis failed:" << message;
    }
}