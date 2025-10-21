#include "LanguageManager.h"
#include <QGuiApplication>
#include <QQmlContext>
#include <QDir>
#include <QDebug>
LanguageManager::LanguageManager(QObject *parent)
    : QObject(parent)
    , m_translator(new QTranslator(this))
    , m_engine(nullptr)
    , m_currentLanguage("zh")
    , m_settings(new QSettings("AETHERMIND", "Knowledge", this))
{
    // 初始化可用语言列表
    m_availableLanguages << "zh" << "en";
    
    // 加载保存的语言设置
    loadLanguageSettings();
}

void LanguageManager::initializeTranslator(QQmlApplicationEngine* engine)
{
    m_engine = engine;
    
    // 安装翻译器到应用程序
    QGuiApplication::installTranslator(m_translator);
    
    // 设置QML上下文属性，用于动态重新翻译
    if (m_engine) {
        m_engine->rootContext()->setContextProperty("languageManager", this);
    }
    
    // 加载当前语言的翻译
    loadTranslation(m_currentLanguage);
}

QString LanguageManager::currentLanguage() const
{
    return m_currentLanguage;
}

QStringList LanguageManager::availableLanguages() const
{
    return m_availableLanguages;
}

void LanguageManager::setCurrentLanguage(const QString& language)
{
    if (m_currentLanguage != language && m_availableLanguages.contains(language)) {
        m_currentLanguage = language;
        
        // 保存语言设置
        saveLanguageSettings();
        
        // 加载新的翻译
        loadTranslation(language);
        
        emit currentLanguageChanged();
        
        // 强制QML重新加载（作为最后手段）
        qDebug() << "[LanguageManager] Language changed to:" << language;
    }
}

QString LanguageManager::getLanguageDisplayName(const QString& language) const
{
    if (language == "zh") {
        return QStringLiteral("中文");
    } else if (language == "en") {
        return "English";
    }
    return language;
}

void LanguageManager::loadTranslation(const QString& language)
{
    // 移除当前翻译器
    QGuiApplication::removeTranslator(m_translator);
    
    // 构建翻译文件路径
    QString translationPath = QStringLiteral(":/translations/ScoreReport_%1.qm").arg(language);
    
    // 加载翻译文件
    if (m_translator->load(translationPath)) {
        qDebug() << "[LanguageManager] Translation loaded successfully for language:" << language;
        QGuiApplication::installTranslator(m_translator);
        
        // 通知QML引擎重新翻译
        if (m_engine) {
            m_engine->retranslate();
        }
    } else {
        qDebug() << "[LanguageManager] Failed to load translation for language:" << language;
        qDebug() << "[LanguageManager] Translation path:" << translationPath;
    }
}

void LanguageManager::saveLanguageSettings()
{
    m_settings->setValue("currentLanguage", m_currentLanguage);
    m_settings->sync();
}

void LanguageManager::loadLanguageSettings()
{
    QString savedLanguage = m_settings->value("currentLanguage", "zh").toString();
    if (m_availableLanguages.contains(savedLanguage)) {
        m_currentLanguage = savedLanguage;
    }
} 