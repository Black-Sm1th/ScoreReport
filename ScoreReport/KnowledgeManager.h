#pragma once
#include "CommonFunc.h"
class KnowledgeManager : public QObject
{
    Q_OBJECT
        SINGLETON_CLASS(KnowledgeManager)
public:
    Q_INVOKABLE void updateKnowledgeList();
};

