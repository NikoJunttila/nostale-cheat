#include "TCPServer.h"
#include "AddressFunctions.h"
#include "PacketUI.h"

#include <QHostAddress>


#ifdef ACTIVATE_FEATURE_TCP_SERVER
extern CPacketUI *g_pUi;


CTcpServer::CTcpServer()
	: m_oMutex(QMutex::RecursionMode::Recursive)
{
	connect(this, &CTcpServer::broadcastPacket, this, &CTcpServer::onBroadcastPacket);
	this->listen(QHostAddress(TCP_SERVER_IP), TCP_SERVER_PORT);
}

CTcpServer::~CTcpServer()
{
	this->stop();
}


void CTcpServer::stop()
{
	this->close();
}


void CTcpServer::incomingConnection(qintptr i_nHandle)
{
	CTcpSocket *pSocket = new CTcpSocket(i_nHandle);

	connect(pSocket, &QTcpSocket::readyRead, this, &CTcpServer::socketReceivedPacket);
	connect(pSocket, &QTcpSocket::disconnected, this, &CTcpServer::socketDisconnected);

	QMutexLocker oLocker(&this->m_oMutex);
	this->m_apSockets.push_back(pSocket);
}

void CTcpServer::socketReceivedPacket() const
{
	CTcpSocket *pSocket = qobject_cast<CTcpSocket *>(sender());
	
	QString sAllPacket = QString::fromUtf8(pSocket->readAll());

	QStringList asPackets = sAllPacket.split('\r');
	for (const QString &sPacket : asPackets)
	{
		if (sPacket.isEmpty())
		{
			continue;
		}

		QStringList asPacketSplitted = sPacket.split(' ');
		if (asPacketSplitted.length() > 1)
		{
			// Get the packet header
			const QString sPacketHeader = asPacketSplitted[0];

			// Remove the packet header
			asPacketSplitted.removeFirst();

			// Concat the packet without header
			const QString sRealPacket = asPacketSplitted.join(' ');

			if (sPacketHeader == TCP_PACKET_RECV_NOS)
			{
				RecvPacket(sRealPacket);
			}
			else if (sPacketHeader == TCP_PACKET_SEND_NOS)
			{
				SendPacket(sRealPacket);
			}
		}
	}
}

void CTcpServer::socketDisconnected()
{
	CTcpSocket *pSocket = qobject_cast<CTcpSocket *>(sender());
	pSocket->deleteLater();

	QMutexLocker oLocker(&this->m_oMutex);
	this->m_apSockets.removeOne(pSocket);
}

void CTcpServer::onBroadcastPacket(QString i_sPacket, const int i_iPacketType)
{
	switch (i_iPacketType)
	{
	case EPacketType::PTReceive:
		i_sPacket = TCP_PACKET_RECV_NOS " " + i_sPacket;
		break;
	case EPacketType::PTSend:
		i_sPacket = TCP_PACKET_SEND_NOS " " + i_sPacket;
		break;

	default: return;
	}

	i_sPacket += '\r';

	const QByteArray abPacket = i_sPacket.toLocal8Bit();

	QMutexLocker oLocker(&this->m_oMutex);
	Q_FOREACH(CTcpSocket *pSocket, this->m_apSockets)
	{
		pSocket->write(abPacket);
	}
}
#endif