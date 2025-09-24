#ifndef GLOBALTEXTMONITOR_H
#define GLOBALTEXTMONITOR_H

#include <QObject>
#include <QTimer>
#include <QString>
#include <QThread>
#include <QMutex>
#include <QMetaObject>

#ifdef Q_OS_WIN
#include <windows.h>
#include <oleacc.h>
#include <UIAutomation.h>
#include <comdef.h>
#pragma comment(lib, "oleacc.lib")
#pragma comment(lib, "user32.lib")
#endif

// 前置声明
class TextMonitorWorker;

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

private slots:
    void onWorkerTextSelected(const QString& selectedText);

private:
    QThread* m_workerThread;
    TextMonitorWorker* m_worker;
    bool m_isMonitoring;
    int m_checkInterval; // 检查间隔，毫秒
};

// 工作线程类，处理文本监控的实际工作
class TextMonitorWorker : public QObject
{
    Q_OBJECT

public:
    explicit TextMonitorWorker(int checkInterval, QObject* parent = nullptr);
    ~TextMonitorWorker();

public slots:
    void startMonitoring();
    void stopMonitoring();

signals:
    void textSelected(const QString& selectedText);

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
    QMutex m_mutex;
    bool m_isMonitoring;
    int m_checkInterval;
};

#endif // GLOBALTEXTMONITOR_H 