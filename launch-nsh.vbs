' launch-nsh.vbs — Launches mintty with nsh, with the correct MSYS2 environment.
' This script lives in {app} (one level above bin\).
' wscript.exe is a GUI host so no console window flashes.

Dim appDir, wsh, env, mintty, nsh_exe, userProfile, homeDir

' Derive {app}\ from this script's own path.
appDir = Left(WScript.ScriptFullName, InStrRev(WScript.ScriptFullName, "\"))

Set wsh = CreateObject("WScript.Shell")
Set env = wsh.Environment("Process")

' Convert the Windows user profile path (e.g. C:\Users\foo) to an MSYS2
' POSIX path (e.g. /c/Users/foo) so $HOME resolves to a directory that
' actually exists on disk and SQLite can create the history database there.
userProfile = env("USERPROFILE")
homeDir = "/" & LCase(Left(userProfile, 1)) & Mid(Replace(userProfile, "\", "/"), 3)

env("MSYSTEM") = "MSYS"
env("MSYSCON") = "mintty"
env("HOME")    = homeDir

' disable_pcon stops the MSYS2 runtime from using Windows ConPTY and falling
' back to spawning a second mintty window when it cannot detect a Cygwin pty.
env("MSYS")    = "disable_pcon"

mintty  = appDir & "bin\mintty.exe"
nsh_exe = appDir & "bin\nsh.exe"

' Start mintty in the user's home directory, not System32.
wsh.CurrentDirectory = userProfile

' Window style 1 = normal; False = do not wait for the process to finish.
wsh.Run """" & mintty & """ --title nsh -e """ & nsh_exe & """", 1, False
