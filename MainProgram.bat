@echo off
SetLocal EnableDelayedExpansion

set tempDummyFolderName=temp
set tempKeyFileName=tempKey.txt
set quickBmsExeName=quickbms_4gb_files.exe
set bmsScriptName=*.bms
set ww2oggExeName=ww2ogg.exe
set packedCodebooksBinName=packed_codebooks_aoTuV_603.bin
set revorbExeName=revorb.exe
set pakFileName=*.pak
set extractFolder=extracted
set convertFolder=converted
set includeFolder=include
set excludeFolder=exclude
set ignoreFolder=ignore

set pakFileEncryptionKey=0x115EE4F8C625C792F37A503308048E79726E512F0BF8D2AD7C4C87BC5947CBA7
set /A sleepDurationPerMinute = 10
set UI=TRUE

@REM Magical File explorer variables!
set FileSelectDialog=powershell -noprofile -command "&{[System.Reflection.Assembly]::LoadWithPartialName('System.windows.forms') | Out-Null;$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog; $OpenFileDialog.ShowDialog()|Out-Null; $OpenFileDialog.FileName}"
set FolderSelectDialog="(new-object -COM 'Shell.Application').BrowseForFolder(0,'Please choose a folder.',0,0).self.path"





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
@REM Params;    1: Question ID, 2: Output variable, 3: (Optional) Default value (YES|NO), 4: (Optional) Question string, 
IF "%~3" == "" (
    set /P userBoolean%~1="%~4 (Y/N): "
) ELSE (
    IF NOT "%~4" == "" echo %~4
    set /P userBoolean%~1="Press ENTER for %~3 (Y/N): "
)

       IF /I "!userBoolean%~1!" == "Y" (
    set intBoolean=TRUE
) ELSE IF /I "!userBoolean%~1!" == "YES" (
    set intBoolean=TRUE
) ELSE IF /I "!userBoolean%~1!" == "1" (
    set intBoolean=TRUE
) ELSE IF /I "!userBoolean%~1!" == "N" (
    set intBoolean=FALSE
) ELSE IF /I "!userBoolean%~1!" == "NO" (
    set intBoolean=FALSE
) ELSE IF /I "!userBoolean%~1!" == "0" (
    set intBoolean=FALSE
) ELSE IF /I "!userBoolean%~1!" == "" IF NOT "%~3" == "" (
    IF "%~3" == "YES" set intBoolean=TRUE
    IF "%~3" == "NO"  set intBoolean=FALSE
)

IF "!intBoolean!" == "" (
    echo "!userBoolean%~1!" is not a valid input.
    echo.
    CALL :AskBoolean "%~1-" booleanRetry %3 %4
    set %2=!booleanRetry!
    EXIT /B 0
)
set %2=!intBoolean!
echo.
EXIT /B 0

@REM Desc;  Asks the user a number question
:AskNumber
@REM Params;    1: Question ID, 2: Output variable, 3: Min, 4: Max, 5: (Optional) Default value, 6: (Optional) Question string,
IF "%~5" == "" (
    set /P userInt%~1="%~6 (%3-%4): "
) ELSE (
    IF NOT "%~6" == "" echo %~6
    set /P userInt%~1="Press ENTER for %5 (%3-%4): "
)

set /A castUserInt="!userInt%~1!"
IF "!userInt%~1!" == "" (
    IF NOT "%~5" == "" (
        set /A intInteger=%5
    ) ELSE (
        echo "!userInt%~1!" is not a valid input.
        echo.
        CALL :AskNumber "%~1-" integerRetry %3 %4 %5 %6
        set /A %2=!integerRetry!
        EXIT /B 0
    )
) ELSE (
    IF "%castUserInt%" EQU "!userInt%~1!" (
        IF "%castUserInt%" LSS "%3" (
            echo %castUserInt% is too small. Value set to %3
            set /A intInteger=%3
        ) ELSE IF "%castUserInt%" GTR "%4" (
            echo %castUserInt% is too large. Value set to %4.
            set /A intInteger=%4
        ) ELSE (
            set /A intInteger=%castUserInt%
        )
    ) ELSE (
        echo "!userInt%~1!" is not a valid input.
        echo.
        CALL :AskNumber "%~1-" integerRetry %3 %4 %5 %6
        set /A %2=!integerRetry!
        EXIT /B 0
    )
)

set /A %2=!intInteger!
echo.
EXIT /B 0

@REM Desc;  Asks the user for a folder path
:AskFolder
@REM Params;    1: Question ID, 2: Output variable, 3: (Optional) Default folder, 4: Question string 5: Type path question continuation
set defaultOk=FALSE
echo %~4
IF NOT "%~3" == "" CALL :AskBoolean "AskFo-%1" defaultOk "YES" "Is "%~f3\" ok?"
IF %defaultOk% == TRUE (
    set intFolderPath=%~f3
) ELSE (
    IF %UI% == TRUE (
        CALL :ShowFolderDialog "AskFo-%1" givenFolderPath
    ) ELSE (
        CALL :TypeFilePath "AskFo-%1" givenFolderPath %5
    )
    IF "!givenFolderPath!" == "" (
        echo "!givenFolderPath!" is not a valid input.
        echo.
        CALL :AskFolder "AskFo-%1" givenFolderPath %3 %4 %5
    )
    CALL :GetFolderPath !givenFolderPath! expandedFolderPath
    set intFolderPath=!expandedFolderPath!
)
set %2=!intFolderPath!
EXIT /B 0

@REM Desc;  Asks the user for a file path
:AskFilePath
@REM Params;    1: Question ID, 2: Output variable, 3: File name
IF %UI% == TRUE (
    CALL :ShowFileDialog "AskFi-%1" givenFilePath %3
) ELSE (
    CALL :TypeFilePath "AskFi-%1" givenFilePath %3
)

CALL :IsSpecifiedFile "!givenFilePath!" %3 isValid
IF !isValid! == TRUE (
    set %2=!givenFilePath!
) ELSE (
    echo "%~3" not found at
    IF "!givenFilePath!" == "" (echo    "!givenFilePath!") ELSE (echo    !givenFilePath!)
    echo.
    CALL :AskFilePath "%~1-" pathRetry %3
    set %2=!pathRetry!
    EXIT /B 0
)
echo.
EXIT /B 0

@REM Desc;  Shows the user a windows folder select window for file selection 
:ShowFolderDialog
@REM Params;    1: Question ID, 2: Output variable
FOR /F "usebackq delims=" %%I IN (`%FolderSelectDialog%`) DO set intFolderPath%~1=%%I
set %2=!intFolderPath%~1!
EXIT /B 0

@REM Desc;  Shows the user a windows file select window for file selection
:ShowFileDialog
@REM Params;    1: Question ID, 2: Output variable, 3: File name
echo Please select path to "%~3" file.
TIMEOUT 1 > NUL
FOR /F "delims=" %%i IN ('%FileSelectDialog%') DO set intFilePath%~1=%%~fi
set %2=!intFilePath%~1!
TIMEOUT 1 > NUL
EXIT /B 0

@REM Desc;  Asks the user to type a file path
:TypeFilePath
@REM Params;    1: Question ID, 2: Output variable, 3: File name
set /P givenFile%~1="Please type path to %~3: "
CALL :GetFullPath !givenFile%~1! intFilePath
set %2=!intFilePath!
EXIT /B 0



@REM Desc;  Check wether or not given path leads to specified file (type)
:IsSpecifiedFile
@REM Params;    1: Path to check, 2: File name/type, 3: Output boolean
set fileName=%~2
IF /I "%fileName:~1,1%" == "." (
    set %3=TRUE
    EXIT /B 0
) 

IF NOT EXIST "%~f1" (
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
@REM Params;    1: Question ID, 2: Output file path, 3: File name
CALL :CheckLocalFile %3 localFileFound intFilePath
IF %localFileFound% == TRUE (
    echo "%~nx3" found at
    echo    %intFilePath%
    CALL :AskBoolean "AcqFi-%~1" useLocalFile "YES" "Use this file?"
    IF !useLocalFile! == FALSE CALL :AskFilePath "AcqFi-%~1" intFilePath %3
)
set %2=!intFilePath!
echo.
EXIT /B 0





@REM Desc;  Extends input to full path
:GetFullPath
@REM Params;    1: Input path, 2: Output variable
set %2=%~f1
EXIT /B 0

@REM Desc;  Expands input to folder path
:GetFolderPath
@REM Params;    1: Input path, 2: Output variable
set %2=%~dpn1
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
CALL :AcquireFile "ExtQBMS" quickBmsPath  %quickBmsExeName%
CALL :AcquireFile "ExtBMSS" bmsScriptPath %bmsScriptName%
CALL :AcquireFile "ExtPFP"  pakFilePath   %pakFileName%
CALL :AskFolder "ExtExFo" extractFolder %extractFolder% "Where would you like to extract .wem files to?" "the folder where you want the .wem files extracted to"

CALL :GetFileName %pakFilePath% subFolderName
set extractSubFolder=%extractFolder%\%subFolderName%

CALL :Sleep 5 "Extraction will begin in 5 seconds." "Launching QuickBMS..."
CALL :MakeFolder %extractSubFolder%
echo %pakFileEncryptionKey% > %tempKeyFileName%
%quickBmsPath% -o %bmsScriptPath% %pakFilePath% %extractSubFolder% <%tempKeyFileName%
DEL %tempKeyFileName%

CALL :PrintExtractEndTutorial %pakFilePath% %extractSubFolder%
EXIT /B 0

@REM Desc;  Converts .wem files into .ogg files
:Convert
@REM Params;    none
CALL :AcquireFile "ConW2O" ww2oggPath          %ww2oggExeName%
CALL :AcquireFile "ConPCB" packedCodebooksPath %packedCodebooksBinName%
CALL :AcquireFile "ConRev" revorbPath          %revorbExeName%
CALL :AskFolder "ConSoFo" sourceFolder "" "Select folder with .wem files to convert to .ogg files." "the folder with the .wem files to convert"
CALL :AskFolder "ConTaFo" targetFolder %convertFolder% "Select folder to which to save the .ogg files." "the folder where to save the .ogg files"
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
CALL :AcquireFile "PacQGMS" quickBmsPath  %quickBmsExeName%
CALL :AcquireFile "PacBMSS" bmsScriptPath %bmsScriptName%
CALL :AcquireFile "PacPFP"  pakFilePath   %pakFileName%

CALL :GetFileName %pakFilePath% pakName

CALL :AskBoolean "PackInFi" includeFiles "YES" "Would you like to add sound files to %pakName%.pak?"
IF %includeFiles% == TRUE (
    set defaultIncludeFolder=%convertFolder%\%pakName%\%includeFolder%
    CALL :GetFolderPath !defaultIncludeFolder! defaultIncludePath
    IF NOT EXIST !defaultIncludePath! set defaultIncludePath=""
    CALL :AskFolder "PacInFo" includeFolder !defaultIncludePath! "Select the folder from which you want to include sound files (.ogg OR .wem)." "the .ogg OR .wem files to include in the %pakName%.pak"

    set defaultWemFolder=%extractFolder%\%pakName%
    CALL :GetFolderPath !defaultWemFolder! defaultWemPath
    IF NOT EXIST !defaultWemPath! set defaultWemPath=""
    CALL :AskFolder "PacWeFo" wemFolder !defaultWemPath! "Select the folder where the .wem files from %pakName%.pak have been extracted to." "all of the .wem files extracted from %pakName%.pak"
)

CALL :AskBoolean "PacExFi" excludeFiles "YES" "Would you like to remove sound files from %pakName%?"
IF %excludeFiles% == TRUE (
    set defaultExcludeFolder=%convertFolder%\%pakName%\%excludeFolder%
    CALL :GetFolderPath !defaultExcludeFolder! defaultExcludePath
    echo defaultExcludePath: "!defaultExcludePath!"
    IF NOT EXIST !defaultExcludePath! set defaultExcludePath=""
    echo defaultExcludePath: "!defaultExcludePath!"
    CALL :AskFolder "PacExFo" excludeFolder !defaultExcludePath! "Select the folder from which you want to exclude sound files (.ogg OR .wem OR .fake)." "the folder with the .ogg OR .wem OR .fake files you want to remove from %pakName%.pak"
)
EXIT /B 0

@REM Desc;  Saves files from include/exclude folders into a .BL3AS (txt) file
:Serialize
@REM Params;    none
echo Serialize placeholder func.
EXIT /B 0

@REM Desc;  Loads files from .BL3AS (txt) file into include/exclude folders
:DeSerialize
@REM Params;    none
echo DeSerialize placeholder func.
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
@REM ToDo;  Offer to create include/exclude/delete folders to the CONVERSION folder
@REM        Make this a separate function
EXIT /B 0





EndLocal