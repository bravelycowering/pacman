@echo off
rmdir /s /q bin
mkdir bin
cd src
tar -acf ..\bin\game.zip **
cd ..
rename .\bin\game.zip game.love