@echo off
set name=forth
set fasmdir=D:\programs\tools\fasm
set include=%fasmdir%\INCLUDE

del /Q %name%.exe 2>nul
del /Q %name%.sym 2>nul
%fasmdir%\FASM.EXE %name%.asm -s %name%.sym
del /Q %name%.udd 2>nul
del /Q %name%.lst 2>nul
rem %fasmdir%\LISTING.EXE -a -b 8 %name%.sym %name%.lst
%fasmdir%\LISTING.EXE -b 8 %name%.sym %name%.lst
del /Q %name%.pre 2>nul
%fasmdir%\PREPSRC.EXE %name%.sym %name%.pre
del /Q %name%.sym 2>nul
