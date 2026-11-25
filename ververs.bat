@echo off
rem Ververst de vissenlijst vanaf deze pc (G&D weigert de servers van GitHub) en zet het resultaat online.
rem Dubbelklik dit bestand. Het haalt eerst de laatste stand van GitHub op, draait scrape.py en uploadt de uitkomst.
chcp 65001 >nul
set PYTHONUTF8=1
cd /d "%~dp0"

echo.
echo === Vissenlijst verversen ===
echo.
echo [1/4] Laatste stand van GitHub ophalen...
rem Uitkomsten van een eerdere losse run (python scrape.py) worden hierna opnieuw gemaakt;
rem eerst weggooien, anders botsen ze met de dagelijkse update van GitHub.
git checkout -q -- index.html vissen_raw.json
if errorlevel 1 goto fout
git pull --rebase --autostash
if errorlevel 1 (
  git rebase --abort >nul 2>&1
  goto fout
)

echo.
echo [2/4] Vissen ophalen bij G^&D Aquaria en Aquariumvissenwinkel (duurt een paar minuten)...
python scrape.py
if errorlevel 1 goto fout

echo.
echo [3/4] Wijzigingen vastleggen...
git add index.html vissen_raw.json
git diff --cached --quiet
if not errorlevel 1 goto niets
git commit -q -m "Vissen bijgewerkt (handmatig) %date%"
if errorlevel 1 goto fout

echo.
echo [4/4] Uploaden naar GitHub (log zo nodig in)...
git push
if errorlevel 1 goto pushfout

echo.
echo Klaar. De site is over een minuutje bijgewerkt.
goto einde

:niets
echo.
echo Er is niets veranderd sinds de vorige keer, dus er valt niets te uploaden.
goto einde

:pushfout
rem De vastlegging terugnemen, zodat een volgende keer weer schoon begint.
git reset -q HEAD~1
echo.
echo *** Uploaden is niet gelukt. Kijk hierboven waarom en start ververs.bat daarna opnieuw. ***
goto einde

:fout
echo.
echo *** Er ging iets mis; kijk hierboven wat. Er is niets kapot: het kan gewoon opnieuw. ***

:einde
echo.
if not defined NOPAUSE pause
