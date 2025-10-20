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
    setisDownloadingUpdate(false);
    
    if (!success) {
        qWarning() << "[LoginManager] Failed to download update file:" << message;
        return;
    }
    
    qDebug() << "[LoginManager] Update file downloaded successfully";
    emit updateDownloadCompleted();
    
    // 文件已经被ApiManager保存到临时位置，直接获取文件路径
    QString downloadedFilePath = data.value("filePath").toString();
    QString fileName = data.value("fileName").toString();
    int fileSize = data.value("fileSize").toInt();
    
    qDebug() << "[LoginManager] Downloaded file info - Path:" << downloadedFilePath 
             << "Name:" << fileName << "Size:" << fileSize << "bytes";
    
    // 验证文件是否存在且有效
    if (downloadedFilePath.isEmpty() || !QFile::exists(downloadedFilePath)) {
        qWarning() << "[LoginManager] Downloaded file not found:" << downloadedFilePath;
        return;
    }
    
    // 验证文件大小
    QFileInfo fileInfo(downloadedFilePath);
    if (fileInfo.size() != fileSize || fileInfo.size() == 0) {
        qWarning() << "[LoginManager] Downloaded file size mismatch or empty. Expected:" << fileSize 
                   << "Actual:" << fileInfo.size();
        return;
    }
    
    // 安装更新
    if (installUpdate(downloadedFilePath)) {
        emit updateInstallationCompleted();
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
    if (downloadedFilePath.isEmpty() || !QFile::exists(downloadedFilePath)) {
        qWarning() << "[LoginManager] Update file does not exist:" << downloadedFilePath;
        return false;
    }
    
    // 获取当前应用程序路径
    QString currentAppPath = QCoreApplication::applicationFilePath();
    QString appDir = QCoreApplication::applicationDirPath();
    QString currentAppName = QFileInfo(currentAppPath).fileName();
    
    // 将压缩包复制到应用程序目录
    QString updateZipPath = appDir + "/update.zip";
    
    qDebug() << "[LoginManager] Installing update from:" << downloadedFilePath 
             << "to app directory:" << appDir;
    
    // 复制压缩包到应用程序目录
    if (QFile::exists(updateZipPath)) {
        QFile::remove(updateZipPath); // 删除已存在的更新文件
    }
    
    if (!QFile::copy(downloadedFilePath, updateZipPath)) {
        qWarning() << "[LoginManager] Failed to copy update file to app directory";
        return false;
    }
    
    qDebug() << "[LoginManager] Update file copied to:" << updateZipPath;
    
    // 创建更新锁文件，防止用户在更新期间再次启动应用
    QString updateLockPath = appDir + "/update.lock";
    QFile lockFile(updateLockPath);
    if (lockFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream lockStream(&lockFile);
        lockStream << QDateTime::currentDateTime().toString(Qt::ISODate);
        lockFile.close();
        qDebug() << "[LoginManager] Update lock file created:" << updateLockPath;
    } else {
        qWarning() << "[LoginManager] Failed to create update lock file";
    }
    
    // 创建批处理脚本来解压缩文件并重启应用
    QString batchScript = appDir + "/update_install.bat";
    QFile batchFile(batchScript);
    
    if (batchFile.open(QIODevice::WriteOnly | QIODevice::Text)) {
        QTextStream out(&batchFile);
        out << "@echo off\n";
        out << "cd /d \"" << QDir::toNativeSeparators(appDir) << "\"\n";
        out << "echo Installing update...\n";
        out << "timeout /t 2 /nobreak > nul\n"; // 等待2秒确保当前应用完全退出
        
        // 检查应用是否仍在运行，最多等待5秒后强制终止
        out << "set WAIT_COUNT=0\n";
        out << ":CHECK_PROCESS\n";
        out << "tasklist /FI \"IMAGENAME eq " << currentAppName << "\" 2>NUL | find /I /N \"" << currentAppName << "\">NUL\n";
        out << "if \"%ERRORLEVEL%\"==\"0\" (\n";
        out << "    if %WAIT_COUNT% LSS 5 (\n";
        out << "        echo Waiting for application to close... (%WAIT_COUNT%/5)\n";
        out << "        timeout /t 1 /nobreak > nul\n";
        out << "        set /a WAIT_COUNT+=1\n";
        out << "        goto CHECK_PROCESS\n";
        out << "    ) else (\n";
        out << "        echo Application still running after 5 seconds, forcing termination...\n";
        out << "        taskkill /F /IM \"" << currentAppName << "\" > nul 2>&1\n";
        out << "        timeout /t 1 /nobreak > nul\n";
        out << "        echo Application terminated.\n";
        out << "    )\n";
        out << ")\n";
        out << "echo Application closed, continuing with update...\n";
        
        // 使用PowerShell解压缩文件（Windows内置）
        out << "echo Extracting update files...\n";
        out << "powershell -command \"& { Add-Type -AssemblyName System.IO.Compression.FileSystem; [System.IO.Compression.ZipFile]::ExtractToDirectory('update.zip', 'temp_update') }\"\n";
        out << "if errorlevel 1 (\n";
        out << "    echo Update extraction failed!\n";
        out << "    pause\n";
        out << "    goto cleanup\n";
        out << ")\n";
        
        // 检查解压后的结构并移动文件
        out << "echo Processing extracted files...\n";
        out << "cd temp_update\n";
        
        // 检查是否只有一个文件夹
        out << "for /f \"tokens=*\" %%i in ('dir /b /ad 2^>nul ^| find /c /v \"\"') do set FOLDER_COUNT=%%i\n";
        out << "for /f \"tokens=*\" %%i in ('dir /b /a-d 2^>nul ^| find /c /v \"\"') do set FILE_COUNT=%%i\n";
        
        out << "if %FOLDER_COUNT%==1 if %FILE_COUNT%==0 (\n";
        out << "    echo Single folder detected, moving contents...\n";
        out << "    for /d %%i in (*) do (\n";
        out << "        cd \"%%i\"\n";
        out << "        for %%f in (*) do move \"%%f\" \"..\\..\\\" >nul 2>&1\n";
        out << "        for /d %%d in (*) do move \"%%d\" \"..\\..\\\" >nul 2>&1\n";
        out << "        cd ..\n";
        out << "    )\n";
        out << ") else (\n";
        out << "    echo Multiple items detected, moving all...\n";
        out << "    for %%f in (*) do move \"%%f\" \"..\\\" >nul 2>&1\n";
        out << "    for /d %%d in (*) do move \"%%d\" \"..\\\" >nul 2>&1\n";
        out << ")\n";
        
        out << "cd ..\n";
        out << "rmdir /s /q temp_update\n";
        out << "del update.zip\n";
        
        out << "echo Update completed successfully!\n";
        out << "del update.lock\n"; // 删除更新锁文件
        out << "echo Restarting application...\n";
        out << "timeout /t 1 /nobreak > nul\n";
        out << "start \"\" \"" << QDir::toNativeSeparators(currentAppPath) << "\"\n";
        out << "goto end\n";
        
        out << ":cleanup\n";
        out << "if exist temp_update rmdir /s /q temp_update\n";
        out << "del update.zip\n";
        out << "del update.lock\n"; // 即使失败也要删除锁文件
        out << ":end\n";
        out << "del \"" << QDir::toNativeSeparators(batchScript) << "\"\n"; // 删除批处理文件自身
        batchFile.close();
        
        // 启动批处理脚本并退出当前应用
        QProcess::startDetached("cmd.exe", QStringList() << "/c" << QDir::toNativeSeparators(batchScript));
        
        // 延迟退出应用，给批处理脚本启动的时间
        QTimer::singleShot(1000, QCoreApplication::instance(), &QCoreApplication::quit);
        
        return true;
    } else {
        qWarning() << "[LoginManager] Failed to create update script";
        // 清理复制的文件
        QFile::remove(updateZipPath);
        return false;
    }
}
