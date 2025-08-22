#ifndef LANGUAGEMANAGER_H
#define LANGUAGEMANAGER_H

#include <QObject>
#include <QTranslator>
#include <QQmlApplicationEngine>
#include <QSettings>
#include "CommonFunc.h"

class LanguageManager : public QObject
{
    Q_OBJECT
    SINGLETON_CLASS(LanguageManager)
    
    Q_PROPERTY(QString currentLanguage READ currentLanguage WRITE setCurrentLanguage NOTIFY currentLanguageChanged)
    Q_PROPERTY(QStringList availableLanguages READ availableLanguages CONSTANT)

public:
    // 初始化翻译器，需要在QQmlApplicationEngine创建后调用
    void initializeTranslator(QQmlApplicationEngine* engine);
    
    // 获取当前语言
    QString currentLanguage() const;
    
    // 获取可用语言列表
    QStringList availableLanguages() const;
    
    // 设置当前语言
    Q_INVOKABLE void setCurrentLanguage(const QString& language);
    
    // 获取语言显示名称
    Q_INVOKABLE QString getLanguageDisplayName(const QString& language) const;

signals:
    void currentLanguageChanged();

private:
    void loadTranslation(const QString& language);
    void saveLanguageSettings();
    void loadLanguageSettings();
    
private:
    QTranslator* m_translator;
    QQmlApplicationEngine* m_engine;
    QString m_currentLanguage;
    QStringList m_availableLanguages;
    QSettings* m_settings;
};

#endif // LANGUAGEMANAGER_H 