#ifndef UCLSCTSSCORER_H
#define UCLSCTSSCORER_H

#include <QObject>
#include <QString>
#include "CommonFunc.h"
#include "ApiManager.h"

class UCLSCTSScorer : public QObject
{
    Q_OBJECT
    QUICK_PROPERTY(QString, sourceText)
    SINGLETON_CLASS(UCLSCTSScorer)

public:
    enum YesNo {
        Yes = 0,  // "是" 对应界面 index 0
        No = 1    // "否" 对应界面 index 1
    };
    Q_ENUM(YesNo)

    enum AbsoluteEnhancement {
        Over50 = 0,     // >50=2分
        Between25_50 = 1,    // 25-50=1分
        Under25 = 2     // <25=0分
    };
    Q_ENUM(AbsoluteEnhancement)

    enum RelativeEnhancement {
        Under0 = 0,     // <0=0分
        Between1_10 = 1,    // 1-10=1分
        Between10_20 = 2,   // 10-20=2分
        Over20 = 3      // >20=3分
    };
    Q_ENUM(RelativeEnhancement)

    Q_INVOKABLE int calculateScore(int nonEnhancedAttenuation, int maxEnhancementPhase, 
                                  int absoluteEnhancement, int relativeEnhancement,
                                  int heterogeneousEnhancement, int irregularShape,
                                  int neovascularity, int dystrophicCalcification, int splittingSign);
    
    Q_INVOKABLE bool needsOption(int stepIndex, int nonEnhancedAttenuation, int maxEnhancementPhase, int heterogeneousEnhancement, int irregularShape, int neovascularity); // 检查是否需要显示某个选项
    Q_INVOKABLE void finishScore(int score);
    Q_INVOKABLE void copyToClipboard(); // 复制文本到剪贴板

private:
    QString resultText;
};

#endif // UCLSCTSSCORER_H 