#ifndef GLOBALTEXTMONITOR_H
#define GLOBALTEXTMONITOR_H

#include <QObject>
#include <QString>
#include <QThread>
#include <QMutex>
#include <QTimer>
#include <QWaitCondition>

#ifdef Q_OS_WIN
#include <windows.h>
#include <oleacc.h>
#include <UIAutomation.h>
#include <comdef.h>
#pragma comment(lib, "oleacc.lib")
#pragma comment(lib, "user32.lib")
#endif

// 前向声明
class TextMonitorWorker;

/**
 * @brief 全局文本监控器 - 主类
 * 负责对外接口和工作线程管理
 */
class GlobalTextMonitor : public QObject
{
    Q_OBJECT

public:
    explicit GlobalTextMonitor(QObject* parent = nullptr);
    ~GlobalTextMonitor();

    void startMonitoring();
    void stopMonitoring();
    bool isMonitoring() const;

signals:
    void textSelected(const QString& selectedText);

    // 内部信号，用于与工作线程通信
    void startWorker();
    void stopWorker();

private slots:
    void onWorkerFinished();
    void onTextDetected(const QString& text);

private:
    void initializeWorkerThread();
    void cleanupWorkerThread();

    QThread* m_workerThread;
    TextMonitorWorker* m_worker;
    QMutex m_statusMutex;
    bool m_isMonitoring;
    int m_checkInterval; // 检查间隔，毫秒
};

/**
 * @brief 文本监控工作线程类
 * 运行在独立线程中，负责所有UI Automation操作
 */
class TextMonitorWorker : public QObject
{
    Q_OBJECT

public:
    explicit TextMonitorWorker(int checkInterval = 100, QObject* parent = nullptr);
    ~TextMonitorWorker();

public slots:
    void startMonitoring();
    void stopMonitoring();

signals:
    void textSelected(const QString& selectedText);
    void finished();

private slots:
    void checkTextSelection();

private:
    void initializeUIAutomation();
    void cleanupUIAutomation();
    QString getSelectedTextFromElement(IUIAutomationElement* element);
    QString getSelectedTextFromActiveWindow();
    bool isTextChanged(const QString& newText);
    bool isWindowChanged(HWND currentWindow);
    void handleWindowSwitch(HWND newWindow, const QString& selectedText);

#ifdef Q_OS_WIN
    IUIAutomation* m_automation;
    IUIAutomationElement* m_rootElement;
    HWND m_currentActiveWindow;
#endif

    QTimer* m_timer;
    QString m_lastSelectedText;
    QString m_currentSelectedText;
    QMutex m_dataMutex;
    bool m_isRunning;
    bool m_isCleanedUp;
    int m_checkInterval;
};

#endif // GLOBALTEXTMONITOR_H 