Set WshShell = WScript.CreateObject("WScript.Shell")
WshShell.Run "dnsforwarder.exe", 0, False
Set WshShell = Nothing