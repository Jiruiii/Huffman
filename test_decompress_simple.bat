@echo off
echo Creating simple test file...
echo AAAA > tiny.txt

echo.
echo Running compression...
Debug\Project.exe

echo.
echo Press any key to continue...
pause
