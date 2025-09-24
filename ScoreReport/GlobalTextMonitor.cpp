#include "GlobalTextMonitor.h"
#include <QDebug>
#include <QGUIApplication>
#include <QClipboard>

#ifdef Q_OS_WIN
#include <comutil.h>
#include <atlcomcli.h>

#pragma comment(lib, "comsuppw.lib")
#pragma comment(lib, "oleaut32.lib")
#endif

GlobalTextMonitor::GlobalTextMonitor(QObject* parent)
    : QObject(parent)
    , m_workerThread(nullptr)
    , m_worker(nullptr)
    , m_isMonitoring(false)
    , m_checkInterval(100) // 100ms检查间隔
{
    // 创建工作线程
    m_workerThread = new QThread(this);
    
    // 创建工作对象
    m_worker = new TextMonitorWorker(m_checkInterval);
    
    // 将工作对象移到工作线程中
    m_worker->moveToThread(m_workerThread);
    
    // 连接信号
    connect(m_worker, &TextMonitorWorker::textSelected, 
            this, &GlobalTextMonitor::onWorkerTextSelected);
    
    // 连接线程生命周期信号
    connect(m_workerThread, &QThread::finished, 
            m_worker, &QObject::deleteLater);
    
    // 启动工作线程
    m_workerThread->start();
}

GlobalTextMonitor::~GlobalTextMonitor()
{
    stopMonitoring();
    
    // 停止并清理工作线程
    if (m_workerThread) {
        m_workerThread->quit();
        m_workerThread->wait();
    }
}

void GlobalTextMonitor::startMonitoring()
{
    if (m_isMonitoring) {
        return;
    }

    m_isMonitoring = true;
    
    // 通过Qt信号槽机制启动工作线程中的监控
    QMetaObject::invokeMethod(m_worker, "startMonitoring", Qt::QueuedConnection);
}

void GlobalTextMonitor::stopMonitoring()
{
    if (!m_isMonitoring) {
        return;
    }

    m_isMonitoring = false;
    
    // 通过Qt信号槽机制停止工作线程中的监控
    QMetaObject::invokeMethod(m_worker, "stopMonitoring", Qt::QueuedConnection);
}

bool GlobalTextMonitor::isMonitoring() const
{
    return m_isMonitoring;
}

void GlobalTextMonitor::onWorkerTextSelected(const QString& selectedText)
{
    // 从工作线程接收到文本选中信号，转发给外部
    emit textSelected(selectedText);
}

// ========== TextMonitorWorker 类实现 ==========

TextMonitorWorker::TextMonitorWorker(int checkInterval, QObject* parent)
    : QObject(parent)
    , m_timer(new QTimer(this))
    , m_isMonitoring(false)
    , m_checkInterval(checkInterval)
#ifdef Q_OS_WIN
    , m_automation(nullptr)
    , m_rootElement(nullptr)
    , m_currentActiveWindow(nullptr)
#endif
{
    // 连接定时器信号
    connect(m_timer, &QTimer::timeout, this, &TextMonitorWorker::checkTextSelection);
    
    // 初始化UI Automation
    initializeUIAutomation();
}

TextMonitorWorker::~TextMonitorWorker()
{
    stopMonitoring();
    cleanupUIAutomation();
}

void TextMonitorWorker::startMonitoring()
{
    if (m_isMonitoring) {
        return;
    }

    QMutexLocker locker(&m_mutex);
    m_isMonitoring = true;
    m_lastSelectedText.clear();
    m_currentSelectedText.clear();

#ifdef Q_OS_WIN
    // 初始化当前活动窗口
    m_currentActiveWindow = GetForegroundWindow();

    // 获取初始选中文本作为基线，但不发出信号
    QString initialText = getSelectedTextFromActiveWindow();
    m_currentSelectedText = initialText;
#endif

    // 启动定时器
    m_timer->start(m_checkInterval);
}

void TextMonitorWorker::stopMonitoring()
{
    if (!m_isMonitoring) {
        return;
    }

    QMutexLocker locker(&m_mutex);
    m_isMonitoring = false;

    // 停止定时器
    m_timer->stop();
}

void TextMonitorWorker::checkTextSelection()
{
    if (!m_isMonitoring) {
        return;
    }

#ifdef Q_OS_WIN
    // 获取当前活动窗口
    HWND currentWindow = GetForegroundWindow();
    if (!currentWindow) {
        return;
    }

    QString selectedText = getSelectedTextFromActiveWindow();

    // 检查是否切换了窗口
    if (isWindowChanged(currentWindow)) {
        handleWindowSwitch(currentWindow, selectedText);
        return;
    }

    // 在同一窗口内检查文本变化
    if (isTextChanged(selectedText)) {
        QMutexLocker locker(&m_mutex);
        m_lastSelectedText = m_currentSelectedText;
        m_currentSelectedText = selectedText;

        // 修复：只在选中非空文本时才发出信号，避免取消选中时也触发信号
        if (!selectedText.isEmpty() && selectedText != m_lastSelectedText) {
            emit textSelected(selectedText);
        }
    }
#endif
}

void TextMonitorWorker::initializeUIAutomation()
{
#ifdef Q_OS_WIN
    // 初始化COM
    HRESULT hr = CoInitializeEx(nullptr, COINIT_APARTMENTTHREADED);
    if (FAILED(hr)) {
        return;
    }

    // 创建UI Automation对象
    hr = CoCreateInstance(CLSID_CUIAutomation, nullptr, CLSCTX_INPROC_SERVER,
        IID_IUIAutomation, (void**)&m_automation);
    if (FAILED(hr)) {
        CoUninitialize();
        return;
    }

    // 获取根元素
    hr = m_automation->GetRootElement(&m_rootElement);
    if (FAILED(hr)) {
        return;
    }
#endif
}

void TextMonitorWorker::cleanupUIAutomation()
{
#ifdef Q_OS_WIN
    if (m_rootElement) {
        m_rootElement->Release();
        m_rootElement = nullptr;
    }

    if (m_automation) {
        m_automation->Release();
        m_automation = nullptr;
    }

    CoUninitialize();
#endif
}

QString TextMonitorWorker::getSelectedTextFromElement(IUIAutomationElement* element)
{
#ifdef Q_OS_WIN
    if (!element || !m_automation) {
        return QString();
    }

    QString result;

    // 尝试获取Text模式
    CComPtr<IUIAutomationTextPattern> textPattern;
    HRESULT hr = element->GetCurrentPatternAs(UIA_TextPatternId, IID_IUIAutomationTextPattern, (void**)&textPattern);

    if (SUCCEEDED(hr) && textPattern) {
        // 获取选中的文本范围
        CComPtr<IUIAutomationTextRangeArray> selectionRanges;
        hr = textPattern->GetSelection(&selectionRanges);

        if (SUCCEEDED(hr) && selectionRanges) {
            int rangeCount = 0;
            hr = selectionRanges->get_Length(&rangeCount);

            if (SUCCEEDED(hr) && rangeCount > 0) {
                CComPtr<IUIAutomationTextRange> range;
                hr = selectionRanges->GetElement(0, &range);

                if (SUCCEEDED(hr) && range) {
                    BSTR selectedText = nullptr;
                    hr = range->GetText(-1, &selectedText);

                    if (SUCCEEDED(hr) && selectedText) {
                        result = QString::fromWCharArray(selectedText);
                        SysFreeString(selectedText);
                    }
                }
            }
        }
    }

    return result;
#else
    Q_UNUSED(element)
        return QString();
#endif
}

QString TextMonitorWorker::getSelectedTextFromActiveWindow()
{
#ifdef Q_OS_WIN
    if (!m_automation) {
        return QString();
    }

    // 获取当前活动窗口
    HWND activeWindow = GetForegroundWindow();
    if (!activeWindow) {
        return QString();
    }

    // 获取焦点元素
    CComPtr<IUIAutomationElement> focusedElement;
    HRESULT hr = m_automation->GetFocusedElement(&focusedElement);

    if (SUCCEEDED(hr) && focusedElement) {
        QString selectedText = getSelectedTextFromElement(focusedElement);
        if (!selectedText.isEmpty()) {
            return selectedText;
        }
    }

    // 如果焦点元素没有选中文本，尝试从活动窗口的文本控件中获取
    CComPtr<IUIAutomationElement> windowElement;
    hr = m_automation->ElementFromHandle(activeWindow, &windowElement);

    if (SUCCEEDED(hr) && windowElement) {
        // 查找文本控件
        CComPtr<IUIAutomationCondition> condition;
        VARIANT varProp;
        VariantInit(&varProp);
        varProp.vt = VT_I4;
        varProp.lVal = UIA_EditControlTypeId;

        hr = m_automation->CreatePropertyCondition(UIA_ControlTypePropertyId, varProp, &condition);
        VariantClear(&varProp);

        if (SUCCEEDED(hr) && condition) {
            CComPtr<IUIAutomationElementArray> elements;
            hr = windowElement->FindAll(TreeScope_Descendants, condition, &elements);

            if (SUCCEEDED(hr) && elements) {
                int elementCount = 0;
                hr = elements->get_Length(&elementCount);

                for (int i = 0; i < elementCount && SUCCEEDED(hr); ++i) {
                    CComPtr<IUIAutomationElement> element;
                    hr = elements->GetElement(i, &element);

                    if (SUCCEEDED(hr) && element) {
                        QString text = getSelectedTextFromElement(element);
                        if (!text.isEmpty()) {
                            return text;
                        }
                    }
                }
            }
        }
    }

    return QString();
#else
    return QString();
#endif
}

bool TextMonitorWorker::isTextChanged(const QString& newText)
{
    QMutexLocker locker(&m_mutex);

    // 如果新文本为空，且之前也为空，则没有变化
    if (newText.isEmpty() && m_currentSelectedText.isEmpty()) {
        return false;
    }

    // 如果新文本不为空，且与当前文本不同，则有变化
    if (!newText.isEmpty() && newText != m_currentSelectedText) {
        return true;
    }

    // 如果新文本为空，但之前不为空，说明取消了选择，也算变化
    if (newText.isEmpty() && !m_currentSelectedText.isEmpty()) {
        return true;
    }

    return false;
}

bool TextMonitorWorker::isWindowChanged(HWND currentWindow)
{
#ifdef Q_OS_WIN
    return m_currentActiveWindow != currentWindow;
#else
    Q_UNUSED(currentWindow)
        return false;
#endif
}

void TextMonitorWorker::handleWindowSwitch(HWND newWindow, const QString& selectedText)
{
#ifdef Q_OS_WIN

    QMutexLocker locker(&m_mutex);

    // 更新当前活动窗口
    m_currentActiveWindow = newWindow;

    // 将当前窗口的选中文本设为基线，但不发出信号
    m_lastSelectedText = m_currentSelectedText;
    m_currentSelectedText = selectedText;
#else
    Q_UNUSED(newWindow)
        Q_UNUSED(selectedText)
#endif
}