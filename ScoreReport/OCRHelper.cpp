#include "OCRHelper.h"
#include <QDebug>

OCRHelper::OCRHelper(const QString& dataPath,
    const QStringList& langs,
    QObject* parent)
    : QObject(parent), api_(nullptr)
{
    if (dataPath.isEmpty()) {
        return;
    }
    QString langStr = langs.join("+");
    api_ = new tesseract::TessBaseAPI();
    if (api_->Init(dataPath.toUtf8().constData(), langStr.toUtf8().constData())) {
        delete api_;
        api_ = nullptr;
    }
}

OCRHelper::~OCRHelper() {
    if (api_) {
        api_->End();
        delete api_;
        api_ = nullptr;
    }
}

QString OCRHelper::recognizeFromFile(const QString& imagePath) {
    if (!api_) {
        return "";
    }
    Pix* image = pixRead(imagePath.toUtf8().constData());
    if (!image) {
        return "";
    }

    api_->SetImage(image);
    char* outText = api_->GetUTF8Text();
    QString result;
    if (outText) {
        result = QString::fromUtf8(outText);
        delete[] outText;
    }

    pixDestroy(&image);
    return result;
}

bool OCRHelper::setVariable(const QString& key, const QString& value) {
    if (!api_) {
        return false;
    }
    bool ok = api_->SetVariable(key.toUtf8().constData(), value.toUtf8().constData());
    return ok;
}
