#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include "LoginManager.h"

int main(int argc, char *argv[])
{
#if defined(Q_OS_WIN)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif

    QGuiApplication app(argc, argv);
    
    // 设置应用程序属性以支持透明窗口
    app.setAttribute(Qt::AA_UseOpenGLES);

    QQmlApplicationEngine engine;

    LoginManager loginManager;
    engine.rootContext()->setContextProperty("$loginManager", &loginManager);


    engine.load(QUrl(QStringLiteral("qrc:/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
