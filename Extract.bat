@echo off
SetLocal EnableDelayedExpansion

set tempDummyFolderName=temp
set tempKeyFileName=tempKey.txt
set pakFileEncryptionKey=0x115EE4F8C625C792F37A503308048E79726E512F0BF8D2AD7C4C87BC5947CBA7
set /A sleepDurationPerMinute = 10

@REM Magical File explorer variable!
set FileSelectDialog=powershell -noprofile -command "&{[System.Reflection.Assembly]::LoadWithPartialName('System.windows.forms') | Out-Null;$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog; $OpenFileDialog.ShowDialog()|Out-Null; $OpenFileDialog.FileName}"



@REM Overall ToDos:
@REM    Re-imagine the workspace
@REM    Re-write the whole thing from the ground up to support different .paks, in paraller
@REM        For example extracted\pakchunk3-WindowsNoEditor\*.wem
@REM        Save files contain .pak name
@REM        Support loading & saving .pak files
@REM        Just make this a .exe program already...
@REM            .exe would probably enable playing and selecting induvidual .ogg files... :thinking_face:



@REM Desc; Processes parameters, sets global variables & selects task 
:Main
@REM Params; 1: mode "Package" | "Convert" | "Serialize" | "DeSerialize"
@REM Mode: "Package"; 2: Thread number, 3: ww2ogg.exe path, 4: revorb.exe path
@REM if paramX == "-sleep", then paramX+1 == sleep duration 
CALL :SetUI %1 %2 %3
CALL :SetSleepDuration %1 %2 %3 %4 %5 %6 %7

IF /I "%1" == "Package" (
    CALL :RunPackaging
    EXIT /B 0
)
IF /I "%1" == "Convert" (
    CALL :RunWemConverter %2 %3 %4
    EXIT /B 0
)
IF /I "%1" == "Serialize" (
    CALL :Serialize
    EXIT /B 0
)
IF /I "%1" == "DeSerialize" (
    CALL :DeSerialize
    EXIT /B 0
)
CALL :ExtractAndConvert
EXIT /B 0



@REM Desc; The "UI" variable set in this function is to be used globally.
@REM       0 = Only command prompt, 1 = Windows file explorer for selecting files & folders
:SetUI
@REM Params; Parameters given to the program
set /A UI=1
IF /I "%~1" == "-noUI" set /A UI=0
IF /I "%~2" == "-noUI" set /A UI=0
IF /I "%~3" == "-noUI" set /A UI=0
EXIT /B 0

@REM Desc; Sets the "sleepDurationPerMinute" variable to be used globally.
:SetSleepDuration
@REM Params; Parameters given to the program
IF /I "%~1" == "-sleep" set /A sleepDurationPerMinute=%~2
IF /I "%~2" == "-sleep" set /A sleepDurationPerMinute=%~3
IF /I "%~3" == "-sleep" set /A sleepDurationPerMinute=%~4
IF /I "%~4" == "-sleep" set /A sleepDurationPerMinute=%~5
IF /I "%~5" == "-sleep" set /A sleepDurationPerMinute=%~6
IF /I "%~6" == "-sleep" set /A sleepDurationPerMinute=%~7
@REM This technique is very sophisticated, I know.
EXIT /B 0





@REM Desc; Directs process flow to extract & convert voice lines from the .pak file.
:ExtractAndConvert
@REM Params; none
CALL :AskBoolean extractWEMs "Would you like to extract .wem files from a .pak file?"
CALL :AskBoolean convertToOGG "Would you like to convert .wem files to .ogg format?"
IF %extractWEMs% EQU 0 IF %convertToOGG% EQU 0 (
    echo No actions selected, nothing to do.
    echo Press any key to close the program.
    TIMEOUT -1 > NUL
    EXIT /B 0
)

IF %extractWEMs% EQU 1 (
    CALL :GetFile "quickbms_4gb_files.exe" qbmsFilePath 
    CALL :GetFile "unreal_tournament_4.bms" scriptFilePath
    CALL :GetFile "pakchunk3-WindowsNoEditor.pak" pakFilePath
)
IF %convertToOGG% EQU 1 (
    CALL :GetFile "ww2ogg.exe" ww2oggFilePath
    CALL :GetFile "revorb.exe" revorbFilePath
    echo How many conversions would you like to run in paraller^?
    echo 3 is recommended. 9 will absolutely melt your computer.
    CALL :AskNumber threadCount 1 9 3
)

IF %extractWEMs%  EQU 1 CALL :Extract %qbmsFilePath% %scriptFilePath% %pakFilePath% extracted^\

CALL :MakeFolder keep
CALL :MakeFolder delete

IF %convertToOGG% EQU 1 (
    echo Launching %threadCount% conversion threads...
    FOR /L %%t IN (2, 1, %threadCount%) DO START /LOW "ConversionThread-%%t" Extract.bat convert %%t %ww2oggFilePath% %revorbFilePath% -sleep %sleepDurationPerMinute%
    CALL :RunWemConverter 1 %ww2oggFilePath% %revorbFilePath%
    CALL :Sleep 5 "File cleaning will begin in a moment." "Starting cleaning.."
    CALL :CleanTemps

    echo Listen to the .ogg files in "converted" folder.
    echo Move the sound files you don't like to "delete" folder,
    echo and the sound files you do like to "keep" folder.
)

echo.
echo Press any key to close the program.
TIMEOUT -1 > NUL
EXIT /B 0





@REM Desc; Ask the user a Yes/No question
:AskBoolean
@REM Params; 1: Output variable, 2: Question string
set /P intBoolean= "%~2 (Y/N): "
IF /I "%intBoolean%" == "y" (
    set /A %~1=1
) ELSE IF /I "%intBoolean%" == "n" (
    set /A %~1=0
) ELSE (
    echo    "%intBoolean%" is not a valid input.
    echo.
    CALL :AskBoolean booleanRetry "%~2"
    set /A %~1=!booleanRetry!
)
EXIT /B 0

@REM Desc; Asks the user a number question
:AskNumber
@REM Params; 1: Output variable, 2: Min, 3: Max, 4: Default
set /P intNumber= "Press ENTER for %~4. (%~2-%~3): "
IF "!intNumber!" == "" (
    set /A %~1=%~4
) ELSE IF /I !intNumber! LSS %2 (
    echo    "!intNumber!" is too small. Value set to %~2.
    echo.
    set /A %~1=%~2
) ELSE IF /I !intNumber! GTR %~3 (
    echo    "!intNumber!" is too large. Value set to %~3.
    echo.
    set /A %~1=%~3
) ELSE (
    set /A %~1=!intNumber!
)
echo.
EXIT /B 0

@REM Desc; Asks the user for a string
:AskString
@REM Params; 1: Output variable, 2: Question string
set /P intString= "%~2: "
IF "!intString!" == "" (
    echo Invalid input.
    CALL :AskString stringRetry "%~2"
    set %~1=!stringRetry!
) ELSE (
    CALL :AskBoolean isVanted "Is "%intString%" correct?"
    IF !isVanted! EQU 1 (
        set %~1=%intString%
    ) ELSE (
        CALL :AskString stringRetry "%~2"
        set %~1=!stringRetry!
    )
)
EXIT /B 0

@REM Desc; Asks the user to type a file path
:InputFilePath
@REM Params; 1: File name, 2: Output variable, 3: Allow any file
set /P intPath= "Please give path to %~nx1 file: "
IF "%~3" EQU "1" (
    set %~2=%intPath%
) ELSE (
    set %~2="%intPath%\%~1"
)
EXIT /B 0

@REM Desc; Asks the user to select a file with the windows file exporer
:DialogFilePath
@REM Params; 1: File name, 2: Output variable, 3: Allow any file
echo Please give path to %~nx1 file:
TIMEOUT 1 > NUL
FOR /F "delims=" %%i IN ('%FileSelectDialog%') DO (
    IF "%~3" EQU "1" (
        set intPath=%%i
    ) ELSE (
        set "intPath=%%~dpi"
    )
)
IF "!intPath!" == "" (
    CALL :Sleep 5 "File selection cancelled. Opening select dialog again in 5 seconds." "Opening file select dialog..."
    CALL :DialogFilePath %~nx1 fileRetry %~3
    set intPath=!fileRetry!
)
IF "%~3" EQU "1" (
    set %~2=!intPath!
) ELSE (
    set %~2=%intPath%%~1
)
EXIT /B 0

@REM Desc; Asks user for file
:AskFilePath
@REM Params; 1: File name, 2: Output variable, 3: Allow any file
IF %UI% EQU 1 (
    CALL :DialogFilePath %~nx1 filePath %~3
) ELSE (
    CALL :InputFilePath %~nx1 filePath %~3
)
set %~2=!filePath!
EXIT /B 0

@REM Desc; Searches project directory for the file, if not found, asks the user
:GetFile
@REM Params; 1: File name, 2: Output variable
IF EXIST %~1 (
    echo Found %~nx1 file from
    echo    %~dpnx1
    echo.
    set %~2=%~dpnx1
) ELSE (
    echo Could not find %~nx1 file from
    echo    %~dp1
    echo.

    CALL :AskFilePath %~nx1 filePath
    CALL :GetFile !filePath! pathRetry
    set %~2=!pathRetry!
)
EXIT /B 0



@REM Desc; Creates a folder to the project directory
:MakeFolder
@REM Params; 1: Folder name
IF NOT EXIST %~dpn1 MD %~n1
EXIT /B 0

@REM Desc; Removes a folder from the project directory
:RemoveFolder
@REM Params; 2: Folder name
IF EXIST %~f1 RMDIR /S /Q %~f1
EXIT /B 0

@REM Desc; Sleeps for a given amount, displaying a updating message 
:Sleep
@REM Params; 1: Duration, 2: Start message, 3: End message
echo %~2
FOR /F %%a IN ('copy /Z "%~dpf0" nul') DO set "CR=%%a"
FOR /L %%s IN (%~1, -1, 1) DO (
    <nul set /p"=Continue in %%s... !CR!"
    TIMEOUT 1 > nul
)
<nul set /p"=%~3"
echo .
EXIT /B 0

@REM Desc; Adds spacing to the start of a value so it has a given length
:NormalizeLength
@REM Params; 1: Length, 2: Value, 3: Return value
set /A length=%~1 
set extraLongString="                                                         %~2"
set quotelessString=%extraLongString:"=%
CALL set normalizedString=%%quotelessString:~-%length%%%
set %~3=%normalizedString%
EXIT /B 0

@REM Desc; removes path & file extension from file name
:CleanFileName
@REM Params; 1: File path/name, 2: Putput variable
FOR /F "tokens=1 delims=." %%l IN ("%~n1") DO set %~2=%%l
EXIT /B 0





@REM Desc; Manages the .wem to .ogg conversion process flow
:RunWemConverter
@REM Params; 1: Thread number, 2: ww2ogg.exe path, 3: revorb.exe path
echo Starting .wem to .ogg conversion...
CALL :MakeFolder converted

set /A fileCount=0
set /A currentFile=0
set /A filesConverted=0
FOR %%x IN ("extracted\*.WEM") DO set /A fileCount+=1
FOR %%x IN ("converted\*.OGG") DO set /A filesConverted+=1

CALL :GetThreadSoring %~1 sortOrder
FOR /F %%f IN ('dir /B /O:%sortOrder% extracted^\*.WEM') DO (
    set /A currentFile+=1
    set operation=Skipping
    IF NOT EXIST converted^\%%~nf.ogg (
        set operation=Converting
        CALL :ExecuteConversion %~f2 %~f3 %%~dpfextracted\%%~nxf %%~dpfconverted\%%~nf.ogg
        set /A filesConverted+=1
    )
    set /A remaining = %fileCount%-!currentFile!
    CALL :PrintProgress !fileCount! !currentFile! !operation! %%~nxf

    IF "%sleepDurationPerMinute%" GTR "!time:~6,2!" CALL :Sleep %sleepDurationPerMinute% "Resting for %sleepDurationPerMinute% seconds..." "Resuming file conversion"
)
echo All files converted.
echo.
IF %~1 EQU 1 (
    EXIT /B 0
) ELSE (
    EXIT
)

@REM Desc; Calls ManageThread.bat with the correct parameters.
@REM       The call is done through another .bat file in order to hide console messages from ww2ogg & revorb
:ExecuteConversion
@REM Params; 1: ww2ogg.exe path, 2: revorb.exe path, 3: .wem souce path, 4: .ogg target path
START /LOW /MIN /WAIT "%~n3" ManageThread.bat %~f1 %~f2 %~f3 %~f4
EXIT /B 0

@REM Desc; Prints conversion progress message
:PrintProgress
@REM Params; 1: File count, 2: Current file, 3: Operation 4: File name
set /A remainingNumber = %~1-%~2
set /A remainingPercentage = (%~2 * 100) / %~1
CALL :NormalizeLength 5 "%remainingNumber%" remainingString
CALL :NormalizeLength 5 "%~2" currentString
CALL :NormalizeLength 3 "%remainingPercentage%" currentPercentage
CALL :NormalizeLength 10 "%~3" currentOperation
echo %currentString%/%~1, %remainingString% remaining, !currentPercentage!%% complete. %currentOperation% %~4
EXIT /B 0

@REM Desc; Returns 'dir' file sorting parameter
:GetThreadSoring
@REM Params; 1: Thread number, 2: Output variable
set /A sortMode = %~1 %% 6
IF %sortMode% EQU 1 SET %~2=-N
IF %sortMode% EQU 2 SET %~2=-S
IF %sortMode% EQU 3 SET %~2=-D
IF %sortMode% EQU 4 SET %~2=N
IF %sortMode% EQU 5 SET %~2=S
IF %sortMode% EQU 0 SET %~2=D
EXIT /B 0

@REM Desc; Deletes .ogg.tmp files which might get left behind during conversion
:CleanTemps
@REM Params; none
set /A filesToDelete = 0
FOR %%x IN ("converted\*TMP") DO set /A filesToDelete+=1
IF !filesToDelete! GTR 0 DEL "converted\*.TMP"
echo Cleaned %filesToDelete% .tmp files.
EXIT /B 0





@REM Desc; Manages extracting .wem files with QuickBMS
:Extract
@REM Params; 1: QuickBMS executable path, 2: QuickBMS sript path, 3: .pak file path, 4: Output folder path
CALL :MakeFolder extracted
echo Launching QuickBMS...
echo %pakFileEncryptionKey% > %tempKeyFileName%
%~f1 -o %~f2 %~f3 %~dp4 <%tempKeyFileName%
DEL %tempKeyFileName%
echo.
echo QuickBMS has completed the extraction.
echo.
EXIT /B 0





@REM Desc; Directs process flow to remove sound files from the .pak
:RunPackaging
@REM Params; none
echo Are the voice lines you want to remove in the "delete" folder^?
echo If so, good. Lets begin.
echo.
TIMEOUT 3 > NUL

CALL :GetFile "quickbms_4gb_files.exe" qbmsFilePath 
CALL :GetFile "unreal_tournament_4.bms" scriptFilePath

CALL :GetPrimarySourceFile sourceFile sourceFromGame

CALL :CreateBackups !sourceFile! !sourceFromGame!
CALL :RemoveFolder %tempDummyFolderName%
CALL :MakeFolder %tempDummyFolderName%
FOR %%f IN ("delete\*OGG") DO COPY NUL "%tempDummyFolderName%\%%~nf.wem" > nul
CALL :Package %qbmsFilePath% %scriptFilePath% !sourceFile! %tempDummyFolderName%
CALL :RemoveFolder %tempDummyFolderName%

CALL :PrintPackagingEndTutorial !sourceFromGame! !sourceFile!
EXIT /B 0

@REM Desc; Tells the user what to do after the .pak has been modified
:PrintPackagingEndTutorial
@REM Params; 1: Is .pak from game folder, 2: Used .pak file path 
IF %~1 EQU 1 (
    echo Your game has been automatically patched.
    echo Launch the game and see if the voice lines you chose have been removed. 
) ELSE (
    echo Please copy "pakchunk3-WindowsNoEditor.pak" from
    echo    %~dpn2.pak
    echo to your Borderlands 3 installation location.
    echo In case you already forgot, the folder structure looks something like this:
    echo    ...\OakGame\Content\Paks\
)
EXIT /B 0

@REM Desc; Searches for the .pak file most likely not already modified,
@REM       and whether or not it's in the game's directory
:GetPrimarySourceFile
@REM Params; 1: Source file output, 2: Is from game directory output

@REM ToDo: Ask user if they'd like a clean start or modify existing mods.
@REM       If clean start, use .pak_ORIGINAL, if modify, use existing .pak
@REM       This probably requires removing autoLoading of .pak files in places

set sourceFile=""
set /A targetPresent = 0
set /A originalPresent = 0
IF EXIST "pakchunk3-WindowsNoEditor.pak" (
    set /A targetPresent = 1
    set sourceFile="pakchunk3-WindowsNoEditor.pak"
)
IF EXIST "pakchunk3-WindowsNoEditor.pak_ORIGINAL" (
    set /A originalPresent = 1
    set sourceFile="pakchunk3-WindowsNoEditor.pak_ORIGINAL"
)
IF !targetPresent! EQU 0 IF !originalPresent! EQU 0 (
    CALL :GetFile "pakchunk3-WindowsNoEditor.pak" externalPath
    CALL :GetCleanerSourceFile !externalPath! primarySourcePath
    set sourceFile=!primarySourcePath!
)
echo.!sourceFile! | findstr /C:"OakGame\Content\Paks">NUL && (set /A sourceFromGame=1) || (set /A sourceFromGame=0) 
set %~1=!sourceFile!
set %~2=!sourceFromGame!
EXIT /B 0


@REM Desc; Selects .pak file most likely to be unmodified from available directories
:GetCleanerSourceFile
@REM Params; 1: File path to .pak file outside of project directory, 2: Output variable
IF EXIST %~dpn1.pak_ORIGINAL (
    set %~2=%~dpn1.pak_ORIGINAL
) ELSE IF EXIST %~dpnx1 (
    set %~2=%~dpnx1
) ELSE (
    set %~2=""
)
EXIT /B 0

@REM Desc; Creates backups of the original .pak file to .pak's & project's directories
:CreateBackups
@REM Params; 1: Used .pak file path, 2: Does path point to game directory
echo Creating backups...
echo NOTE: This will override all "pakchunk3-WindowsNoEditor.pak" files.
                                 COPY /D /Y %~dpnx1 /B %~dpn1.pak          /B > NUL
IF NOT EXIST %~dpn1.pak_ORIGINAL COPY /D /Y %~dpnx1 /B %~dpn1.pak_ORIGINAL /B > NUL
IF %~2 EQU 0                     COPY /D /Y %~dpnx1 /B   %~n1.pak          /B > NUL
IF NOT EXIST   %~n1.pak_ORIGINAL COPY /D /Y %~dpnx1 /B   %~n1.pak_ORIGINAL /B > NUL
echo Backups done.
echo.
EXIT /B 0





@REM Desc; Manages packaging removed .wem files into the .pak file using QuickBMS
:Package
@REM Params; 1: QuickBMS executable path, 2: QuickBMS script path, 3: Used .pak file path, 4: Temporary dummy file folder name
echo Launching QuickBMS...
echo %pakFileEncryptionKey% > %tempKeyFileName%
%~f1 -o -w -r %~f2 %~f3 %~f4 <%tempKeyFileName%
DEL %tempKeyFileName%
echo.
echo QuickBMS has completed the packaging.
echo.
EXIT /B 0





@REM Desc; Saves file names in "delete" folder into a .txt file.
:Serialize
@REM Params; none
echo With this utility you can save the files you've removed from the .pak file into a .txt text file.
echo This way you can easily backup ^& share your selections with other people.
echo.

@REM ToDo: Ask if user wants to save delete and/or keep files
@REM       Only count files of wanted selection
@REM       If neither, abort

set /A filesPresent = 0
FOR %%f IN ("delete\*.*") DO set /A filesPresent+=1
FOR %%f IN ("keep\*.*") DO set /A filesPresent+=1
IF !filesPresent! EQU 0 (
    echo No files detected in "delete" or "keep" folders.
    echo Cannot create selection save files from nothing.
    echo.
    CALL :AskBoolean loadInstead "Would you like to load a selection save file instead?"
    IF !loadInstead! EQU 1 (
        CALL :DeSerialize
    ) ELSE (
        echo Remember to run Extract.bat first to unpack the sound files.
    )
    EXIT /B 0
)

echo Have you moved the .ogg files you want to remove to the "delete" folder,
CALL :AskBoolean hasRemoved "and the ones you want to keep to the "keep" folder?"
IF %hasRemoved% EQU 0 (
    echo.
    echo Since you haven't sorted the files you want to remove or keep yet,
    echo please run Extract.bat to extract ^& convert the sound files from pakchunk3-WindowsNoEditor.pak.
    echo Sound files need to be present in the "delete" and/or "keep" folders.
    EXIT /B 0
)

CALL :AskString receivedName "What would you like to call the save file?"
CALL :CleanFileName %receivedName% outputName
set outputFile=!outputName!.bl3as.txt

set /A toDelete = 0
set /A toKeep = 0

echo [delete]> %outputFile%
FOR %%d IN ("delete\*.*") DO (
    set /A toDelete+=1
    echo %%~nd>> %outputFile%
)
echo.>> %outputFile%
echo [keep]>> %outputFile%
for %%k IN ("keep\*.*") DO (
    set /A toKeep+=1
    echo %%~nk>> %outputFile%
)

echo.
echo File configuration saved to %outputFile%.
echo !toDelete! files to remove, !toKeep! files to keep.
EXIT /B 0


@REM Resc; Patches .pak as instructed in serialized file
:DeSerialize
@REM Params; none
CALL :AskFilePath ".bl3as.txt" serializedFilePath 1
CALL :CleanFileName %serializedFilePath% selectedFileName
CALL :AskBoolean doRemove "Would you like to remove sounds specified in "%selectedFileName%"?"
CALL :AskBoolean doKeep "Would you like to include sounds specified in "%selectedFileName%"?"

IF %doRemove% EQU 0 IF %doKeep% EQU 0 (
    echo It seems you don't want to do anything. Have a nice day.
    EXIT /B 0
)


CALL :GetFile "quickbms_4gb_files.exe" qbmsFilePath 
CALL :GetFile "unreal_tournament_4.bms" scriptFilePath
CALL :GetPrimarySourceFile sourceFile sourceFromGame

CALL :CreateBackups !sourceFile! !sourceFromGame!
CALL :RemoveFolder %tempDummyFolderName%
CALL :MakeFolder %tempDummyFolderName%

set selectMode = ""
set /A filesNotFound = 0
FOR /F "tokens=*" %%l IN (%serializedFilePath%) DO (
    IF /I "%%l" == "[delete]" set selectMode=delete
    IF /I "%%l" == "[keep]" set selectMode=keep
    IF NOT "%%l" == "" IF /I NOT "%%l" == "[delete]" IF /I NOT "%%l" == "[keep]" (
        IF "!selectMode!" == "delete" IF %doRemove% EQU 1 COPY NUL "%tempDummyFolderName%\%%l.wem" > NUL
        IF "!selectMode!" == "keep" IF %doKeep% EQU 1 (
            IF EXIST extracted^\%%l.wem (
                COPY extracted^\%%l.wem "%tempDummyFolderName%\%%l.wem" > NUL
            ) ELSE (
                echo %%l.wem not found in folder "extracted". Cannot include it in the patch.
                set /A filesNotFound+=1
            )
        )        
    )
)

CALL :Package %qbmsFilePath% %scriptFilePath% !sourceFile! %tempDummyFolderName%
CALL :RemoveFolder %tempDummyFolderName%

CALL :PrintPackagingEndTutorial !sourceFromGame! !sourceFile!

EXIT /B 0




EndLocal