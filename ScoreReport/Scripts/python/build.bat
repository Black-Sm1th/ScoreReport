@echo off
REM 禁用 matplotlib 后端自动检测
set MPLBACKEND=Agg

REM 使用自定义 spec 文件打包
pyinstaller kidney_processor_custom.spec --clean

echo.
echo 打包完成！生成的文件位于 dist/kidney_processor.exe
pause

