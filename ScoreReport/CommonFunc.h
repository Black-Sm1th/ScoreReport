#pragma once

#include <QObject>

// 第一个宏：快速创建 Q_PROPERTY
#define QUICK_PROPERTY(type, name) \
    Q_PROPERTY(type name READ get##name WRITE set##name NOTIFY name##Changed) \
private: \
    type m_##name; \
public: \
    type get##name() const { return m_##name; } \
    void set##name(const type& value) { \
        if (m_##name != value) { \
            m_##name = value; \
            emit name##Changed(); \
        } \
    } \
    Q_SIGNAL void name##Changed();

// 第二个宏：当前类为单例（完全自包含，无需额外宏）
#define SINGLETON_CLASS(ClassName) \
private: \
    ClassName(QObject* parent = nullptr); \
    ~ClassName() {} \
    ClassName(const ClassName&) = delete; \
    ClassName& operator=(const ClassName&) = delete; \
public: \
    static ClassName* getInstance() { \
        static ClassName instance; \
        return &instance; \
    } 

// 第三个宏：获取单例类的对象地址
#define GET_SINGLETON(ClassName) ClassName::getInstance()
