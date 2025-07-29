#ifndef UCLSMRSMANAGER_H
#define UCLSMRSMANAGER_H

#include <QObject>
#include <QString>
#include "CommonFunc.h"
#include "ApiManager.h"

class UCLSMRSManager : public QObject
{
    Q_OBJECT
        QUICK_PROPERTY(QString, sourceText)
        SINGLETON_CLASS(UCLSMRSManager)

public:
    enum MacroFat {
        HasMacroFat = 0,  
        NoMacroFat = 1    
    };
    Q_ENUM(MacroFat)

        enum MicroFat {
        HasMicroFat = 0, 
        NoMicroFat = 1   
    };
    Q_ENUM(MicroFat)

        enum T2Signal {
        HighSignal = 0,    
        EqualSignal = 1,  
        LowSignal = 2       
    };
    Q_ENUM(T2Signal)

        enum IntensityLevel {
        High = 0,           
        Low = 1             
    };
    Q_ENUM(IntensityLevel)

        enum RatioCompare {
        Greater = 0,      
        LessEqual = 1      
    };
    Q_ENUM(RatioCompare)

        Q_INVOKABLE int calculateScore(int macroFat, int microFat, int t2Signal, int arterialRatio1, int arterialIndex, int delayedIndex, int ader1, int arterialRatio2, int ader2);
    Q_INVOKABLE QString getDetailedDiagnosis(int macroFat, int microFat, int t2Signal, int arterialRatio1, int arterialIndex, int delayedIndex, int ader1, int arterialRatio2, int ader2);
    Q_INVOKABLE bool needsOption(int macroFat, int microFat, int t2Signal, int optionIndex, int arterialRatio1 = -1, int arterialIndex = -1); // 检查是否需要显示某个选项
    Q_INVOKABLE void finishScore(int score, QString detailedDiagnosis);
    Q_INVOKABLE void copyToClipboard();

private:
    QString resultText;
    struct ScoreResult {
        int score;
        QString diagnosis;
    };
    ScoreResult evaluatePath(int macroFat, int microFat, int t2Signal, int arterialRatio1, int arterialIndex, int delayedIndex, int ader1, int arterialRatio2, int ader2);
};

#endif // UCLSMRSMANAGER_H

