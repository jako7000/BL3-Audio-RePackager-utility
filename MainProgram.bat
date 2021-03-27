@echo off
SetLocal EnableDelayedExpansion

set tempDummyFolderName=temp
set tempKeyFileName=tempKey.txt
set quickBmsExeName=quickbms_4gb_files.exe
set bmsScriptName=*.bms
set pakFileName=*.pak
set extractFolder=extracted

set pakFileEncryptionKey=0x115EE4F8C625C792F37A503308048E79726E512F0BF8D2AD7C4C87BC5947CBA7
set /A sleepDurationPerMinute = 10
set UI=TRUE

@REM Magical File explorer variables!
set FileSelectDialog=powershell -noprofile -command "&{[System.Reflection.Assembly]::LoadWithPartialName('System.windows.forms') | Out-Null;$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog; $OpenFileDialog.ShowDialog()|Out-Null; $OpenFileDialog.FileName}"
set FolderSelectDialog="(new-object -COM 'Shell.Application').BrowseForFolder(0,'Please choose a folder.',0,0).self.path"





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





@REM Desc;  Asks the user a boolean question
:AskBoolean
@REM Params;    1: Output variable, 2: Default (YES | NO), 3: (Optional) Question string
IF NOT "%~3" == "" echo %~3
set /P intBoolean="Press ENTER for %~2 (Y/N): "
IF /I "%intBoolean%" == "" (
    IF /I "%~2" == "YES" set %1=TRUE
    IF /I "%~2" == "NO" set %1=FALSE
) ELSE IF /I "%intBoolean%" == "Y" (
    set %1=TRUE
) ELSE IF /I "%intBoolean%" == "YES" (
    set %1=TRUE
) ELSE IF /I "%intBoolean%" == "1" (
    set %1=TRUE
) ELSE IF /I "%intBoolean%" == "N" (
    set %1=FALSE
) ELSE IF /I "%intBoolean%" == "NO" (
    set %1=FALSE
) ELSE IF /I "%intBoolean%" == "0" (
    set %1=FALSE
) ELSE (
    echo "%intBoolean%" is not a valid input.
    echo.
    CALL AskBoolean booleanRetry %2
    set %1=%2
)
echo.
EXIT /B 0

@REM Desc;  Asks the user a number question
:AskNumber
@REM Params;    1: Output variable, 2: Min, 3: Max, 4: Default value, 5: (Optional) Question string,
IF NOT "%~5" == "" echo %~5
set /P intNumber="Press ENTER for %4 (%2-%3): "
IF "!intNumber!" == "" (
    set /A %1=%4
) ELSE IF /I !intNumber! LSS %2 (
    echo    "!intNumber!" is too small. Value set to %2.
    set /A %1=%2
) ELSE IF /I !intNumber! GTR %3 (
    echo "!intNumber!" is too large. Value set to %3.
    set /A %1=%3
) ELSE (
    set /A %1=!intNumber!
)
echo.
EXIT /B 0

@REM Desc;  Asks the user for a folder path
:AskFolder
@REM Params; 1: Output variable, 2: Default folder, 3: Question string
echo %~3
CALL :AskBoolean defaultOk "YES" "Is "%~f2\" ok?"
IF %defaultOk% == TRUE (
    set %1=%~f2
) ELSE (
    IF %UI% == TRUE (
        CALL :ShowFolderDialog givenFolderPath
    ) ELSE (
        CALL :TypeFilePath givenFolderPath "the folder where you want the .wem files extracted to"
    )
    CALL :PathToFolder !givenFolderPath! intFolderPath
    set %1=!intFolderPath!
)
EXIT /B 0

@REM Desc;  Asks the user for a file path
:AskFilePath
@REM Params;    1: Output variable, 2: File name
IF %UI% == TRUE (
    CALL :ShowFileDialog intFilePath %2
) ELSE (
    CALL :TypeFilePath intFilePath %2
)
CALL :IsSpecifiedFile !intFilePath! %2 isValid
IF %isValid% == TRUE (
    set %1=!intFilePath!
) ELSE (
    echo "%~2" not found at
    echo    !intFilePath!
    echo.
    CALL :AskFilePath pathRetry %2
    set %1=!pathRetry!
)
EXIT /B 0

@REM Desc;  Shows the user a windows folder select window for file selection 
:ShowFolderDialog
@REM Params;    1: Output variable
FOR /F "usebackq delims=" %%I IN (`powershell %FolderSelectDialog%`) DO set "intFilePath=%%I"
set %1=!intFilePath!
EXIT /B 0

@REM Desc;  Shows the user a windows file select window for file selection
:ShowFileDialog
@REM Params;    1: Output variable, 2: File name
echo Please select path to "%~2" file.
TIMEOUT 1 > NUL
FOR /F "delims=" %%i IN ('%FileSelectDialog%') DO set intFilePath=%%~fi
set %1=!intFilePath!
TIMEOUT 1 > NUL
EXIT /B 0

@REM Desc;  Asks the user to type a file path
:TypeFilePath
@REM Params;    1: Output variable, 2: File name
set /P givenFile="Please type path to %~2: "
CALL :NameToPath %givenFile% intFilePath
set %1=%intFilePath%
EXIT /B 0



@REM Desc;  Extends input to full path
:NameToPath
@REM Params;    1: Input name, 2: Output variable
set %2=%~f1
EXIT /B 0

@REM Desc;  Expands input to folder path
:PathToFolder
@REM Params;    1: Input path, 2: Output variable
set %2=%~dpn1
EXIT /B 0

@REM Desc;  Check wether or not given path leads to specified file (type)
:IsSpecifiedFile
@REM Params;    1: Path to check, 2: File name/type, 3: Output boolean
set fileName=%~2
IF /I "%fileName:~1,1%" == "." (
    set %3=TRUE
    EXIT /B 0
) 

IF NOT EXIST %~f1 (
    set %3=FALSE
) ELSE IF "%~nx1" == "%~nx2" (
    set %3=TRUE
) ELSE (
    set %3=FALSE
)
EXIT /B 0

@REM Desc;  Sees if requested file is in the .bat directory
:CheckLocalFile
@REM Params;    1: File name, 2: Output file found, 3: Output file path
IF EXIST %~1 (
    set %2=TRUE
    set %3=%~f1
) ELSE (
    SET %2=FALSE
    set %3=""
)
EXIT /B 0

@REM Desc;  Check if wanted file is present,
@REM        if yes, asks user if this is ok,
@REM        if not ok, asks for wanted file.
@REM        Returns file path.
:AcquireFile
@REM Params;    1: File name, 2: Output file path
CALL :CheckLocalFile %1 localFileFound intFilePath
IF %localFileFound% == TRUE (
    echo "%~nx1" found from
    echo    %intFilePath%
    CALL :AskBoolean useLocalFile "YES" "Use this file?"
    IF !useLocalFile! == FALSE CALL :AskFilePath intFilePath %1
)
set %2=!intFilePath!
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





@REM Desc;  Extracts .wem files from a .pak file
:Extract
@REM Params;    none
CALL :AcquireFile %quickBmsExeName% quickBmsPath
CALL :AcquireFile %bmsScriptName% bmsScriptPath
CALL :AcquireFile %pakFileName% pakFilePath
CALL :AskFolder extractFolder %extractFolder% "Where would you like to extract .wem files to?"
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