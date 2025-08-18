#include "UCLSMRSManager.h"
#include <QClipboard>
#include <QGuiApplication>

UCLSMRSManager::UCLSMRSManager(QObject *parent) : QObject(parent)
{
    setsourceText(QString::fromUtf8("评分依据：UCLA UCLS MRS 系统《Medicina 2020, 56(11), 569》\n版本时间：2020 年"));
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

bool UCLSMRSManager::needsOption(int macroFat, int microFat, int t2Signal, int optionIndex, int arterialRatio1, int arterialIndex)
{
    switch(optionIndex) {
        case 0: // 宏观脂肪 - 总是需要
            return true;
        case 1: // 微脂肪 - 当无宏观脂肪时需要
            return macroFat == NoMacroFat;
        case 2: // T2信号 - 当无宏观脂肪时需要
            return macroFat == NoMacroFat;
        case 3: // 动脉强化比 - 当无宏观脂肪且无微脂肪时需要
            return macroFat == NoMacroFat && microFat == NoMicroFat;
        case 4: // 相对动脉增强比 - 当无宏观脂肪且无微脂肪且高或等T2且动脉强化比>100时需要
            return macroFat == NoMacroFat && microFat == NoMicroFat && (t2Signal == HighSignal || t2Signal == EqualSignal) && arterialRatio1 == Greater;
        case 5: // 延迟增强指数 - 当无宏观脂肪且无微脂肪且高或等T2且动脉强化比>100且相对动脉增强比<5时需要
            return macroFat == NoMacroFat && microFat == NoMicroFat && (t2Signal == HighSignal || t2Signal == EqualSignal) && arterialRatio1 == Greater && arterialIndex == LessEqual;
        case 6: // ADER1 - 当无宏观脂肪且无微脂肪且低T2信号时需要
            return macroFat == NoMacroFat && microFat == NoMicroFat && t2Signal == LowSignal;
        case 7: // 这里不需要arterialRatio2，因为已经在步骤3处理
            return false;
        case 8: // 这里不需要ader2，因为已经在步骤6处理
            return false;
        default:
            return false;
    }
}

UCLSMRSManager::ScoreResult UCLSMRSManager::evaluatePath(int macroFat, int microFat, int t2Signal, int arterialRatio1, int arterialIndex, int delayedIndex, int ader1, int arterialRatio2, int ader2)
{
    ScoreResult result;
    
    // 有宏观脂肪 → 1分（富脂肪AML）
    if (macroFat == HasMacroFat) {
        result.score = 1;
        result.diagnosis = QString::fromUtf8("富脂肪AML");
        return result;
    }
    
    // 无宏观脂肪
    if (macroFat == NoMacroFat) {
        // 有微脂肪
        if (microFat == HasMicroFat) {
            if (t2Signal == HighSignal) {
                // 无（宏观脂肪）-有（微脂肪）-高（T2信号强度）→ 5分（透明细胞癌）
                result.score = 5;
                result.diagnosis = QString::fromUtf8("透明细胞癌");
            } else { // 低T2信号 (有微脂肪时没有"等"选项)
                // 无（宏观脂肪）-有（微脂肪）-低（T2信号强度）→ 1分（乏脂肪AML）
                result.score = 1;
                result.diagnosis = QString::fromUtf8("乏脂肪AML");
            }
            return result;
        }
        
        // 无微脂肪
        if (microFat == NoMicroFat) {
            if (t2Signal == HighSignal || t2Signal == EqualSignal) {
                // 高或等T2信号强度
                if (arterialRatio1 == Greater) {
                    // 大于100（动脉强化比）
                    if (arterialIndex == Greater) {
                        // 无（宏观脂肪）-无（微脂肪）-高或等（T2信号强度）- 大于100（动脉强化比）-大于等于5（相对动脉增强比）→ 5分（透明细胞癌）
                        result.score = 5;
                        result.diagnosis = QString::fromUtf8("透明细胞癌");
                    } else {
                        // 小于5（相对动脉增强比）
                        if (delayedIndex == Greater) {
                            // 无（宏观脂肪）-无（微脂肪）-高或等（T2信号强度）- 大于100（动脉强化比）-小于5（相对动脉增强比）-大于等于125（延迟增强指数）→ 3分（嗜酸细胞瘤）
                            result.score = 3;
                            result.diagnosis = QString::fromUtf8("嗜酸细胞瘤");
                        } else {
                            // 无（宏观脂肪）-无（微脂肪）-高或等（T2信号强度）- 大于100（动脉强化比）-小于5（相对动脉增强比）-小于125（延迟增强指数）→ 4分（嫌色细胞癌）
                            result.score = 4;
                            result.diagnosis = QString::fromUtf8("嫌色细胞癌");
                        }
                    }
                } else {
                    // 无（宏观脂肪）-无（微脂肪）-高或等（T2信号强度）- 小于等于100（动脉强化比）→ 4分（乳头状细胞癌）
                    result.score = 4;
                    result.diagnosis = QString::fromUtf8("乳头状细胞癌");
                }
            } else {
                // 低T2信号强度
                if (arterialRatio1 == Greater) {
                    // 大于100（动脉强化比）
                    if (ader1 == Greater) {
                        // 无（宏观脂肪）-无（微脂肪）-低（T2信号强度）- 大于100（动脉强化比）-大于1.5（ADER）→ 2分（无脂肪AML）
                        result.score = 2;
                        result.diagnosis = QString::fromUtf8("无脂肪AML");
                    } else {
                        // 无（宏观脂肪）-无（微脂肪）-低（T2信号强度）- 大于100（动脉强化比）-小于等于1.5（ADER）→ 4分（透明细胞癌）
                        result.score = 4;
                        result.diagnosis = QString::fromUtf8("透明细胞癌");
                    }
                } else {
                    // 小于等于100（动脉强化比）
                    if (ader1 == Greater) {
                        // 无（宏观脂肪）-无（微脂肪）-低（T2信号强度）- 小于等于100（动脉强化比）-大于1.5（ADER）→ 2分（无脂肪AML）
                        result.score = 2;
                        result.diagnosis = QString::fromUtf8("无脂肪AML");
                    } else {
                        // 无（宏观脂肪）-无（微脂肪）-低（T2信号强度）- 小于等于100（动脉强化比）-小于等于1.5（ADER）→ 4分（乳头状细胞癌）
                        result.score = 4;
                        result.diagnosis = QString::fromUtf8("乳头状细胞癌");
                    }
                }
            }
        }
    }
    
    return result;
}

void UCLSMRSManager::finishScore(int score, QString detailedDiagnosis)
{
    QString scoreText;
    switch(score) {
        case 1: scoreText = QString::fromUtf8("肯定良性。"); break;
        case 2: scoreText = QString::fromUtf8("可能良性。"); break;
        case 3: scoreText = QString::fromUtf8("不确定。"); break;
        case 4: scoreText = QString::fromUtf8("可能恶性。"); break;
        case 5: scoreText = QString::fromUtf8("肯定ccRCC。"); break;
        default: scoreText = QString::fromUtf8("未知。"); break;
    }
    QString title = QString::fromUtf8("UCLS MRS评分：") + QString::number(score) + QString::fromUtf8("分");
    QString result = "";
    resultText = title;
    if (detailedDiagnosis != "") {
        result = detailedDiagnosis + QString::fromUtf8("，") + scoreText;
        resultText += "\n";
        resultText += result;
    }
    resultText += "\n";
    resultText += getsourceText();
    GET_SINGLETON(ApiManager)->addQualityRecord("UCLS MRS", title, "", result);
}

void UCLSMRSManager::copyToClipboard()
{
    QClipboard *clipboard = QGuiApplication::clipboard();
    clipboard->setText(resultText);
}
