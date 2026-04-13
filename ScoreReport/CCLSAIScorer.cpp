#include "CCLSAIScorer.h"
#include <QGuiApplication>
#include <QClipboard>
#include <QDebug>

CCLSAIScorer::CCLSAIScorer(QObject* parent)
    : QObject(parent)
    , resultText("")
{
    setsourceText(QStringLiteral("评分依据：Mayo Clinic CCLS系统（整合cn-ccLS囊变特征）\n版本时间：第2版（2023年修订）"));
    setcclsResult(0.0);
    setccrccResult(0.0);
    setcalculating(false);
}

void CCLSAIScorer::calculateKidney(int t2, int enhancement, int micro, int sei, int ader, int disp)
{
    // 检查所有参数是否已设置
    if (t2 == -1 || enhancement == -1 || micro == -1 ||
        sei == -1 || ader == -1 || disp == -1) {
        qWarning() << QStringLiteral("部分参数未设置，无法计算");
        emit calculationFinished(false, QStringLiteral("部分参数未设置"));
        return;
    }

    setcalculating(true);

    // 构建Python程序路径
    QString pythonPath = "Scripts/kidney_processor.exe";
    
    // 准备参数
    QStringList arguments;
    arguments << QString::number(t2)
              << QString::number(enhancement)
              << QString::number(micro)
              << QString::number(sei)
              << QString::number(ader)
              << QString::number(disp);

    // 创建进程
    QProcess* process = new QProcess(this);
    
    // 连接信号
    connect(process, QOverload<int, QProcess::ExitStatus>::of(&QProcess::finished),
        [=](int exitCode, QProcess::ExitStatus exitStatus) {
            setcalculating(false);
            
            if (exitStatus == QProcess::NormalExit && exitCode == 0) {
                QString output = QString::fromUtf8(process->readAllStandardOutput());
                QString error = QString::fromUtf8(process->readAllStandardError());
                
                // 解析输出结果
                QStringList lines = output.split('\n', Qt::SkipEmptyParts);
                bool foundCCLS = false;
                bool foundCCRCC = false;
                
                for (const QString& line : lines) {
                    if (line.contains("result ccls:", Qt::CaseInsensitive)) {
                        QStringList parts = line.split(':');
                        if (parts.size() >= 2) {
                            bool ok;
                            double value = parts[1].trimmed().toDouble(&ok);
                            if (ok) {
                                setcclsResult(value);
                                foundCCLS = true;
                                qDebug() << QStringLiteral("CCLS结果:") << value;
                            }
                        }
                    } else if (line.contains("result ccrcc:", Qt::CaseInsensitive)) {
                        QStringList parts = line.split(':');
                        if (parts.size() >= 2) {
                            bool ok;
                            double value = parts[1].trimmed().toDouble(&ok);
                            if (ok) {
                                setccrccResult(value);
                                foundCCRCC = true;
                                qDebug() << QStringLiteral("CCRCC结果:") << value;
                            }
                        }
                    }
                }
                
                if (!error.isEmpty()) {
                    qDebug() << QStringLiteral("错误:") << error;
                }
                
                if (foundCCLS && foundCCRCC) {
                    finishScore(getcclsResult(), getccrccResult());
                    emit calculationFinished(true, "");
                } else {
                    emit calculationFinished(false, QStringLiteral("未能解析计算结果"));
                }
            } else {
                qWarning() << QStringLiteral("计算失败！退出代码:") << exitCode;
                QString errorMsg = QString::fromUtf8(process->readAllStandardError());
                qWarning() << QStringLiteral("错误信息:") << errorMsg;
                emit calculationFinished(false, QStringLiteral("计算失败：") + errorMsg);
            }
            process->deleteLater();
        });
    
    connect(process, &QProcess::errorOccurred, [=](QProcess::ProcessError error) {
        setcalculating(false);
        qWarning() << QStringLiteral("进程错误:") << error;
        QString errorMsg = process->errorString();
        qWarning() << QStringLiteral("错误信息:") << errorMsg;
        emit calculationFinished(false, QStringLiteral("进程错误：") + errorMsg);
        process->deleteLater();
    });

    // 启动进程
    qDebug() << QStringLiteral("启动计算程序:") << pythonPath;
    qDebug() << QStringLiteral("参数:") << arguments;
    process->start(pythonPath, arguments);
}

void CCLSAIScorer::finishScore(double cclsValue, double ccrccValue)
{
    QString title = QStringLiteral("CCLS-AI评分结果");
    QString cclsText = QStringLiteral("CCLS：") + QString::number(cclsValue, 'f', 4);
    QString ccrccText = QStringLiteral("CCRCC：") + QString::number(ccrccValue, 'f', 4);
    
    resultText = title + "\n" + cclsText + "\n" + ccrccText + "\n" + getsourceText();
    
    GET_SINGLETON(ApiManager)->addQualityRecord("CCLS AI", title, "", cclsText + "\n" + ccrccText);
}

void CCLSAIScorer::copyToClipboard()
{
    QClipboard *clipboard = QGuiApplication::clipboard();
    clipboard->setText(resultText);
}