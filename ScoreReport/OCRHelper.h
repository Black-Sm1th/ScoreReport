#pragma once

#include <QObject>
#include <QString>
#include <tesseract/baseapi.h>
#include <leptonica/allheaders.h>

class OCRHelper : public QObject {
    Q_OBJECT
public:
    explicit OCRHelper(const QString& dataPath = "language",
        const QStringList& langs = { "chi_sim", "eng"},
        QObject* parent = nullptr);

    ~OCRHelper();

    // 从图片文件识别文字
    Q_INVOKABLE QString recognizeFromFile(const QString& imagePath);

    // 设置 Tesseract 变量
    Q_INVOKABLE bool setVariable(const QString& key, const QString& value);

    // 判断是否可用
    Q_INVOKABLE bool isReady() const { return api_ != nullptr; }

private:
    tesseract::TessBaseAPI* api_;
};
