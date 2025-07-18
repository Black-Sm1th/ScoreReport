#include "CCLSScorer.h"
#include <QGuiApplication>
#include <QClipboard>

CCLSScorer::CCLSScorer(QObject* parent)
    : QObject(parent)
{
}

int CCLSScorer::calculateScore(int t2Signal, int enhancement, int microFat, int segmentalReversal, int arterialRatio, int diffusionRestriction)
{
    switch (t2Signal) {
    case HighSignal:
        return calculatePath1(enhancement, microFat, segmentalReversal, arterialRatio, diffusionRestriction);
    case EqualSignal:
        return calculatePath2(enhancement, microFat, segmentalReversal, arterialRatio, diffusionRestriction);
    case LowSignal:
        return calculatePath3(enhancement, microFat, segmentalReversal, arterialRatio, diffusionRestriction);
    default:
        return 0;
    }
}

bool CCLSScorer::needsOption(int t2Signal, int enhancement, int optionIndex, int microFat)
{
    // optionIndex: 0=T2信号, 1=强化程度, 2=微观脂肪, 3=节段性反转, 4=动脉期比值, 5=弥散受限
    switch (optionIndex) {
    case 0: // T2信号 - 总是需要
        return true;
    case 1: // 强化程度 - 总是需要
        return true;
    case 2: // 微观脂肪
        // 高信号轻度强化不需要微观脂肪
        if (t2Signal == HighSignal && enhancement == Mild) {
            return false;
        }
        // 低信号只有轻度强化才需要微观脂肪
        if (t2Signal == LowSignal) {
            return enhancement == Mild;
        }
        return true;
    case 3: // 节段性反转
        // 低信号不需要节段性反转
        if (t2Signal == LowSignal) {
            return false;
        }
        // 等信号轻度强化不需要节段性反转
        if (t2Signal == EqualSignal && enhancement == Mild) {
            return false;
        }
        // 高信号轻度强化不需要节段性反转
        if (t2Signal == HighSignal && enhancement == Mild) {
            return false;
        }
        // 明显强化或中度强化且微观脂肪为"是"时不需要节段性反转
        if ((enhancement == Obvious || enhancement == Moderate) && microFat == Yes) {
            return false;
        }
        return true;
    case 4: // 动脉期比值
        // 只有低信号明显强化时需要
        return (t2Signal == LowSignal && enhancement == Obvious);
    case 5: // 弥散受限
        // 低信号明显强化时总是需要
        if (t2Signal == LowSignal && enhancement == Obvious) {
            return true;
        }
        // 等信号轻度强化时，只有微观脂肪选择"否"才需要
        if (t2Signal == EqualSignal && enhancement == Mild) {
            return microFat == No; // 只有微观脂肪为"否"时才需要弥散受限
        }
        return false;
    default:
        return false;
    }
}

int CCLSScorer::calculatePath1(int enhancement, int microFat, int segmentalReversal, int arterialRatio, int diffusionRestriction)
{
    // 高信号路径
    switch (enhancement) {
    case Obvious: // 明显强化 >70%
        if (microFat == Yes) { // 微观脂肪:是
            return 5; // 直接返回5分，不需要节段性反转判断
        }
        else {  // 微观脂肪:否
            return segmentalReversal == Yes ? 3 : 4; // 节段性反转: 是=3, 否=4
        }
    case Moderate: // 中度强化 40-70%
        if (microFat == Yes) { // 微观脂肪:是
            return 3; // 直接返回3分，不需要节段性反转判断
        }
        else {  // 微观脂肪:否
            return segmentalReversal == Yes ? 2 : 3; // 节段性反转: 是=2, 否=3
        }
    case Mild: // 轻度强化 <40%
        return 3;
    default:
        return 0;
    }
}

int CCLSScorer::calculatePath2(int enhancement, int microFat, int segmentalReversal, int arterialRatio, int diffusionRestriction)
{
    // 等信号路径
    switch (enhancement) {
    case Obvious: // 明显强化 >70%
        if (microFat == Yes) { // 微观脂肪:是
            return 5; // 直接返回5分，不需要节段性反转判断
        }
        else {  // 微观脂肪:否
            return segmentalReversal == Yes ? 3 : 4; // 节段性反转: 是=3, 否=4
        }
    case Moderate: // 中度强化 40-70%
        if (microFat == Yes) { // 微观脂肪:是
            return 3; // 直接返回3分，不需要节段性反转判断
        }
        else {  // 微观脂肪:否
            return segmentalReversal == Yes ? 2 : 3; // 节段性反转: 是=2, 否=3
        }
    case Mild: // 轻度强化 <40%
        if (microFat == Yes) { // 微观脂肪:是
            return 3; // 直接返回3分
        }
        else { // 微观脂肪:否
            if (diffusionRestriction == Yes) { // 弥散受限:是
                return 1;
            }
            else { // 弥散受限:否
                return 2;
            }
        }
    default:
        return 0;
    }
}

int CCLSScorer::calculatePath3(int enhancement, int microFat, int segmentalReversal, int arterialRatio, int diffusionRestriction)
{
    // 低信号路径
    switch (enhancement) {
    case Obvious: // 明显强化 >70%
        // 需要动脉期比值和弥散受限判断
        if (arterialRatio == Yes) { // 动脉期比值≥1.5: 是
            if (diffusionRestriction == Yes) { // 弥散受限:是
                return 2;
            }
            else { // 弥散受限:否
                return 3;
            }
        }
        else { // 动脉期比值≥1.5: 否
            if (diffusionRestriction == Yes) { // 弥散受限:是
                return 3;
            }
            else { // 弥散受限:否
                return 4;
            }
        }
    case Moderate: // 中度强化 40-70%
        return 3;
    case Mild: // 轻度强化 <40%
        if (microFat == Yes) { // 微观脂肪:是
            return 3;
        }
        else { // 微观脂肪:否
            return 1;
        }
    default:
        return 0;
    }
}

QString CCLSScorer::getDetailedDiagnosis(int t2Signal, int enhancement, int microFat, int segmentalReversal, int arterialRatio, int diffusionRestriction)
{
    // 高信号路径
    if (t2Signal == HighSignal) {
        if (enhancement == Obvious) { // 明显强化
            if (microFat == No && segmentalReversal == Yes) {
                return QString::fromLocal8Bit("嗜酸细胞瘤");
            }
        }
        else if (enhancement == Moderate) { // 中度强化
            if (microFat == Yes) {
                return QString::fromLocal8Bit("嫌色细胞癌");
            }
            else if (microFat == No) {
                if (segmentalReversal == No) {
                    return QString::fromLocal8Bit("嫌色细胞癌");
                }
                else if (segmentalReversal == Yes) {
                    return QString::fromLocal8Bit("嗜酸细胞瘤");
                }
            }
        }
    }
    // 等信号路径
    else if (t2Signal == EqualSignal) {
        if (enhancement == Obvious) { // 明显强化
            if (microFat == No) {
                if (segmentalReversal == No) {
                    return QString::fromLocal8Bit("嫌色细胞癌");
                }
                else if (segmentalReversal == Yes) {
                    return QString::fromLocal8Bit("嗜酸细胞瘤");
                }
            }
        }
        else if (enhancement == Moderate) { // 中度强化
            if (microFat == Yes) {
                return QString::fromLocal8Bit("嫌色细胞癌");
            }
            else if (microFat == No && segmentalReversal == No) {
                return QString::fromLocal8Bit("嗜酸细胞瘤");
            }
        }
        else if (enhancement == Mild) { // 轻度强化
            if (microFat == No) {
                return QString::fromLocal8Bit("乳头状细胞癌");
            }
        }
    }
    // 低信号路径
    else if (t2Signal == LowSignal) {
        if (enhancement == Obvious) { // 明显强化
            if (arterialRatio == Yes) {
                return QString::fromLocal8Bit("AML");
            }
        }
        else if (enhancement == Mild) { // 轻度强化
            if (microFat == No) {
                return QString::fromLocal8Bit("乳头状细胞癌 AML（少见）");
            }
        }
    }
    
    return ""; // 无特定疑似病症
}

void CCLSScorer::copyToClipboard(const QString &text)
{
    QClipboard *clipboard = QGuiApplication::clipboard();
    clipboard->setText(text);
}