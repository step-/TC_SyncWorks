; ////////////////////////////////////////////////////////////////////////////
; // TC_SyncWorks.ahkl 0.21 build 20121221
; // http://ghisler.ch/board/viewtopic.php?p=241083#241083
; // 
; // Extract cm_FileSync comparison results, calculate MD5 sums, run user's
; // post-processing script, which can implement custom functionality.
; //
; // Hotkeys: ^E(extract) ^R(reload) Pause(pause) ^Esc(unlock keyboard/mouse input)
; ////////////////////////////////////////////////////////////////////////////

#SingleInstance, Force
Version = %A_ScriptName% v.0.21 build 20121221

; get script filepathname stem, etc. {{{ , ScriptStem, ScriptName, ScriptDir
StringSplit, p, A_ScriptName, .
StringLeft, ScriptStem, A_ScriptFullPath, % StrLen(A_ScriptFullPath) - StrLen(p%p0%) -1
StringLeft, ScriptName, A_ScriptName, % StrLen(A_ScriptName) - StrLen(p%p0%) -1
ScriptDir = %A_ScriptDir%
; }}}
; ini file variables {{{ , nIni nUser nProg
nIni := ScriptStem . ".ini"
; sections
nUser = Preferences
nProg = Settings
; }}}
IniRead, ShowCancelBefore, %nIni%, %nUser%, ShowCancelBefore, 1
gosub GetHotkeys
gosub Greeting
; install ini and other files, NO destruct user's settings {{{
If( A_IsCompiled ) {
	; FileInstall, sample-config.ini, %nIni%, 0 ; non-destructive
	FileInstall, sample-config.ini, %A_ScriptDir%\sample-config.ini, 1 ; destructive
	FileInstall, sample-post-process.cmd, %A_ScriptDir%\sample-post-process.cmd, 1 ; destructive
	FileInstall, README.txt, %A_ScriptDir%\README.txt, 1
	FileInstall, regex.dat, %A_ScriptDir%\regex.dat, 1
}
; }}}
; includes {{{
#Include %A_ScriptDir%\Lib\
#Include mouse-cursor.inc.ahk
#Include block-mouse-keyboard.inc.ahk
#Include *i %A_ScriptDir%\Opt\
#Include *i opt-SaveAndReloadScript.inc.ahk
; }}}
Return

Greeting:
; {{{
If( ShowCancelBefore ) {
p =
(
%Version% - Instructions`n`nWith TC's Directory Synchronization tool open,
compare two folders then press [%HotkeyExtract%] to extract file lists,
compute MD5 sums, and run your post-processing script.

[%HotkeyExtract%] extract    [%HotkeyUnlock%] unlock    [%HotkeyPause%] pause    [%HotkeyReload%] reload
)
MsgBox, %p%
}
Return
; }}}
GetHotkeys:
; get hotkey preferences {{{
; !^# = Alt Ctrl Win
IniRead, HotkeyExtract, %nIni%, %nUser%, HotkeyExtract, ^E
IniRead, HotkeyPause, %nIni%, %nUser%, HotkeyPause, Pause
IniRead, HotkeyReload, %nIni%, %nUser%, HotkeyReload, ^R
IniRead, HotkeyUnlock, %nIni%, %nUser%, HotkeyUnlock, ^Esc
Hotkey, IfWinActive, ahk_class TCmpForm
Hotkey, %HotkeyExtract%, Extract
Hotkey, %HotkeyPause%, PauseMe
Hotkey, %HotkeyReload%, ReloadMe
Return
; }}}
EnableInput:
#Persistent
; press Ctrl+Esc to unblock keyboard and mouse input, LAlt+Tab is always active {{{
ToolTip, Timed Keyboard/mouse input restored.
SetTimer, RemoveToolTip, 1000
KillFocusHandler()
Return
; }}}
PauseMe:
; {{{
Pause
Return
; }}}
ReloadMe:
; {{{
RestoreCursors()
Reload
Return
; }}}
RemoveToolTip:
; {{{
SetTimer, RemoveToolTip, Off
ToolTip
Return
; }}}

/*
#IfWinActive, ahk_class TCmpForm
^R::Reload
Pause::Pause
^E::
gosub Extract
Return
*/

Extract:
; {{{
;OutputDebug, Started
hWndTCmpForm := WinExist("A")
if( 1 ) { ; UNSUPPORTED TC < 7.50 RC1 ~ TODO Return if version mismatch
	RestoreCursors() ; mouse pointer
	SetSystemCursor("IDC_AppStarting") ; mouse pointer
	; Date and time {{{ , DateTime YYYYMMDDHHMMSS
	DateTime := A_Now
	; }}}
	; get compared folder paths {{{ , LR RR \-terminated
	ControlGetText, LR, TAltEdit2, ahk_class TCmpForm ; left  root path
	ControlGetText, RR, TAltEdit1, ahk_class TCmpForm ; right root path
	; }}}
	; CONSTANTS
	; Windows messages {{{
	LB_SETCARETINDEX := 0x019E
	LB_GETCARETINDEX := 0x019F
	LB_GETTEXT := 0x0189
	; }}}

	; read program settings and user preferences {{{
	IniRead, Logging, %nIni%, %nProg%, Logging, 0
	IniRead, LogFile, %nIni%, %nProg%, LogFile, % A_ScriptDir  "\logfile-" DateTime ".log"
	IniRead, RegexFile, %nIni%, %nProg%, RegexFile, % A_ScriptDir "\regex.dat"

	gosub GetHotkeys
	IniRead, ShowCancelBefore, %nIni%, %nUser%, ShowCancelBefore, 1
	IniRead, ShowProgress, %nIni%, %nUser%, ShowProgress, 1
	IniRead, ShowOKAfter, %nIni%, %nUser%, ShowOKAfter, 1
	IniRead, DirListFile, %nIni%, %nUser%, DirListFile, new-directories.lst
	IniRead, LeftSourcesListFile, %nIni%, %nUser%, LeftSourcesListFile, left-sources.lst
	IniRead, RightDestinationDirListFile, %nIni%, %nUser%, RightDestinationDirListFile, right-destination.lst
	IniRead, RightSourcesListFile, %nIni%, %nUser%, RightSourcesListFile, right-sources.lst
	IniRead, LeftDestinationDirListFile, %nIni%, %nUser%, LeftDestinationDirListFile, left-destination.lst
	IniRead, SequenceFile, %nIni%, %nUser%, SequenceFile, sequence.csv
	IniRead, PostProcessScriptTemplate, %nIni%, %nUser%, PostProcessScriptTemplate, post-process.cmd
	IniRead, PostProcessCommand, %nIni%, %nUser%, PostProcessCommand, `%SystemRoot`%\system32\cmd.exe /c `"`%RunFile`%`"
	IniRead, PostProcessRunWait, %nIni%, %nUser%, PostProcessRunWait, 1
	IniRead, CalcHash, %nIni%, %nUser%, CalcHash, 1
	IniRead, HashType, %nIni%, %nUser%, HashType, md5
	IniRead, HashFormat, %nIni%, %nUser%, HashFormat,
	IniRead, LeftSourcesHashFile, %Ini%, %nUser%, LeftSourcesHashFile, % LR "__L_" DateTime "." HashType
	IniRead, RightSourcesHashFile, %Ini%, %nUser%, RightSourcesHashFile, % RR "__R_" DateTime "." HashType
	; }}}

	LogString =
	LogString(0, "[" LR "]    [" RR "]`n")
	; get sync list control ID - may quit {{{ , ControlID
	ControlGetFocus, ControlID, ahk_id %hWndTCmpForm%
	If( ControlID != "TbkGndListBox1" ) { ; shouldn't happen
		RestoreCursors()
		MsgBox, Please focus the file list in TC's Directory Synchronization window and try again.`n
		Return
	}
	; }}}
	; get ControlID's hwnd - may quit {{{ , hWndControlID
	VarSetCapacity(GuiThreadInfo, 48)
	NumPut(48, GuiThreadInfo, 0)
	if not DllCall("GetGUIThreadInfo", uint, 0, str, GuiThreadInfo) {
		MsgBox, GetGUIThreadInfo() failed
		ExitApp, 1
	}
	;p := A_FormatInteger
	;SetFormat, Integer, H
	hWndControlID := NumGet(GuiThreadInfo, 12)  ; Retrieve the hwndFocus field from the struct.
	;SetFormat, Integer, %p%
	; }}}
; ASSERT: all expandable symbols initialized
	; expand internal symbols and environment variables {{{
	; Instead of the symbol loop below we could use Transform, Deref, String which
	; unconditionally expands all internal variables in String.
	; Instead of the env var loop below we could use function ExpandEnvVars
	; which is commented-out at the bottom of this file.

  ; Match the next three lists with comments in .ini file
	ExpIniVars = DirListFile,LeftSourcesListFile,RightDestinationDirListFile,RightSourcesListFile,LeftDestinationDirListFile,LeftSourcesHashFile,RightSourcesHashFile,SequenceFile,RunFile,LogFile,RegexFile
	SymbolsInIni = LR,RR,DateTime,ScriptDir,ScriptName,HashType
	SymbolsInPostProcessTemplate = DirListFile,LeftSourcesListFile,RightDestinationDirListFile,RightSourcesListFile,LeftDestinationDirListFile,SequenceFile,LeftSourcesHashFile,RightSourcesHashFile,ScriptDir,ScriptName,Logging
	StringSplit, nam, ExpIniVars, `,
	Loop, %nam0% {
		name := nam%A_Index%
		StringSplit, sym, SymbolsInIni, `,
		Loop, %sym0% { ; expand Symbols {{{
			symbol := sym%A_Index%
			%name% := RegExReplace(%name%, "i)%" . symbol . "%", %symbol%)
;OutputDebug, % "symbol{" . symbol . "} " . name . "{" . %name% . "}"
		} ; }}}
		head =
		tail := %name%
		Loop { ; expand env vars {{{ TODO use ExpandEnvVars()
			If( RegExMatch(tail, "Pi)%(\S+?)%" , v) ) {
				varname := SubStr(tail, vPos1, vLen1)
				EnvGet, value, %varname%
				If( value>"" ) {
					head .= SubStr(tail, 1, vPos1-2) . value
				} Else {
					head .= SubStr(tail, 1, vPos1+vLen1)
				}
				tail := SubStr(tail, 1+vPos1+vLen1)
;OutputDebug, % "envvar{" . varname . "}={" . value . "} head-tail{" . head . "}{" . tail . "}"
			} Else {
				%name% := head . tail
				Break
			}
		} ; }}}
	}
	; }}}
	; prepare regex {{{
	FileRead, Regex, %RegexFile%
	If ErrorLevel {
		CleanUp()
		MsgBox, Can't load regex file `"%RegexFile%`" %A_LineNumber%
		ExitApp, 1
	}
	Regex := RegExReplace(Regex, "m)^\(\?", "", p, 1) ; convert PCRE option syntax
	; }}}
	; set file I/O {{{
	foDir  := FileOpen(DirListFile, "w")
	foSrcL := FileOpen(LeftSourcesListFile, "w")
	foSrcR := FileOpen(RightSourcesListFile, "w")
	foSeq  := FileOpen(SequenceFile, "w")
	If( Logging )
		foLog  := FileOpen(LogFile, "a")
	If( !foDir || !foSrcL || !foSrcR || !foSeq || Logging && !foLog ) {
		CleanUp() 
		MsgBox, File write failed %A_LineNumber%
		ExitApp, 1
	}
	; }}}
	Log(0, "=====`n" A_Now " start")
  ; set destination I/O {{{
  FileDelete, %LeftDestinationDirListFile%
  FileAppend, %LR%, %LeftDestinationDirListFile%
  FileDelete, %RightDestinationDirListFile%
  FileAppend, %RR%, %RightDestinationDirListFile%
  ; }}}
	; get panel cursor index {{{ , CursorIndex
	SendMessage, %LB_GETCARETINDEX%, 0, 0, %ControlID%
	CursorIndex := ErrorLevel
	; }}}

	VarSetCapacity(sRow, 8192, 0)
	; get index of top visible row {{{ , TopRowIndex
	i := CursorIndex
	sRow = x
	Loop {
		--i
		If( "" == sRow || i < 0 )
			Break
;OutputDebug, back %i%
		SendMessage, %LB_GETTEXT%, %i%, &sRow, %ControlID%
	}
	TopRowIndex := 1 + i
	; }}}
	; get listbox size {{{ , Max
	ControlGet, Subject, List, , %ControlID%
	Max = 0
	Loop, Parse, Subject, `n
		++Max
	; }}}
;OutputDebug, Max{%Max%} CursorIndex{%CursorIndex%} TopRowIndex{%TopRowIndex%}

	; return on Cancel button {{{
	If( ShowCancelBefore ) {
  	RestoreCursors() ; mouse pointer
		;task modal, question icon, OK/cancel 8192+32+1=8225
		MsgBox, 8225, , %Max% items found. Proceed?
		IfMsgBox Cancel
		{
			CleanUp()
			Return
		}
	}
	; }}}
	Time0Script := A_Now
	SetFocusHandler()
	; iterate reading panel {{{
	Base =
	DirOps = 0
	LSrcOps = 0
	RSrcOps = 0
	LSrcSiz = 0
	RSrcSiz = 0
	NoOps = 0

	SendMessage, %LB_SETCARETINDEX%, 0, 0, %ControlID%
;OutputDebug, set caret 0
	StartProgressBar(Max, 100, "Reading " Max " items...`n[" HotkeyUnlock "] unlock ["
	. HotkeyReload "] reload", "Extraction progress...")
	i = -1
	Loop { ; tested for Max = 999/1000/1001/1002/1999/2000/2001/2002/2100/3201
		Loop {
			If( ++i >= Max )
				Break
			SendMessage, %LB_GETTEXT%, %i%, &sRow, %ControlID%
			If( sRow>"" ) {
				If( iProgressBarNextGoal && i > iProgressBarNextGoal ) {
					p := i * 100 // Max ; fill progress bar up to 100% maximum
					Progress, %i%, %p% `%
					iProgressBarNextGoal += Max // 53 ; to 100% in 53 steps
				}
				; parse row {{{
				;mDir := mDirSame := mOff := mFileTo := mFileUnequal := mFile := mSize := mSizeRest := mFileR := mSizeR := mSizeRest := mFileR1 := mSizeR1 := mSizeRest1 := ""
				p := RegExMatch(sRow, Regex, m)
				If( ErrorLevel ) {
					MsgBox, %ErrorLevel% %A_LineNumber%
					CleanUp()
					Return
				}
;OutputDebug, i{%i%} mDir{%mDir%} mFileTo{%mFileTo%} mFile{%mFile%} mSize{%mSize%} mSizeRest{%mSizeRest%} mFileR{%mFileR%} mSizeR{%mSizeR%} mSizeRestR{%mSizeRestR%} mFileR1{%mFileR1%} mSizeR1{%mSizeR1%} mSizeRestR1{%mSizeRestR1%} mDirSame{%mDirSame%} mOff{%mOff%} mFileUnequal{%mFileUnequal%}
				If( mDir>"" ) {
					MkDir(A_LineNumber, mDirTo == "L to R" ? RR : LR, mDir) ; sets Base
				} Else If( mFile>"" ) {
					If( mFileTo == "L to R" ) {
						CpFileToR(A_LineNumber)
					} Else {
						CpFileToL(A_LineNumber, false)
					}
				} Else If( mFileR1>"" ) {
					CpFileToL(A_LineNumber, true)
				} Else If( mDirSame>"" ) {
					++NoOps ; TC uses "DIR EQ" for both unticked and equal dirs
					Base := mDirSame
				} Else If( mOff>"" || mFileUnequal>"" ) {
					++NoOps ; unticked file
				} Else {
					KillFocusHandler()
					MsgBox, Unhandled match %A_LineNumber% `n{%sRow%}`n`nPlease press Ctrl+C to copy this message to the clipboard, then paste it to a text file and attach the file to your bug report at http://ghisler.ch/board/viewtopic.php?p=241083
	OutputDebug, Unhandled match %A_LineNumber% `n{%sRow%}
					LogString(A_FileLine, "Unhandled match " . A_LineNumber . " {" . sRow . "}")
					CleanUp()
					Return
				}
				; }}}
			} Else {
				; scroll down {{{
				--i
				SendMessage, %LB_SETCARETINDEX%, %i%, 0, %ControlID%
;OutputDebug, set caret %i%
				Break
				; }}}
			}
		}
		If( i >= Max )
			Break
;OutputDebug, Outer %i%
	}
	StopProgressBar(Max)
	SendMessage, %LB_SETCARETINDEX%, %TopRowIndex%, 0, %ControlID%
;OutputDebug, set caret %TopRowIndex%, done reading panel.
	; }}}
	CleanUp(false)
	secExtract := A_Now - Time0Script ; {{{
	If( 0 >= secExtract)
		secExtract = 1 ; }}}
	LogString(0,"@ Extraction time " FmtTime(secExtract) " ~ "
	. Max " total items, " NoOps " unticked/no op`n"
	. "left: " LSrcOps " files = " CommaAdd(LSrcSiz) " bytes ~ "
	. "right: " RSrcOps " files = " CommaAdd(RSrcSiz) " bytes`n"
	. "new dirs: " DirOps "`n"
	. "`n")
	If( ShowOKAfter )
		MsgBox, %LogString%
	; optionally create MD5 digest files {{{
	If( CalcHash ) {
		p = 1
		If( ShowCancelBefore ) {
			;task modal, question icon, OK/cancel 8192+32+1=8225
			MsgBox, 8225, , Calculate MD5 sums ? (intensive)
			IfMsgBox Cancel
				p = 0
		}
		If( p ) {
			MaxFiles := LSrcOps+RSrcOps
			StartProgressBar(MaxFiles, 0, "Hashing " MaxFiles " files...`n[Pause] ["
			. HotkeyReload "] reload", "Hashing progress...")
			Time0Hash := A_Now
			HashFileList(LeftSourcesListFile, LeftSourcesHashFile, LR, MaxFiles)
			HashFileList(RightSourcesListFile,RightSourcesHashFile,RR, MaxFiles)
			secHash := A_Now - Time0Hash ; {{{
			If( 0 >= secHash)
				secHash = 1 ; }}}
			StopProgressBar(MaxFiles)
			LogString(0, "@ Hashing time " FmtTime(secHash) " ~ "
			. MaxFiles " files hashed"
			. "`n")
			If( ShowOKAfter )
				MsgBox, %LogString%
		}
	}
	; }}}
	; generate and run post-processing script {{{
	if( FileExist(PostProcessScriptTemplate) ) {
		RunFile := RegExReplace(PostProcessScriptTemplate, "^(.*?)(\.[^.]+)?$", "$1-run$2")
		FileRead, Template, %PostProcessScriptTemplate%
		; expand Symbols {{{
		StringSplit, sym, SymbolsInPostProcessTemplate, `,
		Loop, %sym0% {
			symbol := sym%A_Index%
			Template := RegExReplace(Template, "i)%" . symbol . "%", %symbol%)
		}
		; }}}
		StringReplace, PostProcessCommand, PostProcessCommand, `%RunFile`%, %RunFile%, All
		PostProcessCommand := ExpandEnvVars(PostProcessCommand)
		FileDelete, %RunFile%
		FileAppend, %Template%, %RunFile%
		p = 1
		If( ShowCancelBefore ) {
			;task modal, question icon, OK/cancel 8192+32+1=8225
			MsgBox, 8225, , File "%RunFile%" created.`nStart %PostProcessCommand% ?
			IfMsgBox Cancel
				p = 0
		}
		If( p ) {
			If( PostProcessRunWait ) {
				Time0PostProcess := A_Now
				RunWait, %PostProcessCommand%
				p := ErrorLevel
				secPostProcess := A_Now - Time0PostProcess ; {{{
				If( 0 >= secPostProcess)
					secPostProcess = 1 ; }}}
				LogString(0, "@ Post-processing time " FmtTime(secPostProcess) " ~ "
				. RunFile " returned " p
				. "`n")
			} Else {
				Run, %PostProcessCommand%
				LogString(0, RunFile " started"
				. "`n")
			}
		}
	}
	; }}}
	Log(0, LogString "`n" A_Now " end")
	LogString(0, "All done    [" HotkeyExtract "] extract again")
	If( ShowOKAfter )
		MsgBox, %LogString%
	CleanUp()
	Regex=
	sRow=
	LogString=
}
Return
; }}}

#IfWinActive

MkDir(aId, aRootPath, aDir="")
{ ; {{{
	global foDir, DirOps, Base = aDir
	If( aDir ) {
		p := aRootPath . Base
		foDir.WriteLine(p)
		Sequence(1,p)
		++DirOps
		Return
	}
	Return
} ; }}}
CpFileToR(aId)
{ ; {{{
	global LR, RR, Base, foSrcL, LSrcOps, LSrcSiz, mFile, mSize, mSizeRest, mFileR, mSizeR, mSizeRestR
	aSize := mSize
	if( mSizeRest>"" )
	{
	    src := mSizeRestR>"" ? A3(LR Base, false) : A2(LR Base)
	    if( "" == src )
			src := dst := Base . mFile
		else
		{
			aSize := mFile " " mSize " " mSizeRest
			StringReplace, aSize, aSize, %src%,
			src := dst := Base . src
		}
	}
	else{
		src := dst := Base . mFile
	}
;OutputDebug, src{%src%} aSize{%aSize%}
	aSize := RegExReplace(aSize,"\D+")
	foSrcL.WriteLine(src)
	Sequence(2, "", LR src, RR dst, aSize)
	++LSrcOps
	LSrcSiz += aSize
	Return
} ; }}}
A2(dir) ; return <longest existing mFile>`n<revised mSize> or ""
{ ; {{{
;ref bug-track\20121212-test-setup {{{
;line "L2R fileL 2 800 801 18.03.09" could mean
;name {L2R fileL} size {2 800 801} or
;name {L2R fileL 2} size {800 801} or
;name {L2R fileL 2 800} size {801} and is parsed as
;mSize {2} mSizeRest {800 801 } mFile {L2R fileL} + mSizeR, mSizeRestR, mFileR
;}}}

	global mSize, mSizeRest, mFile
	s := mSize
	r := Trim(RegExReplace(mSize . " " . mSizeRest, "\b\d+ $", ""))
	f := mFile
	take := f
	revlist := take
	Loop, Parse, r, %A_Space%
	{
		take := take " " A_LoopField
		revlist := Trim(take) "`n" revlist
	}
;OutputDebug, A2: mSize{%mSize%} mSizeRest{%mSizeRest%}`nr{%r%}`nrevlist{%revlist%}
	ret := ""
	Loop, Parse, revlist, `n
	{
		if( FileExist(dir A_LoopField) )
		{
			ret := A_LoopField
			break
		}
	}
	Return, ret
} ; }}}
CpFileToL(aId, bNoLeft)
{ ; {{{
	global LR, RR, Base, foSrcR, RSrcOps, RSrcSiz, mFile, mSize, mSizeRest
	if( bNoLeft )
	{	; when bNoLeft the regex names right-side matches as mFileR1, mSizeR1, etc.
		global mSizeR1, mSizeRestR1, mFileR1
		aSize := mSizeR1
		aSizeRest := mSizeRestR1
		aFile := mFileR1
	}
	else ; when !bNoLeft the regex names right-side matches as mFileR, mSizeR, etc.
	{
		global mSizeR, mSizeRestR, mFileR
		aSize := mSizeR
		aSizeRest := mSizeRestR
		aFile := mFileR

	}
	if( aSizeRest>"" ) {
	    src := A3(RR Base, bNoLeft)
	    if( "" == src )
			src := dst := Base . aFile
		else
		{
			aSize := aSize " " aSizeRest aFile
			StringReplace, aSize, aSize, %src%,
			src := dst := Base . src
		}
	} else
		src := dst := Base . aFile
;OutputDebug, bNoLeft{%bNoLeft%} src{%src%} aSize{%aSize%}
	aSize := RegExReplace(aSize,"\D+")
	foSrcR.WriteLine(src)
	Sequence(3, "", RR src, LR dst, aSize)
	++RSrcOps
	RSrcSiz += aSize
	Return
} ; }}}
A3(dir, bNoLeft) ; return <longest existing mFileR|mFileR1>`n<revised mSizeR|mSizeR1> or ""
{ ; {{{
;ref bug-track\20121212-test-setup {{{
;line "14:00:01 3 800 801 2 R2L fileR" could mean
;size {3} name {800 801 2 R2L fileR} or
;size {3 800} name {801 2 R2L fileR} or
;size {3 800 801} name {2 R2L fileR} or
;size {3 800 802 2} name {R2L fileR} and is parsed as
;mSizeR1 {3} mSizeRestR1 {800 801 2 } mFileR1 {R2L fileR}
;}}}
	if( bNoLeft )
	{	; when bNoLeft the regex names right-side matches as mFileR1, mSizeR1, etc.
		global mSizeR1, mSizeRestR1, mFileR1
		s := mSizeR1
		x := mSizeRestR1
		f := mFileR1
	}
	else ; when !bNoLeft the regex names right-side matches as mFileR, mSizeR, etc.
	{
		global mSizeR, mSizeRestR, mFileR
		s := mSizeR
		x := mSizeRestR
		f := mFileR
	}
	r := ""
	Loop, Parse, x, %A_Space%
	{
		r := A_LoopField " " r
	}
	r := Trim(r)
	take := f
	revlist := take
	Loop, Parse, r, %A_Space%
	{
		take := A_LoopField " " take 
		revlist := Trim(take) "`n" revlist
	}
;if( bNoLeft )
;OutputDebug, A3: bNoLeft{%bNoLeft%} mSizeR1{%mSizeR1%} mSizeRestR1{%mSizeRestR1%}`nr{%r%}`nrevlist{%revlist%}
;else
;OutputDebug, A3: bNoLeft{%bNoLeft%} mSizeR{%mSizeR%} mSizeRestR{%mSizeRestR%}`nr{%r%}`nrevlist{%revlist%}
	ret := ""
	Loop, Parse, revlist, `n
	{
		if( FileExist(dir A_LoopField) )
		{
			ret := A_LoopField
			break
		}
	}
	Return, ret
} ; }}}
Sequence(iType,sDir,sSrc="",sDst="",sSrcSize="")
{ ; CSV file {{{ columns: seq counter,op type,dir,src fullpath,dst fullpath,src size
	global foSeq
	static count=0
	++count
	s = %count%,%iType%,`"%sDir%`",`"%sSrc%`",`"%sDst%`",`"%sSrcSize%`"
	foSeq.WriteLine( s )
} ; }}}
FmtTime(iSeconds)
{ ; to HH.mm.ss {{{
	h := iSeconds // 3600
	m := Mod(iSeconds, 3600) // 60
	s := Mod(iSeconds, 60)
	p := "20120202" SubStr("0" h, -1) SubStr("0" m, -1) SubStr("0" s, -1)
	FormatTime, p, %p%, HH.mm.ss
	Return p
} ; }}}
LogString(aId, aEvent)
{ ; {{{
	global LogString
	LogString .= "`n" aEvent ; (aId ? "`t" . aId : "")
} ; }}}
LogStringTop(aId, aEvent)
{ ; {{{
	global LogString
	LogString := aEvent (aId ? "`t" . aId : "") "`n" LogString
} ; }}}
Log(Id, sText)
{ ; {{{
	global Logging, foLog
	If( Logging && foLog ) {
		s := (Id ? Id "`t" : "") sText
		foLog.WriteLine( s )
	}
} ; }}}
StartProgressBar(iMax, iThreshold=100, sText="", sTitle="Progress...", sFont="")
{ ; {{{
	; no activate the progress bar if iMax < iThreshold
	; progress bar range 1 .. iMax
	; caller must use Progress, %i% to advance the progress bar, i=1 .. iMax
	; update Progress only when the next goal is reached, 1 <= iProgressBarNextGoal <= iMax by ~ 2% increments
	; caller may use  %iProgressCounter% instead of %i% when grouping function calls (see Hashing example)
 	global ShowProgress, iProgressBarNextGoal, iProgressCounter
	If( ShowProgress ) {
		If( iMax < iThreshold ) {
			iProgressBarNextGoal = 0
			iProgressCounter = 0
		} Else {
			iProgressBarNextGoal = 1 ; min bar
			iProgressCounter = 0
			; (B1 thin border,) Px x% min bar, Range 0-iMax, Width 200, FM10 10pt sText font, WM400 no bold sText
			Progress, P%iProgressBarNextGoal% R0-%iMax% W200 FM10 WM400, %iProgressBarNextGoal% `%, %sText%, %sTitle%, %sFont%
			Progress, %iProgressBarNextGoal%
		}
	}
} ; }}}
StopProgressBar(iMax)
{ ; {{{
	global iProgressBarNextGoal, iProgressCounter
	If( iProgressBarNextGoal ) {
		Sleep, 250
		Progress, %iMax%, 100 `%
		Sleep, 250
		Progress, Off
	}
	iProgressBarNextGoal = 0
	iProgressCounter = 0
} ; }}}
CleanUp(bCloseAll=true)
{ ; {{{
	global foDir, foSrcL, foSrcR, foSeq, foLog
  ; file I/O {{{
  If foDir
		foDir  := 0 * foDir.Close()
  If foSrcL
		foSrcL := 0 * foSrcL.Close()
  If foSrcR
		foSrcR := 0 * foSrcR.Close()
  If foSeq
		foSeq  := 0 * foSeq.Close()
	If( bCloseAll ) {
		If foLog
			foLog  := 0 * foLog.Close()
	}
	; }}}
	KillFocusHandler()
} ; }}}
HashFileList(In, Out, RootPath, iMax, bAbsolute=0)
{ ; {{{
	If( not FileExist(In) )
		Return
	global HashFormat,iProgressBarNextGoal,iProgressCounter
	bUnixSlash = 0
  sSep := " *"
	If( "linux" == HashFormat ) {
		bUnixSlash = 1
		sSep := "  "
	}
	Loop, Read, %In%, *%Out%
	{
		++iProgressCounter
		If( iProgressBarNextGoal && iProgressCounter > iProgressBarNextGoal  ) {
			p :=  iProgressCounter * 100 // iMax ; fill progress bar up to 100% maximum
			Progress, %iProgressCounter%, %p% `%
			iProgressBarNextGoal += iMax // 53 ; to 100% in 53 steps
		}
		x := FileMD5( RootPath A_LoopReadLine )
		If( bAbsolute ) {
			p := RootPath A_LoopReadLine
		} Else {
			p := A_LoopReadLine
		}
		If( bUnixSlash )
			StringReplace, p, p, \, /, All
			FileAppend, %x%%sSep%%p%`n
	}
} ; }}}
FileMD5( sFile="", cSz=4 )
{ ; www.autohotkey.com/forum/viewtopic.php?p=275910#275910 ; {{{
; by SKAN http://www.autohotkey.com/forum/topic64211-30.html
 cSz  := (cSz<0||cSz>8) ? 2**22 : 2**(18+cSz), VarSetCapacity( Buffer,cSz,0 )
 hFil := DllCall( "CreateFile", Str,sFile,UInt,0x80000000, Int,3,Int,0,Int,3,Int,0,Int,0 )
 IfLess,hFil,1, Return,hFil
 DllCall( "GetFileSizeEx", UInt,hFil, Str,Buffer ),   fSz := NumGet( Buffer,0,"Int64" )
 VarSetCapacity( MD5_CTX,104,0 ),    DllCall( "advapi32\MD5Init", Str,MD5_CTX )
 Loop % ( fSz//cSz+!!Mod(fSz,cSz) )
   DllCall( "ReadFile", UInt,hFil, Str,Buffer, UInt,cSz, UIntP,bytesRead, UInt,0 )
 , DllCall( "advapi32\MD5Update", Str,MD5_CTX, Str,Buffer, UInt,bytesRead )
 DllCall( "advapi32\MD5Final", Str,MD5_CTX ), DllCall( "CloseHandle", UInt,hFil )
 Loop % StrLen( Hex:="123456789ABCDEF0" )
  N := NumGet( MD5_CTX,87+A_Index,"Char"), MD5 .= SubStr(Hex,N>>4,1) . SubStr(Hex,N&15,1)
Return MD5
} ; }}}
SetFocusHandler()
{ ; start tracking mouse and block/restore keyboard/mouse input {{{
/* FIXME MOUSE TRACKING
OutputDebug, %A_ThisFunc%
	OnMessage(0x200, "OnMouseMove")     ; WM_MOUSEMOVE
	OnMessage(0x2A1, "OnMouseHover")    ; WM_MOUSEHOVER
	OnMessage(0x2A3, "OnMouseLeave")    ; WM_MOUSELEAVE
	global hWndControlID
	OnMouseMove(0, A_Now, 0, hWndControlID)
*/
	BlockSystemInput()
} ; }}}
KillFocusHandler()
{	; stop tracking mouse and unblock keyboard/mouse input {{{
/* FIXME MOUSE TRACKING
OutputDebug, %A_ThisFunc%
	OnMessage(0x200,"")
	OnMessage(0x2A1,"")
	OnMessage(0x2A3,"")
*/
	UnBlockSystemInput()
}
; }}}
BlockSystemInput() {
; {{{, Off
	global HotkeyUnlock
;OutputDebug, %A_ThisFunc%(%HotkeyUnlock%)
	Hotkey, IfWinActive
	Hotkey, %HotkeyUnlock%, EnableInput, On
	Hotkey, Alt & Tab, AltTab, On
  SetSystemCursor("IDC_Cross") ; mouse pointer
	BlockKeyboardInputs()
	BlockMouseClicks()
}
; }}}
UnBlockSystemInput() {
; {{{
	global HotkeyUnlock
;OutputDebug, %A_ThisFunc%
	BlockKeyboardInputs("Off")
	BlockMouseClicks("Off")
	RestoreCursors() ; mouse pointer
	Hotkey, IfWinActive,
	Hotkey, %HotkeyUnlock%, Off, UseErrorLevel
	Hotkey, Alt & Tab, Off, UseErrorLevel
} ; }}}
/* FIXME MOUSE TRACKING
OnMouseMove(wParam, lParam, msg, hwnd)
;http://www.autohotkey.com/forum/topic18323.html?p=194226 {{{
{
    static TrackWnd, TrackPos
global hWndTCmpForm,hWndControlID
OutputDebug, % A_ThisFunc " wParam{" wParam "} lParam{" lParam "} msg{" msg "} hwnd{" hwnd "} TrackWnd{" TrackWnd "} hWndTCmpForm{" hWndTCmpForm "} hWndControlID{" hWndControlID "}" 
static cnt
    
    ; Ignore repeat WM_MOUSEMOVE messages if position hasn't changed.
    if (TrackWnd = hwnd && TrackPos = lParam)
        return
    
++cnt
OutputDebug,% A_ThisFunc " " cnt
    
		; http://msdn.microsoft.com/en-us/library/windows/desktop/ms645604(v=vs.85).aspx
    VarSetCapacity(ET, 16)
    NumPut(16   , ET,  0)
    NumPut(0x3  , ET,  4)   ; TME_HOVER=0x1, TME_LEAVE=0x2, TME_NON_CLIENT=0x10
    NumPut(hwnd , ET,  8)
    NumPut(500  , ET, 12)   ; hover timeout in ms
    
    TrackWnd := hwnd
    TrackPos := lParam

    If not DllCall("TrackMouseEvent", "uint", &ET)
			OutputDebug, TrackMouseEvent() failed.
}
; }}}
OnMouseHover(wParam, lParam, msg, hwnd)
; {{{
{
OutputDebug,    % A_ThisFunc
}
; }}}
OnMouseLeave(wParam, lParam, msg, hwnd)
; {{{
{
OutputDebug,   % A_ThisFunc 
}
; }}}
*/
ExpandEnvVars(sText) 
{ ; {{{ %SystemRoot% %TEMP% %COMMANDER_PATH% etc.
VarSetCapacity(dest, 2048) 
	If not DllCall("ExpandEnvironmentStrings", "str", sText, "str", dest, int, 1999, "Cdecl int") 
		OutputDebug, ExpandEnvironmentStrings() failed
	Return dest 
} ; }}}
CommaAdd(num)
{ ;  PhiLho's {{{ cited here http://www.joellipman.com/articles/automation/autohotkey/531-format-numbers-in-autohotkey-with-commas.html
  VarSetCapacity(fNum,32)
  DllCall("GetNumberFormat",UInt,0x0409,UInt,0,Str,Num,UInt,0,Str,fNum,Int,32)
  return SubStr(fNum,1,StrLen(fNum) - 3)
} ; }}}
/* NOT USED
Min(x,y)
{ ; {{{
Return x<y ? x : y
} ; }}}
Max(x,y)
{ ; {{{
Return x>y ? x : y
} ; }}}
*/
; EOF
; vim: se fdm=marker ts=2 sw=2 noet nu ft=autohotkey fenc=utf-8: