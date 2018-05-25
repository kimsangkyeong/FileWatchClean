Set objShell = CreateObject("Shell.Application")
Set FSO = CreateObject("Scripting.FileSystemObject")
objShell.ShellExecute "C:\FileWatchClean.bat " , "c:\temp2 10 5", "", "runas", 0
