@echo off
chcp 65001 >nul
cd /d "%~dp0"

echo 최신 내용 가져오기...
git pull origin main

echo 완료되었습니다.