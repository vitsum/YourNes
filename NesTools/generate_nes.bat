@echo off

rem Check if a filename was provided as an argument
if %1 == "" (
echo No file was provided as an argument.
pause
exit /b
)

rem Set the filename as a variable
set filename=%~n1

echo Assembling file %1...
rem Assemble the file using ca65
ca65 %1 -o "%~dp1%filename%.o" -t nes

rem Check the exit code of ca65
if errorlevel 1 (
echo An error occurred while assembling the file.
pause
exit /b
)

echo Linking object file %~dp1%filename%.o...
rem Link the object file using ld65
ld65 "%~dp1%filename%.o" -o "%~dp1%filename%.nes" -t nes

rem Check the exit code of ld65
if errorlevel 1 (
echo An error occurred while linking the object file.
pause
exit /b
)

echo Opening .nes file in default program...
rem Launch the default emulator for .nes
start "" "%~dp1%filename%.nes"

echo Done!
pause