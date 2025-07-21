#ifndef TNMMANAGER_H
#define TNMMANAGER_H

#include <QObject>
#include <QClipboard>
#include <QGuiApplication>

class TNMManager : public QObject
{
    Q_OBJECT
    Q_PROPERTY(QString clipboardContent READ clipboardContent NOTIFY clipboardContentChanged)
    Q_PROPERTY(bool isAnalyzing READ isAnalyzing NOTIFY isAnalyzingChanged)

public:
    explicit TNMManager(QObject *parent = nullptr);

    QString clipboardContent() const;
    bool isAnalyzing() const;

    Q_INVOKABLE bool checkClipboard();

signals:
    void clipboardContentChanged();
    void isAnalyzingChanged();

private:
    QClipboard *m_clipboard;
    QString m_clipboardContent;
    bool m_isAnalyzing;
};

#endif // TNMMANAGER_H 