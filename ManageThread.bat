@echo off
@REM Params; 1: ww2ogg.exe path, 2: ww2ogg.exe path, 3: .wem source path, 4: .ogg target path
@REM These calls are executed outside of Extract.bat in order to supress console messages from ww2ogg & ww2ogg
CALL %~f1 %~f3 -o %~f4 --pcb "%~dp1packed_codebooks_aoTuV_603.bin"
CALL %~f2 %~f4
EXIT

