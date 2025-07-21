#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QFontDatabase>
#include <QDebug>
#include "LoginManager.h"
#include "CCLSScorer.h"
#include "TNMManager.h"

int main(int argc, char *argv[])
{
#if defined(Q_OS_WIN)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
    
    // 设置应用程序属性以支持透明窗口 - 必须在QGuiApplication创建之前
    QCoreApplication::setAttribute(Qt::AA_UseOpenGLES);

    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;

    LoginManager loginManager;
    engine.rootContext()->setContextProperty("$loginManager", &loginManager);
    
    CCLSScorer cclsScorer;
    engine.rootContext()->setContextProperty("$cclsScorer", &cclsScorer);
    
    TNMManager tnmManager;
    engine.rootContext()->setContextProperty("$tnmManager", &tnmManager);

    // 加载字体并检查是否成功
    int fontId1 = QFontDatabase::addApplicationFont(":/fonts/AlibabaPuHuiTi-3-55-Regular.ttf");
    int fontId2 = QFontDatabase::addApplicationFont(":/fonts/AlibabaPuHuiTi-3-65-Medium.ttf");
    int fontId3 = QFontDatabase::addApplicationFont(":/fonts/AlibabaPuHuiTi-3-85-Bold.ttf");

    engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
