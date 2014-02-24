@echo off
:: bl.exe and pegar.lua are in the Bonaluna project created by Christophe Delord
:: Bonaluna project website: http://cdsoft.fr/bl/bonaluna.html
:: -- License of Bonaluna --
:: Copyright (C) 2010-2014 Christophe Delord, CDSoft.fr
:: Freely available under the terms of the Lua license
:: -------------------------
echo start to create tcpdns.exe
echo;
bl.exe pegar.lua read:bl.exe lua:../tcpdns.lua write:tcpdns.exe
echo;
echo please wait...
echo finished!
pause