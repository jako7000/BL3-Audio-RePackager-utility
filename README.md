# BL3-Audio-RePackager-utility
A batch file for extracting &amp; injecting audio files from Brolderlands 3 .pak files.

## Requirements
This .bat file utilizes several differend programs.
1. QuickBMS for extracting & packaging Borderlands'.pak files.
	Website: http://aluigi.altervista.org/quickbms.htm
	Direct download: http://aluigi.altervista.org/papers/quickbms.zip
2. unreal_tournament_4.bms script file for QuickBMS to use.
	Website: http://aluigi.altervista.org/quickbms.htm
	Direct download: http://aluigi.altervista.org/bms/unreal_tournament_4.bms
3. ww2ogg for converting .wem files to .ogg files.
	GitHub: https://github.com/hcs64/ww2ogg
	Direct download: https://github.com/hcs64/ww2ogg/releases/download/0.24/ww2ogg024.zip
4.  revorb for compressing (& perhaps fixing) the converted .ogg files.
	Website: --
	Direct download: https://cloudflare-ipfs.com/ipfs/QmVgjfU7qgPEtANatrfh7VQJby9t1ojrTbN7X8Ei4djF4e/revorb.exe

## Usage
#### Extracting .ogg files
1. Download all the listed programs
1.1 Optional: Put them all in the same folder with the Extract.bat ([image example](https://i.imgur.com/ZDdMtIX.png "All required files in the same folder"))
1.1.1 ww2ogg requires the `packed_codebooks_aoTuV_603.bin` file, which comes with it.
Make sure it's in the same folder with ww2ogg.exe
1.2 Optional: Also copy the `pakchunk3-WindowsNoEditor.pak` file from `..\OakGame\Content\Paks\`
2. Double click the Extract.bat file.
3. Answer `Y` & `Y` to the questions to extract & convert audio files.
3.1 The program will ask locations for the required files if they aren't located in the same folder with the Extract.bat
4. Input the number of .wem -> .ogg conversions running at the same time.
The `pakchunk3-WindowsNoEditor.pak` contains 35 000 audio files, and converting them all will take a while. Recommended number of conversions is 3. 6 requires *some* beef from the CPU. I don't know what kind of a beast of a CPU you'll need to **efficiently** run 9 at the same time.
5.  Wait for the program to complete extraction.
5.1 If you interrupt the extraction process, it will start from the beginnig next time.
6. Wait for the program to complete conversion.
6.1 This process can be interrupted at any time, no data will be lost.
Simply close the window(s). 
6.2 Depending on how many concurrent conversions you selected earlier, the program will open new windows to run alongside it.
6.3 Your computer might become unresponsive during the conversion process.
The conversion will stop for 10 seconds every minute, during which the system should briefly become responsive, allowing you to stop the process.
7. Converted files can be found in the "converted" folder.
