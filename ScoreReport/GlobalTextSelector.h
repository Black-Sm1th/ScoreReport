#ifndef GLOBALTEXTSELECTOR_H
#define GLOBALTEXTSELECTOR_H

#include <QObject>
#include <QString>
#include <QPoint>
#include <QTimer>

#ifdef Q_OS_WIN
#include <windows.h>
#endif

/**
 * @brief 全局划词监听器
 * 通过监听鼠标事件 + 剪贴板方式检测全局文本选择
 * 比 UI Automation 方式更通用，几乎适用于所有应用程序
 */
class GlobalTextSelector : public QObject
{
    Q_OBJECT

public:
    explicit GlobalTextSelector(QObject* parent = nullptr);
    ~GlobalTextSelector();

    /**
     * @brief 开始监控划词
     */
    void startMonitoring();

    /**
     * @brief 停止监控划词
     */
    void stopMonitoring();

    /**
     * @brief 是否正在监控
     * @return true 正在监控，false 未监控
     */
    bool isMonitoring() const;

signals:
    /**
     * @brief 检测到文本选择时发出
     * @param selectedText 选中的文本
     */
    void textSelected(const QString& selectedText);

private slots:
    void onSelectionTimeout();
    // 这两个需要是槽函数，以便通过 QMetaObject::invokeMethod 调用
    void handleMouseDown(const QPoint& pos);
    void handleMouseUp(const QPoint& pos);

private:
    static LRESULT CALLBACK MouseProc(int nCode, WPARAM wParam, LPARAM lParam);
    QString getSelectedTextViaClipboard();
    QString getClipboardText();
    bool setClipboardText(const QString& text);
    void simulateCopy();

    static HHOOK s_mouseHook;
    static GlobalTextSelector* s_instance;

    bool m_isMonitoring;
    bool m_isMouseDown;
    QPoint m_mouseDownPos;
    QTimer* m_selectionTimer;
    QString m_lastClipboardText;  // 保存原剪贴板内容
    
    int m_minDragDistance;        // 最小拖拽距离，防止误触发
    int m_selectionDelay;         // 选择后延迟获取文本的时间（毫秒）
};

#endif // GLOBALTEXTSELECTOR_H
