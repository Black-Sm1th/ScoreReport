#ifndef CCLSAISCORER_H
#define CCLSAISCORER_H

#include <QObject>
#include <QString>
#include <QProcess>
#include "CommonFunc.h"
#include "ApiManager.h"

class CCLSAIScorer : public QObject
{
    Q_OBJECT
    QUICK_PROPERTY(QString, sourceText)
    QUICK_PROPERTY(double, cclsResult)
    QUICK_PROPERTY(double, ccrccResult)
    QUICK_PROPERTY(bool, calculating)
    SINGLETON_CLASS(CCLSAIScorer)

public:
    enum T2Signal {
        LowSignal = 0,      // 低信号
        MidSignal = 1,      // 中信号
        HighSignal = 2      // 高信号
    };
    Q_ENUM(T2Signal)

    enum Enhancement {
        Mild = 0,           // 轻度强化
        Moderate = 1,       // 中度强化
        Obvious = 2         // 明显强化
    };
    Q_ENUM(Enhancement)

    enum HasOrNot {
        No = 0,             // 无
        Yes = 1             // 有
    };
    Q_ENUM(HasOrNot)

    Q_INVOKABLE void calculateKidney(int t2, int enhancement, int micro, int sei, int ader, int disp);
    Q_INVOKABLE void finishScore(double cclsValue, double ccrccValue);
    Q_INVOKABLE void copyToClipboard();

signals:
    void calculationFinished(bool success, QString errorMessage);

private:
    QString resultText;
};

#endif // CCLSAISCORER_H
