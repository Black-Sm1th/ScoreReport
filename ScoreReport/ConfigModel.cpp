#include "ConfigModel.h"
#include <QFile>
#include <QDir>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QDebug>

ConfigModel::ConfigModel(QObject *parent)
    : QObject(parent)
    , m_internalBaseUrl("http://172.20.117.53:9898/api")
    , m_publicBaseUrl("http://111.6.178.34:24603/api")
    , m_usePublicNetwork(true)
    , m_homeViewTabs({QStringLiteral("通用"), QStringLiteral("肾")})
{
    loadConfig();
}

QString ConfigModel::getBaseUrl() const
{
    return getusePublicNetwork() ? m_publicBaseUrl : m_internalBaseUrl;
}

void ConfigModel::loadConfig()
{
    QString configDir = "AppData/config/";
    QString configPath = configDir + "config.json";
    
    QFile configFile(configPath);
    
    if (!configFile.exists()) {
        QDir dir;
        if (!dir.mkpath(configDir)) {
            setusePublicNetwork(true);
            return;
        }
        
        QJsonObject networkObj;
        networkObj["usePublicNetwork"] = true;
        networkObj["internalBaseUrl"] = m_internalBaseUrl;
        networkObj["publicBaseUrl"] = m_publicBaseUrl;
        
        QJsonArray tabsArray;
        for (const QString& tab : m_homeViewTabs)
            tabsArray.append(tab);
        
        QJsonObject rootObj;
        rootObj["network"] = networkObj;
        rootObj["HomeViewTab"] = tabsArray;
        
        if (configFile.open(QIODevice::WriteOnly)) {
            QJsonDocument doc(rootObj);
            configFile.write(doc.toJson(QJsonDocument::Indented));
            configFile.close();
        } else {
            setusePublicNetwork(true);
            return;
        }
    }
    
    if (!configFile.open(QIODevice::ReadOnly)) {
        setusePublicNetwork(true);
        return;
    }
    
    QByteArray configData = configFile.readAll();
    configFile.close();
    
    QJsonDocument doc = QJsonDocument::fromJson(configData);
    if (!doc.isObject()) {
        setusePublicNetwork(true);
        return;
    }
    
    QJsonObject rootObj = doc.object();
    bool needSave = false;
    
    if (rootObj.contains("network")) {
        QJsonObject networkObj = rootObj["network"].toObject();
        
        if (networkObj.contains("usePublicNetwork")) {
            setusePublicNetwork(networkObj["usePublicNetwork"].toBool());
        } else {
            setusePublicNetwork(true);
        }
        
        if (networkObj.contains("internalBaseUrl")) {
            m_internalBaseUrl = networkObj["internalBaseUrl"].toString();
        }
        
        if (networkObj.contains("publicBaseUrl")) {
            m_publicBaseUrl = networkObj["publicBaseUrl"].toString();
        }
    } else {
        setusePublicNetwork(true);
    }
    
    if (rootObj.contains("HomeViewTab") && rootObj["HomeViewTab"].isArray()) {
        QJsonArray tabsArray = rootObj["HomeViewTab"].toArray();
        QStringList tabs;
        for (const QJsonValue& val : tabsArray)
            tabs.append(val.toString());
        if (!tabs.isEmpty())
            sethomeViewTabs(tabs);
    } else {
        QJsonArray tabsArray;
        for (const QString& tab : m_homeViewTabs)
            tabsArray.append(tab);
        rootObj["HomeViewTab"] = tabsArray;
        needSave = true;
    }
    
    if (needSave) {
        QFile saveFile(configPath);
        if (saveFile.open(QIODevice::WriteOnly)) {
            QJsonDocument saveDoc(rootObj);
            saveFile.write(saveDoc.toJson(QJsonDocument::Indented));
            saveFile.close();
        }
    }
}
