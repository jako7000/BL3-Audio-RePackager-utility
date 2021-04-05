@echo off
SetLocal EnableDelayedExpansion

set path_current=%~dp0
set path_current=%path_current:~0,-1%
set path_temp=%TEMP%
IF NOT EXIST %path_temp% set path_temp=%path_current%\temp
set path_tempFiles=%path_temp%\BL3AU_soundFiles

set folder_extract=extracted
set folder_convert=converted
set folder_include=include
set folder_exclude=exclude

set file_tempKey=BL3AU_EnctryptionKey.txt
set file_tempConfig=BL3AU_config.ini
set file_config=BL3AU_config.ini
set file_quickBms=quickbms_4gb_files.exe
set file_ww2ogg=ww2ogg.exe
set file_packedCodebooks=packed_codebooks_aoTuV_603.bin
set file_revorb=revorb.exe

set path_extract=%path_current%\%folder_extract%
set path_convert=%path_current%\%folder_convert%
set path_tempKey=%path_temp%\%file_tempKey%
set path_tempConfig=%path_temp%\%file_tempConfig%
set path_config=%path_current%\%file_config%
set path_quickBms=%path_current%\%file_quickBms%
set path_ww2ogg=%path_current%\%file_ww2ogg%
set path_packedCodebooks=%path_current%\%file_packedCodebooks%
set path_revorb=%path_current%\%file_revorb%
set path_save=%path_current%

set type_bmsScript=.bms
set type_pak=.pak
set type_wem=.wem
set type_ogg=.ogg
set type_fake=.fake
set type_save=.BL3AU

set save_package=[PACKAGE]
set save_folder=[FOLDER]
set save_files=[FILES]

set pakFileEncryptionKey=0x115EE4F8C625C792F37A503308048E79726E512F0BF8D2AD7C4C87BC5947CBA7
set /A sleepDurationPerMinute=10
set UI=TRUE
set useConfig=TRUE

@REM Magical File explorer variables!
set FileSelectDialog=powershell -noprofile -command "&{[System.Reflection.Assembly]::LoadWithPartialName('System.windows.forms') | Out-Null;$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog; $OpenFileDialog.ShowDialog()|Out-Null; $OpenFileDialog.FileName}"
set FolderSelectDialog="powershell (new-object -COM 'Shell.Application').BrowseForFolder(0,'Please choose a folder.',0,0).self.path"

@REM Variable name translations
set locale[path_extract]=Default extract path
set locale[path_convert]=Default convert path
set locale[path_quickBms]=QuickBMS.exe
set locale[path_ww2ogg]=ww2ogg.exe
set locale[path_ww2ogg]=packed_codebooks_aoTuV_603.bin
set locale[path_revorb]=revorb.exe





@REM Desc; Processes parameters, sets global variables & selects task
:Main
@REM Params; 1: mode "Extract" | "Convert" | "Package" | "Serialize" | "DeSerialize" | "Thread", 2->: Optional parameters
CALL :SetUI %1 %2 %3 %4 %5 %6 %7 %8 %9
CALL :SetSleepDuration %1 %2 %3 %4 %5 %6 %7 %8 %9
CALL :SetEncryptionKey %1 %2 %3 %4 %5 %6 %7 %8 %9
CALL :SetConfig %1 %2 %3 %4 %5 %6 %7 %8 %9
CALL :ReadConfig

IF /I "%~1" == "Thread" (
    CALL :ManageThread %2 %3 %4 %5 %6 %7
) ELSE (
    CALL :SelectOperationMode %1
)

EXIT /B 0

@REM Desc;  Sets the global "UI" variable
@REM        FALSE = Ask files using command prompt, TRUE = Ask files using windows file exporer
:SetUI
@REM Params;    Parameters given to the program, searches for -ui
CALL :SearchBooleanParameterValue "-ui" UI %1 %2 %3 %4 %5 %6 %7 %8 %9
EXIT /B 0

@REM Desc;  Sets the global "sleepDurationPerMinute" variable
:SetSleepDuration
@REM Params;    Parameters given to the program, searches for -sd
CALL :SearchParameterVariable "-sd" sleepDurationPerMinute %1 %2 %3 %4 %5 %6 %7 %8 %9
EXIT /B 0

@REM Desc;  Sets the global "pakFileEncryptionKey" variable
:SetEncryptionKey
@REM Params;    Parameters given to the program, searches for -key
CALL :SearchParameterVariable "-key" pakFileEncryptionKey %1 %2 %3 %4 %5 %6 %7 %8 %9
EXIT /B 0

@REM Desc;  Sets the global "useConfig" variable
:SetConfig
@REM Params;    Parameters given to the program, searches for -conf
CALL :SearchBooleanParameterValue "-conf" useConfig %1 %2 %3 %4 %5 %6 %7 %8 %9
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

@REM Desc;  Reads BL3AU config file & loads settings
:ReadConfig
@REM Params;    none
IF NOT EXIST %path_config% EXIT /B 0

set configLoadAnnounced=FALSE
FOR /F "eol=/ tokens=1,2 delims==" %%a IN (%path_config%) DO IF NOT "%%~a" == "" IF NOT "%%~b" == "" (
    IF !configLoadAnnounced! == FALSE (
        set configLoadAnnounced=TRUE
        echo Loaded values from config file at
        echo    %path_config%
    )
    set %%~a=%%~b
    set valueName=%%~a
    IF NOT "!locale[%%~a]!" == "" set valueName=!locale[%%~a]!
    CALL :NormalizeLength 33 "!valueName!" normalizedKey
    echo -!normalizedKey!: %%~b
)
IF !configLoadAnnounced! == TRUE (
    echo.
    echo.
    echo.
)
EXIT /B 0





@REM Desc;  Asks the user a boolean question
:AskBoolean
@REM Params;    1: Question ID, 2: Output variable, 3: (Optional) Default value (YES|NO), 4: (Optional) Question string
IF "%~3" == "" (
    set /P userBoolean%~1="%~4 (Y/N): "
) ELSE (
    IF NOT "%~4" == "" echo %~4
    set /P userBoolean%~1="Press ENTER for %~3 (Y/N): "
)

       IF /I "!userBoolean%~1!" == "Y" (
    set intBoolean%~1=TRUE
) ELSE IF /I "!userBoolean%~1!" == "YES" (
    set intBoolean%~1=TRUE
) ELSE IF /I "!userBoolean%~1!" == "1" (
    set intBoolean%~1=TRUE
) ELSE IF /I "!userBoolean%~1!" == "N" (
    set intBoolean%~1=FALSE
) ELSE IF /I "!userBoolean%~1!" == "NO" (
    set intBoolean%~1=FALSE
) ELSE IF /I "!userBoolean%~1!" == "0" (
    set intBoolean%~1=FALSE
) ELSE IF /I "!userBoolean%~1!" == "" (
    IF "%~3" == "YES" set intBoolean%~1=TRUE
    IF "%~3" == "NO"  set intBoolean%~1=FALSE
)

IF "!intBoolean%~1!" == "" (
    echo "!userBoolean%~1!" is not a valid input.
    echo.
    CALL :AskBoolean "%~1-" booleanRetry%~1 %3 %4
    set %2=!booleanRetry%~1!
    EXIT /B 0
)
set %2=!intBoolean%~1!
echo.
EXIT /B 0

@REM Desc;  Asks the user a number question
:AskNumber
@REM Params;    1: Question ID, 2: Output variable, 3: Min, 4: Max, 5: (Optional) Default value, 6: (Optional) Question string,
IF "%~5" == "" (
    set /P userInteger%~1="%~6 (%3-%4): "
) ELSE (
    IF NOT "%~6" == "" echo %~6
    set /P userInteger%~1="Press ENTER for %5 (%3-%4): "
)

set /A castUserInteger%~1=!userInteger%~1!
echo User: "!userInteger%~1!", cast: "!castUserInteger%~1!"
IF "!castUserInteger%~1!" EQU "!userInteger%~1!" (
           IF "!castUserInteger%~1!" ==  "" (
        IF NOT "%~5" == "" set /A intInteger%~1=%~5
    ) ELSE IF "!castUserInteger%~1!" LSS "%3" (
        echo !castUserInteger%~1! is too small. Value set to %3
        set /A intInteger%~1=%3
    ) ELSE IF "!castUserInteger%~1!" GTR "%4" (
        echo !castUserInteger%~1! is too large. Value set to %4.
        set /A intInteger%~1=%4
    ) ELSE (
        set /A intInteger%~1=!castUserInteger%~1!
    )
)

IF "!intInteger%~1!" == "" (
    echo "!userInt%~1!" is not a valid input.
    echo.
    CALL :AskNumber "%~1-" integerRetry%~1 %3 %4 %5 %6
    set /A %2=!integerRetry%~1!
    EXIT /B 0
)
set /A %2=!intInteger%~1!
echo.
EXIT /B 0

@REM Desc;  Asks the user for a string
:AskString
@REM Params;    1: Quesiton ID, 2: Output variable, 3: (Optional) Default string, 4: (Optional) Question string
IF "%~3" == "" (
    set /P userString%~1="%~4: "
) ELSE (
    IF NOT "%~4" == "" echo %~4
    set /P userString%~1="Press ENTER for %3: "
)

IF "!userString%~1!" == "" (
    IF NOT "%~3" == "" set intString%~1=%~3
) ELSE (
    set intString%~1=!userString%~1!
)

IF "!intString%~1!" == "" (
    echo "!userString%~1!" is not a valid input.
    echo.
    CALL :AskString "%~1-" stringRetry%~1 %3 %4
    set %2=!stringRetry%~1!
    EXIT /B 0
)
set %2=!intString%~1!
echo.
EXIT /B 0

@REM Desc;  Returns asked file or folder
:AcquireResource
@REM Params;    1: Question string, 2: Output variable, 3: (INT) Validation level, 4: File/Folder, 5: (Optional) Config key, 6: (Optional) Question string
@REM Validation level: 3.1 = Match exactly, 3.2: Must exist + use 4 as default, 3.3: Doesn't need to exist + use 4 as default
set intResource%~1=
set useFoundResource=FALSE
CALL :GetFileName %4 resourceName
IF "%~4" == "" CALL :GetFileName "!%~5!" resourceName
CALL :GetFileExtension %4 resourceExtension
IF "%~4" == "" CALL :GetFileExtension "!%~5!" resourceExtension
set isFile=FALSE
set resourceType=folder
IF NOT "!resourceExtension!" == "" (
    set isFile=TRUE
    set resourceType=file
)

IF %3 EQU 3                     set intResource%~1=%~4
IF EXIST "%~4" (
                                set intResource%~1=%~4
    IF EXIST %path_current%\%~4 set intResource%~1=%path_current%\%~4
)
IF EXIST !%~5!                  set intResource%~1=!%~5!

IF NOT "%~6" == "" echo %~6
IF NOT "!intResource%~1!" == "" (
    CALL :GetFullPath !intResource%~1! resourcePath
    echo Use "!resourceName!!resourceExtension!" at
    echo    !resourcePath!
    CALL :AskBoolean "AcqRe-%~1" useFoundResource "YES" "Use this !resourceType!?"
)

IF !useFoundResource! == FALSE (
    set intResource%~1=
    CALL :AskResource "AcqRe-%~1" userResourcePath%~1 !isFile! "Please select path to !resourceName!!resourceExtension!"
)
CALL :IsSpecifiedFile "AcqRe-%~1" isValid !userResourcePath%~1! !resourceName!!resourceExtension!

IF %3 EQU 1 IF !isValid! == TRUE IF EXIST !userResourcePath%~1! set intResource%~1=!userResourcePath%~1!
IF %3 EQU 2                      IF EXIST !userResourcePath%~1! set intResource%~1=!userResourcePath%~1!
IF %3 EQU 3                                                     set intResource%~1=!userResourcePath%~1!

CALL :GetFullPath "!intResource%~1!" intResource%~1

IF "!intResource%~1!" == "" (
    IF NOT "!userResourcePath%~1!" == "" echo "!userResourcePath%~1!"
    echo Given resource is not valid.
    echo.
    CALL :AcquireResource "%~1-" resourceRetry%~1 %3 %4 %5 %6
    set intResource%~1=!resourceRetry%~1!
)

IF NOT "%~5" == "" CALL :SaveToConfig %5 "!intResource%~1!"
set %2=!intResource%~1!
set questionId=%~1
IF NOT "!questionId:~-1!" == "-" echo.
EXIT /B 0

@REM Desc;  Propts user to input a file or folder
:AskResource
@REM Params;    1: Question string, 2: Output variable, 3: Is file, 4: (Optional) Question string
IF NOT "%~4" == "" echo %~4
IF %UI% == FALSE (
    CALL :TypeFilePath "AskRe-%~1" userResourcePath%~1
) ELSE (
    IF %3 == TRUE (
        CALL :ShowFileDialog "AskRe-%~1" userResourcePath%~1
    ) ELSE (
        CALL :ShowFolderDialog "AskRe-%~1" userResourcePath%~1
    )
)

CALL :GetFullPath "!userResourcePath%~1!" fullPath%~1
IF "!fullPath%~1!" == "" (
    echo Input is not valid.
    echo.
    CALL :AskResource "%~1-" resourceRetry%~1 %3
)

set %2=!fullPath%~1!
EXIT /B 0

@REM Desc;  Shows the user a windows folder select window for file selection 
:ShowFolderDialog
@REM Params;    1: Question ID, 2: Output variable, 3: (Optional) Folder name
IF NOT "%~3" == "" echo Please select path to %~3
TIMEOUT 1 > NUL
FOR /F "usebackq delims=" %%i IN (`%FolderSelectDialog%`) DO set userFolderPath%~1=%%~fi
TIMEOUT 1 > NUL
set %2=!userFolderPath%~1!
EXIT /B 0

@REM Desc;  Shows the user a windows file select window for file selection
:ShowFileDialog
@REM Params;    1: Question ID, 2: Output variable, 3: (Optional) File name
IF NOT "%~3" == "" echo Please select path to %~3
TIMEOUT 1 > NUL
FOR /F "delims=" %%i IN ('%FileSelectDialog%') DO set userFilePath%~1=%%~fi
TIMEOUT 1 > NUL
set %2=!userFilePath%~1!
EXIT /B 0

@REM Desc;  Asks the user to type a file path
:TypeFilePath
@REM Params;    1: Question ID, 2: Output variable, 3: (Optional) File path
IF "%~3" == "" (
    set /P userPath%~1="Please type a path: "
) ELSE (
    set /P userPath%~1="Please type path to %~3: "
)
CALL :GetFullPath "!userPath%~1!" intPath%~1
set %2=!intPath%~1!
EXIT /B 0



@REM Desc;  Check wether or not given path leads to specified file (type)
:IsSpecifiedFile
@REM Params;    1: Question ID, 2: Output variable, 3: File to validate, 4: Validation, 5: (Optional) Debug
set fileName%~1=%~n3
set fileExtension%~1=%~x3
set validationName%~1=%~n4
set validationExtension%~1=%~x4

IF NOT      "!validationName%~1!" == "" IF /I      "!validationName%~1!" ==      "!fileName%~1!" (set nameOk%~1=TRUE) ELSE (set nameOk%~1=FALSE)
IF NOT "!validationExtension%~1!" == "" IF /I "!validationExtension%~1!" == "!fileExtension%~1!" (set typeOk%~1=TRUE) ELSE (set typeOk%~1=FALSE)

SET intValidation%~1=TRUE
IF !nameOk%~1! == FALSE set intValidation%~1=FALSE
IF !typeOk%~1! == FALSE set intValidation%~1=FALSE

IF "%~5" == "TRUE" (
    echo :IsSpecifiedFile; fiNa: "!fileName%~1!", fiEx: "!fileExtension%~1!"
    echo :IsSpecifiedFile; vaNa: "!validationName%~1!", vaEx: "!validationExtension%~1!",
    echo :IsSpecifiedFile; naOk: "!nameOk%~1!", exOk: "!typeOk%~1!"
)

set %2=!intValidation%~1!
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

@REM Desc;  Saves given value to a given key to the config file
:SaveToConfig
@REM Params;    1: Value key, 2: Value value
IF %useConfig% == FALSE EXIT /B 0

IF NOT EXIST %path_config% echo //Config file for Borderlands 3 Audio Utility >%path_config%
set updateExisting=FALSE
set oldValue=""
CALL :GetStringLength "%~1" keyLength
FOR /F "eol=; tokens=1 delims==" %%c IN ('findstr /I "%~1=" %path_config%') DO (
    set updateExisting=TRUE
    set oldValue=%%~c
)

IF !updateExisting! == FALSE (
    echo %~1=%~2>>%path_config%
) ELSE IF NOT "%~2" == "!oldValue!" (
    FOR /F "eol= delims=" %%l IN (%path_config%) DO (
        CALL :Trim "%%l" line
        IF "!line:~0,%keyLength%!" == "%~1" (
            echo %~1=%~2>>%path_tempConfig%
        ) ELSE (
            echo %%l>>%path_tempConfig%
        )
    )

    MOVE /Y %path_tempConfig% %path_config% >NUL
)
EXIT /B 0

@REM Desc;  Shifts through given paths and returns first existing one
:FindExistingResource
@REM Params;    1: Output variable, 2-> Paths to test
set pathToTest=%~f2
set lastTest=FALSE

IF "!pathToTest!" == "" (
    set %1=
    EXIT /B 0
) ELSE IF EXIST "!pathToTest!" (
    set %1=!pathToTest!
    EXIT /B 0
)
SHIFT /2
CALL :FindExistingResource %1 %2 %3 %4 %5 %6 %7 %8 %9
EXIT /B 0

@REM Desc;   Extends input to path relative to given root
:GetRelativePath
@REM Params;    1: Root dir, 2: Path to relate, 3: Output variable
set rootDir=%~1
set pathToRelate=%~2
CALL :GetStringLength %rootDir% rootLength
set /A charsToRemove=%rootLength%-2
set %3=!pathToRelate:~%rootLength%!
EXIT /B 0

@REM Desc;  Extends input to full path
:GetFullPath
@REM Params;    1: Input path, 2: Output variable
set fullPath=%~f1
IF "!fullPath:~-1!" == "\" set fullPath=!fullPath:~0,-1!
set %2=!fullPath!
EXIT /B 0

@REM Desc;  Expands input to folder path
:GetFolderPath
@REM Params;    1: Input path, 2: Output variable 3: (Optional) (Boolean) No name 
IF "%~3" == "TRUE" (
    set %2=%~dp1
) ELSE (
    set %2=%~dpn1
)
EXIT /B 0

@REM Desc;  Expands input to file name
:GetFileName
@REM Params;    1: Input path, 2: Output variable
set %2=%~n1
EXIT /B 0

@REM Desc;  Expands input to file extension
:GetFileExtension
@REM Params;    1: Input pat, 2: Output variable
set %2=%~x1
EXIT /B 0

@REM Desc;  Adds spacing to the start of a value so it has a given length
:NormalizeLength
@REM Params;    1: Length, 2: Value, 3: Output variable
set /A length=%~1
set extraLongString="                                                         %~2"
set quotelessString=%extraLongString:"=%
CALL set normalizedString=%%quotelessString:~-%length%%%
set %3=%normalizedString%
EXIT /B 0

@REM Desc;   Calculates the length of a string
:GetStringLength
@REM Params;    1: Input string, 2: Output variable
SetLocal disableDelayedExpansion
set /A fullLength=0
FOR /F "delims=:" %%n IN ('"(cmd /V:ON /C echo(%~1!&echo()|findstr /O ^^"') DO set /A fullLength=%%n-3
EndLocal & set /A %~2=%fullLength%-1
EXIT /B 0

@REM Desc;  Removes spaces from the beginning & end of a string
:Trim
@REM Params;    1: String to trim, 2: Output variable, 3: (Optional) Max amount of spaces to trim from the end
set str=%~1
set /A endTrimCount=32
IF NOT "%~3" == "" set /A endTrimCount=%~3
FOR /F "tokens=* delims= " %%c IN ("!str!") DO set str=%%c
FOR /L %%c IN (1,1,!endTrimCount!) DO IF "!str:~-1!"==" " set str=!str:~0,-1!
set %2=!str!
EXIT /B 0


@REM Desc;  Sleeps for a given amount while displaying an updating message
:Sleep
@REM Params;    1: Duration, 2: Start message, 3: End message
echo %~2
FOR /F %%a IN ('COPY /Z "%~dpf0" NUL') DO set "CR=%%a"
FOR /L %%s IN (%~1, -1, 1) DO (
    <NUL set /P"=Continue in %%s... !CR!"
    TIMEOUT 1 > NUL
)
<NUL set /p"=%~3"
echo .
EXIT /B 0

@REM Desc;  Creates a folder if it doesn't already exist
:MakeFolder
@REM Params;    1: Folder path
IF NOT EXIST %~dpn1 MD %~dpn1
EXIT /B 0

@REM Desc;  Removes a given folder
:RemoveFolder
@REM Params;    1: Folder path
IF EXIST %~f1 RMDIR /S /Q %~f1
EXIT /B 0

@REM Desc;  Deletes .tmp files
:CleanTemps
@REM Params;    1: Folder path to clean
set /A filesToDelete=0
FOR %%x IN ("%~dpn1\*.tmp") DO set /A filesToDelete+=1
IF !filesToDelete! GTR 0 DEL "%~dpn1\*.tmp"
echo Cleaned !filesToDelete! .tmp files from
echo    %~dpn1\
echo.
EXIT /B 0

@REM Desc; Creates a backup copy of the given path
:CreateBackup
@REM Params;    1: Path to backup, 2: Path of the backup
set backupPath=%~dpn1_ORIGINAL%~x1
IF NOT EXIST %backupPath% COPY /D /Y %~f1 /B %backupPath% /B > NUL
set %2=%backupPath%
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
    CALL :AskNumber "SOM-OM" modeNumber 1 5 1
)

IF !modeNumber! EQU 1 CALL :Extract
IF !modeNumber! EQU 2 CALL :Convert
IF !modeNumber! EQU 3 CALL :Package
IF !modeNumber! EQU 4 CALL :Serialize
IF !modeNumber! EQU 5 CALL :DeSerialize
EXIT /B 0

@REM Desc;  Runs operations related to a single conversion thread
:ManageThread
@REM Params;    1: Thread number, 2: ww2ogg.exe path, 3: packed_codebooks_aoTuV_603.bin path
@REM            4: revorb.exe path, 5: .wem source folder path, 6: .ogg target folder path
echo Starting .wem to .ogg conversion...

set /A fileCount=0
set /A currentFile=0
set /A filesConverted=0
FOR %%x IN ("%~f5\*.wem") DO set /A fileCount+=1
FOR %%x IN ("%~f6\*.ogg") DO set /A filesConverted+=1

CALL :GetThreadSoring %~1 sortOrder
FOR /F %%f IN ('dir /B /O:%sortOrder% %~f5\*.wem') DO (
    set /A currentFile+=1
    set operation=Skipping
    IF /I NOT EXIST "%~f6\%%~nf.ogg" (
        set operation=Converting
        START /LOW /MIN /WAIT "%%~nf" SilentConversion.bat %~f2 %~f3 %~f4 "%~f5\%%~nxf" "%~f6\%%~nf.ogg"
        set /A filesConverted+=1
    )
    set /A remaining=%fileCount%-!currentFile!
    CALL :PrintProgress !fileCount! !currentFile! !operation! %%~nxf

    IF %sleepDurationPerMinute% GTR !time:~6,2! CALL :Sleep %sleepDurationPerMinute% "Resting for %sleepDurationPerMinute% seconds..." "Resuming file conversion."
)
echo All files conerted.
echo.
IF %~1 EQU 1 (
   EXIT /B 0
) ELSE (
    EXIT
)
EXIT /B 0

@REM Desc;  Returns a 'dir' command file sotring parameter
:GetThreadSoring
@REM Params;    1: Thread number, 2: Output variable
set /A sortMode = %~1 %% 6
IF %sortMode% EQU 1 SET %2=-N
IF %sortMode% EQU 2 SET %2=-S
IF %sortMode% EQU 3 SET %2=-D
IF %sortMode% EQU 4 SET %2=N
IF %sortMode% EQU 5 SET %2=S
IF %sortMode% EQU 0 SET %2=D
EXIT /B 0

@REM Desc;  Prints conversion progress message
:PrintProgress
@REM Params;    1: File count, 2: Current file, 3: Operaiton, 4: File name
set /A remainingNumber=%~1-%~2
set /A remainingPercentage=(%~2*100)/%~1
CALL :NormalizeLength 5 "%remainingNumber%" remainingString
CALL :NormalizeLength 5 "%~2" currentString
CALL :NormalizeLength 3 "%remainingPercentage%" currentPercentage
CALL :NormalizeLength 10 "%~3" currentOperation
echo %currentString%/%~1, %remainingString% remaining, !currentPercentage!%% complete. %currentOperation% %~4
EXIT /B 0





@REM Desc;  Extracts .wem files from a .pak file
:Extract
@REM Params;    none
echo This utility extracts .wem files from .pak files.
echo.

CALL :AcquireResource "ExtQBMS" path_quickBms  1 %path_quickBms%  path_quickBms  "Select %file_quickBms%"
CALL :AcquireResource "ExtBMSS" path_bmsScript 1 %type_bmsScript% path_bmsScript "Select %type_bmsScript% script for QuickBMS to use."
CALL :AcquireResource "ExtPFP"  pakFilePath    1 %type_pak%       ""             "Select the %type_pak% file you want to extract."

CALL :GetFileName %pakFilePath% pakName
CALL :GetStringLength %pakName% pakNameLength
set /A pakFolderNameLength=%pakNameLength%+1

set extractSubFolder=%path_extract%\%pakName%
CALL :AcquireResource "ExtExFo" extractSubFolder 3 %extractSubFolder% "" "Where would you like to extract .wem files to?"
IF NOT "!extractSubFolder:~-%pakNameLength%!" == "%pakName%" set extractSubFolder=!extractSubFolder!\%pakName%
CALL :SaveToConfig path_extract !extractSubFolder:~0,-%pakFolderNameLength%!

CALL :Sleep 5 "Extraction will begin in 5 seconds." "Launching QuickBMS..."
CALL :MakeFolder %extractSubFolder%
echo %pakFileEncryptionKey% > %path_tempKey%
%path_quickBms% -o %path_bmsScript% %pakFilePath% %extractSubFolder% <%path_tempKey%
DEL %path_tempKey%

CALL :PrintExtractEndTutorial %pakFilePath% %extractSubFolder%
EXIT /B 0



@REM Desc;  Converts .wem files into .ogg files
:Convert
@REM Params;    none
echo This utility converts %type_wem% files into %type_ogg% files.
echo.

CALL :AcquireResource "ConW2O"  path_ww2ogg          1 %path_ww2ogg%          path_ww2ogg          "Select %file_ww2ogg%"
CALL :AcquireResource "ConPCB"  path_packedCodebooks 1 %path_packedCodebooks% path_packedCodebooks "Select the %file_packedCodebooks% file for %file_ww2ogg% to use."
CALL :AcquireResource "ConRev"  path_revorb          1 %path_revorb%          path_revorb          "Select %file_revorb%"
CALL :AcquireResource "ConPaFi" pakFilePath          1 %type_pak%             ""                   "Select the %type_pak% file from which the %type_wem% files were extracted from."

CALL :GetFileName %pakFilePath% pakName
CALL :GetStringLength %pakName% pakNameLength
set /A pakFolderNameLength=%pakNameLength%+1

set extractSubFolder=%path_extract%\%pakName%
CALL :AcquireResource "ConExFo" extractSubFolder 2 %extractSubFolder% "" "Select the folder where the %type_wem% files were extracted to from %pakName%%type_pak%"
IF NOT "!extractSubFolder:~-%pakNameLength%!" == "%pakName%" set extractSubFolder=!extractSubFolder!\%pakName%
CALL :SaveToConfig path_extract !extractSubFolder:~0,-%pakFolderNameLength%!

set convertSubFolder=%path_convert%\%pakName%
CALL :AcquireResource "ConCoFo" convertSubFolder 3 %convertSubFolder% "" "Select the folder where you want to save the %type_ogg% files converted from %pakName%%type_pak%'s %type_wem% files."
IF NOT "!convertSubFolder:~-%pakNameLength%!" == "%pakName%" set convertSubFolder=!convertSubFolder!\%pakName%
CALL :SaveToConfig path_convert !convertSubFolder:~0,-%pakFolderNameLength%!

echo How many conversions would you like to run in paraller^?
echo 3 is recommended. 9 will absolutely melt your computer.
CALL :AskNumber "ConTC" threadCount 1 9 3

echo Launchin %threadCount% conversion threads...
CALL :MakeFolder %convertSubFolder%
FOR /L %%t IN (2, 1, %threadCount%) DO START /LOW "ConversionThread-%%t" MainProgram.bat "Thread" %%t %ww2oggPath% %packedCodebooksPath% %revorbPath% %extractSubFolder% %convertSubFolder%
CALL :ManageThread 1 %path_ww2ogg% %path_packedCodebooks% %path_revorb% %extractSubFolder% %convertSubFolder%

CALL :Sleep 5 "File cleaning will begin in a moment." "Starting cleaning."
CALL :CleanTemps %convertSubFolder%

CALL :PrintConvertEndTutorial %extractSubFolder% %convertSubFolder%
EXIT /B 0



@REM Desc;  Adds & removes files from a .pak file
:Package
@REM Params;    none
echo This utility patches a .pak file.
echo.

CALL :AcquireResource "PacQGMS" path_quickBms  1 %file_quickBms%  path_quickBms  "Select %file_quickBms%"
CALL :AcquireResource "PacBMSS" path_bmsScript 1 %type_bmsScript% path_bmsScript "Select %type_bmsScript% file for QuickBMS to use."
CALL :AcquireResource "PacPFP"  pakFilePath    1 %type_pak%       ""             "Select the %type_pak% file you want to patch."

CALL :GetFileName %pakFilePath% pakName

CALL :AskBoolean "PackInFo" includeFiles "NO" "Would you like to add sound files to %pakName%%type_pak%?"
IF %includeFiles% == TRUE (
    CALL :FindExistingResource defaultIncludePath "%path_convert%\%pakName%\%folder_include%" "%path_extract%\%pakName%\%folder_include%"
    CALL :AcquireResource "PacInFo" includeFolder 2 "!defaultIncludePath!" "" "Select the folder with the %type_ogg%/%type_wem%/%type_fake% files from %pakName%%type_pak% you want to include back in it."

    CALL :FindExistingResource defaultWemPath "%path_extract%\%pakName%"
    CALL :AcquireResource "PacWeFo" wemFolder 1 "!defaultWemPath!" "" "Select the folder where the %type_wem% files from %pakName%%type_pak% have been extracted to."
)

CALL :AskBoolean "PacExFo" excludeFiles "YES" "Would you like to remove sound files from %pakName%%type_pak%?"
IF %excludeFiles% == TRUE (
    CALL :FindExistingResource defaultExcludePath "%path_convert%\%pakName%\%folder_exclude%"
    CALL :AcquireResource "PacExFo" excludeFolder 2 "!defaultExcludePath!" "" "Select the folder with the %type_ogg%/%type_wem%/%type_fake% files from %pakName%%type_pak% you want to exclude out of it."
)

IF %includeFiles% == FALSE IF %excludeFiles% == FALSE (
    echo So you don't want to include or exclude files?
    echo Then why did you call me? I'm quitting...
    echo.
    EXIT /B 0
)

echo The .pak file to patch:
echo    %pakFilePath%
IF %includeFiles% == TRUE (
    echo The folder from which to load the original %type_wem% files:
    echo    %wemFolder%
    echo The folder from which to select sound files to include:
    echo    %includeFolder%
)
IF %excludeFiles% == TRUE (
    echo The folder from whick to select sound files to exclude:
    echo    %excludeFolder%
)
echo.
CALL :AskBoolean "PacAFC" filesAreCorrect "" "Are you sure the paths listed above are correct?"
IF %filesAreCorrect% == FALSE (
    echo Please run this program again and choose the correct paths.
    EXIT /B 0
)

CALL :Sleep 5 "Patching will begin in 5 seconds." "Loading configuration..."

CALL :CreateBackup %pakFilePath% pakBacupPath
CALL :RemoveFolder %path_tempFiles%
CALL :MakeFolder %path_tempFiles%

ECHO Include: %includeFiles%, Folder: %includeFolder%
ECHO Exclude: %excludeFiles%, Folder: %excludeFolder%
ECHO TEMP FILES: "%path_tempFiles%",
TIMEOUT -1

IF %includeFiles% == TRUE FOR %%i IN ("%includeFolder%\*.*") DO (
    @REM ECHO "%wemFolder%\%%~ni.wem" == "%path_tempFiles%\%%~ni.wem"
    ECHO INCLUDE "%%i"
    COPY "%wemFolder%\%%~ni.wem" "%path_tempFiles%\%%~ni.wem" > NUL
)
IF %excludeFiles% == TRUE FOR %%e IN ("%excludeFolder%\*.*") DO (
    ECHO EXCLUDE "%%e"
    @REM ECHO NUL == "%path_tempFiles%\%%~ne.wem"
    COPY                     NUL "%path_tempFiles%\%%~ne.wem" > NUL
)

echo Launching QuickBMS...
@REM echo %pakFileEncryptionKey% > "%path_tempKey%"
@REM %path_quickBms% -o -w -r %type_bmsScript% %pakFilePath% %path_tempFiles% <%path_tempKey%
@REM DEL %path_tempKey%

@REM CALL :RemoveFolder %path_tempFiles%

CALL :PrintPackageEndTutorial %pakFilePath% %pakBacupPath%
EXIT /B 0



@REM Desc;  Saves file/folder structure into a .BL3AU (txt) file
:Serialize
@REM Params;    none
echo This utility saves the audio files from selected subfolders into a save file.
echo.

CALL :AcquireResource "SerPFP" pakFilePath 1 %type_pak% "" "Select the %type_pak% file you want to save selections for."
CALL :GetFileName %pakFilePath% pakName
CALL :GetStringLength %pakName% pakNameLength
set /A pakFolderNameLength=%pakNameLength%+1

CALL :FindExistingResource defaultConvertedPath "%path_convert%\%pakName%"
CALL :AcquireResource "SerCoFo" convertedFolder 2 "!defaultConvertedPath!" "" "Select the folder containing sorted %type_ogg%/%type_wem%/%type_fake% files you'd like to save."

CALL :AskString "SerFiNa" saveName "" "Name for save file"
set saveName=%saveName%.%pakName%%type_save%
CALL :AcquireResource "SerSaFo" saveFolder 3 %path_save% "" "Select folder to which you'd like to send the "!saveName!" save file."
set saveFile=%saveFolder%\%saveName%
CALL :SaveToConfig path_save %saveFolder%

set /A subFolderCount=0
FOR /F %%f IN ('dir /B /S /A:D %convertedFolder%\*.*') DO (
    set /A filesInFolder=0
    FOR %%x IN ("%%f\*.*") DO set /A filesInFolder+=1
    IF !filesInFolder! GTR 0 (
        set /A subFolderCount+=1
        CALL :GetFileName %%~ff subFolderName
        CALL :GetRelativePath %convertedFolder% %%~ff relativeSubFolder

        set subFolders[!subFolderCount!]=%%~ff
        set subFoldersRelative[!subFolderCount!]=!relativeSubFolder!
        set SubFolderNames[!subFolderCount!]=!subFolderName!
        set subFolderFileCounts[!subFolderCount!]=!filesInFolder!
    )
)

IF !subFolderCount! EQU 0 (
    echo No subfolders found from
    echo    %convertedFolder%\
    echo.
    echo Please create folders and move sound files to them, and try again.
    echo.
    EXIT /B 0
)

echo Found !subFolderCount! folders with sound files in them.
FOR /L %%s IN (1, 1, !subFolderCount!) DO (
    CALL :NormalizeLength 6 !subFolderFileCounts[%%s]! normalizedFileCount
    echo    %%s: !normalizedFileCount! files in !SubFolderNames[%%s]!
)


CALL :AskBoolean "SerSaAl" saveAll "YES" "Would you like to save ALL of these selections?"
set saveSome=FALSE
FOR /L %%s IN (1, 1, !subFolderCount!) DO IF %saveAll% == FALSE (
    DO CALL :AskBoolean "SerSaSu-%%s" saveSub[%%s] "YES" "Would you like to save !SubFolderNames[%%s]!?"
    IF !saveSub[%%s]! == TRUE set saveSome=TRUE
) ELSE (
    set saveSub[%%s]=TRUE
    set saveSome=TRUE
)

IF !saveSome! == FALSE (
    echo No subfolders selected to be saved.
    echo Please select at least some subfolders to be saved next time.
    echo.
)

echo Selections from
FOR /L %%s IN (1, 1, !subFolderCount!) DO IF !saveSub[%%s]! == TRUE echo    !SubFolderNames[%%s]!
echo will be saved to
echo   %saveFile%
echo.
echo Press any key to create save file...
TIMEOUT -1 > NUL

echo //Borderlands 3 Audio Utility save file for %pakName%.pak>%saveFile%
echo %save_package%>>%saveFile%
echo    %pakName%.pak>>%saveFile%
echo.>>%saveFile%

FOR /L %%s IN (1, 1, !subFolderCount!) DO IF !saveSub[%%s]! == TRUE (
    echo %save_folder%>>%saveFile%
    echo    !subFoldersRelative[%%s]!>>%saveFile%
    echo %save_files%>>%saveFile%
    FOR %%f IN ("!subFolders[%%s]!\*.*") DO echo    %%~nf>>%saveFile%
    echo.>>%saveFile%
)

CALL :PrintSerializeEndTutorial %saveFile%
EXIT /B 0



@REM Desc;  Loads files from .BL3AU (txt) file into include/exclude folders
:DeSerialize
@REM Params;    none
echo This utility loads .BL3AU save files to the directory.
echo.

CALL :AcquireResource "DesSaFi" saveFile 1 %type_save% "" "Select %type_save% file to load."

set savePackage=FALSE
set /A pakFileCount=0

FOR /F "eol=/ tokens=*" %%l IN (%saveFile%) DO (
    CALL :Trim %%l line

    IF !savePackage! == TRUE IF "!line:~-4!" == "%type_pak%" (
        set /A pakFileCount+=1
        set savePackage=FALSE

        CALL :GetFileName !line! pakName[!pakFileCount!]
        set      packageNames[!pakFileCount!]=!line!
        set     packageSorted[!pakFileCount!]=FALSE
        set shouldLoadPackage[!pakFileCount!]=FALSE
        set     doLoadPackage[!pakFileCount!]=FALSE
        set       onlyExclude[!pakFileCount!]=FALSE
        set     resourcePaths[!pakFileCount!]=""
        set       loadFormats[!pakFileCount!]=""
    )
    IF "!line!" == "%save_package%" (
        set savePackage=TRUE
    ) ELSE (
        set savePackage=FALSE
    )

    IF "!line!" == "%save_folder%" set packageSorted[!pakFileCount!]=TRUE
)

set function_loopPackages=FOR /L %%p IN (1, 1, !pakFileCount!) DO 

%function_loopPackages% IF !packageSorted[%%p]! == TRUE CALL :AskBoolean "DesLoPa-%%p" shouldLoadPackage[%%p] "YES" "Load file sorting for !packageNames[%%p]!?"

%function_loopPackages% IF !shouldLoadPackage[%%p]! == TRUE (
    CALL :AskBoolean "DesRePa-%%p" doLoadPackage[%%p] "" "Have you extracted or converted the the files from !packageNames[%%p]!?"

    IF !doLoadPackage[%%p]! == TRUE (
        CALL :FindExistingResource defaultResourceFolder "%path_convert%\!pakName[%%p]!" "%path_extract%\!pakName[%%p]!"
        CALL :AcquireResource "DesRePa-%%p" resourcePaths[%%p] 1 "!defaultResourceFolder!" "" "Select the folder where you have the %type_ogg%/%type_wem% files from !packageNames[%%p]!"

        FOR %%f IN ("!resourcePaths[%%p]!\*.*") DO (
            IF %%~xf == %type_wem% set loadFormats[%%p]=%type_wem%
            IF %%~xf == %type_ogg% set loadFormats[%%p]=%type_ogg%
            IF %%~xf == %type_fake% set loadFormats[%%p]=%type_fake%
        )
    ) ELSE (
        set loadFormats[%%p]=%type_fake%
        set onlyExclude[%%p]=TRUE
        echo Warning: If you don't have the files from !packageNames[%%p]! extracted or converted, you can only load the save file for sound file deletion. No files can be added back to this package at the moment.
        echo.
    )

)

echo Press any key to load save file from %saveFile% to
%function_loopPackages% IF !doLoadPackage[%%p]! == TRUE echo    !resourcePaths[%%p]!
TIMEOUT -1 > NUL

echo.
%function_loopPackages% IF !doLoadPackage[%%p]! == TRUE (
    FOR /F %%f IN ('dir /B /S /A:-D !resourcePaths[%%p]!\*.*') DO (
        IF NOT EXIST !resourcePaths[%%p]!\%%~nxf MOVE /Y %%~ff !resourcePaths[%%p]!\%%~nxf >NUL 2>NUL
    )
    FOR /F %%f IN ('dir /B /S /A:D !resourcePaths[%%p]!\*.*') DO CALL :RemoveFolder %%~ff
    echo Cleaned !resourcePaths[%%p]!\
)
echo.

%function_loopPackages% IF !doLoadPackage[%%p]! == TRUE (
    set operationMode=""
    set currentPackage=""
    set /A currentPackageIndex=0
    set currentFolder=""
    set currentFile=""
    set /A filesNotFound[%%p]=0

    FOR /F "eol=/ tokens=*" %%l IN (%saveFile%) DO (
        CALL :Trim %%l line

        IF "!line:~0,1!" == "[" (
            set operationMode=!line!
        ) ELSE IF NOT "!operationMode!" == "" (
            IF !operationMode! == %save_package% (
                set currentPackage=!line!
                set /A currentPackageIndex+=1
            )
            IF %%p EQU !currentPackageIndex! IF !doLoadPackage[%%p]! == TRUE (
                IF !operationMode! == %save_folder% (
                    set currentFolder=!line!
                    CALL :MakeFolder !resourcePaths[%%p]!\!line!
                ) ELSE IF !operationMode! == %save_files% IF NOT !currentFolder! == "" (
                    set currentFile=!line!!loadFormats[%%p]!
                    set currentFileRelative=!resourcePaths[%%p]!\!currentFile!
                    CALL :GetFullPath !currentFileRelative! currentFilePath
                    MOVE /Y !currentFilePath! !resourcePaths[%%p]!\!currentFolder!\!currentFileName! >NUL 2>NUL
                    IF ERRORLEVEL 1 set /A filesNotFound[%%p]+=1
                )
            )
        )
    )
)

%function_loopPackages% IF !doLoadPackage[%%p]! == TRUE IF !filesNotFound[%%p]! GTR 0 (
    echo There were problems loading the save for !packageNames[%%p]!
    echo This was most likely caused by missing !loadFormats[%%p]! files.
    echo Make sure ALL .ogg files extracted ^& converted from !packageNames[%%p]! are in
    echo    !resourcePaths[%%p]!
    echo.
)

CALL :PrintDeSerializeEndTutorial %saveFile% !pakFileCount!
EXIT /B 0





@REM Desc;  Prints instructions for the user after extraction has been completed
:PrintExtractEndTutorial
@REM Params;    1: .pak file path, 2: Extract folder path
echo .wem files extracted from
echo    %~f1
echo to
echo    %~f2\
echo.
echo.
echo NOTE:  Do NOT add, remove, or change the contents of
echo            %~f2\
echo        You can however move the folder around. Just don't change the contents.
echo.
echo.
@REM ToDo;  Ask user if they want to convert/deSerialize files, if yes, call :Convert/:DeSerialize
@REM        Make this a separate function
@REM        Ask number, enter for nothing (close window)
EXIT /B 0

@REM Desc;  Prints instructions for the user after conversion has been completed
:PrintConvertEndTutorial
@REM Params;    1: .wem source folder, 2: .ogg target folder
echo Converted .wem files from
echo    %~f1\
echo to .ogg files in
echo    %~f2\
echo.
echo.
echo Now you can sort the .ogg files to different folders depending if you want to include, exclude or save them.
echo.
echo.
@REM ToDo;  Offer to create include/exclude/delete folders to the CONVERSION folder
@REM        Make this a separate function
EXIT /B 0

@REM Desc;  Prints instructions for the user after conversion has been completed
:PrintPackageEndTutorial
@REM Params;    1: Packaged .pak path, 2: Backup .pak path
echo.
echo The %~nx1 file at
echo    %~dp1
echo has been patched. Move it to the game's directory.
echo Backup of the original has been created to %~f2
echo.
echo.
EXIT /B 0

@REM Desc;  Prints instructions for the user after save file creation has been completed.
:PrintSerializeEndTutorial
@REM Params;    1: Save file
echo Save file created to
echo    %~f1
echo.
echo Now you can store your sound configurations in a compact format and share them with other people.
echo.
EXIT /B 0

@REM Desc;  Prints instructions for the user after save file had been loadeed
:PrintDeSerializeEndTutorial
@REM Params;    1: Save file path, 2: .pak count
echo Saves loaded from
echo    %~f1
echo to
FOR /L %%p IN (1, 1, %~2) DO IF !doLoadPackage[%%p]! == TRUE echo    !resourcePaths[%%p]!\
echo.
echo Now you can edit the selections, or Package them into your .pak files.
echo.
EXIT /B 0







@REM Desc;  Function for helping testing :AcquireResource function
:Test_AcquireResource
@REM Params;    none
@REM Notes;
@REM    - This test deleted the config file
@REM    - Really needs more automation to be more robust
@REM    - Not worth it
@REM    - Functions should be callable from outside this .bat file so test data & cases can be stored there
@REM        - OperationMode: Test, Func: "functionName", ...functionParams
@REM        - IF "!operationMode!" == "Test" CALL :%~2 %3 %4 %5 %6 %7 %8 %9

:   Test parameters
:   1: Resource
:   1.1: Name (Folder)
:   1.2: .Extension
:   1.3: File.Extension
:   2: Config key
:   2.1: Not specified
:   2.1: Not saved
:   2.2: Saved & valid
:   2.3: Saved & invalid
:   3: Existing
:   3.1: Exists
:   3.2: Doesn't exist

: ToDo;
:   4: In current directory
:   4.1: Present in directory 
:   4.2: Missing from directory 

DEL %path_config%
CALL :MakeFolder test\validFolder
echo.>test\validFile.BL3AU
CALL :SaveToConfig test_invalidFolder %path_current%\test\invalidFolder
CALL :SaveToConfig test_validFolder   %path_current%\test\validFolder
CALL :SaveToConfig test_invalidFile   %path_current%\test\invalidFile.BL3AU
CALL :SaveToConfig test_validFile     %path_current%\test\validFile.BL3AU

echo 1.1: Folder,    2.1: No key,        3.1: Old, "!out!"
CALL :AcquireResource "111" out TRUE "test"       ""                  "Question string.exe"
echo 1.2: Extension, 2.1: No key,        3.1: Old, "!out!"
CALL :AcquireResource "211" out TRUE ".BL3AU"     ""                  "Question string.exe"
echo 1.3: File,      2.1: No key,        3.1: Old, "!out!"
CALL :AcquireResource "311" out TRUE "fil1.BL3AU" ""                  "Question string.exe"

echo 1.1: Folder,    2.2: Not saved,     3.1: Old, "!out!"
CALL :AcquireResource "121" out TRUE "test"       key1                "Question string.exe"
echo 1.2: Extension, 2.2: Not saved,     3.1: Old, "!out!"
CALL :AcquireResource "221" out TRUE ".BL3AU"     key2                "Question string.exe"
echo 1.3: File,      2.2: Not saved,     3.1: Old, "!out!"
CALL :AcquireResource "321" out TRUE "fil1.BL3AU" key3                "Question string.exe"

echo 1.1: Folder,    2.3: Saved valid,   3.1: Old, "!out!"
CALL :AcquireResource "131" out TRUE "test"       test_validFolder    "Question string.exe"
echo 1.2: Extension, 2.3: Saved valid,   3.1: Old, "!out!"
CALL :AcquireResource "231" out TRUE ".BL3AU"     test_validFile      "Question string.exe"
echo 1.3: File,      2.3: Saved valid,   3.1: Old, "!out!"
CALL :AcquireResource "331" out TRUE "fil1.BL3AU" test_validFile      "Question string.exe"

echo 1.1: Folder,    2.4: Saved invalid, 3.1: Old, "!out!"
CALL :AcquireResource "141" out TRUE "test"       test_invalidFolder  "Question string.exe"
echo 1.2: Extension, 2.4: Saved invalid, 3.1: Old, "!out!"
CALL :AcquireResource "241" out TRUE ".BL3AU"     test_invalidFile    "Question string.exe"
echo 1.3: File,      2.4: Saved invalid, 3.1: Old, "!out!"
CALL :AcquireResource "341" out TRUE "fil1.BL3AU" test_invalidFile    "Question string.exe"



echo 1.1: Folder,    2.1: No key,        3.2: New, "!out!"
CALL :AcquireResource "112" out FALSE "test"       ""                 "Question string.exe"
echo 1.2: Extension, 2.1: No key,        3.2: New, "!out!"
CALL :AcquireResource "212" out FALSE ".BL3AU"     ""                 "Question string.exe"
echo 1.3: File,      2.1: No key,        3.2: New, "!out!"
CALL :AcquireResource "312" out FALSE "fil1.BL3AU" ""                 "Question string.exe"

echo 1.1: Folder,    2.2: Not saved,     3.2: New, "!out!"
CALL :AcquireResource "122" out FALSE "test"       key4               "Question string.exe"
echo 1.2: Extension, 2.2: Not saved,     3.2: New, "!out!"
CALL :AcquireResource "222" out FALSE ".BL3AU"     key5               "Question string.exe"
echo 1.3: File,      2.2: Not saved,     3.2: New, "!out!"
CALL :AcquireResource "322" out FALSE "fil1.BL3AU" key6               "Question string.exe"

echo 1.1: Folder,    2.3: Saved valid,   3.2: New, "!out!"
CALL :AcquireResource "132" out FALSE "test"       test_validFolder   "Question string.exe"
echo 1.2: Extension, 2.3: Saved valid,   3.2: New, "!out!"
CALL :AcquireResource "232" out FALSE ".BL3AU"     test_validFile     "Question string.exe"
echo 1.3: File,      2.3: Saved valid,   3.2: New, "!out!"
CALL :AcquireResource "332" out FALSE "fil1.BL3AU" test_validFile     "Question string.exe"

echo 1.1: Folder,    2.4: Saved invalid, 3.2: New, "!out!"
CALL :AcquireResource "142" out FALSE "test"       test_invalidFolder "Question string.exe"
echo 1.2: Extension, 2.4: Saved invalid, 3.2: New, "!out!"
CALL :AcquireResource "242" out FALSE ".BL3AU"     test_invalidFile   "Question string.exe"
echo 1.3: File,      2.4: Saved invalid, 3.2: New, "!out!"
CALL :AcquireResource "342" out FALSE "fil1.BL3AU" test_invalidFile   "Question string.exe"


DEL %path_config%
CALL :RemoveFolder test
EXIT

EndLocal