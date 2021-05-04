#Include "WinHTTP.au3"
#Include <ScreenCapture.au3>

;; Create c:\tmp
;; Setup your own telegram bot, get the bot token and chat id

;; Main parameters ============================================================
Global $repeatTime = 1000 * 60 * 60   ;; 1 hour
Global $scappath = "c:\tmp\sc.jpg"

Global $myhostname = "Test"

; get pid: tasklist /v | findstr cmd
; get hnd: usually can get via _GetHwndFromPID but sometimes it may fail. Override by supplying hnd, default: ""
; Ver 3a: The issue i am facing is not about not getting the handle.. for some reasons, mod version is not getting the image

; [0] -> pid, [1] -> handle
; but if [0] <> 0, then [1] == 0 is mod , 1 == normal. 
Global $tasks[2][2] = [ _
	[18756, 0], _
	[9404, 0] _
]

; check cmd line params to override the params above
; ie, autoit3 winreporting.au3 <hostname> <no. of tasks> <pid 1> <hnd 1> ... 

if $CmdLine[0] <> 0 then
	if $CmdLine[0] < 2 or $CmdLine[0] <> (2 + $CmdLine[2] * 2) then
		MsgBox(0, "Error", "Expected params: <hostname> <no. of tasks> <pid 1> <hnd 1> ... <pid n> <hnd n>" & _
		@CRLF & "Note: if pid <> 0, then hnd is either 0 (mod) or 1 (non mod) scrcap" & _
		@CRLF & "set pid to 0 if you have the handle")
		Exit
	endif
	
	$myhostname = $CmdLine[1]
	
	ReDim $tasks[$CmdLine[2]][$CmdLine[2]]
	
	for $i = 0 to $CmdLine[2] - 1
		$tasks[$i][0] = $CmdLine[3+$i*2]
		$tasks[$i][1] = $CmdLine[4+$i*2]
	Next
endif


$Query = "https://api.telegram.org/bot<token>/sendPhoto"
Local $Form = '<form action="' & $Query & '" method="post" enctype="multipart/form-data">' & _
              '<input type="text" name="chat_id"/>' & _
              '<input type="file" name="photo"/>'   & _
              '<input type="text" name="caption"/>'
$Form &= '</form>'

; #FUNCTION# ====================================================================================================================
; Author ........: Paul Campbell (PaulIA)
; Modified.......: chimp
;
; modified version of the _ScreenCapture_CaptureWnd() function
; It uses the _WinAPI_PrintWindow() to capture the window
; ===============================================================================================================================
Func _ScreenCapture_CaptureWnd_mod($sFileName, $hWin, $bCursor = True)
    Local $bRet = False

    Local $iSize = WinGetPos($hWin)

    Local $iW = $iSize[2]
    Local $iH = $iSize[3]
    Local $hWnd = _WinAPI_GetDesktopWindow()
    Local $hDDC = _WinAPI_GetDC($hWnd)
    Local $hCDC = _WinAPI_CreateCompatibleDC($hDDC)
    Local $hBMP = _WinAPI_CreateCompatibleBitmap($hDDC, $iW, $iH)

    ; $hCDC Identifies the device context
    ; $hBMP Identifies the object to be selected
    _WinAPI_SelectObject($hCDC, $hBMP)
    _WinAPI_PrintWindow($hWin, $hCDC)

    If $bCursor Then
        Local $aCursor = _WinAPI_GetCursorInfo()
        If Not @error And $aCursor[1] Then
            $bCursor = True ; Cursor info was found.
            Local $hIcon = _WinAPI_CopyIcon($aCursor[2])
            Local $aIcon = _WinAPI_GetIconInfo($hIcon)
            If Not @error Then
                _WinAPI_DeleteObject($aIcon[4]) ; delete bitmap mask return by _WinAPI_GetIconInfo()
                If $aIcon[5] <> 0 Then _WinAPI_DeleteObject($aIcon[5]); delete bitmap hbmColor return by _WinAPI_GetIconInfo()
                _WinAPI_DrawIcon($hCDC, $aCursor[3] - $aIcon[2] - $iSize[0], $aCursor[4] - $aIcon[3] - $iSize[1], $hIcon)
            EndIf
            _WinAPI_DestroyIcon($hIcon)
        EndIf
    EndIf

    _WinAPI_ReleaseDC($hWnd, $hDDC)
    _WinAPI_DeleteDC($hCDC)
    If $sFileName = "" Then Return $hBMP

    $bRet = _ScreenCapture_SaveImage($sFileName, $hBMP, True)
    Return SetError(@error, @extended, $bRet)
EndFunc   ;==>_ScreenCapture_CaptureWnd_mod

; #FUNCTION# ====================================================================================================================
; Author ........: ?
;
; Not sure where i copied from.. but it works!
; ===============================================================================================================================
Func _GetHwndFromPID($PID)
    $hWnd = 0
    $stPID = DllStructCreate("int")
    Do
        $winlist2 = WinList()
        For $i = 1 To $winlist2[0][0]
            If $winlist2[$i][0] <> "" Then
                DllCall("user32.dll", "int", "GetWindowThreadProcessId", "hwnd", $winlist2[$i][1], "ptr", DllStructGetPtr($stPID))
                If DllStructGetData($stPID, 1) = $PID Then
                    $hWnd = $winlist2[$i][1]
                    ExitLoop
                EndIf
            EndIf
        Next
        Sleep(100)
    Until $hWnd <> 0
    Return $hWnd
EndFunc ;==>_GetHwndFromPID

; #FUNCTION# ====================================================================================================================
; Author: Me
;
; Function to do screen cap and send
; ===============================================================================================================================

Func _DoWork()
    For $i = 0 UBound($tasks, 1) - 1
		if $tasks[$i][0] <> 0 then
			$hWnd = _GetHwndFromPID($tasks[$i][0])
			
			if $tasks[$i][1] == 0 then
				_ScreenCapture_CaptureWnd_mod($scappath, $hWnd)
			else
				WinActivate($hWnd)
				Sleep(100)
				_ScreenCapture_CaptureWnd($scappath, $hWnd)
			endif
		else
			$hWnd = Hwnd(String($tasks[$i][1]))
			_ScreenCapture_CaptureWnd_mod($scappath, $hWnd)
		endif
		
		Local $hOpen = _WinHttpOpen()
		Local $hForm = $Form

		Local $Response = _WinHttpSimpleFormFill($hForm,$hOpen,Default, _
                  "name:chat_id", <chat id>, _
                  "name:photo"  , $scappath, _
                  "name:caption", $myhostname)
		_WinHttpCloseHandle($hOpen)
		_WinHttpCloseHandle($hForm)
	Next
EndFunc ;==> _DoWork

;; 'Main' ==========================================

While 1
   _DoWork()
   Sleep($repeatTime)
WEnd