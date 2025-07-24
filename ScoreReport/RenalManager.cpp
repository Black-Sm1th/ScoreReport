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
    setinCompleteContent("");
    setrenalResult("");
    setrenalScorer("");
    setmissingFieldsList(QVariantList());
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

void RenalManager::submitContent(const QString& inputContents)
{
    // 获取当前登录用户的ID
    QString userId = m_loginManager->getUserId();
    if (userId.isEmpty() || userId == "-1") {
        return;
    }

    // 拼接原始剪贴板内容和选择的缺失项内容
    QString finalContent = getclipboardContent();
    if (!inputContents.isEmpty()) {
        finalContent += "\n" + inputContents;
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
    setrenalResult("");
    setrenalScorer("");
    setinCompleteInfo("");
    setinCompleteContent("");
    setmissingFieldsList(QVariantList());
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
            setrenalScorer(QString::number(detailData.value("total_score").toInt()));
            QString title = QString::fromLocal8Bit("RENAL评分：") + getrenalScorer() + QString::fromLocal8Bit("分");
            QString result = detailData.value("complexity").toString() + QString::fromLocal8Bit("。") + detailData.value("recommendation").toString() + QString::fromLocal8Bit("\n");
            result += QString::fromLocal8Bit("R：") + detailData.value("basis").toObject().value("R").toString() + QString::fromLocal8Bit("\n");
            result += QString::fromLocal8Bit("E：") + detailData.value("basis").toObject().value("E").toString() + QString::fromLocal8Bit("\n");
            result += QString::fromLocal8Bit("N：") + detailData.value("basis").toObject().value("N").toString() + QString::fromLocal8Bit("\n");
            result += QString::fromLocal8Bit("A：") + detailData.value("basis").toObject().value("A").toString() + QString::fromLocal8Bit("\n");
            result += QString::fromLocal8Bit("L：") + detailData.value("basis").toObject().value("L").toString();
            setrenalResult(result);
            resultText = title;
            resultText += "\n";
            resultText += result;
            resultText += "\n";
            resultText += getsourceText();
            m_apiManager->addQualityRecord("RENAL", title, getclipboardContent(), result, currentChatId);
        }
        else{
            QString info = detailData.value("message").toString();
            QJsonArray missing_fields = detailData.value("missing_fields").toArray();
            QVariantList list;
            QString content = "";
            for (const QJsonValue& value : missing_fields) {
                content += value.toString() + QString::fromLocal8Bit("：");
                content += detailData.value("basis").toObject().value(value.toString()).toString();
                if (missing_fields.last() != value) {
                    content += "\n";
                }
                list.append(value.toString());
            }
            setinCompleteContent(content);
            setmissingFieldsList(list);
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