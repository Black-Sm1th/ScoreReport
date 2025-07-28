#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QFontDatabase>
#include <QDebug>
#include "LoginManager.h"
#include "CCLSScorer.h"
#include "TNMManager.h"
#include "ApiManager.h"
#include "CommonFunc.h"
#include "RenalManager.h"
#include "HistoryManager.h"
#include "UCLSMRSManager.h"
int main(int argc, char *argv[])
{
#if defined(Q_OS_WIN)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
    
    // 设置应用程序属性以支持透明窗口 - 必须在QGuiApplication创建之前
    QCoreApplication::setAttribute(Qt::AA_UseOpenGLES);

    QGuiApplication app(argc, argv);

    QQmlApplicationEngine engine;
    // 使用单例模式获取实例
    auto* apiManager = GET_SINGLETON(ApiManager);
    engine.rootContext()->setContextProperty("$apiManager", apiManager);

    auto* historyManager = GET_SINGLETON(HistoryManager);
    engine.rootContext()->setContextProperty("$historyManager", historyManager);

    auto* loginManager = GET_SINGLETON(LoginManager);
    engine.rootContext()->setContextProperty("$loginManager", loginManager);
    
    auto* cclsScorer = GET_SINGLETON(CCLSScorer);
    engine.rootContext()->setContextProperty("$cclsScorer", cclsScorer);
    
    auto* tnmManager = GET_SINGLETON(TNMManager);
    engine.rootContext()->setContextProperty("$tnmManager", tnmManager);

    auto* renalManager = GET_SINGLETON(RenalManager);
    engine.rootContext()->setContextProperty("$renalManager", renalManager);
    
    auto* uclsmrsManager = GET_SINGLETON(UCLSMRSManager);
    engine.rootContext()->setContextProperty("$uclsmrsManager", uclsmrsManager);

    // 加载字体并检查是否成功
    int fontId1 = QFontDatabase::addApplicationFont(":/fonts/AlibabaPuHuiTi-3-55-Regular.ttf");
    int fontId2 = QFontDatabase::addApplicationFont(":/fonts/AlibabaPuHuiTi-3-65-Medium.ttf");
    int fontId3 = QFontDatabase::addApplicationFont(":/fonts/AlibabaPuHuiTi-3-85-Bold.ttf");

    engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;

    return app.exec();
}
