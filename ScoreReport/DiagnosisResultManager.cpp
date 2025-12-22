#include "DiagnosisResultManager.h"
#include "ApiManager.h"
#include "LoginManager.h"
#include <QDebug>
#include <QString>
#include <QClipboard>
#include <QGuiApplication>
DiagnosisResultManager::DiagnosisResultManager(QObject* parent)
    : QObject(parent)
    , m_isSending(false)
{
    // 连接API管理器的信号
    auto* apiManager = GET_SINGLETON(ApiManager);
    //connect(apiManager, &ApiManager::streamChatResponse,
    //    this, &DiagnosisResultManager::onStreamChatResponse);
    connect(apiManager, &ApiManager::streamChatFinished,
        this, &DiagnosisResultManager::onStreamChatFinished);
    m_currentChatId = CommonFunc::generateNumericUUID();
    m_promptMessage = QStringLiteral("影像所见：\n两侧胸廓对称。肺窗示两肺见数个微结节灶（大者image13），直径约2 - 4mm，边界清。右肺上叶见钙化灶，余两肺野纹理清晰，未见明显异常密度影。两侧肺门不大。纵隔窗示心影及大血管形态正常。纵隔内未见肿块及明显肿大淋巴结。未见胸腔积液及胸膜增厚。 附见：肝脏密度（CT值为43HU）较脾脏(CT值为56HU)低。\n影像诊断：\n1、两肺微结节，右肺上叶钙化灶，随诊。 2、脂肪肝\n\n检查所见：\n鼻中隔无明显偏曲。双侧中道清。鼻咽部淋巴组织增生，双侧咽隐窝对称。咽喉部慢性充血。会厌未见明显异常。双侧声带边缘光滑，活动正常，闭合可。双侧梨状窝对称。\n检查结论：\n鼻炎 咽喉炎\n\n请根据上面两段模板，根据检查 / 影像所见生成诊断结论（具体到可能病名）\n诊断结论结构 : \"diagnosisResult:\"\n检查 / 影像所见：");
}

void DiagnosisResultManager::sendMessage(const QString& message)
{
    
    if (message.trimmed().isEmpty() || m_isSending) {
        return;
    }

    QString trimmedMessage = message.trimmed();
    setoriginalMessages(trimmedMessage);
    m_allText = "";
    m_allText += QStringLiteral("检查所见：\n");
    m_allText += trimmedMessage;
    m_allText += QStringLiteral("\n检查结论：\n");

    // 发送到API
    auto* loginManager = GET_SINGLETON(LoginManager);
    QString userId = loginManager->getcurrentUserId();

    auto* apiManager = GET_SINGLETON(ApiManager);
    apiManager->streamChat(m_promptMessage + trimmedMessage, userId, m_currentChatId);
    setisSending(true);
    emit rollToBottom();
}

void DiagnosisResultManager::endAnalysis()
{
    // 中断当前聊天
    GET_SINGLETON(ApiManager)->abortStreamChatByChatId(m_currentChatId);
    setisSending(false);
    setoriginalMessages("");
    setresponseMessages("");
    m_resultText = "";
    m_allText = "";
}

void DiagnosisResultManager::onStreamChatResponse(const QString& data, const QString& chatId)
{
    //// 验证是否为当前会话
    //if (chatId != m_currentChatId) {
    //    return;
    //}

    //if (m_responseMessages.isEmpty()) {
    //    // 第一次接收响应：移除思考状态
    //    m_responseMessages = data;
    //}
    //else {
    //    // 追加响应内容
    //    m_responseMessages += data;
    //}
}

void DiagnosisResultManager::onStreamChatFinished(bool success, const QString& message, const QString& chatId)
{
    // 验证是否为当前会话
    if (chatId != m_currentChatId) {
        return;
    }
    qDebug() << "[DiagnosisResultManager] Chat finished, success:" << success << ", message:" << message;
    if (message.startsWith("diagnosisResult:")) {
        m_resultText = message.mid(16).trimmed();
        setresponseMessages(m_resultText);
    }
    m_allText += m_resultText;
    // 重置状态
    setisSending(false);
    emit rollToBottom();
}

void DiagnosisResultManager::copyToClipboard(int index)
{
    QClipboard* clipboard = QGuiApplication::clipboard();
    if (index == 0) {
        clipboard->setText(m_resultText);
    }
    else if (index == 1) {
        clipboard->setText(m_allText);
    }
}