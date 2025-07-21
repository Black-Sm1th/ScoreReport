#include "LoginManager.h"

LoginManager::LoginManager(QObject* parent)
    : QObject(parent)
    , m_isLoggedIn(false)
    , m_currentUserName("")
    , currentUserId(-1)
    , m_networkMgr(new QNetworkAccessManager(this))
{
    // 接收来自网络请求的响应
    connect(m_networkMgr, &QNetworkAccessManager::finished,
        this, &LoginManager::onNetworkReply);
}


bool LoginManager::isLoggedIn() const
{
    return m_isLoggedIn;
}

void LoginManager::setIsLoggedIn(bool loggedIn)
{
    if (m_isLoggedIn != loggedIn) {
        m_isLoggedIn = loggedIn;
        emit isLoggedInChanged();
    }
}

QString LoginManager::currentUserName() const
{
    return m_currentUserName;
}

void LoginManager::setCurrentUserName(const QString& currentUserName)
{
    if (m_currentUserName != currentUserName) {
        m_currentUserName = currentUserName;
        emit currentUserNameChanged();
    }
}

bool LoginManager::login(const QString& username, const QString& password)
{
    qDebug() << "[LoginManager] Starting login for user:" << username;

    QUrl url(usePublic
        ? QStringLiteral("http://111.6.178.34:9205/api/admin/user/login")
        : QStringLiteral("http://192.168.1.2:9898/api/admin/user/login"));

    QNetworkRequest req(url);
    req.setHeader(QNetworkRequest::ContentTypeHeader, "application/json");

    QJsonObject json;
    json["userAccount"] = username;
    json["userPassword"] = password;
    QByteArray body = QJsonDocument(json).toJson();

    qDebug() << "[LoginManager] POST URL:" << url.toString();
    qDebug() << "[LoginManager] Request body:" << body;

    m_networkMgr->post(req, body);

    return true;
}

void LoginManager::onNetworkReply(QNetworkReply* reply)
{
    QUrl replyUrl = reply->url();
    qDebug() << "[LoginManager] Reply received from:" << replyUrl.toString();

    if (!replyUrl.path().endsWith("/login")) {
        qDebug() << "[LoginManager] Ignored non-login reply";
        reply->deleteLater();
        return;
    }

    if (reply->error() == QNetworkReply::NoError) {
        QByteArray respData = reply->readAll();
        qDebug() << "[LoginManager] Response data:" << respData;

        QJsonDocument doc = QJsonDocument::fromJson(respData);
        if (!doc.isObject()) {
            qWarning() << "[LoginManager] Invalid JSON response";
            emit loginResult(false, "Invalid server response");
        }
        else {
            QJsonObject obj = doc.object();
            int code = obj.value("code").toInt();
            QString msg = obj.value("message").toString();
            bool success = (code == 0);
            qDebug() << "[LoginManager] code =" << code << ", success =" << success << ", message =" << msg;

            if (success) {
                QJsonObject dataObj = obj.value("data").toObject();
                QString respUser = dataObj.value("userName").toString();
                currentUserId = dataObj.value("id").toInt();
                qDebug() << "[LoginManager] received username:" << respUser;
                setCurrentUserName(respUser);
                setIsLoggedIn(true);
            }
            else {
                setIsLoggedIn(false);
            }

            emit loginResult(success, msg);
        }
    }
    else {
        QString err = reply->errorString();
        qWarning() << "[LoginManager] Network error:" << err;
        emit loginResult(false, err);
    }

    reply->deleteLater();
}

void LoginManager::logout()
{
    setIsLoggedIn(false);
    setCurrentUserName("");
    currentUserId = -1;
    emit logoutSuccess();
}

int LoginManager::getUserId()
{
    return 0;
}
