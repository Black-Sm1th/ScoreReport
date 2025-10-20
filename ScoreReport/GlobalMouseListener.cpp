#include "GlobalMouseListener.h"

HHOOK GlobalMouseListener::m_hook = nullptr;
GlobalMouseListener* GlobalMouseListener::m_instance = nullptr;

GlobalMouseListener::GlobalMouseListener(QObject* parent)
    : QObject(parent) {
    m_instance = this;
}

GlobalMouseListener::~GlobalMouseListener() {
    stop();
    m_instance = nullptr;
}

void GlobalMouseListener::start() {
    if (!m_hook) {
        m_hook = SetWindowsHookEx(WH_MOUSE_LL, MouseProc, nullptr, 0);
    }
}

void GlobalMouseListener::stop() {
    if (m_hook) {
        UnhookWindowsHookEx(m_hook);
        m_hook = nullptr;
    }
}

LRESULT CALLBACK GlobalMouseListener::MouseProc(int nCode, WPARAM wParam, LPARAM lParam) {
    if (nCode >= 0 && m_instance) {
        MSLLHOOKSTRUCT* mouse = (MSLLHOOKSTRUCT*)lParam;
        QPoint pos(mouse->pt.x, mouse->pt.y);

        switch (wParam) {
        case WM_LBUTTONDOWN:
            emit m_instance->mouseEvent(LeftButton, 0, pos);
            break;
        case WM_RBUTTONDOWN:
            emit m_instance->mouseEvent(RightButton, 0, pos);
            break;
        case WM_MBUTTONDOWN:
            emit m_instance->mouseEvent(MiddleButton, 0, pos);
            break;
        case WM_MOUSEWHEEL: {
            int delta = GET_WHEEL_DELTA_WPARAM(mouse->mouseData);
            emit m_instance->mouseEvent(Wheel, delta, pos);
            break;
        }
        }
    }
    return CallNextHookEx(m_hook, nCode, wParam, lParam);
}
