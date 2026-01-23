#ifndef GLOBALTEXTSELECTOR_H
#define GLOBALTEXTSELECTOR_H

#include <QObject>
#include <QString>
#include <QPoint>
#include <QTimer>
#include <QThread>
#include <QMutex>

#ifdef Q_OS_WIN
#include <windows.h>
#endif

class TextSelectorWorker;

/**
 * @brief 全局划词监听器
 * 通过监听鼠标事件 + 剪贴板方式检测全局文本选择
 * 使用工作线程处理耗时操作，不阻塞主线程
 */
class GlobalTextSelector : public QObject
{
    Q_OBJECT

public:
    explicit GlobalTextSelector(QObject* parent = nullptr);
    ~GlobalTextSelector();

    void startMonitoring();
    void stopMonitoring();
    bool isMonitoring() const;

signals:
    void textSelected(const QString& selectedText);

    // 内部信号
    void requestGetText();

private slots:
    void handleMouseDown(const QPoint& pos);
    void handleMouseUp(const QPoint& pos);
    void onSelectionTimeout();
    void onTextRetrieved(const QString& text);

private:
    static LRESULT CALLBACK MouseProc(int nCode, WPARAM wParam, LPARAM lParam);

    static HHOOK s_mouseHook;
    static GlobalTextSelector* s_instance;

    bool m_isMonitoring;
    bool m_isMouseDown;
    QPoint m_mouseDownPos;
    QTimer* m_selectionTimer;
    
    int m_minDragDistance;
    int m_selectionDelay;

    // 工作线程
    QThread* m_workerThread;
    TextSelectorWorker* m_worker;
};

/**
 * @brief 工作线程类，处理剪贴板操作
 */
class TextSelectorWorker : public QObject
{
    Q_OBJECT

public:
    explicit TextSelectorWorker(QObject* parent = nullptr);

public slots:
    void getSelectedText();

signals:
    void textRetrieved(const QString& text);

private:
    QString getClipboardText();
    bool setClipboardText(const QString& text);
    void simulateCopy();

    QString m_savedClipboardText;
    QMutex m_mutex;
    bool m_isProcessing;
};

#endif // GLOBALTEXTSELECTOR_H
