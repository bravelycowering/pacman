@echo off

rem MAKE GAME.LOVE

rmdir /s /q bin
mkdir bin
cd src
tar -acf ..\bin\game.zip **
cd ..
rename .\bin\game.zip game.love

rem MAKE WEBSITE

call lovejs bin/game.love bin/html -c -t game

rem RUN WEB SERVER

python -m http.server 80