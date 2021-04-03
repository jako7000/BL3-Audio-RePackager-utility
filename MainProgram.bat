@echo off
SetLocal EnableDelayedExpansion

set file_tempKey=%TEMP%\BL3AU_EnctryptionKey.txt
set file_quickBms=quickbms_4gb_files.exe
set file_ww2ogg=ww2ogg.exe
set file_packedCodebooks=packed_codebooks_aoTuV_603.bin
set file_revorb=revorb.exe

set type_bmsScript=.bms
set type_pak=.pak
set type_wem=.wem
set type_ogg=.ogg
set type_fake=.fake
set type_save=.BL3AU

set folder_current=%~dp0
set folder_temp=%TEMP%\BL3AU\
set folder_extract=extracted
set folder_convert=converted
set folder_include=include
set folder_exclude=exclude
set folder_ignore=ignore

set save_package=[PACKAGE]
set save_folder=[FOLDER]
set save_files=[FILES]

IF "%TEMP%" == "" (
    echo TEMP environment variable not found.
    echo ATTEMPTING to use "%rootDir:~0,-1%" as TEMP instead.
    echo (This probably doesn't work...)
    set %TEMP% = %folder_current:~0,-1%
)

set pakFileEncryptionKey=0x115EE4F8C625C792F37A503308048E79726E512F0BF8D2AD7C4C87BC5947CBA7
set /A sleepDurationPerMinute = 10
set UI=TRUE

@REM Magical File explorer variables!
set FileSelectDialog=powershell -noprofile -command "&{[System.Reflection.Assembly]::LoadWithPartialName('System.windows.forms') | Out-Null;$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog; $OpenFileDialog.ShowDialog()|Out-Null; $OpenFileDialog.FileName}"
set FolderSelectDialog="powershell (new-object -COM 'Shell.Application').BrowseForFolder(0,'Please choose a folder.',0,0).self.path"





@REM Desc; Processes parameters, sets global variables & selects task
:Main
@REM Params; 1: mode "Extract" | "Convert" | "Package" | "Serialize" | "DeSerialize" | "Thread", 2->: Optional parameters
CALL :SetUI %1 %2 %3 %4 %5 %6 %7 %8 %9
CALL :SetSleepDuration %1 %2 %3 %4 %5 %6 %7 %8 %9
CALL :SetEncryptionKey %1 %2 %3 %4 %5 %6 %7 %8 %9

IF /I "%~1" == "Thread" (
    CALL :ManageThread %2 %3 %4 %5 %6 %7
) ELSE (
    CALL :SelectOperationMode %1
)

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

@REM Desc;  Asks the user for a folder path
:AskFolder
@REM Params;    1: Question ID, 2: Output variable, 3: (Optional) Default folder, 4: (Optional) Question string, 5: (Optional) Resource description string
IF NOT "%~4" == "" echo %~4
IF NOT "%~3" == "" CALL :AskBoolean "AskFo-%~1" defaultOk%~1 "YES" "Is "%~f3\" ok?"
IF "!defaultOk%~1!" == "TRUE" (
    set intFolderPath%~1=%~f3
) ELSE (
    IF %UI% == TRUE (
        CALL :ShowFolderDialog "AskFo-%~1" userFolderPath%~1 %5
    ) ELSE (
        CALL :TypeFilePath "AskFo-%~1" userFolderPath%~1 %5
    )

)

IF NOT "!userFolderPath%~1!" == "" set intFolderPath%~1=!userFolderPath%~1!

IF "!intFolderPath%~1!" == "" (
    echo "!intFolderPath%~1!" is not a valid path.
    echo.
    CALL :AskFolder "%~1" folderRetry%~1 %3 %4 %5
    set %2=!folderRetry%~1!
    EXIT /B 0
)
set %2=!intFolderPath%~1!
echo.
EXIT /B 0

@REM Desc;  Asks the user for a file path
:AskFilePath
@REM Params;    1: Question ID, 2: Output variable, 3: (Optional) Default file, 4: (Optional) File name/extension 5: (Optional) Question string, 6: (Optional) Resource description string
IF NOT "%~5" == "" echo %~5
IF NOT "%~3" == "" CALL :AskBoolean "AskFi-%~1" defaultOk%~1 "YES" "Is "%~f3\" ok?"
IF "!defaultOk%~1!" == "TRUE" (
    set intFilePath%~1=%~f3
) ELSE (
    IF %UI% == TRUE (
        CALL :ShowFileDialog "AskFi-%~1" userFilePath%~1 %6
    ) ELSE (
        CALL :TypeFilePath "AskFi-%~1" userFilePath%~1 %6
    )
)

IF "%~4" == "" (
    set intFilePath%~1=!userFilePath%~1!
) ELSE (
    CALL :IsSpecifiedFile "AskFi-%~1" isValid%~1 !userFilePath%~1! %4
    IF !isValid%~1! == TRUE set intFilePath%~1=!userFilePath%~1!
)

IF "!intFilePath%~1!" == "" (
    echo "!userFilePath%~1!" is not a valid input.
    echo.
    CALL :AskFilePath "%~1-" fileRetry%~1 %3 %4 %5 %6
    set %2=!fileRetry%~1!
    EXIT /B 0
)
set %2=!intFilePath%~1!
echo.
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
CALL :GetFullPath !userPath%~1! intPath%~1
set %2=!intPath%~1!
EXIT /B 0



@REM Desc;  Check wether or not given path leads to specified file (type)
:IsSpecifiedFile
@REM Params;    1: Question ID, 2: Output variable, 3: File to validate, 4: Validation
set fileName%~1=%~n3
set fileExtension%~1=%~x3
set validationName%~1=%~n4
set validationExtension%~1=%~x4

IF NOT      "!validationName%~1!" == "" IF /I      "!validationName%~1!" ==      "!fileName%~1!" (set nameOk%~1=TRUE) ELSE (set nameOk%~1=FALSE)
IF NOT "!validationExtension%~1!" == "" IF /I "!validationExtension%~1!" == "!fileExtension%~1!" (set typeOk%~1=TRUE) ELSE (set typeOk%~1=FALSE)

SET intValidation%~1=TRUE
IF !nameOk%~1! == FALSE set intValidation%~1=FALSE
IF !typeOk%~1! == FALSE set intValidation%~1=FALSE

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

@REM Desc;  Check if wanted file is present,
@REM        if yes, asks user if this is ok,
@REM        if not ok, asks for wanted file.
@REM        Returns file path.
:AcquireFile
@REM Params;    1: Question ID, 2: Output file path, 3: File name
CALL :CheckLocalFile %3 localFileFound intFilePath%~1
IF %localFileFound% == TRUE (
    echo "%~nx3" found at
    echo    !intFilePath%~1!
    CALL :AskBoolean "AcqFi-%~1" useLocalFile "YES" "Use this file?"
)
IF NOT "!useLocalFile!" == "TRUE" CALL :AskFilePath "AcqFi-%~1" intFilePath%~1 "" %3 "" %3
set %2=!intFilePath%~1!
echo.
EXIT /B 0





@REM Desc;  Extends input to full path
:GetFullPath
@REM Params;    1: Input path, 2: Output variable
set %2=%~f1
EXIT /B 0

@REM Desc;   Extends input to path relative to given root
:GetRelativePath
@REM Params;    1: Root dir, 2: Path to relate, 3: Output variable
set rootDir=%~1
set pathToRelate=%~2
CALL :GetStringLength %rootDir% rootLength
set /A charsToRemove=%rootLength%-3
set %3=!pathToRelate:~%rootLength%!
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
FOR /F "delims=:" %%n IN ('"(CMD /V:ON /C echo(%~1!&echo()|FINDSTR /O ^^"') DO set /A fullLength=%%n-3
EndLocal & set /A %~2=%fullLength%
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
CALL :AcquireFile "ExtQBMS" quickBmsPath  %file_quickBms%
CALL :AcquireFile "ExtBMSS" bmsScriptPath %type_bmsScript%
CALL :AcquireFile "ExtPFP"  pakFilePath   %type_pak%

CALL :GetFileName %pakFilePath% subFolderName
set extractSubFolder=%folder_extract%\%subFolderName%

CALL :AskFolder "ExtExFo" extractFolder %extractSubFolder% "Where would you like to extract .wem files to?" "the folder where you want the .wem files extracted to"

CALL :Sleep 5 "Extraction will begin in 5 seconds." "Launching QuickBMS..."
CALL :MakeFolder %extractSubFolder%
echo %pakFileEncryptionKey% > %file_tempKey%
%quickBmsPath% -o %bmsScriptPath% %pakFilePath% %extractSubFolder% <%file_tempKey%
DEL %file_tempKey%

CALL :PrintExtractEndTutorial %pakFilePath% %extractSubFolder%
EXIT /B 0



@REM Desc;  Converts .wem files into .ogg files
:Convert
@REM Params;    none
CALL :AcquireFile "ConW2O" ww2oggPath          %file_ww2ogg%
CALL :AcquireFile "ConPCB" packedCodebooksPath %file_packedCodebooks%
CALL :AcquireFile "ConRev" revorbPath          %file_revorb%
CALL :AskFolder "ConSoFo" sourceFolder "" "Select folder with .wem files to convert to .ogg files." "the folder with the .wem files to convert"
CALL :AskFolder "ConTaFo" targetFolder %folder_convert% "Select folder to which to save the .ogg files." "the folder where to save the .ogg files"
echo How many conversions would you like to run in paraller^?
echo 3 is recommended. 9 will absolutely melt your computer.
CALL :AskNumber "ConTC" threadCount 1 9 3

CALL :GetFileName %sourceFolder% subFolderName
set convertSubFolder=%targetFolder%\%subFolderName%

echo Launchin %threadCount% conversion threads...
CALL :MakeFolder %convertSubFolder%
FOR /L %%t IN (2, 1, %threadCount%) DO START /LOW "ConversionThread-%%t" MainProgram.bat "Thread" %%t %ww2oggPath% %packedCodebooksPath% %revorbPath% %sourceFolder% %convertSubFolder%
CALL :ManageThread 1 %ww2oggPath% %packedCodebooksPath% %revorbPath% %sourceFolder% %convertSubFolder%

CALL :Sleep 5 "File cleaning will begin in a moment." "Starting cleaning."
CALL :CleanTemps %convertSubFolder%

CALL :PrintConvertEndTutorial %sourceFolder% %convertSubFolder%
EXIT /B 0



@REM Desc;  Adds & removes files from a .pak file
:Package
@REM Params;    none
CALL :AcquireFile "PacQGMS" quickBmsPath  %file_quickBms%
CALL :AcquireFile "PacBMSS" bmsScriptPath %type_bmsScript%
CALL :AcquireFile "PacPFP"  pakFilePath   %type_pak%

CALL :GetFileName %pakFilePath% pakName

CALL :AskBoolean "PackInFi" includeFiles "YES" "Would you like to add sound files to %pakName%.pak?"
IF %includeFiles% == TRUE (
    set defaultIncludeFolder=%folder_convert%\%pakName%\%folder_include%
    CALL :GetFolderPath !defaultIncludeFolder! defaultIncludePath
    IF NOT EXIST !defaultIncludePath! set defaultIncludePath=""
    CALL :AskFolder "PacInFo" includeFolder !defaultIncludePath! "Select the folder from which you want to include sound files (.ogg OR .wem)." "the .ogg OR .wem files to include in the %pakName%.pak"

    set defaultWemFolder=%folder_extract%\%pakName%
    CALL :GetFolderPath !defaultWemFolder! defaultWemPath
    IF NOT EXIST !defaultWemPath! set defaultWemPath=""
    CALL :AskFolder "PacWeFo" wemFolder !defaultWemPath! "Select the folder where the .wem files from %pakName%.pak have been extracted to." "all of the .wem files extracted from %pakName%.pak"
)

CALL :AskBoolean "PacExFi" excludeFiles "YES" "Would you like to remove sound files from %pakName%?"
IF %excludeFiles% == TRUE (
    set defaultExcludeFolder=%folder_convert%\%pakName%\%folder_exclude%
    CALL :GetFolderPath !defaultExcludeFolder! defaultExcludePath
    IF NOT EXIST !defaultExcludePath! set defaultExcludePath=""
    CALL :AskFolder "PacExFo" excludeFolder !defaultExcludePath! "Select the folder from which you want to exclude sound files (.ogg OR .wem OR .fake)." "the folder with the .ogg OR .wem OR .fake files you want to remove from %pakName%.pak"
)

IF %includeFiles% == FALSE IF %excludeFiles% == FALSE (
    echo So you don't want to include or exclude files?
    echo Then why did you call me? I'm quitting...
    echo.
    EXIT /B 0
)

echo The .pak file to patch:
echo    %pakFilePath%
IF %includeFiles% == TRUE echo The folder from which to load the original .wem filed:
IF %includeFiles% == TRUE echo    %wemFolder%
IF %includeFiles% == TRUE echo The folder from which to select sound files to include:
IF %includeFiles% == TRUE echo    %includeFolder%
IF %excludeFiles% == TRUE echo The folder from whick to select sound files to exclude:
IF %excludeFiles% == TRUE echo    %excludeFolder%
echo.
CALL :AskBoolean "PacAFC" filesAreCorrect "" "Are you sure the paths listed above are correct?"
IF %filesAreCorrect% == FALSE (
    echo Please run this program again and choose the correct paths.
    EXIT /B 0
)

echo Press any key to begin packaging...
TIMEOUT -1 > NUL

CALL :CreateBackup %pakFilePath% pakBacupPath
CALL :RemoveFolder %folder_temp%
CALL :MakeFolder %folder_temp%
CALL :GetFolderPath %folder_temp% fullTempFolderPath

IF %includeFiles% == TRUE FOR %%i IN ("%includeFolder%\*.*") DO COPY "%wemFolder%\%%~ni.wem" "%folder_temp%\%%~ni.wem" > NUL
IF %excludeFiles% == TRUE FOR %%e IN ("%excludeFolder%\*.*") DO COPY                     NUL "%folder_temp%\%%~ne.wem" > NUL

echo Launching QuickBMS...
echo %pakFileEncryptionKey% > "%file_tempKey%"
%quickBmsPath% -o -w -r %bmsScriptPath% %pakFilePath% %fullTempFolderPath% <%file_tempKey%
DEL %file_tempKey%

CALL :RemoveFolder %fullTempFolderPath%

CALL :PrintPackageEndTutorial %pakFilePath% %pakBacupPath%
EXIT /B 0



@REM Desc;  Saves file/folder structure into a .BL3AU (txt) file
:Serialize
@REM Params;    none
echo This utility saves the audio files from selected subfolders into a save file.
echo.

CALL :AcquireFile "SerPFP" pakFilePath %type_pak%
CALL :GetFileName %pakFilePath% pakName

set defaultConvertedFolder=%folder_convert%\%pakName%
CALL :GetFolderPath !defaultConvertedFolder! defaultConvertedPath
IF NOT EXIST !defaultConvertedPath! set defaultConvertedPath=""
CALL :AskFolder "SerCoFo" convertedFolder !defaultConvertedPath! "Select the folder containing sorted .ogg OR .wem you'd like to save." "the folder from which you'd like to save the sorted .ogg OR .wem files"

CALL :AskString "SerFiNa" saveName "" "Name for save file"
set saveName=%saveName%.%pakName%.BL3AU
CALL :AskFolder "SerSaFo" saveFolder %folder_current:~0,-1% "Select folder to which you'd like to send the "!saveName!" save file." "the folder to where you'd like to send the "!saveName!" save file"
set saveFile=%saveFolder%\%saveName%

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

CALL :AcquireFile "DesSaFi" saveFile %type_save%

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
        set defaultResourceFolder=%folder_convert%\!pakName[%%p]!
        IF NOT EXIST !defaultResourceFolder! set defaultResourceFolder=%folder_extract%\!pakName[%%p]!
        IF NOT EXIST !defaultResourceFolder! set defaultResourceFolder=""

        CALL :AskFolder "DesRePa-%%p" resourcePaths[%%p] !defaultResourceFolder! "Select the folder where you have converted (.ogg) or extracted (.wem) the files from !packageNames[%%p]! to." "the folder where you have converted or extracted !packageNames[%%p]! files to"

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
echo Now you can sort the .ogg files to different folders depending if you want to include, exclude or ignore them.
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



EndLocal