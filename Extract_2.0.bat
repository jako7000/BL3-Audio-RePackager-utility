@echo off
SetLocal EnableDelayedExpansion

set tempDummyFolderName=temp
set tempKeyFileName=tempKey.txt
set pakFileEncryptionKey=0x115EE4F8C625C792F37A503308048E79726E512F0BF8D2AD7C4C87BC5947CBA7
set /A sleepDurationPerMinute = 10
set UI=TRUE

@REM Magical File explorer variable!
set FileSelectDialog=powershell -noprofile -command "&{[System.Reflection.Assembly]::LoadWithPartialName('System.windows.forms') | Out-Null;$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog; $OpenFileDialog.ShowDialog()|Out-Null; $OpenFileDialog.FileName}"





@REM Desc; Processes parameters, sets global variables & selects task
:Main
@REM Params; 1: mode "Extract" | "Convert" | "Package" | "Serialize" | "DeSerialize", 2->: Optional parameters
CALL :SetUI %1 %2 %3 %4 %5 %6 %7 %8 %9
CALL :SetSleepDuration %1 %2 %3 %4 %5 %6 %7 %8 %9
CALL :SetEncryptionKey %1 %2 %3 %4 %5 %6 %7 %8 %9

CALL :SelectOperationMode %1

EXIT /B 0

@REM Desc;  Sets the global "UI" variable
@REM        FALSE = Ask files using command prompt, TRUE = Ask files using windows file exporer
:SetUI
@REM Params;    Parameters given to the program, searches for -UI
CALL :SearchBooleanParameterValue "-ui" UI %1 %2 %3 %4 %5 %6 %7 %8 %9
EXIT /B 0

@REM Desc;  Sets the global "sleepDurationPerMinute" variable
:SetSleepDuration
@REM Params;    Parameters given to the program, searches for -sd
CALL :SearchParameterVariable "-sd" sleepDurationPerMinute %1 %2 %3 %4 %5 %6 %7 %8 %9
EXIT /B 0

@REM Desc;  Sets the global "pakFileEncryptionKey" variable
:SetEncryptionKey
@REM Params;    Parameters given to the program, searched for -key
CALL :SearchParameterVariable "-key" pakFileEncryptionKey %1 %2 %3 %4 %5 %6 %7 %8 %9
EXIT /B 0

@REM Desc;  Searches & returns value for a given parameter name
:SearchParameterVariable
@REM Params;    1: Parameter name, 2: Return variable, 3->: Parameters given to the program
set name=%~1
set parameter=%~3
set value=%~4
IF /I "%parameter%" == "" (
    EXIT /B 0
) ELSE IF /I "%parameter%" == "%name%" (
    set %2=%value%
    EXIT /B 0
)
SHIFT /3
CALL :SearchParameterVariable %1 %2 %3 %4 %5 %6 %7 %8 %9
EXIT /B 0

@REM Desc;  Searches & returns boolean value for a given parameter name
:SearchBooleanParameterValue
@REM Params;    1: Parameter name, 2: Return variable, 3-> Parameters given to the program
set name=%~1
set parameter=%~3
set value=%~4
IF /I "%parameter%" == "" (
    EXIT /B 0
) ELSE IF /I "%parameter%" == "%name%" (
    set tested=TRUE
    IF /I "%value%" == "FALSE" set tested=FALSE
    IF /I "%value%" == "0" set tested=FALSE
    IF /I "%value%" == "N" set tested=FALSE
    IF /I "%value%" == "NO" set tested=FALSE
    set %2=!tested!
    EXIT /B 0
)
SHIFT /3
CALL :SearchBooleanParameterValue %1 %2 %3 %4 %5 %6 %7 %8 %9
EXIT /B 0





@REM Desc;  Asks the user a number question
:AskNumber
@REM Params; 1: Output variable, 2: Min, 3: Max, 4: Default value, 5: (Optional) Question string,
IF NOT "%~5" == "" echo %~5
set /P intNumber="Press ENTER for %4 (%2-%3): "
IF "!intNumber!" == "" (
    set /A %1=%4
) ELSE IF /I !intNumber! LSS %2 (
    echo    "!intNumber" is too small. Value set to %2.
    set /A %1=%2
) ELSE IF /I !intNumber! GTR %3 (
    echo "!intNumber!" is too large. Value set to %3.
    set /A %1=%3
) ELSE (
    set /A %1=!intNumber!
)
echo.
EXIT /B 0





@REM Desc;  Executes correct function based on input
:SelectOperationMode
@REM Params;    1: (Optional) mode "Extract" | "Convert" | "Package" | "Serialize" | "DeSerialize"
set modeNumber=0
IF /I "%~1" == "Extract" set /A modeNumber=1
IF /I "%~1" == "Convert" set /A modeNumber=2
IF /I "%~1" == "Package" set /A modeNumber=3
IF /I "%~1" == "Serialize" set /A modeNumber=4
IF /I "%~1" == "DeSerialize" set /A modeNumber=5

IF /I !modeNumber! EQU 0 (
    echo What would you like to do?
    echo    1 = Extract .wem files from a .pak file.
    echo    2 = Convert .wem files to .ogg files.
    echo    3 = Add ^& remove selected files from a .pak file.
    echo    4 = Save selected files into a .BL3AU file.
    echo    5 = Load files from a .BL3AU file.
    CALL :AskNumber modeNumber 1 5 1
)

IF !modeNumber! EQU 1 CALL :Extract
IF !modeNumber! EQU 2 CALL :Convert
IF !modeNumber! EQU 3 CALL :Package
IF !modeNumber! EQU 4 CALL :Serialize
IF !modeNumber! EQU 5 CALL :DeSerialize
EXIT /B 0





@REM Desc;  
:Extract
echo Extract placeholder func.
@REM Params;    
EXIT /B 0

@REM Desc;  
:Convert
echo Convert placeholder func.
@REM Params;    
EXIT /B 0

@REM Desc;  
:Package
echo Package placeholder func.
@REM Params;    
EXIT /B 0

@REM Desc;  
:Serialize
echo Serialize placeholder func.
@REM Params;    
EXIT /B 0

@REM Desc;  
:DeSerialize
echo DeSerialize placeholder func.
@REM Params;    
EXIT /B 0







EndLocal