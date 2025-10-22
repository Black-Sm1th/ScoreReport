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
#include <QProcess>
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
    sethasUpdateAvailable(false);  // 默认没有更新
    setlatestVersion("");  // 最新版本为空
    setupdateFileName("");  // 更新文件名为空
    setisDownloadingUpdate(false);  // 默认不在下载更新
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
    connect(m_apiManager, &ApiManager::getSystemUpdateListResponse,
        this, &LoginManager::onSystemUpdateListResponse);
    connect(m_apiManager, &ApiManager::downloadAppFileResponse,
        this, &LoginManager::onDownloadAppFileResponse);
    // 启动时加载保存的凭据和用户列表
    loadSavedCredentials();
    loadUserList();
    
    // 启动时检查更新
    QTimer::singleShot(2000, this, &LoginManager::checkForUpdates); // 延迟2秒检查更新，避免影响启动速度
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
    
    // 获取所有.log文件（包括应用日志和更新日志）
    QStringList logFiles = dir.entryList(QStringList() << "*.log", QDir::Files);
    if (logFiles.isEmpty()) {
        qDebug() << "[LoginManager] No log files found in:" << logDir;
        return;
    }
    
    int deletedCount = 0;
    int totalCount = logFiles.size();
    
    // 删除所有日志文件（包括ScoreReport_*.log和update_*.log）
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
    
    qDebug() << QStringLiteral("[LoginManager] Log cleanup completed: %1/%2 files deleted from %3")
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

/**
 * @brief 检查系统更新
 * 
 * 向服务器请求最新的版本列表，检查是否有新版本可用
 */
void LoginManager::checkForUpdates()
{
    if (!m_apiManager) {
        qWarning() << "[LoginManager] ApiManager is null, cannot check for updates";
        return;
    }
    
    qDebug() << "[LoginManager] Checking for updates, current version:" << getcurrentVersion();
    m_isManual = false;
    m_apiManager->getSystemUpdateList(2); // appType = 2
}

void LoginManager::manualCheckForUpdates()
{
    if (!m_apiManager) {
        qWarning() << "[LoginManager] ApiManager is null, cannot check for updates";
        return;
    }

    qDebug() << "[LoginManager] Checking for updates, current version:" << getcurrentVersion();
    m_isManual = true;
    m_apiManager->getSystemUpdateList(2); // appType = 2
}

/**
 * @brief 下载并安装更新
 * 
 * 下载最新版本文件并替换当前应用程序
 */
void LoginManager::downloadAndInstallUpdate()
{
    if (!m_apiManager || getlatestVersion().isEmpty() || getupdateFileName().isEmpty()) {
        qWarning() << "[LoginManager] Cannot download update: missing ApiManager or update info";
        return;
    }
    
    if (getisDownloadingUpdate()) {
        qDebug() << "[LoginManager] Update download already in progress";
        return;
    }
    
    setisDownloadingUpdate(true);
    qDebug() << "[LoginManager] Starting update download:" << getupdateFileName();
    m_apiManager->downloadAppFile(getupdateFileName());
}

/**
 * @brief 处理系统更新列表响应
 * @param success 请求是否成功
 * @param message 服务器返回的消息
 * @param data 系统更新列表数据
 */
void LoginManager::onSystemUpdateListResponse(bool success, const QString& message, const QJsonObject& data)
{
    if (!success) {
        qWarning() << "[LoginManager] Failed to get system update list:" << message;
        return;
    }
    
    // 解析更新列表数据
    QJsonValue dataValue = data.value("data");
    if (!dataValue.isArray()) {
        qWarning() << "[LoginManager] Invalid update list data format";
        return;
    }
    
    QJsonArray updateList = dataValue.toArray();
    if (updateList.isEmpty()) {
        qDebug() << "[LoginManager] No updates available in the list";
        return;
    }
    
    // 获取第一个更新项（最新版本）
    QJsonObject latestUpdate = updateList[0].toObject();
    QString versionNumber = latestUpdate.value("versionNumber").toString();
    QString fileName = latestUpdate.value("fileName").toString();
    
    if (versionNumber.isEmpty() || fileName.isEmpty()) {
        qWarning() << "[LoginManager] Invalid update data: missing version or filename";
        return;
    }
    
    qDebug() << "[LoginManager] Latest version from server:" << versionNumber << "fileName:" << fileName;
    
    // 比较版本
    compareVersions(versionNumber);
    
    // 保存更新信息
    setlatestVersion(versionNumber);
    setupdateFileName(fileName);
}

/**
 * @brief 处理下载App文件响应
 * @param success 下载是否成功
 * @param message 服务器返回的消息
 * @param data 下载结果数据
 */
void LoginManager::onDownloadAppFileResponse(bool success, const QString& message, const QJsonObject& data)
{
    qDebug() << "[LoginManager] ========== Download App File Response Received ==========";
    qDebug() << "[LoginManager] Success:" << success << "Message:" << message;
    
    setisDownloadingUpdate(false);
    
    if (!success) {
        qWarning() << "[LoginManager] ERROR: Failed to download update file:" << message;
        return;
    }
    
    qDebug() << "[LoginManager] Update file downloaded successfully";
    qDebug() << "[LoginManager] Response data keys:" << data.keys();
    emit updateDownloadCompleted();
    
    // 文件已经被ApiManager保存到临时位置，直接获取文件路径
    QString downloadedFilePath = data.value("filePath").toString();
    QString fileName = data.value("fileName").toString();
    int fileSize = data.value("fileSize").toInt();
    
    qDebug() << "[LoginManager] Downloaded file info - Path:" << downloadedFilePath;
    qDebug() << "[LoginManager] Downloaded file name:" << fileName;
    qDebug() << "[LoginManager] Expected file size:" << fileSize << "bytes";
    
    // 验证文件是否存在且有效
    if (downloadedFilePath.isEmpty()) {
        qWarning() << "[LoginManager] ERROR: Downloaded file path is empty!";
        return;
    }
    
    if (!QFile::exists(downloadedFilePath)) {
        qWarning() << "[LoginManager] ERROR: Downloaded file not found at path:" << downloadedFilePath;
        return;
    }
    
    qDebug() << "[LoginManager] Downloaded file exists, verifying size...";
    
    // 验证文件大小
    QFileInfo fileInfo(downloadedFilePath);
    qDebug() << "[LoginManager] Actual file size:" << fileInfo.size() << "bytes";
    qDebug() << "[LoginManager] File readable:" << fileInfo.isReadable();
    qDebug() << "[LoginManager] File writable:" << fileInfo.isWritable();
    
    if (fileInfo.size() == 0) {
        qWarning() << "[LoginManager] ERROR: Downloaded file is empty!";
        return;
    }
    
    if (fileInfo.size() != fileSize) {
        qWarning() << "[LoginManager] WARNING: File size mismatch! Expected:" << fileSize 
                   << "Actual:" << fileInfo.size();
        // 不返回，继续尝试安装
    }
    
    // 安装更新
    qDebug() << "[LoginManager] Starting update installation...";
    if (installUpdate(downloadedFilePath)) {
        qDebug() << "[LoginManager] Update installation initiated successfully";
        emit updateInstallationCompleted();
    } else {
        qWarning() << "[LoginManager] ERROR: Update installation failed!";
    }
}

/**
 * @brief 比较版本号
 * @param serverVersion 服务器版本号
 */
void LoginManager::compareVersions(const QString& serverVersion)
{
    QString currentVer = getcurrentVersion();
    
    // 移除版本号前的"V"前缀进行比较
    QString cleanCurrentVer = currentVer.startsWith("V") ? currentVer.mid(1) : currentVer;
    QString cleanServerVer = serverVersion.startsWith("V") ? serverVersion.mid(1) : serverVersion;
    
    qDebug() << "[LoginManager] Comparing versions - Current:" << cleanCurrentVer << "Server:" << cleanServerVer;
    
    // 简单的版本比较（假设格式为 x.y.z）
    QStringList currentParts = cleanCurrentVer.split('.');
    QStringList serverParts = cleanServerVer.split('.');
    
    // 确保版本号格式正确
    if (currentParts.size() != 3 || serverParts.size() != 3) {
        qWarning() << "[LoginManager] Invalid version format for comparison";
        return;
    }
    
    bool hasUpdate = false;
    
    // 比较主版本号
    int currentMajor = currentParts[0].toInt();
    int serverMajor = serverParts[0].toInt();
    if (serverMajor > currentMajor) {
        hasUpdate = true;
    } else if (serverMajor == currentMajor) {
        // 比较次版本号
        int currentMinor = currentParts[1].toInt();
        int serverMinor = serverParts[1].toInt();
        if (serverMinor > currentMinor) {
            hasUpdate = true;
        } else if (serverMinor == currentMinor) {
            // 比较修订版本号
            int currentPatch = currentParts[2].toInt();
            int serverPatch = serverParts[2].toInt();
            if (serverPatch > currentPatch) {
                hasUpdate = true;
            }
        }
    }
    
    sethasUpdateAvailable(hasUpdate);
    
    if (hasUpdate) {
        emit updateAvailable(serverVersion, getupdateFileName());
    }else{
        if (m_isManual) {
            emit noneUpdateAvailable();
        }
    }
}

/**
 * @brief 安装更新
 * @param downloadedFilePath 下载的更新压缩包路径
 * @return 是否成功启动安装过程
 */
bool LoginManager::installUpdate(const QString& downloadedFilePath)
{
    qDebug() << "[LoginManager] ========== Starting Update Installation ==========";
    qDebug() << "[LoginManager] Downloaded file path:" << downloadedFilePath;
    
    if (downloadedFilePath.isEmpty() || !QFile::exists(downloadedFilePath)) {
        qWarning() << "[LoginManager] ERROR: Update file does not exist:" << downloadedFilePath;
        return false;
    }
    
    QFileInfo downloadedFileInfo(downloadedFilePath);
    qDebug() << "[LoginManager] Downloaded file size:" << downloadedFileInfo.size() << "bytes";
    qDebug() << "[LoginManager] Downloaded file last modified:" << downloadedFileInfo.lastModified().toString();
    
    // 获取当前应用程序路径
    QString currentAppPath = QCoreApplication::applicationFilePath();
    QString appDir = QCoreApplication::applicationDirPath();
    QString currentAppName = QFileInfo(currentAppPath).fileName();
    
    qDebug() << "[LoginManager] Current application path:" << currentAppPath;
    qDebug() << "[LoginManager] Application directory:" << appDir;
    qDebug() << "[LoginManager] Current application name:" << currentAppName;
    
    // 将压缩包复制到应用程序目录
    QString updateZipPath = appDir + "/update.zip";
    
    qDebug() << "[LoginManager] Installing update from:" << downloadedFilePath 
             << "to app directory:" << appDir;
    
    // 复制压缩包到应用程序目录
    if (QFile::exists(updateZipPath)) {
        qDebug() << "[LoginManager] Removing existing update.zip file";
        if (!QFile::remove(updateZipPath)) {
            qWarning() << "[LoginManager] WARNING: Failed to remove existing update.zip";
        } else {
            qDebug() << "[LoginManager] Existing update.zip removed successfully";
        }
    }
    
    qDebug() << "[LoginManager] Copying update file to:" << updateZipPath;
    if (!QFile::copy(downloadedFilePath, updateZipPath)) {
        qWarning() << "[LoginManager] ERROR: Failed to copy update file to app directory";
        QFile::Permissions perms = downloadedFileInfo.permissions();
        qWarning() << "[LoginManager] Source file permissions:" << perms;
        return false;
    }
    
    // 验证复制后的文件
    QFileInfo copiedFileInfo(updateZipPath);
    qDebug() << "[LoginManager] Update file copied successfully";
    qDebug() << "[LoginManager] Copied file path:" << updateZipPath;
    qDebug() << "[LoginManager] Copied file size:" << copiedFileInfo.size() << "bytes";
    qDebug() << "[LoginManager] Original file size:" << downloadedFileInfo.size() << "bytes";
    
    if (copiedFileInfo.size() != downloadedFileInfo.size()) {
        qWarning() << "[LoginManager] WARNING: File size mismatch after copy!";
    }
    
    // 创建更新锁文件，防止用户在更新期间再次启动应用
    QString updateLockPath = appDir + "/update.lock";
    qDebug() << "[LoginManager] Creating update lock file:" << updateLockPath;
    QFile lockFile(updateLockPath);
    if (lockFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream lockStream(&lockFile);
        QString lockTimestamp = QDateTime::currentDateTime().toString(Qt::ISODate);
        lockStream << lockTimestamp;
        lockFile.close();
        qDebug() << "[LoginManager] Update lock file created successfully with timestamp:" << lockTimestamp;
    } else {
        qWarning() << "[LoginManager] WARNING: Failed to create update lock file";
    }
    
    // 创建批处理脚本来解压缩文件并重启应用
    QString batchScript = appDir + "/update_install.bat";
    qDebug() << "[LoginManager] Creating batch script:" << batchScript;
    QFile batchFile(batchScript);
    
    if (batchFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream out(&batchFile);
        out << "@echo off\n";
        out << "cd /d \"" << QDir::toNativeSeparators(appDir) << "\"\n";
        
        // 创建日志文件，将所有输出重定向到日志文件（使用绝对路径和时间戳）
        out << "set APP_DIR=%CD%\n";
        out << "set LOG_DIR=%APP_DIR%\\AppData\\logs\n";
        out << "if not exist \"%LOG_DIR%\" mkdir \"%LOG_DIR%\"\n";
        
        // 生成时间戳文件名（格式：update_2025-10-21_18-30-45.log）
        out << "for /f \"tokens=1-3 delims=/- \" %%a in (\"%date%\") do set LOGDATE=%%a-%%b-%%c\n";
        out << "for /f \"tokens=1-3 delims=:. \" %%a in (\"%time%\") do set LOGTIME=%%a-%%b-%%c\n";
        out << "set LOGTIME=%LOGTIME: =0%\n";  // 前导零填充
        out << "set LOG_FILE=%LOG_DIR%\\update_%LOGDATE%_%LOGTIME%.log\n";
        
        out << "echo ========== Update Process Started at %date% %time% ========== > \"%LOG_FILE%\"\n";
        out << "echo [UPDATE] Installing update... >> \"%LOG_FILE%\" 2>&1\n";
        out << "echo [UPDATE] Current directory: %CD% >> \"%LOG_FILE%\" 2>&1\n";
        out << "echo [UPDATE] Target application: " << currentAppName << " >> \"%LOG_FILE%\" 2>&1\n";
        out << "echo [UPDATE] Log file: %LOG_FILE% >> \"%LOG_FILE%\" 2>&1\n";
        out << "timeout /t 2 /nobreak > nul\n"; // 等待2秒确保当前应用完全退出
        
        // 检查应用是否仍在运行，最多等待5秒后强制终止
        out << "set WAIT_COUNT=0\n";
        out << ":CHECK_PROCESS\n";
        out << "tasklist /FI \"IMAGENAME eq " << currentAppName << "\" 2>NUL | find /I /N \"" << currentAppName << "\">NUL\n";
        out << "if \"%ERRORLEVEL%\"==\"0\" (\n";
        out << "    if %WAIT_COUNT% LSS 5 (\n";
        out << "        echo [UPDATE] Waiting for application to close... (%WAIT_COUNT%/5) >> \"%LOG_FILE%\" 2>&1\n";
        out << "        timeout /t 1 /nobreak > nul\n";
        out << "        set /a WAIT_COUNT+=1\n";
        out << "        goto CHECK_PROCESS\n";
        out << "    ) else (\n";
        out << "        echo [UPDATE] Application still running after 5 seconds, forcing termination... >> \"%LOG_FILE%\" 2>&1\n";
        out << "        taskkill /F /IM \"" << currentAppName << "\" >> \"%LOG_FILE%\" 2>&1\n";
        out << "        timeout /t 1 /nobreak > nul\n";
        out << "        echo [UPDATE] Application terminated. >> \"%LOG_FILE%\" 2>&1\n";
        out << "    )\n";
        out << ")\n";
        out << "echo [UPDATE] Application closed, continuing with update... >> \"%LOG_FILE%\" 2>&1\n";
        
        // 检查旧可执行文件状态并尝试删除
        out << "echo [UPDATE] Checking old executable before update... >> \"%LOG_FILE%\" 2>&1\n";
        out << "if exist \"" << currentAppName << "\" (\n";
        out << "    echo [UPDATE] Old executable found: " << currentAppName << " >> \"%LOG_FILE%\" 2>&1\n";
        out << "    dir \"" << currentAppName << "\" | find \"" << currentAppName << "\" >> \"%LOG_FILE%\" 2>&1\n";
        out << "    echo [UPDATE] Attempting to delete old executable... >> \"%LOG_FILE%\" 2>&1\n";
        out << "    del /F /Q \"" << currentAppName << "\" >> \"%LOG_FILE%\" 2>&1\n";
        out << "    if exist \"" << currentAppName << "\" (\n";
        out << "        echo [UPDATE] WARNING: Failed to delete old executable, will try to overwrite >> \"%LOG_FILE%\" 2>&1\n";
        out << "    ) else (\n";
        out << "        echo [UPDATE] Old executable deleted successfully >> \"%LOG_FILE%\" 2>&1\n";
        out << "    )\n";
        out << ") else (\n";
        out << "    echo [UPDATE] WARNING: Old executable not found! >> \"%LOG_FILE%\" 2>&1\n";
        out << ")\n";
        
        // 使用PowerShell解压缩文件（Windows内置）
        out << "echo [UPDATE] Extracting update files... >> \"%LOG_FILE%\" 2>&1\n";
        out << "echo [UPDATE] Zip file: update.zip >> \"%LOG_FILE%\" 2>&1\n";
        out << "if not exist update.zip (\n";
        out << "    echo [UPDATE] ERROR: update.zip not found! >> \"%LOG_FILE%\" 2>&1\n";
        out << "    pause\n";
        out << "    goto cleanup\n";
        out << ")\n";
        out << "powershell -command \"& { Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('update.zip', 'temp_update') }\" >> \"%LOG_FILE%\" 2>&1\n";
        out << "if errorlevel 1 (\n";
        out << "    echo [UPDATE] ERROR: Update extraction failed! >> \"%LOG_FILE%\" 2>&1\n";
        out << "    pause\n";
        out << "    goto cleanup\n";
        out << ")\n";
        out << "echo [UPDATE] Extraction completed successfully >> \"%LOG_FILE%\" 2>&1\n";
        
        // 等待3秒，让防病毒软件扫描完毕
        out << "echo [UPDATE] Waiting for antivirus scan to complete... >> \"%LOG_FILE%\" 2>&1\n";
        out << "timeout /t 3 /nobreak > nul\n";
        
        // 检查解压后的结构并移动文件
        out << "echo [UPDATE] Processing extracted files... >> \"%LOG_FILE%\" 2>&1\n";
        out << "cd temp_update\n";
        out << "echo [UPDATE] Contents of temp_update folder: >> \"%LOG_FILE%\" 2>&1\n";
        out << "dir /b >> \"%LOG_FILE%\" 2>&1\n";
        
        // 检查是否只有一个文件夹
        out << "for /f \"tokens=*\" %%i in ('dir /b /ad 2^>nul ^| find /c /v \"\"') do set FOLDER_COUNT=%%i\n";
        out << "for /f \"tokens=*\" %%i in ('dir /b /a-d 2^>nul ^| find /c /v \"\"') do set FILE_COUNT=%%i\n";
        out << "echo [UPDATE] Folder count: %FOLDER_COUNT%, File count: %FILE_COUNT% >> \"%LOG_FILE%\" 2>&1\n";
        
        out << "if %FOLDER_COUNT%==1 if %FILE_COUNT%==0 (\n";
        out << "    echo [UPDATE] Single folder detected, moving contents... >> \"%LOG_FILE%\" 2>&1\n";
        out << "    for /d %%i in (*) do (\n";
        out << "        echo [UPDATE] Entering folder: %%i >> \"%LOG_FILE%\" 2>&1\n";
        out << "        cd \"%%i\"\n";
        out << "        echo [UPDATE] Contents of inner folder: >> \"%LOG_FILE%\" 2>&1\n";
        out << "        dir /b >> \"%LOG_FILE%\" 2>&1\n";
        out << "        echo [UPDATE] Copying and replacing files in application directory... >> \"%LOG_FILE%\" 2>&1\n";
        out << "        for %%f in (*) do (\n";
        out << "            echo [UPDATE] Processing file: %%f >> \"%LOG_FILE%\" 2>&1\n";
        out << "            if exist \"..\\..\\%%f\" (\n";
        out << "                echo [UPDATE] Deleting existing file: %%f >> \"%LOG_FILE%\" 2>&1\n";
        out << "                del /F /Q \"..\\..\\%%f\" >> \"%LOG_FILE%\" 2>&1\n";
        out << "                if exist \"..\\..\\%%f\" (\n";
        out << "                    echo [UPDATE] WARNING: Failed to delete %%f, retrying after 2 seconds... >> \"%LOG_FILE%\" 2>&1\n";
        out << "                    timeout /t 2 /nobreak > nul\n";
        out << "                    del /F /Q \"..\\..\\%%f\" >> \"%LOG_FILE%\" 2>&1\n";
        out << "                )\n";
        out << "            )\n";
        out << "            copy /Y \"%%f\" \"..\\..\\\" >> \"%LOG_FILE%\" 2>&1\n";
        out << "            if errorlevel 1 (\n";
        out << "                echo [UPDATE] ERROR: Failed to copy file %%f, retrying after 2 seconds... >> \"%LOG_FILE%\" 2>&1\n";
        out << "                timeout /t 2 /nobreak > nul\n";
        out << "                copy /Y \"%%f\" \"..\\..\\\" >> \"%LOG_FILE%\" 2>&1\n";
        out << "                if errorlevel 1 (\n";
        out << "                    echo [UPDATE] ERROR: Failed to copy file %%f after retry >> \"%LOG_FILE%\" 2>&1\n";
        out << "                ) else (\n";
        out << "                    echo [UPDATE] Successfully copied %%f after retry >> \"%LOG_FILE%\" 2>&1\n";
        out << "                )\n";
        out << "            ) else (\n";
        out << "                echo [UPDATE] Successfully copied: %%f >> \"%LOG_FILE%\" 2>&1\n";
        out << "            )\n";
        out << "        )\n";
        out << "        echo [UPDATE] Copying and replacing directories in application directory... >> \"%LOG_FILE%\" 2>&1\n";
        out << "        for /d %%d in (*) do (\n";
        out << "            echo [UPDATE] Processing directory: %%d >> \"%LOG_FILE%\" 2>&1\n";
        out << "            if exist \"..\\..\\%%d\" (\n";
        out << "                echo [UPDATE] Deleting existing directory: %%d >> \"%LOG_FILE%\" 2>&1\n";
        out << "                rd /S /Q \"..\\..\\%%d\" >> \"%LOG_FILE%\" 2>&1\n";
        out << "            )\n";
        out << "            echo [UPDATE] Copying directory: %%d >> \"%LOG_FILE%\" 2>&1\n";
        out << "            xcopy \"%%d\" \"..\\..\\%%d\\\" /E /I /Y /Q >> \"%LOG_FILE%\" 2>&1\n";
        out << "            if errorlevel 1 (\n";
        out << "                echo [UPDATE] ERROR: Failed to copy directory %%d >> \"%LOG_FILE%\" 2>&1\n";
        out << "            ) else (\n";
        out << "                echo [UPDATE] Successfully copied: %%d >> \"%LOG_FILE%\" 2>&1\n";
        out << "            )\n";
        out << "        )\n";
        out << "        cd ..\n";
        out << "    )\n";
        out << ") else (\n";
        out << "    echo [UPDATE] Multiple items detected, copying and replacing all... >> \"%LOG_FILE%\" 2>&1\n";
        out << "    for %%f in (*) do (\n";
        out << "        echo [UPDATE] Processing file: %%f >> \"%LOG_FILE%\" 2>&1\n";
        out << "        if exist \"..\\%%f\" (\n";
        out << "            echo [UPDATE] Deleting existing file: %%f >> \"%LOG_FILE%\" 2>&1\n";
        out << "            del /F /Q \"..\\%%f\" >> \"%LOG_FILE%\" 2>&1\n";
        out << "            if exist \"..\\%%f\" (\n";
        out << "                echo [UPDATE] WARNING: Failed to delete %%f, retrying after 2 seconds... >> \"%LOG_FILE%\" 2>&1\n";
        out << "                timeout /t 2 /nobreak > nul\n";
        out << "                del /F /Q \"..\\%%f\" >> \"%LOG_FILE%\" 2>&1\n";
        out << "            )\n";
        out << "        )\n";
        out << "        copy /Y \"%%f\" \"..\\\" >> \"%LOG_FILE%\" 2>&1\n";
        out << "        if errorlevel 1 (\n";
        out << "            echo [UPDATE] ERROR: Failed to copy file %%f, retrying after 2 seconds... >> \"%LOG_FILE%\" 2>&1\n";
        out << "            timeout /t 2 /nobreak > nul\n";
        out << "            copy /Y \"%%f\" \"..\\\" >> \"%LOG_FILE%\" 2>&1\n";
        out << "            if errorlevel 1 (\n";
        out << "                echo [UPDATE] ERROR: Failed to copy file %%f after retry >> \"%LOG_FILE%\" 2>&1\n";
        out << "            ) else (\n";
        out << "                echo [UPDATE] Successfully copied %%f after retry >> \"%LOG_FILE%\" 2>&1\n";
        out << "            )\n";
        out << "        ) else (\n";
        out << "            echo [UPDATE] Successfully copied: %%f >> \"%LOG_FILE%\" 2>&1\n";
        out << "        )\n";
        out << "    )\n";
        out << "    for /d %%d in (*) do (\n";
        out << "        echo [UPDATE] Processing directory: %%d >> \"%LOG_FILE%\" 2>&1\n";
        out << "        if exist \"..\\%%d\" (\n";
        out << "            echo [UPDATE] Deleting existing directory: %%d >> \"%LOG_FILE%\" 2>&1\n";
        out << "            rd /S /Q \"..\\%%d\" >> \"%LOG_FILE%\" 2>&1\n";
        out << "        )\n";
        out << "        echo [UPDATE] Copying directory: %%d >> \"%LOG_FILE%\" 2>&1\n";
        out << "        xcopy \"%%d\" \"..\\%%d\\\" /E /I /Y /Q >> \"%LOG_FILE%\" 2>&1\n";
        out << "        if errorlevel 1 (\n";
        out << "            echo [UPDATE] ERROR: Failed to copy directory %%d >> \"%LOG_FILE%\" 2>&1\n";
        out << "        ) else (\n";
        out << "            echo [UPDATE] Successfully copied: %%d >> \"%LOG_FILE%\" 2>&1\n";
        out << "        )\n";
        out << "    )\n";
        out << ")\n";
        
        out << "cd ..\n";
        out << "echo [UPDATE] Verifying new executable... >> \"%LOG_FILE%\" 2>&1\n";
        out << "if exist \"" << currentAppName << "\" (\n";
        out << "    echo [UPDATE] New executable found: " << currentAppName << " >> \"%LOG_FILE%\" 2>&1\n";
        out << "    dir \"" << currentAppName << "\" | find \"" << currentAppName << "\" >> \"%LOG_FILE%\" 2>&1\n";
        out << ") else (\n";
        out << "    echo [UPDATE] ERROR: New executable not found after update! >> \"%LOG_FILE%\" 2>&1\n";
        out << "    echo [UPDATE] Current directory contents: >> \"%LOG_FILE%\" 2>&1\n";
        out << "    dir /b >> \"%LOG_FILE%\" 2>&1\n";
        out << "    pause\n";
        out << ")\n";
        out << "echo [UPDATE] Cleaning up temporary files... >> \"%LOG_FILE%\" 2>&1\n";
        out << "rmdir /s /q temp_update >> \"%LOG_FILE%\" 2>&1\n";
        out << "del update.zip >> \"%LOG_FILE%\" 2>&1\n";
        
        out << "echo [UPDATE] Update completed successfully! >> \"%LOG_FILE%\" 2>&1\n";
        out << "del update.lock >> \"%LOG_FILE%\" 2>&1\n"; // 删除更新锁文件
        out << "echo [UPDATE] Restarting application... >> \"%LOG_FILE%\" 2>&1\n";
        out << "timeout /t 1 /nobreak > nul\n";
        out << "start \"\" \"" << QDir::toNativeSeparators(currentAppPath) << "\" >> \"%LOG_FILE%\" 2>&1\n";
        out << "if errorlevel 1 (\n";
        out << "    echo [UPDATE] ERROR: Failed to restart application! >> \"%LOG_FILE%\" 2>&1\n";
        out << "    pause\n";
        out << ") else (\n";
        out << "    echo [UPDATE] Application restarted successfully >> \"%LOG_FILE%\" 2>&1\n";
        out << ")\n";
        out << "goto end\n";
        
        out << ":cleanup\n";
        out << "echo [UPDATE] Cleanup: Removing temporary files... >> \"%LOG_FILE%\" 2>&1\n";
        out << "if exist temp_update rmdir /s /q temp_update >> \"%LOG_FILE%\" 2>&1\n";
        out << "del update.zip >> \"%LOG_FILE%\" 2>&1\n";
        out << "del update.lock >> \"%LOG_FILE%\" 2>&1\n"; // 即使失败也要删除锁文件
        out << ":end\n";
        out << "echo [UPDATE] Update process finished, removing batch script... >> \"%LOG_FILE%\" 2>&1\n";
        out << "echo ========== Update Process Ended at %date% %time% ========== >> \"%LOG_FILE%\" 2>&1\n";
        out << "del \"" << QDir::toNativeSeparators(batchScript) << "\"\n"; // 删除批处理文件自身
        batchFile.close();
        
        qDebug() << "[LoginManager] Batch script created successfully";
        qDebug() << "[LoginManager] Batch script path:" << batchScript;
        
        // 日志文件路径（使用时间戳命名）
        QString logDir = appDir + "/AppData/logs";
        QString timestamp = QDateTime::currentDateTime().toString("yyyy-MM-dd_hh-mm-ss");
        QString updateLogPath = logDir + "/update_" + timestamp + ".log";
        qDebug() << "[LoginManager] Update process will be logged to:" << updateLogPath;
        qDebug() << "[LoginManager] IMPORTANT: Check AppData/logs/update_*.log for detailed update progress and any errors";
        
        // 验证批处理脚本文件
        QFileInfo batchFileInfo(batchScript);
        if (batchFileInfo.exists()) {
            qDebug() << "[LoginManager] Batch script file size:" << batchFileInfo.size() << "bytes";
        } else {
            qWarning() << "[LoginManager] ERROR: Batch script file was not created!";
            return false;
        }
        
        // 启动批处理脚本并退出当前应用
        qDebug() << "[LoginManager] Starting batch script with cmd.exe";
        QString batchScriptNative = QDir::toNativeSeparators(batchScript);
        qDebug() << "[LoginManager] Native path:" << batchScriptNative;
        
        bool started = QProcess::startDetached("cmd.exe", QStringList() << "/c" << batchScriptNative);
        if (started) {
            qDebug() << "[LoginManager] Batch script started successfully";
        } else {
            qWarning() << "[LoginManager] ERROR: Failed to start batch script!";
            return false;
        }
        
        // 延迟退出应用，给批处理脚本启动的时间
        qDebug() << "[LoginManager] Scheduling application exit in 1 second...";
        QTimer::singleShot(1000, QCoreApplication::instance(), &QCoreApplication::quit);
        
        qDebug() << "[LoginManager] ========== Update Installation Setup Complete ==========";
        return true;
    } else {
        qWarning() << "[LoginManager] ERROR: Failed to create update script file";
        qWarning() << "[LoginManager] Batch script path:" << batchScript;
        // 清理复制的文件
        qDebug() << "[LoginManager] Cleaning up copied update file";
        if (QFile::remove(updateZipPath)) {
            qDebug() << "[LoginManager] Update zip file removed";
        } else {
            qWarning() << "[LoginManager] WARNING: Failed to remove update zip file";
        }
        return false;
    }
}
