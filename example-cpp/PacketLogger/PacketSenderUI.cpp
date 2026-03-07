#include "PacketSenderUI.h"
#include "AddressFunctions.h"
#include "PacketUI.h"
#include "Config.h"

#include <QTimer>


static const QStringList s_asSpam = { "Start", "Stop" };


CPacketSenderUI::CPacketSenderUI(CPacketSender *i_pParent, const QString &i_sType)
	: QGroupBox(i_pParent), m_sType(i_sType), m_fIsSpamStarted(false)
{
	this->m_oUI.setupUi(this);

	this->m_oUI.pbSend->setText(i_sType);
}

CPacketSenderUI::~CPacketSenderUI()
{
}


void CPacketSenderUI::onSendPacket() const
{
	if (this->m_oUI.teSendPackets->toPlainText().isEmpty()) return;

	QStringList asPackets = this->m_oUI.teSendPackets->toPlainText().split('\n');
	for (const QString &sPacket : asPackets) {
		if (sPacket.isEmpty()) continue;

		if (this->m_sType == FILTER_MACRO_SEND)
			SendPacket(sPacket);
		else if (this->m_sType == FILTER_MACRO_RECV)
			RecvPacket(sPacket);
	}
}

void CPacketSenderUI::onSpamPacketTick() const
{
	if (this->m_fIsSpamStarted) {
		this->onSendPacket();
		QTimer::singleShot(this->m_oUI.sbTime->value(), this, &CPacketSenderUI::onSpamPacketTick);
	}
}

void CPacketSenderUI::onSpamPacket()
{
	this->m_fIsSpamStarted = !this->m_fIsSpamStarted;
	this->m_oUI.pbSpam->setText(s_asSpam[this->m_fIsSpamStarted]);

	if (this->m_fIsSpamStarted)
		onSpamPacketTick();
}


CPacketSender::CPacketSender(CPacketUI *i_pParent)
	: QDialog(i_pParent), m_oSend(this, FILTER_MACRO_SEND), m_oRecv(this, FILTER_MACRO_RECV)
{
	this->setObjectName("CPacketSender");
	this->setStyleSheet("#CPacketSender { background-color: #1E1E1E; }");

	this->setWindowTitle("[PacketLogger] Sender");

	this->m_oSend.setTitle("Send");
	this->m_oSend.move(0, 0);

	this->m_oRecv.setTitle("Receive");
	this->m_oRecv.move(0, this->m_oSend.geometry().height() + 5);

	this->adjustSize();
	
	this->setMinimumSize(this->size());
	this->setMaximumSize(this->size());

	this->m_oSend.show();
	this->m_oRecv.show();
}

CPacketSender::~CPacketSender()
{
}