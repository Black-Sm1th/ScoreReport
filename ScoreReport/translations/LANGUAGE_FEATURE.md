# 语言切换功能使用说明

## 功能概述
本项目已添加完整的多语言支持，支持中文和英文界面切换。

## 支持的语言
- 中文 (zh) - 默认语言
- 英文 (en)

## 如何切换语言

### 方法1：右键菜单切换
1. 右键点击悬浮窗
2. 在弹出的右键菜单中点击"语言"选项
3. 系统会自动在中文和英文之间切换

### 方法2：程序化切换
```cpp
// 在C++代码中
auto* languageManager = GET_SINGLETON(LanguageManager);
languageManager->setCurrentLanguage("en"); // 切换到英文
languageManager->setCurrentLanguage("zh"); // 切换到中文
```

```qml
// 在QML代码中
languageManager.setCurrentLanguage("en") // 切换到英文
languageManager.setCurrentLanguage("zh") // 切换到中文
```

## 语言设置保存
- 用户选择的语言会自动保存到系统设置中
- 下次启动应用程序时会自动恢复上次选择的语言

## 添加新的翻译字符串

### 在QML中
使用 `qsTr()` 函数包装需要翻译的字符串：
```qml
Text {
    text: qsTr("需要翻译的文本")
}
```

### 在C++中
使用 `tr()` 函数或 `QObject::tr()`：
```cpp
QString text = tr("需要翻译的文本");
```

## 更新翻译文件

### 1. 编辑翻译文件
编辑 `translations/ScoreReport_zh.ts` 和 `translations/ScoreReport_en.ts` 文件，添加对应的翻译。

### 2. 编译翻译文件
```bash
translations文件夹下
lrelease ScoreReport_zh.ts -qm ScoreReport_zh.qm
lrelease ScoreReport_en.ts -qm ScoreReport_en.qm
```

## 技术实现要点

### 1. 单例模式的语言管理器
LanguageManager 使用单例模式，确保全局只有一个语言管理实例。

### 2. 动态翻译
语言切换时会自动触发 QML 引擎的重新翻译，所有使用 `qsTr()` 的文本都会立即更新。

### 3. 设置持久化
使用 QSettings 将语言偏好保存到系统注册表或配置文件中。

### 4. 资源嵌入
编译后的 .qm 翻译文件会嵌入到应用程序资源中，无需外部文件。

## 注意事项
1. 所有界面文本都应使用 `qsTr()` 或 `tr()` 函数包装
2. 修改翻译后需要运行 `lrelease` 重新编译
3. 翻译文件使用 UTF-8 编码，支持各种语言字符 