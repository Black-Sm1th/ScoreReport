#include "TNMManager.h"
#include <QDebug>

TNMManager::TNMManager(QObject *parent)
    : QObject(parent)
    , m_clipboard(QGuiApplication::clipboard())
    , m_apiManager(nullptr)
    , m_loginManager(nullptr)
{
    m_languageManager = GET_SINGLETON(LanguageManager);
    m_apiManager = GET_SINGLETON(ApiManager);
    m_loginManager = GET_SINGLETON(LoginManager);
    QObject::connect(m_apiManager, &ApiManager::tnmAiQualityScoreResponse, this, &TNMManager::onTnmAiQualityScoreResponse);
    QObject::connect(m_apiManager, &ApiManager::cancerDiagnoseTypeResponse, this, &TNMManager::onCancerDiagnoseTypeResponse);
    setisAnalyzing(false);
    setisCompleted(false);
    setclipboardContent("");
    setinCompleteInfo("");
    settipList(QVariantList());
    setinCompleteInfoDetail("");
    setTNMConclusion("");
    setStage("");
    setTConclusion("");
    setNConclusion("");
    setMConclusion("");
    // 初始化癌种相关属性
    setisDetectingCancer(false);
    setshowCancerSelection(false);
    setcancerTypes(QVariantList());
    setselectedCancerType("");
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
    
    // 重置癌种相关状态
    setshowCancerSelection(false);
    setcancerTypes(QVariantList());
    setselectedCancerType("");
    
    // 先进行癌种检测
    setisDetectingCancer(true);
    m_apiManager->getCancerDiagnoseType(getclipboardContent(), m_languageManager->currentLanguage());
}

void TNMManager::endAnalysis()
{
    if (!getisCompleted() && !getisDetectingCancer() && !getshowCancerSelection()) {
        m_apiManager->deleteChatById(currentChatId);
    }
    resetAllParams();
    m_apiManager->abortRequestsByType("tnm-ai-score");
    m_apiManager->abortRequestsByType("cancer-diagnose-type");
    
    // 重置癌种相关状态
    setisDetectingCancer(false);
    setshowCancerSelection(false);
    setcancerTypes(QVariantList());
    setselectedCancerType("");
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
    m_apiManager->getTnmAiQualityScore(currentChatId, userId, finalContent, m_languageManager->currentLanguage(),getselectedCancerType());
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
    setinCompleteInfoDetail("");
    settipList(QVariantList());
    setTNMConclusion("");
    setStage("");
    setTConclusion("");
    setNConclusion("");
    setMConclusion("");
    // 重置癌种相关状态
    setisDetectingCancer(false);
    setshowCancerSelection(false);
    setcancerTypes(QVariantList());
    setselectedCancerType("");
    currentChatId = "";
    resultText = "";
}

/**
 * @brief 选择癌种并开始TNM分析
 * @param cancerType 用户选择的癌种
 */
void TNMManager::selectCancerType(const QString& cancerType)
{
    setselectedCancerType(cancerType);
    setshowCancerSelection(false);
    
    // 开始TNM分析
    QString userId = m_loginManager->getcurrentUserId();
    if (userId.isEmpty() || userId == "-1") {
        return;
    }
    
    setisAnalyzing(true);
    m_apiManager->getTnmAiQualityScore(currentChatId, userId, getclipboardContent(), 
                                     m_languageManager->currentLanguage(), cancerType);
}

/**
 * @brief 跳过癌种选择，直接进行TNM分析
 */
void TNMManager::skipCancerSelection()
{
    setselectedCancerType("");
    setshowCancerSelection(false);
    
    // 开始TNM分析
    QString userId = m_loginManager->getcurrentUserId();
    if (userId.isEmpty() || userId == "-1") {
        return;
    }
    
    setisAnalyzing(true);
    m_apiManager->getTnmAiQualityScore(currentChatId, userId, getclipboardContent(), 
                                     m_languageManager->currentLanguage());
}

void TNMManager::onTnmAiQualityScoreResponse(bool success, const QString& message, const QJsonObject& data)
{
    setisAnalyzing(false);
    
    if (success) {
        QJsonObject detailData = data.value("data").toObject();
        QString status = detailData.value("status").toString();
        if (status == "success") {
            setisCompleted(true);
            setinCompleteInfo("");
            setinCompleteInfoDetail("");
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
            QString T = detailData.value("basis").toObject().value("T").toString();
            QString N = detailData.value("basis").toObject().value("N").toString();
            QString M = detailData.value("basis").toObject().value("M").toString();
            QString infoDetail = QString::fromLocal8Bit("T：") + T + QString::fromLocal8Bit("\n\nN：") + N + QString::fromLocal8Bit("\n\nM：") + M;
            QVariantList list;

            for (const QJsonValue& value : tips) {
                list.append(value.toString());  // 转成 QVariantMap
            }
            settipList(list);
            setinCompleteInfoDetail(infoDetail);
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

/**
 * @brief 处理癌症诊断类型响应
 * @param success 是否成功
 * @param message 响应消息
 * @param data 响应数据
 */
void TNMManager::onCancerDiagnoseTypeResponse(bool success, const QString& message, const QJsonObject& data)
{
    setisDetectingCancer(false);
    
    if (success) {
        QJsonArray cancerArray = data.value("types").toArray();
        QVariantList cancerList;
        for (const QJsonValue& value : cancerArray) {
            QString cancerObj = value.toString();
            QVariantMap cancerMap;
            cancerMap["name"] = cancerObj;
            cancerList.append(cancerMap);
        }
        // 显示癌种选择界面
        setcancerTypes(cancerList);
        setshowCancerSelection(true);
    } else {
        qWarning() << "[TNMManager] Cancer diagnosis failed:" << message;
        // 癌种检测失败，直接进行TNM分析
        skipCancerSelection();
    }
}