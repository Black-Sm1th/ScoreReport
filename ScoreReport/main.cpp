#include <QGuiApplication>
#include <QQmlApplicationEngine>
#include <QQmlContext>
#include <QFontDatabase>
#include <QDebug>
#include <QDateTime>
#include <QDir>
#include <QFile>
#include <QTextStream>
#include <QStandardPaths>
#include <QMutex>
#include "LoginManager.h"
#include "CCLSScorer.h"
#include "TNMManager.h"
#include "ApiManager.h"
#include "CommonFunc.h"
#include "RenalManager.h"
#include "HistoryManager.h"
#include "UCLSMRSManager.h"
#include "UCLSCTSScorer.h"
#include "ChatManager.h"
#include "LanguageManager.h"
#include "ReportManager.h"
#include "Version.h"
// 全局日志文件指针和互斥锁
static QFile* g_logFile = nullptr;
static QTextStream* g_logStream = nullptr;
static QMutex g_logMutex;

/**
 * @brief 自定义消息处理器 - 将日志同时输出到文件和控制台
 * @param type 消息类型
 * @param context 消息上下文
 * @param msg 消息内容
 */
void customMessageOutput(QtMsgType type, const QMessageLogContext &context, const QString &msg)
{
    QMutexLocker locker(&g_logMutex);
    
    // 格式化时间戳
    QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss.zzz");
    
    // 确定消息类型字符串
    QString typeStr;
    switch (type) {
    case QtDebugMsg:    typeStr = "DEBUG"; break;
    case QtWarningMsg:  typeStr = "WARN "; break;
    case QtCriticalMsg: typeStr = "CRIT "; break;
    case QtFatalMsg:    typeStr = "FATAL"; break;
    case QtInfoMsg:     typeStr = "INFO "; break;
    }
    
    // 格式化日志消息
    QString formattedMsg = QString("[%1] [%2] %3").arg(timestamp, typeStr, msg);
    
    // 输出到控制台（保持原有行为）
    fprintf(stderr, "%s\n", formattedMsg.toLocal8Bit().constData());
    
    // 输出到文件
    if (g_logStream) {
        *g_logStream << formattedMsg << Qt::endl;
        g_logStream->flush(); // 确保立即写入文件
    }
}

/**
 * @brief 初始化日志系统
 * @return 是否初始化成功
 */
bool initializeLogging()
{
    // 创建日志目录 - 在当前运行路径下的AppData/logs文件夹
    QString logDir = "AppData/logs";
    QDir dir;
    if (!dir.mkpath(logDir)) {
        qWarning() << "Failed to create log directory:" << logDir;
        return false;
    }
    
    // 生成日志文件名（包含时间戳）
    QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd_hh-mm-ss");
    QString logFileName = QString("ScoreReport_%1.log").arg(timestamp);
    QString logFilePath = QDir(logDir).filePath(logFileName);
    
    // 创建日志文件
    g_logFile = new QFile(logFilePath);
    if (!g_logFile->open(QIODevice::WriteOnly | QIODevice::Append)) {
        qWarning() << "Failed to open log file:" << logFilePath;
        delete g_logFile;
        g_logFile = nullptr;
        return false;
    }
    
    // 创建文本流
    g_logStream = new QTextStream(g_logFile);
    g_logStream->setCodec("UTF-8");
    
    // 写入日志启动信息
    QString startMsg = QString("========== ScoreReport Log Started at %1 ==========")
                       .arg(QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss"));
    *g_logStream << startMsg << Qt::endl;
    g_logStream->flush();
    
    qInfo() << "Log system initialized successfully. Log file:" << logFilePath;
    return true;
}

/**
 * @brief 清理日志系统
 */
void cleanupLogging()
{
    if (g_logStream) {
        QString endMsg = QString("========== ScoreReport Log Ended at %1 ==========")
                         .arg(QDateTime::currentDateTime().toString("yyyy-MM-dd hh:mm:ss"));
        *g_logStream << endMsg << Qt::endl;
        g_logStream->flush();
        
        delete g_logStream;
        g_logStream = nullptr;
    }
    
    if (g_logFile) {
        g_logFile->close();
        delete g_logFile;
        g_logFile = nullptr;
    }
}

int main(int argc, char *argv[])
{
#if defined(Q_OS_WIN)
    QCoreApplication::setAttribute(Qt::AA_EnableHighDpiScaling);
#endif
    
    // 设置应用程序属性以支持透明窗口 - 必须在QGuiApplication创建之前
    QCoreApplication::setAttribute(Qt::AA_UseOpenGLES);

    QGuiApplication app(argc, argv);
    
    // 初始化日志系统
    if (!initializeLogging()) {
        qCritical() << "Failed to initialize logging system";
    }
    
    // 安装自定义消息处理器
    qInstallMessageHandler(customMessageOutput);
    
    // 设置应用程序信息，解决FileDialog的QSettings错误
    QCoreApplication::setOrganizationName("AETHERMIND");
    QCoreApplication::setOrganizationDomain("aethermind.com");
    QCoreApplication::setApplicationName("ScoreReport");
    QCoreApplication::setApplicationVersion(VER_VERSION_STR);

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
    
    auto* uclsctsScorer = GET_SINGLETON(UCLSCTSScorer);
    engine.rootContext()->setContextProperty("$uclsctsScorer", uclsctsScorer);

    // 为主界面创建ChatManager实例
    auto* chatManager = new ChatManager();
    engine.rootContext()->setContextProperty("$chatManager", chatManager);

    // 为独立chat窗口创建单独的ChatManager实例
    auto* independentChatManager = new ChatManager();
    engine.rootContext()->setContextProperty("$independentChatManager", independentChatManager);

    auto* reportManager = GET_SINGLETON(ReportManager);
    engine.rootContext()->setContextProperty("$reportManager", reportManager);

    // 初始化语言管理器
    auto* languageManager = GET_SINGLETON(LanguageManager);
    languageManager->initializeTranslator(&engine);

    // 加载字体并检查是否成功
    int fontId1 = QFontDatabase::addApplicationFont(":/fonts/AlibabaPuHuiTi-3-55-Regular.ttf");
    int fontId2 = QFontDatabase::addApplicationFont(":/fonts/AlibabaPuHuiTi-3-65-Medium.ttf");
    int fontId3 = QFontDatabase::addApplicationFont(":/fonts/AlibabaPuHuiTi-3-85-Bold.ttf");

    engine.load(QUrl(QStringLiteral("qrc:/qml/main.qml")));
    if (engine.rootObjects().isEmpty())
        return -1;
    
    return app.exec();
}
