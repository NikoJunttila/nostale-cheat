#pragma once
#include <QGroupBox>
#include <QDialog>
#include "ui_PacketSenderUI.h"

class CPacketUI;
class CPacketSender;
class CPacketSenderUI : public QGroupBox
{
	Q_OBJECT
public:
	CPacketSenderUI(CPacketSender *i_pParent, const QString &i_sType);
	~CPacketSenderUI();

private slots:
	void onSendPacket() const;
	void onSpamPacketTick() const;
	void onSpamPacket();

private:
	Ui::CPacketSenderUI m_oUI;
	const QString m_sType;
	bool m_fIsSpamStarted;
};



class CPacketSender : public QDialog {
	Q_OBJECT
public:
	CPacketSender(CPacketUI *i_pParent);
	~CPacketSender();

private:
	CPacketSenderUI m_oSend;
	CPacketSenderUI m_oRecv;
};