#include "LoginManager.h"
#include "ApiManager.h"
#include <QClipboard>
#include <QGuiApplication>
#include <QScreen>
#include <QPixmap>
#include <QStandardPaths>
#include <QDir>
#include <QDateTime>
#include <QTimer>
#include "Version.h"
LoginManager::LoginManager(QObject* parent)
    : QObject(parent)
    , m_apiManager(nullptr)
    , m_settings(nullptr)
{
    QString str = VER_VERSION_STR;
    QString ver = "V" + str;
    setcurrentVersion(ver);
    setcurrentUserId("");
    setisLoggedIn(false);
    setcurrentUserName("");
    setcurrentUserAvatar("");
    setsavedUsername("");
    setsavedPassword("");
    setisChangingUser(false);
    setisAdding(false);
    setisRegistering(false);
    setrememberPassword(false);
    setuserList(QVariantList());
    setshowDialogOnTextSelection(false);  // 默认不显示弹窗
    setshowHelpBubble(true);  // 默认显示聊天气泡
    m_selector = new GlobalTextMonitor();
    m_mouseListener = new GlobalMouseListener();
    connect(m_selector, &GlobalTextMonitor::textSelected,
        this, &LoginManager::onTextSelected);
    connect(m_mouseListener, &GlobalMouseListener::mouseEvent,
        this, &LoginManager::onMouseEvent);
    // 初始化QSettings
    m_settings = new QSettings("AETHERMIND", "Knowledge", this);
    m_timer = new QTimer();
    m_timer->setSingleShot(true);
    connect(m_timer, &QTimer::timeout,
        this, &LoginManager::onTimeout);
    m_apiManager = GET_SINGLETON(ApiManager);
    connect(m_apiManager, &ApiManager::loginResponse,
        this, &LoginManager::onLoginResponse);
    connect(m_apiManager, &ApiManager::registerResponse,
        this, &LoginManager::onRegistResponse);
    // 启动时加载保存的凭据和用户列表
    loadSavedCredentials();
    loadUserList();
}

bool LoginManager::login(const QString& username, const QString& password)
{
    if (!m_apiManager) {
        qWarning() << "[LoginManager] ApiManager is null!";
        emit loginResult(false, "Internal error: ApiManager not available");
        return false;
    }
    
    // 使用ApiManager进行登录请求
    m_apiManager->loginUser(username, password);
    return true;
}

void LoginManager::onLoginResponse(bool success, const QString& message, const QJsonObject& data)
{   
    if (success) {
        QString respUser = data.value("userName").toString();
        QString respCurrentUserId = data.value("id").toString();
        QString userAvatar = data.value("userAvatar").toString();
        setcurrentUserId(respCurrentUserId);
        setcurrentUserAvatar(userAvatar);
        setcurrentUserName(respUser);
        setisLoggedIn(true);
        setisAdding(false);
        setisChangingUser(false);
        
        // 只有当弹窗设置为开启时才启动文本监控
        if (getshowDialogOnTextSelection()) {
            m_selector->startMonitoring();
        }
        // 添加用户到列表（这里需要从UI获取密码，暂时先用空字符串占位）
        // 实际的密码会在UI层的loginResult处理中调用addUserToList
    } else {
        setisLoggedIn(false);
        setcurrentUserName("");
        setcurrentUserAvatar("");
        setcurrentUserId("");
    }
    
    emit loginResult(success, message);
}

void LoginManager::logout()
{
    qDebug() << "[LoginManager] User logout";
    setisLoggedIn(false);
    setcurrentUserName("");
    setcurrentUserAvatar("");
    setcurrentUserId("");
    m_selector->stopMonitoring();
    emit logoutSuccess();
}

void LoginManager::saveCredentials(const QString& username, const QString& password, bool remember)
{
    if (!m_settings) {
        return;
    }
    
    setrememberPassword(remember);
    setsavedUsername(username);
    
    if (remember) {
        setsavedPassword(password);
        // 保存到QSettings
        m_settings->setValue("username", username);
        m_settings->setValue("password", password);
        m_settings->setValue("rememberPassword", true);
    } else {
        setsavedPassword("");
        // 只保存用户名，清除密码
        m_settings->setValue("username", username);
        m_settings->remove("password");
        m_settings->setValue("rememberPassword", false);
    }
    m_settings->sync();
    
    qDebug() << "[LoginManager] Credentials saved, remember password:" << remember;
}

void LoginManager::loadSavedCredentials()
{
    if (!m_settings) {
        return;
    }
    
    QString username = m_settings->value("username", "").toString();
    QString password = m_settings->value("password", "").toString();
    bool remember = m_settings->value("rememberPassword", false).toBool();
    bool showDialog = m_settings->value("showDialogOnTextSelection", false).toBool();
    bool showHelpBubble = m_settings->value("showHelpBubble", true).toBool();
    
    setsavedUsername(username);
    setsavedPassword(remember ? password : "");
    setrememberPassword(remember);
    setshowDialogOnTextSelection(showDialog);
    setshowHelpBubble(showHelpBubble);
    
    qDebug() << "[LoginManager] Loaded saved credentials, username:" << username << "remember:" << remember << "showDialog:" << showDialog << "showHelpBubble:" << showHelpBubble;
}


void LoginManager::addUserToList(const QString& username, const QString& password, const QString& userId, const QString& avatar)
{
    if (!m_settings || userId.isEmpty()) {
        return;
    }
    
    // 检查用户是否已经在列表中
    QVariantMap existingUser = findUserInList(userId);
    if (!existingUser.isEmpty()) {
        // 用户已存在，更新信息
        QVariantList currentList = getuserList();
        for (int i = 0; i < currentList.size(); ++i) {
            QVariantMap userMap = currentList[i].toMap();
            if (userMap.value("userId").toString() == userId) {
                userMap["username"] = username;
                userMap["password"] = password;
                userMap["avatar"] = avatar;
                currentList[i] = userMap;
                break;
            }
        }
        setuserList(currentList);
    } else {
        // 新用户，添加到列表
        QVariantMap userMap;
        userMap["username"] = username;
        userMap["password"] = password;
        userMap["userId"] = userId;
        userMap["avatar"] = avatar;
        
        QVariantList currentList = getuserList();
        currentList.append(userMap);
        setuserList(currentList);
    }
    
    // 保存到设置
    saveUserList();
    
    qDebug() << "[LoginManager] Added/Updated user in list:" << username << "userId:" << userId;
}

void LoginManager::removeUserFromList(const QString& userId)
{
    if (!m_settings || userId.isEmpty()) {
        return;
    }
    QVariantList currentList = getuserList();
    for (int i = 0; i < currentList.size(); ++i) {
        QVariantMap userMap = currentList[i].toMap();
        if (userMap.value("userId").toString() == userId) {
            currentList.removeAt(i);
            setuserList(currentList);
            saveUserList();
            qDebug() << "[LoginManager] Removed user from list, userId:" << userId;
            break;
        }
    }
}

bool LoginManager::registAccount(const QString& userAccount, const QString& userPassword, const QString& checkPassword)
{
    if (!m_apiManager) {
        qWarning() << "[LoginManager] ApiManager is null!";
        emit registResult(false, "Internal error: ApiManager not available");
        return false;
    }

    // 使用ApiManager进行登录请求
    m_apiManager->registerUser(userAccount, userPassword, checkPassword);
    return true;
}

void LoginManager::stopMonitoring()
{
    if (m_selector->isMonitoring()) {
        m_selector->stopMonitoring();
    }
    delete m_selector;
}

void LoginManager::copyToClipboard(const QString& text)
{
    QClipboard* clipboard = QGuiApplication::clipboard();
    clipboard->setText(text);
}

void LoginManager::onRegistResponse(bool success, const QString& message, const QJsonObject& data)
{
    emit registResult(success, message);
}

void LoginManager::onTextSelected(const QString& text)
{
    // 获取当前鼠标位置
    m_currentStr = text.trimmed();
    currentPos = QCursor::pos();
    changeMouseStatus(true);
    m_timer->start(500);
}

void LoginManager::onMouseEvent(GlobalMouseListener::MouseButton button, int delta, QPoint pos)
{
    m_timer->stop();
    emit mouseEvent();
}

void LoginManager::onTimeout()
{
    emit textSelectionDetected(m_currentStr, currentPos.x(), currentPos.y());
}

void LoginManager::loadUserList()
{
    if (!m_settings) {
        return;
    }
    
    QVariantList loadedList = m_settings->value("userList", QVariantList()).toList();
    setuserList(loadedList);
    
    qDebug() << "[LoginManager] Loaded user list, count:" << loadedList.size();
}

void LoginManager::saveUserList()
{
    if (!m_settings) {
        return;
    }
    
    m_settings->setValue("userList", getuserList());
    m_settings->sync();
    
    qDebug() << "[LoginManager] Saved user list, count:" << getuserList().size();
}

QVariantMap LoginManager::findUserInList(const QString& userId)
{
    if (userId.isEmpty()) {
        return QVariantMap();
    }
    
    QVariantList currentList = getuserList();
    for (const QVariant& userVariant : currentList) {
        QVariantMap userMap = userVariant.toMap();
        if (userMap.value("userId").toString() == userId) {
            return userMap;
        }

    }
    
    return QVariantMap();
}

void LoginManager::saveShowDialogSetting(bool showDialog)
{
    if (!m_settings) {
        return;
    }
    
    bool oldSetting = getshowDialogOnTextSelection();
    setshowDialogOnTextSelection(showDialog);
    m_settings->setValue("showDialogOnTextSelection", showDialog);
    m_settings->sync();
    
    // 如果用户已登录且设置发生了变化，相应地启动或停止监控
    if (getisLoggedIn() && oldSetting != showDialog) {
        if (showDialog) {
            // 设置改为true，启动监控
            m_selector->startMonitoring();
            qDebug() << "[LoginManager] Started text monitoring due to setting change";
        } else {
            // 设置改为false，停止监控
            m_selector->stopMonitoring();
            qDebug() << "[LoginManager] Stopped text monitoring due to setting change";
        }
    }
}

void LoginManager::processScreenshotArea(int x, int y, int width, int height)
{
    qDebug() << "[LoginManager] Processing screenshot area:" << x << y << width << height;

    // 获取主屏幕
    QScreen* screen = QGuiApplication::primaryScreen();
    if (!screen) {
        qWarning() << "[LoginManager] Cannot get primary screen";
        return;
    }

    // 截取指定区域
    QPixmap screenshot = screen->grabWindow(0, x, y, width, height);
    if (screenshot.isNull()) {
        qWarning() << "[LoginManager] Failed to capture screenshot area";
        return;
    }

    // 创建临时目录保存截图
    QString tempDir = QStandardPaths::writableLocation(QStandardPaths::TempLocation);
    QDir dir(tempDir);
    if (!dir.exists()) {
        dir.mkpath(tempDir);
    }

    // 生成唯一的文件名
    QString timestamp = QDateTime::currentDateTime().toString("yyyyMMdd_hhmmss_zzz");
    QString screenshotPath = tempDir + "/screenshot_" + timestamp + ".png";

    // 保存截图
    if (!screenshot.save(screenshotPath, "PNG")) {
        qWarning() << "[LoginManager] Failed to save screenshot to:" << screenshotPath;
        return;
    }

    qDebug() << "[LoginManager] Screenshot saved to:" << screenshotPath;
}

void LoginManager::changeMouseStatus(bool type)
{
    if (!type) {
        m_mouseListener->stop();
    }
    else {
        m_mouseListener->start();
    }
}

void LoginManager::clearAllCache()
{
    if (!m_settings) {
        qWarning() << "[LoginManager] QSettings is null, cannot clear cache";
        return;
    }
    
    // 清除日志文件
    clearLogFiles();
    
    // 清除LoginManager的所有设置
    m_settings->clear();
    m_settings->sync();
    setshowHelpBubble(true);
    
    qDebug() << "[LoginManager] Successfully cleared all application cache and reset properties";
}

void LoginManager::clearLogFiles()
{
    // 日志文件目录路径（与main.cpp中的路径保持一致）
    QString logDir = "AppData/logs";
    
    QDir dir(logDir);
    if (!dir.exists()) {
        qDebug() << "[LoginManager] Log directory does not exist:" << logDir;
        return;
    }
    
    // 获取所有.log文件
    QStringList logFiles = dir.entryList(QStringList() << "*.log", QDir::Files);
    if (logFiles.isEmpty()) {
        qDebug() << "[LoginManager] No log files found in:" << logDir;
        return;
    }
    
    int deletedCount = 0;
    int totalCount = logFiles.size();
    
    // 删除所有日志文件
    foreach (const QString& fileName, logFiles) {
        QString filePath = dir.filePath(fileName);
        QFile file(filePath);
        
        if (file.remove()) {
            qDebug() << "[LoginManager] Deleted log file:" << fileName;
            deletedCount++;
        } else {
            qWarning() << "[LoginManager] Failed to delete log file:" << fileName;
        }
    }
    
    qDebug() << QString("[LoginManager] Log cleanup completed: %1/%2 files deleted from %3")
                .arg(deletedCount).arg(totalCount).arg(logDir);
    
    // 如果所有文件都被删除，尝试删除空的logs目录
    if (deletedCount == totalCount) {
        QStringList remainingFiles = dir.entryList(QDir::NoDotAndDotDot | QDir::AllEntries);
        if (remainingFiles.isEmpty()) {
            if (dir.rmdir(".")) {
                qDebug() << "[LoginManager] Removed empty log directory:" << logDir;
            }
        }
    }
}

void LoginManager::saveHelpBubbleSetting(bool showHelpBubble)
{
    if (!m_settings) {
        return;
    }
    
    setshowHelpBubble(showHelpBubble);
    m_settings->setValue("showHelpBubble", showHelpBubble);
    m_settings->sync();
    
    qDebug() << "[LoginManager] Help bubble setting changed to:" << showHelpBubble;
}
