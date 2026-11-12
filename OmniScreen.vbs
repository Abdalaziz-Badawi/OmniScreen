Set WshShell = CreateObject("WScript.Shell")
Set fso = CreateObject("Scripting.FileSystemObject")
ScriptDir = fso.GetParentFolderName(WScript.ScriptFullName)
MainScript = ScriptDir & "\app\Main.ps1"

Cmd = "powershell.exe -NoProfile -ExecutionPolicy Bypass -STA -File """ & MainScript & """"
WshShell.Run Cmd, 0, False
