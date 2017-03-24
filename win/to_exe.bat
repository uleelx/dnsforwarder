@echo off
:: bl.exe is in the Bonaluna project created by Christophe Delord
:: Bonaluna project website: http://cdsoft.fr/bl/bonaluna.html
:: -- License of Bonaluna --
:: Copyright (C) 2010-2016 Christophe Delord, CDSoft.fr
:: Freely available under the terms of the Lua license
:: -------------------------
echo start to create dnsforwarder.exe, it may take a second time...
bl.exe -e "Pegar().read('bl.exe').lua('../task.lua').lua('../dnsforwarder.lua').write('dnsforwarder.exe')"
echo;
echo finished!
pause
