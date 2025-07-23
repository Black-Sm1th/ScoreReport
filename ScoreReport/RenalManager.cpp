#include "RenalManager.h"
#include <QDebug>

RenalManager::RenalManager(QObject *parent)
    : QObject(parent)
    , m_clipboard(QGuiApplication::clipboard())
    , m_apiManager(nullptr)
    , m_loginManager(nullptr)
{
    m_apiManager = GET_SINGLETON(ApiManager);
    m_loginManager = GET_SINGLETON(LoginManager);
    QObject::connect(m_apiManager, &ApiManager::renalAiQualityScoreResponse, this, &RenalManager::onRenalAiQualityScoreResponse);
    setisAnalyzing(false);
    setisCompleted(false);
    setclipboardContent("");
    setinCompleteInfo("");
    settipList(QVariantList());
    currentChatId = "";
    resultText = "";
    setsourceText(QString::fromLocal8Bit("评分依据：Kutikov RENAL评分系统\n版本时间：原始版（2009年发布）"));
}

bool RenalManager::checkClipboard()
{
    QString content = m_clipboard->text().trimmed();
    
    if (content.isEmpty()) {
        return false;
    }
    setclipboardContent(content);
    return true;
}

void RenalManager::startAnalysis()
{
    currentChatId = CommonFunc::generateNumericUUID();
    // 获取当前登录用户的ID
    QString userId = m_loginManager->getUserId();
    if (userId.isEmpty() || userId == "-1") {
        return;
    }
    setisAnalyzing(true);
    m_apiManager->getRenalAiQualityScore(currentChatId, userId, getclipboardContent());
}

void RenalManager::endAnalysis()
{
    if (!getisCompleted()) {
        m_apiManager->deleteChatById(currentChatId);
    }
    resetAllParams();
    m_apiManager->abortRequestsByType("renal-ai-score");
}

void RenalManager::submitContent(const QVariantList& inputContents)
{
    // 获取当前登录用户的ID
    QString userId = m_loginManager->getUserId();
    if (userId.isEmpty() || userId == "-1") {
        return;
    }
    
    // 拼接原始剪贴板内容和所有输入框内容
    QString finalContent = getclipboardContent();
    
    for (const QVariant& content : inputContents) {
        QString inputText = content.toString().trimmed();
        if (!inputText.isEmpty()) {
            finalContent += "\n" + inputText;
        }
    }
    
    setclipboardContent(finalContent);
    // 设置分析状态并调用API
    setisAnalyzing(true);
    m_apiManager->getRenalAiQualityScore(currentChatId, userId, finalContent);
}

void RenalManager::pasteAnalysis()
{
    QString content = m_clipboard->text().trimmed();
    if (content.isEmpty()) {
        emit checkFailed();
        return;
    }
    resetAllParams();
    setclipboardContent(content);
    startAnalysis();
}

void RenalManager::resetAllParams()
{
    setisCompleted(false);
    setisAnalyzing(false);
    setclipboardContent("");
    setinCompleteInfo("");
    settipList(QVariantList());
    currentChatId = "";
    resultText = "";
}

void RenalManager::onRenalAiQualityScoreResponse(bool success, const QString& message, const QJsonObject& data)
{
    setisAnalyzing(false);
    
    if (success) {
        qDebug() << "[RenalManager] Response data:" << data;
        QJsonObject detailData = data.value("data").toObject();
        QString status = detailData.value("status").toString();
        if (status == "success") {
            setisCompleted(true);
            setinCompleteInfo("");

            QString title = "";
            QString result = "";
            resultText = title;
            resultText += "\n";
            resultText += result;
            resultText += "\n";
            resultText += getsourceText();

            m_apiManager->addQualityRecord("RENAL", title, getclipboardContent(), result, currentChatId);
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
        qWarning() << "[RenalManager] Renal analysis failed:" << message;
    }
}

void RenalManager::copyToClipboard()
{
    QClipboard* clipboard = QGuiApplication::clipboard();
    clipboard->setText(resultText);
}