' launch-nsh.vbs — Launches mintty with nsh, with the correct MSYS2 environment.
' This script lives in {app} (one level above bin\).
' wscript.exe is a GUI host so no console window flashes.

Dim appDir, wsh, env, mintty, nsh_exe

' Derive {app}\ from this script's own path.
appDir = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))

Set wsh = CreateObject("WScript.Shell")
Set env = wsh.Environment("Process")

' Tell the MSYS2 runtime it is running inside mintty so it does not
' auto-spawn a second terminal window, and use MSYS2 drive mount style
' (/c, /d, ...) instead of Cygwin-style (/cygdrive/c, /cygdrive/d, ...).
env("MSYSTEM") = "MSYS"
env("MSYSCON") = "mintty"

mintty  = appDir & "bin\mintty.exe"
nsh_exe = appDir & "bin\nsh.exe"

' Window style 1 = normal; False = do not wait for the process to finish.
wsh.Run """" & mintty & """ --title nsh -e """ & nsh_exe & """", 1, False
