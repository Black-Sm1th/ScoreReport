#include "OCRHelper.h"
#include <QDebug>

OCRHelper::OCRHelper(const QString& dataPath,
    const QStringList& langs,
    QObject* parent)
    : QObject(parent), api_(nullptr)
{
    if (dataPath.isEmpty()) {
        qWarning() << "[OCR] 未指定 tessdata 路径，跳过初始化";
        return;
    }

    QString langStr = langs.join("+");
    api_ = new tesseract::TessBaseAPI();

    qDebug() << "[OCR] 初始化中, path =" << dataPath << " langs =" << langStr;

    if (api_->Init(dataPath.toUtf8().constData(), langStr.toUtf8().constData())) {
        qWarning() << "[OCR][错误] 初始化失败, 请检查 tessdata 路径和语言包";
        delete api_;
        api_ = nullptr;
    }
    else {
        qDebug() << "[OCR] 初始化成功";
    }
}

OCRHelper::~OCRHelper() {
    if (api_) {
        qDebug() << "[OCR] 释放资源";
        api_->End();
        delete api_;
        api_ = nullptr;
    }
}

QString OCRHelper::recognizeFromFile(const QString& imagePath) {
    if (!api_) {
        qWarning() << "[OCR][错误] API 未初始化";
        return "";
    }

    qDebug() << "[OCR] 开始识别图片:" << imagePath;
    Pix* image = pixRead(imagePath.toUtf8().constData());
    if (!image) {
        qWarning() << "[OCR][错误] 无法读取图像:" << imagePath;
        return "";
    }

    api_->SetImage(image);
    char* outText = api_->GetUTF8Text();
    QString result;
    if (outText) {
        result = QString::fromUtf8(outText);
        qDebug() << "[OCR] 识别完成, 字符数:" << result.size();
        delete[] outText;
    }
    else {
        qWarning() << "[OCR][错误] 识别失败 (返回空)";
    }

    pixDestroy(&image);
    return result;
}

bool OCRHelper::setVariable(const QString& key, const QString& value) {
    if (!api_) {
        qWarning() << "[OCR][错误] API 未初始化";
        return false;
    }
    bool ok = api_->SetVariable(key.toUtf8().constData(), value.toUtf8().constData());
    if (ok) {
        qDebug() << "[OCR] SetVariable 成功:" << key << "=" << value;
    }
    else {
        qWarning() << "[OCR][警告] SetVariable 失败:" << key << "=" << value;
    }
    return ok;
}
