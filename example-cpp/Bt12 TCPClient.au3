#RequireAdmin
#include <PacketLogger_Api.au3>

;#################################################################################
Dim $MyPetIds[0]
Dim $Target = 0

Dim $MonstersOnMap[0]
Dim $TempLog = ""

Dim $PlayerId = -1, $PlayerX = -1, $PlayerY = -1

Const $MaxMonsterCount = 3

Dim $Started = False

Const $No = "No"
Const $Yes = "Yes"
Const $Title = "PacketLogger Hax - Connected: "

HotKeySet("{F1}", "StartStop")
;#################################################################################

PacketLogger_Startup()
;PacketLogger_SetDisconnectedCallback(CallbackDisconnected)
Dim $Socket = -1

#include <EditConstants.au3>
#include <GUIConstants.au3>
#include <ScrollBarConstants.au3>
#include <GuiEdit.au3>

#Region ### START Koda GUI sect	; 344 280
$Form = GUICreate($Title & $No, 811, 415, 323, 219)
$lPetId = GUICtrlCreateLabel("PetIds: -", 8, 4, 250, 14)
GUICtrlSetFont(-1, 10, 800, 0, "MS Sans Serif")

$lPlayerData = GUICtrlCreateLabel("PlayerId: -, X: -, Y: -", 8, 20, 250, 14)
GUICtrlSetFont(-1, 10, 800, 0, "MS Sans Serif")

$lTarget = GUICtrlCreateLabel("Target: -", 8, 42, 200, 22)
GUICtrlSetFont(-1, 14, 800, 0, "MS Sans Serif")
$lIsStarted = GUICtrlCreateLabel("IsStarted: No", 8, 72, 200, 28)
GUICtrlSetFont(-1, 14, 800, 0, "MS Sans Serif")
$eMonstersOnMap = GUICtrlCreateEdit("", 8, 140, 76, 272, BitOR($GUI_SS_DEFAULT_EDIT,$ES_READONLY))
GUICtrlSetData(-1, "")
$lMonstersOnMap = GUICtrlCreateLabel("Monsters on Map:", 8, 104, 168, 28)
GUICtrlSetFont(-1, 14, 800, 0, "MS Sans Serif")
$rOnlyTarget = GUICtrlCreateRadio("Only Target", 88, 144, 100, 28)
GUICtrlSetState(-1, $GUI_CHECKED)
GUICtrlSetFont(-1, 10, 800, 0, "MS Sans Serif")
$rMonstersOnMap = GUICtrlCreateRadio("All on Map", 88, 176, 100, 28)
GUICtrlSetFont(-1, 10, 800, 0, "MS Sans Serif")
$cbLoot = GUICtrlCreateCheckbox("Loot", 88, 208, 110, 28)
GUICtrlSetFont(-1, 10, 800, 0, "MS Sans Serif")
$lTimerHandle = GUICtrlCreateLabel("Handle Timer:", 91, 244, 100, 28)
GUICtrlSetFont(-1, 10, 800, 0, "MS Sans Serif")
$iHandleTimer = GUICtrlCreateInput("25", 91, 272, 156, 24)
GUICtrlSetFont(-1, 10, 800, 0, "MS Sans Serif")
$eLog = GUICtrlCreateEdit("", 254, 32, 554, 380, BitOR($GUI_SS_DEFAULT_EDIT,$ES_READONLY))
GUICtrlSetData(-1, "")
$lLog = GUICtrlCreateLabel("Log:", 256, 0, 45, 28)
GUICtrlSetFont(-1, 14, 800, 0, "MS Sans Serif")

$bClearPets = GUICtrlCreateButton("Clear Pets", 110, 380, 110, 28)
GUICtrlSetFont(-1, 12, 800, 0, "MS Sans Serif")

GUISetState(@SW_SHOW)
#EndRegion ### END Koda GUI section ###

GUIRegisterMsg($WM_COMMAND, "HandleGUIWMEvents")

UpdateHandleTimer()
AdlibRegister("UpdateUI", 1000)
AdlibRegister("RespawnRefreshAllPets", 700)

While 1
	ConnectToPacketLogger()

	$nMsg = GUIGetMsg()
	Switch $nMsg
		Case -3
			ExitLoop
		Case $bClearPets
			ClearPetIds()

	EndSwitch

	If $Socket <> -1 Then PacketLogger_Handle($Socket, IncomingPacket, 8192 * 10)
WEnd

If $Socket <> -1 Then PacketLogger_Close($Socket)
PacketLogger_Shutdown()

Func ConnectToPacketLogger()
	If $Socket = -1 Then
		$Ports = PacketLogger_GetPorts()

		If UBound($Ports) > 0 Then
			$Socket = PacketLogger_ConnectTo($Ports[0])

			If Not $Socket Then
				$Socket = -1
			Else
				WinSetTitle($Form, "", $Title & $Yes & " - 127.0.0.1:" & $Ports[0])
				RefreshPetIds()
			EndIf
		EndIf
	EndIf
EndFunc

Func CallbackDisconnected($Socket)
	WinSetTitle($Form, "", $Title & $No)
	MsgBox(0,"",$Socket & " disconnected!")
EndFunc

; For UI
Func SetPetId($id)
	If  _ArraySearch($MyPetIds, $id) = -1 Then
		ReDim $MyPetIds[UBound($MyPetIds) + 1]
		$MyPetIds[UBound($MyPetIds) - 1] = $id

		UpdatePetIds()

		AddLog("New PetId retrived!")
	EndIf
EndFunc   ;==>SetPetId

Func SetTargetId($id)
	$Target = $id
	GUICtrlSetData($lTarget, "Target: " & ($Target = 0 ? '-' : $Target))

	AddLog("New Target retrived! Id: " & $id)
EndFunc   ;==>SetTargetId

Func UpdatePlayerUI()
	GUICtrlSetData($lPlayerData, "PlayerId: " & $PlayerId & ", X: " & $PlayerX & ", Y: " & $PlayerY)
EndFunc

Func SetPlayerId($Id)
	$PlayerId = $Id
	UpdatePlayerUI()
EndFunc

Func SetPlayerPos($X, $Y)
	$PlayerX = $X
	$PlayerY = $Y
	UpdatePlayerUI()
EndFunc

Func AddLog($Text)
	$TempLog &= $Text & @CRLF
EndFunc

Func UpdateHandleTimer()
	$HandleTime = GUICtrlRead($iHandleTimer)
	If Not StringIsInt($HandleTime) Then
		$HandleTime = 100
	ElseIf $HandleTime <= 5 Then
		$HandleTime = 5
	EndIf

	AddLog("Updated HandleTimer to: " & $HandleTime)
	AdlibUnRegister("Handle")
	AdlibRegister("Handle", $HandleTime)
EndFunc

Func HandleGUIWMEvents($hWnd, $iMsg, $iwParam, $ilParam)
    $nNotifyCode = BitShift($iwParam, 16)
    $nID = BitAND($iwParam, 0x0000FFFF)
    $hCtrl = $ilParam

    If $nNotifyCode = $EN_CHANGE Then
        If $hCtrl = GUICtrlGetHandle($iHandleTimer) Then
            UpdateHandleTimer()
        EndIf
    EndIf

    Return $GUI_RUNDEFMSG
EndFunc

Func UpdateUI()
	If $TempLog <> "" Then
		GUICtrlSetData($eLog, GUICtrlRead($eLog) & $TempLog)
		_GUICtrlEdit_Scroll($eLog, $SB_SCROLLCARET)
		$TempLog = ""
	EndIf
EndFunc

Func UpdatePetIds()
	GUICtrlSetData($lPetId, "PetIds: " & _ArrayToString($MyPetIds, ","))
EndFunc

Func UpdateMonstersOnMap()
	$Data = ""
	For $i = 0 To UBound($MonstersOnMap) - 1
		$Data &= $MonstersOnMap[$i] & @CRLF
	Next
	GUICtrlSetData($eMonstersOnMap, $Data)
EndFunc

Func StartStop()
	$Started = Not $Started
	GUICtrlSetData($lIsStarted, "IsStarted: " & ($Started ? "Yes" : "No"))
EndFunc   ;==>StartStop

; General SendPacket loop
Func RespawnRefreshAllPets()
	If $Socket = -1 Or Not $Started Or UBound($MyPetIds) = 0 Then Return

	Dim $Packets[UBound($MyPetIds)]

	For $i = 0 To UBound($MyPetIds) - 1
		$Packets[$i] = "n_run 4 2 4 " & $MyPetIds[$i]
	Next

	PacketLogger_SendPacket($Socket, $Packets)
EndFunc

Func Handle()
	If Not $Started Then Return
	If UBound($MyPetIds) = 0 Then Return

	$PetAttackPacket = "suctl 5 1 "

	; Solo-Target Spam kill (Add checkbox on UI all monsters or in target)
	If GUICtrlRead($rOnlyTarget) = $GUI_CHECKED Then
		If $Target <> 0 Then
			Dim $Packets[UBound($MyPetIds)]

			For $i = 0 To UBound($Packets) - 1
				$Packets[$i] = $PetAttackPacket & $MyPetIds[$i] & " 3 " & $Target
			Next

			PacketLogger_SendPacket($Socket, $Packets)
		EndIf
	ElseIf GUICtrlRead($rMonstersOnMap) = $GUI_CHECKED Then
		$MonsterCount = UBound($MonstersOnMap)
		If $MonsterCount > $MaxMonsterCount Then
			$MonsterCount = $MaxMonsterCount
		EndIf

		If $MonsterCount > 0 Then
			Dim $Packets[$MonsterCount * UBound($MyPetIds)]

			For $i = 0 To $MonsterCount - 1
				For $j = 0 To UBound($MyPetIds) - 1
					$Packets[$i * UBound($MyPetIds) + $j] = $PetAttackPacket & $MyPetIds[$j] & " 3 " & $MonstersOnMap[$i]
				Next
			Next

			PacketLogger_SendPacket($Socket, $Packets)
		EndIf
	EndIf
EndFunc   ;==>Handle


Func RefreshPetIds()
	ClearPetIds()
	PacketLogger_SendPacket($Socket, "npinfo 0")
EndFunc

Func ClearPetIds()
	ReDim $MyPetIds[0]
	UpdatePetIds()
EndFunc


; Packet Handlers
Func HandleIn($PacketSplitted)
	If UBound($PacketSplitted) < 3 Then Return
	If $PacketSplitted[1] <> 3 Then Return
	;If $PacketSplitted[2] = 439 Then
		_ArrayAdd($MonstersOnMap, $PacketSplitted[3])
		UpdateMonstersOnMap()
		AddLog("New Monster on Map found! Id: " & $PacketSplitted[3] & " Vnum: " & $PacketSplitted[2])
	;EndIf
EndFunc   ;==>HandleIn

Func HandleSu($PacketSplitted)
	If UBound($PacketSplitted) < 16 Then Return
	If $PacketSplitted[3] <> 3 Then Return

	; Hp <= 0
	If $PacketSplitted[12] <= 0 Then
		If $PacketSplitted[4] = $Target Then
			SetTargetId(0)
		EndIf

		$Index = _ArraySearch($MonstersOnMap, $PacketSplitted[4])
		If $Index <> -1 Then
			_ArrayDelete($MonstersOnMap, $Index)
			UpdateMonstersOnMap()
			AddLog("Monster died! Id: " & $PacketSplitted[4] & ", IndexInArray: " & $Index)
		EndIf
	EndIf
EndFunc   ;==>HandleSu

Func HandleNcif($PacketSplitted)
	If UBound($PacketSplitted) < 3 Then Return
	If $PacketSplitted[1] <> 3 Then Return ; When no monster, return

	If $Target <> $PacketSplitted[2] Then
		SetTargetId($PacketSplitted[2])
	EndIf
EndFunc   ;==>HandleNcif

Func HandlePInit($PacketSplitted)
	Return
	If UBound($PacketSplitted) < 3 Then Return

	For $i = 2 To UBound($PacketSplitted) -1
		$PetData = StringSplit($PacketSplitted[$i], "|", 2)
		If UBound($PetData) < 7 Then ContinueLoop

		SetPetId($PetData[1])
	Next
EndFunc   ;==>HandlePInit

Func HandleSendRest($PacketSplitted)
	;Return
	If UBound($PacketSplitted) < 4 Then Return

	For $i = 2 To UBound($PacketSplitted) - 1 Step 2
		If $PacketSplitted[$i] = 1 Then
			SetPlayerId($PacketSplitted[$i + 1])
		;ElseIf $PacketSplitted[$i] = 2 Then
		;	SetPetId($PacketSplitted[$i + 1])
		EndIf
	Next
EndFunc   ;==>HandleSendRest

Func HandleAt($PacketSplitted)
	If UBound($PacketSplitted) < 5 Then Return

	ReDim $MonstersOnMap[0]
	AddLog("Map changed! Monsters and Pets cleared.")
	UpdateMonstersOnMap()

	RefreshPetIds()

	SetPlayerId($PacketSplitted[1])
	SetPlayerPos($PacketSplitted[3], $PacketSplitted[4])
EndFunc   ;==>HandleAt

Func HandlePets_Sc($PacketSplitted)
	If UBound($PacketSplitted) < 4 Then Return

	SetPetId($PacketSplitted[3])
EndFunc

Func HandleDrop($PacketSplitted)
	If UBound($PacketSplitted) < 7 Then Return
	If $PlayerId = -1 Or $PlayerX = -1 Or $PlayerY = -1 Then Return

	If GUICtrlRead($cbLoot) = $GUI_CHECKED Then
		$ItemVnum = $PacketSplitted[1]
		$ItemTempId = $PacketSplitted[2]
		$ItemX = $PacketSplitted[3]
		$ItemY = $PacketSplitted[4]
		$Amount = $PacketSplitted[5]


		Dim $Packets[3] = [ "walk " & $ItemX & " " & $ItemY & " 0 10", _
							"get 1 " & $PlayerId & " " & $ItemTempId, _
							"walk " & $PlayerX & " " & $PlayerY & " 0 10" ]

		PacketLogger_SendPacket($Socket, $Packets)
	EndIf
EndFunc

Func HandleC_info($PacketSplitted)
	If UBound($PacketSplitted) < 10 Then Return
	SetPlayerId($PacketSplitted[6])
EndFunc

Func HandleWalk($PacketSplitted)
	If UBound($PacketSplitted) < 4 Then Return
	SetPlayerPos($PacketSplitted[1], $PacketSplitted[2])
EndFunc

#cs

walk 106 74 0 10
get 1 333 100003


drop 1046 100011 102 81 22820 0 0 -1

#ce

; Packet Callback
Func IncomingPacket($Type, $PacketSplitted, $FullPacket)
	;MsgBox(0,"", "Type: " & $Type & @CRLF & "PacketName: " & $PacketSplitted[0] & @CRLF & "Packet: " & $FullPacket)
	If $PacketSplitted[0] = "pinit" Then
		HandlePInit($PacketSplitted)
	ElseIf $Type = $PacketLogger_Send And $PacketSplitted[0] = "rest" Then
		HandleSendRest($PacketSplitted)
	ElseIf $PacketSplitted[0] = "ncif" Then
		HandleNcif($PacketSplitted)
	ElseIf $PacketSplitted[0] = "su" Then
		HandleSu($PacketSplitted)
	ElseIf $PacketSplitted[0] = "in" Then
		HandleIn($PacketSplitted)
	ElseIf $PacketSplitted[0] = "at" Then
		HandleAt($PacketSplitted)
	ElseIf $PacketSplitted[0] = "sc_p" Or $PacketSplitted[0] = "sc_n" Then
		HandlePets_Sc($PacketSplitted)
	ElseIf $PacketSplitted[0] = "drop" Then
		HandleDrop($PacketSplitted)
	ElseIf $PacketSplitted[0] = "walk" Then
		HandleWalk($PacketSplitted)
	EndIf
EndFunc   ;==>IncomingPacket
