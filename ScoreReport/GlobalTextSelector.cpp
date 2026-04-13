#include "GlobalTextSelector.h"
#include <QDebug>
#include <QMutexLocker>
#include <cmath>

#ifdef Q_OS_WIN
#include <windows.h>
#endif

// ============================================================
// GlobalTextSelector 实现
// ============================================================

HHOOK GlobalTextSelector::s_mouseHook = nullptr;
GlobalTextSelector* GlobalTextSelector::s_instance = nullptr;

GlobalTextSelector::GlobalTextSelector(QObject* parent)
    : QObject(parent)
    , m_isMonitoring(false)
    , m_isMouseDown(false)
    , m_selectionTimer(new QTimer(this))
    , m_minDragDistance(10)
    , m_selectionDelay(200)
    , m_workerThread(nullptr)
    , m_worker(nullptr)
{
    m_selectionTimer->setSingleShot(true);
    connect(m_selectionTimer, &QTimer::timeout, this, &GlobalTextSelector::onSelectionTimeout);

    // 初始化工作线程
    m_workerThread = new QThread(this);
    m_worker = new TextSelectorWorker();
    m_worker->moveToThread(m_workerThread);

    connect(this, &GlobalTextSelector::requestGetText, m_worker, &TextSelectorWorker::getSelectedText, Qt::QueuedConnection);
    connect(m_worker, &TextSelectorWorker::textRetrieved, this, &GlobalTextSelector::onTextRetrieved, Qt::QueuedConnection);
    connect(m_workerThread, &QThread::finished, m_worker, &QObject::deleteLater);

    m_workerThread->start();
}

GlobalTextSelector::~GlobalTextSelector()
{
    stopMonitoring();

    if (m_workerThread) {
        m_workerThread->quit();
        m_workerThread->wait(1000);
    }
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
    // 不在这里读取剪贴板，减少操作
}

void GlobalTextSelector::handleMouseUp(const QPoint& pos)
{
    if (!m_isMouseDown) {
        return;
    }
    m_isMouseDown = false;

    int dx = pos.x() - m_mouseDownPos.x();
    int dy = pos.y() - m_mouseDownPos.y();
    double distance = std::sqrt(dx * dx + dy * dy);

    if (distance >= m_minDragDistance) {
        m_selectionTimer->start(m_selectionDelay);
    }
}

void GlobalTextSelector::onSelectionTimeout()
{
    // 发信号给工作线程处理
    emit requestGetText();
}

void GlobalTextSelector::onTextRetrieved(const QString& text)
{
    if (!text.isEmpty()) {
        emit textSelected(text);
    }
}

// ============================================================
// TextSelectorWorker 实现 - 在工作线程中运行
// ============================================================

TextSelectorWorker::TextSelectorWorker(QObject* parent)
    : QObject(parent)
    , m_isProcessing(false)
{
}

void TextSelectorWorker::getSelectedText()
{
    // 防止重复处理
    {
        QMutexLocker locker(&m_mutex);
        if (m_isProcessing) {
            return;
        }
        m_isProcessing = true;
    }

#ifdef Q_OS_WIN
    // 检查用户是否正在进行键盘操作
    SHORT ctrlState = GetAsyncKeyState(VK_CONTROL);
    SHORT shiftState = GetAsyncKeyState(VK_SHIFT);
    SHORT altState = GetAsyncKeyState(VK_MENU);
    
    if ((ctrlState & 0x8000) || (shiftState & 0x8000) || (altState & 0x8000)) {
        QMutexLocker locker(&m_mutex);
        m_isProcessing = false;
        return;
    }
#endif

    // 保存当前剪贴板内容
    m_savedClipboardText = getClipboardText();

    // 清空剪贴板
    setClipboardText(QString());
    Sleep(15);

    // 模拟 Ctrl+C
    simulateCopy();
    Sleep(30);

    // 获取选中的文本
    QString selectedText = getClipboardText();

    // 恢复原来的剪贴板内容
    Sleep(10);
    setClipboardText(m_savedClipboardText);

    {
        QMutexLocker locker(&m_mutex);
        m_isProcessing = false;
    }

    // 检查是否有新选中的文本
    if (!selectedText.isEmpty() && selectedText != m_savedClipboardText) {
        emit textRetrieved(selectedText.trimmed());
    }
}

QString TextSelectorWorker::getClipboardText()
{
#ifdef Q_OS_WIN
    QString result;
    
    // 尝试打开剪贴板，减少重试次数
    int retries = 3;
    while (retries > 0) {
        if (OpenClipboard(nullptr)) {
            break;
        }
        Sleep(5);
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

bool TextSelectorWorker::setClipboardText(const QString& text)
{
#ifdef Q_OS_WIN
    int retries = 3;
    while (retries > 0) {
        if (OpenClipboard(nullptr)) {
            break;
        }
        Sleep(5);
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

void TextSelectorWorker::simulateCopy()
{
#ifdef Q_OS_WIN
    // 再次检查修饰键状态
    SHORT ctrlState = GetAsyncKeyState(VK_CONTROL);
    SHORT shiftState = GetAsyncKeyState(VK_SHIFT);
    SHORT altState = GetAsyncKeyState(VK_MENU);
    
    if ((ctrlState & 0x8000) || (shiftState & 0x8000) || (altState & 0x8000)) {
        return;
    }

    INPUT inputs[4] = {};
    ZeroMemory(inputs, sizeof(inputs));
    
    inputs[0].type = INPUT_KEYBOARD;
    inputs[0].ki.wVk = VK_CONTROL;
    inputs[0].ki.dwFlags = 0;
    
    inputs[1].type = INPUT_KEYBOARD;
    inputs[1].ki.wVk = 'C';
    inputs[1].ki.dwFlags = 0;
    
    inputs[2].type = INPUT_KEYBOARD;
    inputs[2].ki.wVk = 'C';
    inputs[2].ki.dwFlags = KEYEVENTF_KEYUP;
    
    inputs[3].type = INPUT_KEYBOARD;
    inputs[3].ki.wVk = VK_CONTROL;
    inputs[3].ki.dwFlags = KEYEVENTF_KEYUP;
    
    // 一次性发送，更高效
    SendInput(4, inputs, sizeof(INPUT));
#endif
}
