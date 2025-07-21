#include "TNMManager.h"
#include <QDebug>

TNMManager::TNMManager(QObject *parent)
    : QObject(parent)
    , m_clipboard(QGuiApplication::clipboard())
    , m_isAnalyzing(false)
{

}

QString TNMManager::clipboardContent() const
{
    return m_clipboardContent;
}

bool TNMManager::isAnalyzing() const
{
    return m_isAnalyzing;
}

bool TNMManager::checkClipboard()
{
    QString content = m_clipboard->text().trimmed();
    
    if (content.isEmpty()) {
        return false;
    }
    m_clipboardContent = content;
    emit clipboardContentChanged();
    return true;
}