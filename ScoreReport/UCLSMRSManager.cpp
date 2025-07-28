#include "UCLSMRSManager.h"
#include <QClipboard>
#include <QGuiApplication>

UCLSMRSManager::UCLSMRSManager(QObject* parent) : QObject(parent)
{
    setsourceText("Medicina 2020, 56(11), 569");
}

int UCLSMRSManager::calculateScore(int macroFat, int microFat, int t2Signal, int arterialRatio1, int arterialIndex, int delayedIndex, int ader1, int arterialRatio2, int ader2)
{
    ScoreResult result = evaluatePath(macroFat, microFat, t2Signal, arterialRatio1, arterialIndex, delayedIndex, ader1, arterialRatio2, ader2);
    return result.score;
}

QString UCLSMRSManager::getDetailedDiagnosis(int macroFat, int microFat, int t2Signal, int arterialRatio1, int arterialIndex, int delayedIndex, int ader1, int arterialRatio2, int ader2)
{
    ScoreResult result = evaluatePath(macroFat, microFat, t2Signal, arterialRatio1, arterialIndex, delayedIndex, ader1, arterialRatio2, ader2);
    return result.diagnosis;
}

bool UCLSMRSManager::needsOption(int macroFat, int microFat, int t2Signal, int optionIndex)
{
    switch (optionIndex) {
    case 0: // 宏观脂肪 - 总是需要
        return true;
    case 1: // 微脂肪 - 当无宏观脂肪时需要
        return macroFat == NoMacroFat;
    case 2: // T2信号 - 当无宏观脂肪时需要
        return macroFat == NoMacroFat;
    case 3: // 相对动脉强化比1 - 当无宏观脂肪且有微脂肪时需要
        return macroFat == NoMacroFat && microFat == HasMicroFat;
    case 4: // 相对动脉增强指数 - 当无宏观脂肪且有微脂肪且T2高信号时需要
        return macroFat == NoMacroFat && microFat == HasMicroFat && t2Signal == HighSignal;
    case 5: // 延迟增强指数 - 当无宏观脂肪且有微脂肪且T2高信号时需要
        return macroFat == NoMacroFat && microFat == HasMicroFat && t2Signal == HighSignal;
    case 6: // ADER1 - 当无宏观脂肪且有微脂肪且T2高信号时需要
        return macroFat == NoMacroFat && microFat == HasMicroFat && t2Signal == HighSignal;
    case 7: // 相对动脉强化比2 - 当无宏观脂肪且有微脂肪且T2低信号时需要
        return macroFat == NoMacroFat && microFat == HasMicroFat && t2Signal == LowSignal;
    case 8: // ADER2 - 当无宏观脂肪且有微脂肪且T2低信号时需要
        return macroFat == NoMacroFat && microFat == HasMicroFat && t2Signal == LowSignal;
    default:
        return false;
    }
}

UCLSMRSManager::ScoreResult UCLSMRSManager::evaluatePath(int macroFat, int microFat, int t2Signal, int arterialRatio1, int arterialIndex, int delayedIndex, int ader1, int arterialRatio2, int ader2)
{
    ScoreResult result;

    // 有宏观脂肪
    if (macroFat == HasMacroFat) {
        result.score = 1;
        result.diagnosis = "富脂肪AML";
        return result;
    }

    // 无宏观脂肪
    if (macroFat == NoMacroFat) {
        // 有微脂肪
        if (microFat == HasMicroFat) {
            // T2高信号
            if (t2Signal == HighSignal) {
                // 相对动脉强化比>100
                if (arterialRatio1 == Greater) {
                    // 相对动脉增强指数≥5
                    if (arterialIndex == Greater) {
                        // 延迟增强指数≥125
                        if (delayedIndex == Greater) {
                            // ADER>1.5
                            if (ader1 == Greater) {
                                result.score = 5;
                                result.diagnosis = "透明细胞癌";
                            }
                            else { // ADER≤1.5
                                result.score = 1;
                                result.diagnosis = "乏脂肪AML";
                            }
                        }
                        else { // 延迟增强指数<125
                            // ADER>1.5
                            if (ader1 == Greater) {
                                result.score = 4;
                                result.diagnosis = "透明细胞癌";
                            }
                            else { // ADER≤1.5
                                result.score = 3;
                                result.diagnosis = "嗜酸细胞癌";
                            }
                        }
                    }
                    else { // 相对动脉增强指数<5
                        // 延迟增强指数≥125
                        if (delayedIndex == Greater) {
                            // ADER>1.5
                            if (ader1 == Greater) {
                                result.score = 4;
                                result.diagnosis = "嫌色细胞癌";
                            }
                            else { // ADER≤1.5
                                result.score = 4;
                                result.diagnosis = "乳头状细胞癌";
                            }
                        }
                        else { // 延迟增强指数<125
                            // ADER>1.5
                            if (ader1 == Greater) {
                                result.score = 2;
                                result.diagnosis = "无脂肪AML";
                            }
                            else { // ADER≤1.5
                                result.score = 4;
                                result.diagnosis = "透明细胞癌";
                            }
                        }
                    }
                }
                else { // 相对动脉强化比≤100
                    result.score = 2;
                    result.diagnosis = "无脂肪AML";
                }
            }
            else { // T2低信号
                // 相对动脉强化比>100
                if (arterialRatio2 == Greater) {
                    // ADER>1.5
                    if (ader2 == Greater) {
                        result.score = 4;
                        result.diagnosis = "透明细胞癌";
                    }
                    else { // ADER≤1.5
                        result.score = 2;
                        result.diagnosis = "无脂肪AML";
                    }
                }
                else { // 相对动脉强化比≤100
                    // ADER>1.5
                    if (ader2 == Greater) {
                        result.score = 4;
                        result.diagnosis = "乳头状细胞癌";
                    }
                    else { // ADER≤1.5
                        result.score = 2;
                        result.diagnosis = "无脂肪AML";
                    }
                }
            }
        }
        else { // 无微脂肪
            result.score = 2;
            result.diagnosis = "无脂肪AML";
        }
    }

    return result;
}

void UCLSMRSManager::finishScore(int score, QString detailedDiagnosis)
{
    QString scoreText;
    switch (score) {
    case 1: scoreText = "肯定良性"; break;
    case 2: scoreText = "可能良性"; break;
    case 3: scoreText = "不确定"; break;
    case 4: scoreText = "可能恶性"; break;
    case 5: scoreText = "肯定ccRCC"; break;
    default: scoreText = "未知"; break;
    }

    resultText = QString("UCLS-MRS评分：%1分\n符合%2典型特征\n%3\n%4")
        .arg(score)
        .arg(detailedDiagnosis)
        .arg(scoreText)
        .arg(getsourceText());
}

void UCLSMRSManager::copyToClipboard()
{
    QClipboard* clipboard = QGuiApplication::clipboard();
    clipboard->setText(resultText);
}
