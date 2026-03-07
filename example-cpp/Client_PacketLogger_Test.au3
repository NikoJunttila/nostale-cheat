#cs
 Sending to Nos:
 	0 = Recv
 	1 = Send
 Examples:
 	0 ncif 1 3232
 	1 gold 9999999


 Recving from Nos:
	0 = Recv
	1 = Send
 Examples:
 	0 ncif 1 3232
 	1 gold 9999999
#ce

Opt("WinTitleMatchMode", 2)

$PacketLoggerTitle = WinGetTitle("NosTale PacketLogger - Server: 127.0.0.1")
If $PacketLoggerTitle = "" Then
	MsgBox(0, "PacketLogger Error!", "Couldn't find the PacketLogger with about title!")
	Exit
EndIf

$Port = StringRegExp($PacketLoggerTitle, "127\.0\.0\.1\:(\d+)", 3)
If Not IsArray($Port) Then
	MsgBox(0, "PacketLogger Error!", "Couldn't find port in PacketLogger title! Title: " & $PacketLoggerTitle)
	Exit
EndIf

$Port = $Port[0]

TCPStartup()

$socket = TCPConnect("127.0.0.1", $Port)
If $socket < 1 Then
	MsgBox(0, "Connection Error!", "Couldn't connect to the PacketLogger Server!")
	Exit
EndIf

TCPSend($socket, "0 guri 10 1 10044 974")


While True
	$packet = TCPRecv($socket, 8192)
	If $packet <> "" Then
		MsgBox(0, "Packet Recvd", "Incoming Packet: " & $packet)
		ExitLoop
	EndIf
WEnd

TCPCloseSocket($socket)
TCPShutdown()