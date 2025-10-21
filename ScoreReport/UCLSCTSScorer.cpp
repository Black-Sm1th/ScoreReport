#include "UCLSCTSScorer.h"
#include <QGuiApplication>
#include <QClipboard>

UCLSCTSScorer::UCLSCTSScorer(QObject* parent)
    : QObject(parent)
    , resultText("")
{
    setsourceText(QStringLiteral("评分依据：UCLS CTS 系统《Medicina 2021, 57(8), 816》\n版本时间：2021 年"));
}

int UCLSCTSScorer::calculateScore(int nonEnhancedAttenuation, int maxEnhancementPhase, 
                                 int absoluteEnhancement, int relativeEnhancement,
                                 int heterogeneousEnhancement, int irregularShape,
                                 int neovascularity, int dystrophicCalcification, int splittingSign)
{
    int totalScore = 0;
    
    // 定量特征评分 - 前两步是一起的，有一个选"否"就是0分
    // 第一步选"否"就不显示第二步，两步都是0分
    // 两步都选"是"才一共得1分
    if (nonEnhancedAttenuation == Yes && maxEnhancementPhase == Yes) {
        totalScore += 1; // 前两步合起来1分
    }
    
    // 3. 绝对强化
    switch (absoluteEnhancement) {
    case Over50:        // >50
        totalScore += 2;
        break;
    case Between25_50:  // 25-50
        totalScore += 1;
        break;
    case Under25:       // <25
        totalScore += 0;
        break;
    }
    
    // 4. 皮髓质期相对强化
    switch (relativeEnhancement) {
    case Under0:        // <0
        totalScore += 0;
        break;
    case Between1_10:   // 1-10
        totalScore += 1;
        break;
    case Between10_20:  // 10-20
        totalScore += 2;
        break;
    case Over20:        // >20
        totalScore += 3;
        break;
    }
    
    // 定性特征评分 - 第5、6、7、8步是一起的，有一个选"否"就是0分  
    // 第5步选"否"就不显示后面的步骤，四步都是0分
    // 四步都选"是"才一共得1分
    if (heterogeneousEnhancement == Yes && irregularShape == Yes && 
        neovascularity == Yes && dystrophicCalcification == Yes) {
        totalScore += 1; // 第5、6、7、8步合起来1分
    }
    
    // 5. 劈裂征
    if (splittingSign == Yes) {
        totalScore -= 1;  // 劈裂征是减分项
    }
    
    return totalScore;
}

bool UCLSCTSScorer::needsOption(int stepIndex, int nonEnhancedAttenuation, int maxEnhancementPhase, int heterogeneousEnhancement, int irregularShape, int neovascularity)
{
    switch (stepIndex) {
    case 0: // 不强化区域衰减量绝对值小于45HU - 总是需要
        return true;
    case 1: // 在皮髓质期病变强化程度最高 - 只有前一个选"是"才需要
        return (nonEnhancedAttenuation == Yes);
    case 2: // 绝对强化 - 总是需要
        return true;
    case 3: // 皮髓质期相对强化 - 总是需要
        return true;
    case 4: // 非均匀强化 - 总是需要
        return true;
    case 5: // 不规则外形 - 只有非均匀强化选"是"才需要
        return (heterogeneousEnhancement == Yes);
    case 6: // 新生血管 - 需要前面的定性特征都选"是"
        return (heterogeneousEnhancement == Yes && irregularShape == Yes);
    case 7: // 营养不良性钙化 - 需要前面的定性特征都选"是"
        return (heterogeneousEnhancement == Yes && irregularShape == Yes && neovascularity == Yes);
    case 8: // 劈裂征 - 总是需要
        return true;
    default:
        return false;
    }
}

void UCLSCTSScorer::finishScore(int score)
{
    QString title = QStringLiteral("UCLS CTS评分：") + QString::number(score) + QStringLiteral("分");
    resultText = title;
    resultText += "\n";
    resultText += getsourceText();
    GET_SINGLETON(ApiManager)->addQualityRecord("UCLS CTS", title, "", "");
}

void UCLSCTSScorer::copyToClipboard()
{
    QClipboard *clipboard = QGuiApplication::clipboard();
    clipboard->setText(resultText);
} 