@echo off
@REM Desc;  Runs conversion programs in an isolated batch file to hide their outputs
:Main
@REM Params;    1: ww2ogg.exe path, 2: packed_codebooks_aoTuV_603.bin path, 3: revorb.exe path,
@REM            4: .wem input file, 5: .ogg output file
IF "%~1" EQU "" CALL :HandleWrongCall
CALL :CheckParameter "%1" 1 "ww20gg.exe path"
CALL :CheckParameter "%2" 2 "packed_codebooks_aoTuV_603.bin path"
CALL :CheckParameter "%3" 3 "revorb.exe path"
CALL :CheckParameter "%4" 4 ".wem input file"
CALL :CheckParameter "%5" 5 ".ogg output file"
CALL :Convert %1 %2 %3 %4 %5
EXIT /B 0

:HandleWrongCall
IF EXIST MainProgram.bat (
        START "MainProgram" MainProgram.bat
        EXIT
    ) ELSE (
        echo This file is used by "MainProgram.bat".
        echo Please run "MainProgram.bat" instead.
        echo.
        echo Press any kay to close this window.
        TIMEOUT -1 > NUL
        EXIT
    )
EXIT /B 0

@REM Desc;  Prints error message & aborts
:CheckParameter
@REM Params;    1: Parameter value, 2: Parameter number, 3: Parameter name
echo CheckParameter: "%~1"
IF "%~1" == "" (
    echo SilentConversion.bat is missing parameter number %~2: "%~3", aborting.
    EXIT
)
EXIT /B 0

@REM Desc;  Calls ww2ogg.exe & revorb.exe with correct parameters
:Convert
@REM Params;    1: ww2ogg.exe path, 2: packed_codebooks_aoTuV_603.bin path, 3: revorb.exe,
@REM            4: .wem input file, 5: .ogg output file
CALL %~f1 %~f4 -o %~5 --pcb %~2
CALL %~3 %~5
EXIT