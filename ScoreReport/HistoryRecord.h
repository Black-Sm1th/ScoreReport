#include "CommonFunc.h"
#include <QObject>

class HistoryRecord : public QObject
{
    Q_OBJECT
        SINGLETON_CLASS(HistoryRecord)

};