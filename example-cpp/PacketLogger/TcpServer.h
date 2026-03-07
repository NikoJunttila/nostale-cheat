#pragma once
#include "Defines.h"

#ifdef ACTIVATE_FEATURE_TCP_SERVER
#include <QTcpServer>
#include <QTcpSocket>
#include <QMutex>

#include <memory>

class CTcpSocket : public QTcpSocket
{
	Q_OBJECT

public:
	CTcpSocket(const qintptr i_nHandle)
	{
		QAbstractSocket::setSocketDescriptor(i_nHandle);
	}

	~CTcpSocket()
	{
		QAbstractSocket::close();
	}

private:
	
};

class CTcpServer : public QTcpServer
{
	Q_OBJECT

public:
	CTcpServer();
	~CTcpServer();

public:
	void stop();

signals:
	void broadcastPacket(QString i_sPacket, int i_iPacketType);

private slots:
	void incomingConnection(qintptr i_nHandle) Q_DECL_OVERRIDE;
	void socketReceivedPacket() const;
	void socketDisconnected();

	void onBroadcastPacket(QString i_sPacket, int i_iPacketType);

private:
	QMutex					m_oMutex;
	QVector<CTcpSocket *>	m_apSockets;
};
#endif