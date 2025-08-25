#pragma once
#include <QObject>
#include <QPoint>
#include <windows.h>

class GlobalMouseListener : public QObject {
    Q_OBJECT
public:
    explicit GlobalMouseListener(QObject* parent = nullptr);
    ~GlobalMouseListener();

    void start();
    void stop();

    enum MouseButton {
        LeftButton = 0,
        RightButton,
        MiddleButton,
        Wheel
    };
    Q_ENUM(MouseButton)

signals:
    void mouseEvent(MouseButton button, int delta, QPoint pos);

private:
    static LRESULT CALLBACK MouseProc(int nCode, WPARAM wParam, LPARAM lParam);
    static HHOOK m_hook;
    static GlobalMouseListener* m_instance;
};
