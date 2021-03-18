@echo off
SetLocal EnableDelayedExpansion

set tempDummyFolderName=temp
set tempKeyFileName=tempKey.txt
set pakFileEncryptionKey=0x115EE4F8C625C792F37A503308048E79726E512F0BF8D2AD7C4C87BC5947CBA7
set /A sleepDurationPerMinute = 10

@REM Magical File explorer variable!
set FileSelectDialog=powershell -noprofile -command "&{[System.Reflection.Assembly]::LoadWithPartialName('System.windows.forms') | Out-Null;$OpenFileDialog = New-Object System.Windows.Forms.OpenFileDialog; $OpenFileDialog.ShowDialog()|Out-Null; $OpenFileDialog.FileName}"



:Main
@REM Params; 1: mode "package" | "convert"
@REM Mode: "package"; 2: Thread number, 3: ww2ogg.exe path, 4: revorb.exe path
@REM if paramX == "-sleep", then paramX+1 == sleep duration 
CALL :SetUI %1 %2 %3
CALL :SetSleepDuration %1 %2 %3 %4 %5 %6 %7

IF "%1" == "package" (
    CALL :RunPackaging
    EXIT /B 0
)
IF "%1" == "convert" (
    CALL :RunWemConverter %2 %3 %4
    EXIT /B 0
)
CALL :ExtractAndConvert
EXIT /B 0

:SetUI
@REM The "UI" variable set in this function is to be used globally.
@REM 0 = Only command prompt, 1 = Windows file explorer for selecting files & folders
set /A UI=1
IF /I "%~1" == "-noUI" set /A UI=0
IF /I "%~2" == "-noUI" set /A UI=0
IF /I "%~3" == "-noUI" set /A UI=0
EXIT /B 0

:SetSleepDuration
@REM Sets the "sleepDurationPerMinute" variable to be used globally.
IF /I "%~1" == "-sleep" set /A sleepDurationPerMinute=%~2
IF /I "%~2" == "-sleep" set /A sleepDurationPerMinute=%~3
IF /I "%~3" == "-sleep" set /A sleepDurationPerMinute=%~4
IF /I "%~4" == "-sleep" set /A sleepDurationPerMinute=%~5
IF /I "%~5" == "-sleep" set /A sleepDurationPerMinute=%~6
IF /I "%~6" == "-sleep" set /A sleepDurationPerMinute=%~7
@REM This technique is very sophisticated, I know.
EXIT /B 0

:ExtractAndConvert
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
)
echo Press any key to close the program.
TIMEOUT -1 > NUL
EXIT /B 0





@REM intVariable is shorthand for internal variable
:AskBoolean
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

:AskNumber
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

:AskFilePath
set /P intPath= "Please give path to %~nx1 file: "
set %~2="%intPath%\%~1"
EXIT /B 0

:DialogFilePath
echo Please give path to %~nx1 file:
TIMEOUT 1 > NUL
FOR /F "delims=" %%i IN ('%FileSelectDialog%') DO set "intPath=%%~dpi"
set %~2="%intPath%%~1"
EXIT /B 0

:GetFile
IF EXIST %~1 (
    echo Found %~nx1 file from
    echo    %~dpnx1
    echo.
    set %~2=%~dpnx1
) ELSE (
    echo Could not find %~nx1 file from
    echo    %~dp1
    echo.

    IF %UI% EQU 1 (
        CALL :DialogFilePath %~nx1 filePath
    ) ELSE (
        CALL :AskFilePath %~nx1 filePath
    )
    CALL :GetFile !filePath! pathRetry
    set %~2=!pathRetry!
)
EXIT /B 0

:MakeFolder
IF NOT EXIST %~dpn1 MD %~n1
EXIT /B 0

:RemoveFolder
IF EXIST %~f1 RMDIR /S /Q %~f1
EXIT /B 0

:Sleep
echo %~2
FOR /F %%a IN ('copy /Z "%~dpf0" nul') DO set "CR=%%a"
FOR /L %%s IN (%~1, -1, 1) DO (
    <nul set /p"=Continue in %%s... !CR!"
    TIMEOUT 1 > nul
)
<nul set /p"=%~3"
echo .
EXIT /B 0



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
    @REM echo !currentFile!/%fileCount%, !remaining! remaining.   !operation:"=! %%~nxf
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

:ExecuteConversion
@REM Params; 1: ww2ogg.exe path, 2: revorb.exe path, 3: .wem souce path, 4: .ogg target path
START /LOW /MIN /WAIT "%~n3" ManageThread.bat %~f1 %~f2 %~f3 %~f4
EXIT /B 0

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

:NormalizeLength
@REM Params; 1: Length, 2: Value, 3: Return value
set /A length=%~1 
set extraLongString="                                                         %~2"
set quotelessString=%extraLongString:"=%
CALL set normalizedString=%%quotelessString:~-%length%%%
set %~3=%normalizedString%
EXIT /B 0

:GetThreadSoring
set /A sortMode = %~1 %% 6
IF %sortMode% EQU 1 SET %~2=-N
IF %sortMode% EQU 2 SET %~2=-S
IF %sortMode% EQU 3 SET %~2=-D
IF %sortMode% EQU 4 SET %~2=N
IF %sortMode% EQU 5 SET %~2=S
IF %sortMode% EQU 0 SET %~2=D
EXIT /B 0

:CleanTemps
set /A filesToDelete = 0
FOR %%x IN ("converted\*TMP") DO set /A filesToDelete+=1
IF !filesToDelete! GTR 0 DEL "converted\*.TMP"
echo Cleaned %filesToDelete% .tmp files.
EXIT /B 0



:Extract
CALL :MakeFolder extracted
echo Launching QuickBMS...
echo %pakFileEncryptionKey% > %tempKeyFileName%
%~f1 -o %~f2 %~f3 %~dp4 <%tempKeyFileName%
DEL %tempKeyFileName%
echo.
echo QuickBMS has completed the extraction.
echo.
EXIT /B 0



:RunPackaging
echo Are the voice lines you want to remove in the "delete" folder^?
echo If so, good. Lets begin.
echo.
TIMEOUT 3 > NUL

CALL :GetFile "quickbms_4gb_files.exe" qbmsFilePath 
CALL :GetFile "unreal_tournament_4.bms" scriptFilePath

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
    CALL :GetPrimarySourceFile !externalPath! primarySourcePath
    set sourceFile=!primarySourcePath!
)
echo.!sourceFile! | findstr /C:"OakGame\Content\Paks">NUL && (set /A sourceFromGame=1) || (set /A sourceFromGame=0) 

CALL :CreateBackups !sourceFile! !sourceFromGame!
CALL :MakeFolder %tempDummyFolderName%
FOR %%f IN ("delete\*OGG") DO COPY NUL "%tempDummyFolderName%\%%~nf.wem" > nul
CALL :Package %qbmsFilePath% %scriptFilePath% !sourceFile! %tempDummyFolderName%
CALL :RemoveFolder %tempDummyFolderName%

CALL :PrintEndTutorial !sourceFromGame! !sourceFile!
EXIT /B 0

:PrintEndTutorial
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

:GetPrimarySourceFile
IF EXIST %~dpn1.pak_ORIGINAL (
    set %~2=%~dpn1.pak_ORIGINAL
) ELSE IF EXIST %~dpnx1 (
    set %~2=%~dpnx1
) ELSE (
    set %~2=""
)
EXIT /B 0

:CreateBackups
echo Creating backups...
echo NOTE: This will override all "pakchunk3-WindowsNoEditor.pak" files.
                                 COPY /D /Y %~dpnx1 /B %~dpn1.pak          /B > NUL
IF NOT EXIST %~dpn1.pak_ORIGINAL COPY /D /Y %~dpnx1 /B %~dpn1.pak_ORIGINAL /B > NUL
IF %~2 EQU 0                     COPY /D /Y %~dpnx1 /B   %~n1.pak          /B > NUL
IF NOT EXIST   %~n1.pak_ORIGINAL COPY /D /Y %~dpnx1 /B   %~n1.pak_ORIGINAL /B > NUL
echo Backups done.
echo.
EXIT /B 0


:Package
echo Launching QuickBMS...
echo %pakFileEncryptionKey% > %tempKeyFileName%
%~f1 -o -w -r %~f2 %~f3 %~f4 <%tempKeyFileName%
DEL %tempKeyFileName%
echo.
echo QuickBMS has completed the packaging.
echo.
EXIT /B 0

EndLocal