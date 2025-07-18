#ifndef CCLSSCORER_H
#define CCLSSCORER_H

#include <QObject>
#include <QString>

class CCLSScorer : public QObject
{
    Q_OBJECT

public:
    enum T2Signal {
        HighSignal = 0,
        EqualSignal = 1,
        LowSignal = 2   
    };
    Q_ENUM(T2Signal)

        enum Enhancement {
        Obvious = 0,    
        Moderate = 1,    
        Mild = 2          
    };
    Q_ENUM(Enhancement)

        enum YesNo {
        Yes = 0,  // "是" 对应界面 index 0
        No = 1    // "否" 对应界面 index 1
    };
    Q_ENUM(YesNo)

    explicit CCLSScorer(QObject* parent = nullptr);

    Q_INVOKABLE int calculateScore(int t2Signal, int enhancement, int microFat, int segmentalReversal, int arterialRatio, int diffusionRestriction);
    Q_INVOKABLE QString getDetailedDiagnosis(int t2Signal, int enhancement, int microFat, int segmentalReversal, int arterialRatio, int diffusionRestriction);
    Q_INVOKABLE bool needsOption(int t2Signal, int enhancement, int optionIndex, int microFat = -1); // 检查是否需要显示某个选项
    Q_INVOKABLE void copyToClipboard(const QString &text); // 复制文本到剪贴板

private:
    int calculatePath1(int enhancement, int microFat, int segmentalReversal, int arterialRatio, int diffusionRestriction);
    int calculatePath2(int enhancement, int microFat, int segmentalReversal, int arterialRatio, int diffusionRestriction);
    int calculatePath3(int enhancement, int microFat, int segmentalReversal, int arterialRatio, int diffusionRestriction);
};

#endif // CCLSSCORER_H 