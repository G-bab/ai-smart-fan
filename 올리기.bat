@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo 변경된 파일 확인...
git status

set /p msg=작업내용설명 입력: 
git add .
git commit -m "%msg%"
git push origin main

echo 완료되었습니다.