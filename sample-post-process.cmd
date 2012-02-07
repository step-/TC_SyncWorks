@echo off
setlocal

rem --- Autohotkey exports the following right-side variables ---
set NewDirList=%DirListFile%
set Lfls=%LeftSourcesListFile%
set Rfls=%RightSourcesListFile%
for /F "tokens=*" %%i in ('type "%LeftDestinationDirListFile%"') do set Ldir=%%i
for /F "tokens=*" %%i in ('type "%RightDestinationDirListFile%"') do set Rdir=%%i
set Sequ=%SequenceFile%
set Lhsh=%LeftSourcesHashFile%
set Rhsh=%RightSourcesHashFile%
set CallersDir=%ScriptDir%
set Caller=%ScriptName%
set Logging=%Logging%

rem --- Relative vs absolute paths ----
rem Ldir and Mdir are absolute paths as determined by TC.
rem All other exported paths may be relative or absolute
rem depending on their .ini file setting. Since %CD% is
rem Autohotkey's script's installation path, you can
rem convert a relative to absolute path this way, i.e.,
rem   rem DON'T CD before this line
rem   SET AbsLfls=%CD%\%Lfsl%
rem   rem add more SET commands here
rem   rem You may CD after this line

echo Caller's name: "%Caller%" located in "%CallersDir%"
if %Logging% == 0 (
  echo Caller has enabled logging
) else (
  echo Caller has disabled logging
)
echo.
echo Example of what this batch file could do:
echo.
echo Create all directories in "%NewDirList%"
echo Copy left to right all files in "%Lfls%" to directory "%Rdir%"
echo Copy right to left all files in "%Rfls%" to directory "%Ldir%"
echo The above dir/file operations according to sequence in "%Sequ%"
echo The hash file of left sources is "%Lhsh%"
echo The hash file of right sources is "%Rhsh%"
echo.
echo Done.
echo.
echo Press any key to exit.
pause>nul
endlocal
