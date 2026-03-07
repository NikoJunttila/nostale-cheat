#pragma once
#include <QMainWindow>
#include <QMouseEvent>
#include <QMenu>

#include "ui_PacketUI.h"
#include "PacketSenderUI.h"
#include "FilterUI.h"

enum EPacketType {
	PTReceive,
	PTSend,
};

class CPacketUI : public QMainWindow
{
	Q_OBJECT

public:
	CPacketUI(QWidget *i_pParent = 0);
	~CPacketUI();

signals:
	void addPacket(const QString &, int);

private slots:
	void onAddPacket(const QString &i_sPacket, int i_iPacketType);
	void onAdvancedLWMove(QMouseEvent *i_pEvent);
	void onAdvancedGBLeave(QEvent *i_pEvent);
	void onLogClearClicked();

	void hideMoveAll() {
		this->m_oRecvFilter.hide(); this->m_oRecvFilter.move(this->pos());
		this->m_oSendFilter.hide(); this->m_oSendFilter.move(this->pos());

		this->m_oRecvBlocker.hide(); this->m_oRecvBlocker.move(this->pos());
		this->m_oSendBlocker.hide(); this->m_oSendBlocker.move(this->pos());
	}

	void onSendFilter() { this->hideMoveAll(); this->m_oSendFilter.show(); }
	void onRecvFilter() { this->hideMoveAll(); this->m_oRecvFilter.show(); }

	void onSendBlocker() { this->hideMoveAll(); this->m_oSendBlocker.show(); }
	void onRecvBlocker() { this->hideMoveAll(); this->m_oRecvBlocker.show(); }

	void onSenderPressed() { this->m_oSenderUI.show(); }

	void enterEvent(QEvent *i_pEvent) { QWidget::enterEvent(i_pEvent); this->onAdvancedGBLeave(nullptr); }
	void leaveEvent(QEvent *i_pEvent) { QWidget::leaveEvent(i_pEvent); this->onAdvancedGBLeave(nullptr); }

	void closeEvent(QCloseEvent *i_pEvent);

	void menuTriggered(QAction *i_pAction);

public:
	CFilterUI &sendFilter() { return m_oSendFilter; }
	CFilterUI &recvFilter() { return m_oRecvFilter; }

	CFilterUI &sendBlocker() { return m_oSendBlocker; }
	CFilterUI &recvBlocker() { return m_oRecvBlocker; }

private:
	Ui::CPacketUI m_oUI;
	QMenu *m_pLWMenu;

	CPacketSender m_oSenderUI;

	CFilterUI m_oSendFilter;
	CFilterUI m_oRecvFilter;

	CFilterUI m_oSendBlocker;
	CFilterUI m_oRecvBlocker;
};