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
    setTNMConclusion("");
    setStage("");
    setTConclusion("");
    setNConclusion("");
    setMConclusion("");
    currentChatId = "";
    resultText = "";
    setsourceText(QString::fromLocal8Bit("评分依据：AJCC/UICC联合制定\n版本时间：第八版（2021年发布，2025年适用）"));
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
    currentChatId = CommonFunc::generateNumericUUID();
    // 获取当前登录用户的ID
    QString userId = m_loginManager->getcurrentUserId();
    if (userId.isEmpty() || userId == "-1") {
        return;
    }
    setisAnalyzing(true);
    m_apiManager->getTnmAiQualityScore(currentChatId, userId, getclipboardContent());
}

void TNMManager::endAnalysis()
{
    if (!getisCompleted()) {
        m_apiManager->deleteChatById(currentChatId);
    }
    resetAllParams();
    m_apiManager->abortRequestsByType("tnm-ai-score");
}

void TNMManager::submitContent(const QVariantList& inputContents)
{
    // 获取当前登录用户的ID
    QString userId = m_loginManager->getcurrentUserId();
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
    m_apiManager->getTnmAiQualityScore(currentChatId, userId, finalContent);
}

void TNMManager::pasteAnalysis()
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

void TNMManager::resetAllParams()
{
    setisCompleted(false);
    setisAnalyzing(false);
    setclipboardContent("");
    setinCompleteInfo("");
    settipList(QVariantList());
    setTNMConclusion("");
    setStage("");
    setTConclusion("");
    setNConclusion("");
    setMConclusion("");
    currentChatId = "";
    resultText = "";
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
            QString T = detailData.value("conclusion").toObject().value("T").toString();
            QString N = detailData.value("conclusion").toObject().value("N").toString();
            QString M = detailData.value("conclusion").toObject().value("M").toString();
            QString stage = detailData.value("stage").toString();
            setTNMConclusion(T + N + M);
            setStage(stage);
            QString TC = detailData.value("basis").toObject().value("T").toString();
            QString NC = detailData.value("basis").toObject().value("N").toString();
            QString MC = detailData.value("basis").toObject().value("M").toString();
            setTConclusion(TC);
            setNConclusion(NC);
            setMConclusion(MC);

            QString title = QString::fromLocal8Bit("TNM分期：") + getTNMConclusion();
            QString result = QString::fromLocal8Bit("临床分期：") + getStage() + QString::fromLocal8Bit("\nT分期 （原发肿瘤）：\n") + getTConclusion() + QString::fromLocal8Bit("\nN分期 （区域淋巴结）：\n") + getNConclusion() + QString::fromLocal8Bit("\nM分期 （原发肿瘤）：\n") + getMConclusion();
            resultText = title;
            resultText += "\n";
            resultText += result;
            resultText += "\n";
            resultText += getsourceText();

            m_apiManager->addQualityRecord("TNM", title, getclipboardContent(), result, currentChatId);
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

void TNMManager::copyToClipboard()
{
    QClipboard* clipboard = QGuiApplication::clipboard();
    clipboard->setText(resultText);
}