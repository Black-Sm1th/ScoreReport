#pragma once
#include <QObject>
#include <QString>
#include <QStringList>
#include "CommonFunc.h"

class ConfigModel : public QObject
{
    Q_OBJECT

    QUICK_PROPERTY(bool, usePublicNetwork)
    QUICK_PROPERTY(QStringList, homeViewTabs)

    SINGLETON_CLASS(ConfigModel)

public:
    void loadConfig();

    QString internalBaseUrl() const { return m_internalBaseUrl; }
    QString publicBaseUrl() const { return m_publicBaseUrl; }
    QString getBaseUrl() const;

private:
    QString m_internalBaseUrl;
    QString m_publicBaseUrl;
};
