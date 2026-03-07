#include "HookFunctions.h"
#include "PacketUI.h"
#include <iostream>

#include <qtextstream.h>
#include <qtextcodec.h>


extern CPacketUI *g_pUi;


bool HookFunctions::HandleRecvPacket(char *i_szPacket) {
	const QString sPacket = QString::fromLocal8Bit(i_szPacket).replace('\n', "");

	QTextCodec* codec = QTextCodec::codecForName("windows-1250");
	QTextDecoder decoder{ codec };

	QString str = decoder.toUnicode(i_szPacket);

	emit g_pUi->addPacket(str, EPacketType::PTReceive);
	return g_pUi->recvBlocker().isFiltered(sPacket);
}

bool HookFunctions::HandleSendPacket(char *i_szPacket) {
	const QString sPacket = QString::fromLocal8Bit(i_szPacket).replace('\n', "");

	emit g_pUi->addPacket(sPacket, EPacketType::PTSend);
	return g_pUi->sendBlocker().isFiltered(sPacket);
}