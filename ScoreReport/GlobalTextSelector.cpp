#include "GlobalTextSelector.h"
#include <QGuiApplication>
#include <QClipboard>
#include <QMimeData>
#include <QDebug>
#include <QThread>
#include <cmath>

#ifdef Q_OS_WIN
#include <windows.h>
#endif

// 静态成员初始化
HHOOK GlobalTextSelector::s_mouseHook = nullptr;
GlobalTextSelector* GlobalTextSelector::s_instance = nullptr;

GlobalTextSelector::GlobalTextSelector(QObject* parent)
    : QObject(parent)
    , m_isMonitoring(false)
    , m_isMouseDown(false)
    , m_selectionTimer(new QTimer(this))
    , m_minDragDistance(10)      // 最小拖拽10像素才认为是划词
    , m_selectionDelay(200)      // 鼠标释放后200ms获取文本，避免与用户操作冲突
{
    m_selectionTimer->setSingleShot(true);
    connect(m_selectionTimer, &QTimer::timeout, this, &GlobalTextSelector::onSelectionTimeout);
}

GlobalTextSelector::~GlobalTextSelector()
{
    stopMonitoring();
}

void GlobalTextSelector::startMonitoring()
{
    if (m_isMonitoring) {
        return;
    }

#ifdef Q_OS_WIN
    if (!s_mouseHook) {
        s_instance = this;
        s_mouseHook = SetWindowsHookEx(WH_MOUSE_LL, MouseProc, nullptr, 0);
        if (s_mouseHook) {
            m_isMonitoring = true;
            qDebug() << "GlobalTextSelector: 开始监控划词";
        } else {
            qWarning() << "GlobalTextSelector: 无法安装鼠标钩子";
        }
    }
#endif
}

void GlobalTextSelector::stopMonitoring()
{
    if (!m_isMonitoring) {
        return;
    }

#ifdef Q_OS_WIN
    if (s_mouseHook) {
        UnhookWindowsHookEx(s_mouseHook);
        s_mouseHook = nullptr;
        s_instance = nullptr;
        m_isMonitoring = false;
        qDebug() << "GlobalTextSelector: 停止监控划词";
    }
#endif

    m_selectionTimer->stop();
    m_isMouseDown = false;
}

bool GlobalTextSelector::isMonitoring() const
{
    return m_isMonitoring;
}

LRESULT CALLBACK GlobalTextSelector::MouseProc(int nCode, WPARAM wParam, LPARAM lParam)
{
    if (nCode >= 0 && s_instance) {
        MSLLHOOKSTRUCT* mouseInfo = reinterpret_cast<MSLLHOOKSTRUCT*>(lParam);
        QPoint pos(mouseInfo->pt.x, mouseInfo->pt.y);

        switch (wParam) {
        case WM_LBUTTONDOWN:
            // 使用 QMetaObject::invokeMethod 确保在主线程处理
            QMetaObject::invokeMethod(s_instance, "handleMouseDown", Qt::QueuedConnection,
                                      Q_ARG(QPoint, pos));
            break;
        case WM_LBUTTONUP:
            QMetaObject::invokeMethod(s_instance, "handleMouseUp", Qt::QueuedConnection,
                                      Q_ARG(QPoint, pos));
            break;
        }
    }
    return CallNextHookEx(s_mouseHook, nCode, wParam, lParam);
}

void GlobalTextSelector::handleMouseDown(const QPoint& pos)
{
    m_isMouseDown = true;
    m_mouseDownPos = pos;
    m_selectionTimer->stop();
    
    // 保存当前剪贴板内容
    m_lastClipboardText = getClipboardText();
}

void GlobalTextSelector::handleMouseUp(const QPoint& pos)
{
    if (!m_isMouseDown) {
        return;
    }
    m_isMouseDown = false;

    // 计算拖拽距离
    int dx = pos.x() - m_mouseDownPos.x();
    int dy = pos.y() - m_mouseDownPos.y();
    double distance = std::sqrt(dx * dx + dy * dy);

    // 如果拖拽距离足够，认为是划词操作
    if (distance >= m_minDragDistance) {
        // 延迟一小段时间后获取选中文本，确保应用程序已完成选择
        m_selectionTimer->start(m_selectionDelay);
    }
}

void GlobalTextSelector::onSelectionTimeout()
{
    QString selectedText = getSelectedTextViaClipboard();
    
    if (!selectedText.isEmpty()) {
        emit textSelected(selectedText);
    }
}

QString GlobalTextSelector::getClipboardText()
{
#ifdef Q_OS_WIN
    QString result;
    
    // 尝试打开剪贴板，带重试
    int retries = 5;
    while (retries > 0) {
        if (OpenClipboard(nullptr)) {
            break;
        }
        Sleep(10);
        retries--;
    }
    
    if (retries == 0) {
        return result;
    }

    HANDLE hData = GetClipboardData(CF_UNICODETEXT);
    if (hData) {
        wchar_t* pszText = static_cast<wchar_t*>(GlobalLock(hData));
        if (pszText) {
            result = QString::fromWCharArray(pszText);
            GlobalUnlock(hData);
        }
    }
    
    CloseClipboard();
    return result;
#else
    return QString();
#endif
}

bool GlobalTextSelector::setClipboardText(const QString& text)
{
#ifdef Q_OS_WIN
    // 尝试打开剪贴板，带重试
    int retries = 5;
    while (retries > 0) {
        if (OpenClipboard(nullptr)) {
            break;
        }
        Sleep(10);
        retries--;
    }
    
    if (retries == 0) {
        return false;
    }

    EmptyClipboard();
    
    if (!text.isEmpty()) {
        size_t size = (text.length() + 1) * sizeof(wchar_t);
        HGLOBAL hGlobal = GlobalAlloc(GMEM_MOVEABLE, size);
        if (hGlobal) {
            wchar_t* pszDest = static_cast<wchar_t*>(GlobalLock(hGlobal));
            if (pszDest) {
                memcpy(pszDest, text.toStdWString().c_str(), size);
                GlobalUnlock(hGlobal);
                SetClipboardData(CF_UNICODETEXT, hGlobal);
            }
        }
    }
    
    CloseClipboard();
    return true;
#else
    Q_UNUSED(text)
    return false;
#endif
}

QString GlobalTextSelector::getSelectedTextViaClipboard()
{
#ifdef Q_OS_WIN
    // 先检查用户是否正在进行键盘操作，如果是则完全跳过，不干扰用户
    SHORT ctrlState = GetAsyncKeyState(VK_CONTROL);
    SHORT shiftState = GetAsyncKeyState(VK_SHIFT);
    SHORT altState = GetAsyncKeyState(VK_MENU);
    
    if ((ctrlState & 0x8000) || (shiftState & 0x8000) || (altState & 0x8000)) {
        // 用户正在进行键盘操作，完全跳过，不做任何剪贴板操作
        return QString();
    }
#endif

    // 清空剪贴板
    setClipboardText(QString());

    // 短暂延迟
    QThread::msleep(20);

    // 模拟 Ctrl+C
    simulateCopy();

    // 等待复制操作完成
    QThread::msleep(50);

    // 获取新的剪贴板内容
    QString selectedText = getClipboardText();

    // 始终恢复原来的剪贴板内容
    QThread::msleep(10);
    setClipboardText(m_lastClipboardText);

    // 如果没有获取到新内容
    if (selectedText.isEmpty()) {
        return QString();
    }

    // 如果获取到的和原来一样，说明没有选中新文本
    if (selectedText == m_lastClipboardText) {
        return QString();
    }

    return selectedText.trimmed();
}

void GlobalTextSelector::simulateCopy()
{
#ifdef Q_OS_WIN
    // 检查修饰键当前状态，如果用户正在按着这些键，则跳过模拟
    // 避免和用户的实际按键操作冲突
    SHORT ctrlState = GetAsyncKeyState(VK_CONTROL);
    SHORT shiftState = GetAsyncKeyState(VK_SHIFT);
    SHORT altState = GetAsyncKeyState(VK_MENU);
    
    // 如果任何修饰键被按下（最高位为1表示按下），跳过模拟
    if ((ctrlState & 0x8000) || (shiftState & 0x8000) || (altState & 0x8000)) {
        return;
    }

    // 模拟按下 Ctrl+C
    INPUT inputs[4] = {};
    ZeroMemory(inputs, sizeof(inputs));
    
    // Ctrl 按下
    inputs[0].type = INPUT_KEYBOARD;
    inputs[0].ki.wVk = VK_CONTROL;
    inputs[0].ki.dwFlags = 0;
    
    // C 按下
    inputs[1].type = INPUT_KEYBOARD;
    inputs[1].ki.wVk = 'C';
    inputs[1].ki.dwFlags = 0;
    
    // C 释放
    inputs[2].type = INPUT_KEYBOARD;
    inputs[2].ki.wVk = 'C';
    inputs[2].ki.dwFlags = KEYEVENTF_KEYUP;
    
    // Ctrl 释放
    inputs[3].type = INPUT_KEYBOARD;
    inputs[3].ki.wVk = VK_CONTROL;
    inputs[3].ki.dwFlags = KEYEVENTF_KEYUP;
    
    // 逐个发送，避免一次性发送导致的问题
    SendInput(1, &inputs[0], sizeof(INPUT));  // Ctrl down
    Sleep(5);
    SendInput(1, &inputs[1], sizeof(INPUT));  // C down
    Sleep(5);
    SendInput(1, &inputs[2], sizeof(INPUT));  // C up
    Sleep(5);
    SendInput(1, &inputs[3], sizeof(INPUT));  // Ctrl up
    Sleep(10);  // 确保按键完全释放
#endif
}
