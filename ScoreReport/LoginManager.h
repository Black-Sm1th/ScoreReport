#ifndef LOGINMANAGER_H
#define LOGINMANAGER_H

#include <QObject>
#include <QString>
#include <QDebug>
#include <QJsonObject>
#include <QSettings>
#include <QVariantList>
#include <QVariantMap>
#include <QCursor>
#include <QPoint>
#include "CommonFunc.h"
#include "GlobalTextMonitor.h"
#include "GlobalMouseListener.h"
class ApiManager;

class LoginManager : public QObject
{
    Q_OBJECT
    QUICK_PROPERTY(bool, isLoggedIn)
    QUICK_PROPERTY(QString, currentUserId)
    QUICK_PROPERTY(QString, currentUserName)
    QUICK_PROPERTY(QString, currentUserAvatar)
    QUICK_PROPERTY(QString, savedUsername)
    QUICK_PROPERTY(QString, savedPassword)
    QUICK_PROPERTY(bool, rememberPassword)
    QUICK_PROPERTY(QVariantList, userList)
    QUICK_PROPERTY(bool, isChangingUser)
    QUICK_PROPERTY(bool, isAdding)
    QUICK_PROPERTY(bool, isRegistering)
    QUICK_PROPERTY(bool, showDialogOnTextSelection)
    SINGLETON_CLASS(LoginManager)

public:
    Q_INVOKABLE bool login(const QString& username, const QString& password);
    Q_INVOKABLE void logout();
    Q_INVOKABLE void saveCredentials(const QString& username, const QString& password, bool remember);
    Q_INVOKABLE void loadSavedCredentials();
    Q_INVOKABLE void addUserToList(const QString& username, const QString& password, const QString& userId, const QString& avatar);
    Q_INVOKABLE void removeUserFromList(const QString& userId);
    Q_INVOKABLE bool registAccount(const QString& userAccount, const QString& userPassword, const QString& checkPassword);
    Q_INVOKABLE void stopMonitoring();
    Q_INVOKABLE void copyToClipboard(const QString& text);
    Q_INVOKABLE void saveShowDialogSetting(bool showDialog);
    Q_INVOKABLE void performScreenshotOCR();
    Q_INVOKABLE void processScreenshotArea(int x, int y, int width, int height);
    Q_INVOKABLE void changeMouseStatus(bool type);
signals:
    void loginResult(bool success, const QString& message);
    void logoutSuccess();
    void registResult(bool success, const QString& message);
    void textSelectionDetected(const QString& text, int mouseX, int mouseY);
    void screenshotOCRResult(const QString& text);
    void startScreenshotSelection();
    void mouseEvent();
private slots:
    void onRegistResponse(bool success, const QString& message, const QJsonObject& data);
    void onLoginResponse(bool success, const QString& message, const QJsonObject& data);
    void onTextSelected(const QString& text);
    void onMouseEvent(GlobalMouseListener::MouseButton button, int delta, QPoint pos);
    void onTimeout();
private:
    void loadUserList();
    void saveUserList();
    QVariantMap findUserInList(const QString& userId);
    GlobalTextMonitor* m_selector;
    ApiManager* m_apiManager;
    QSettings* m_settings;
    GlobalMouseListener* m_mouseListener;
    QTimer* m_timer;
    QString m_currentStr = "";
};

#endif // LOGINMANAGER_H 