#include "PacketUI.h"
#include "AddressFunctions.h"
#include "TcpServer.h"
#include "Config.h"

#include <QMessageBox>
#include <QFileDialog>
#include <QTextStream>
#include <QClipboard>
#include <QTime>
#include <thread>

#ifdef ACTIVATE_FEATURE_TCP_SERVER
extern CTcpServer *g_pTcpServer;
#endif

const QColor g_oBackgroundColor = QColor(0x1E1E1E);
const QColor g_oMarkedColor = QColor(Qt::darkYellow);

#define LW_MENU_COPY_SELECTED	"Copy Packets"
#define LW_MENU_RESEND_PACKET	"Resend Packets"
#define LW_MENU_SAVE_FILE		"Save Log to File"
#define LW_MENU_MARK_SELECTED	"Mark selected"

#define START_SPLIT_PACKET	"["
#define SPLIT_PACKET		"]\t"
#define SEND_PREFIX			START_SPLIT_PACKET "Send"		SPLIT_PACKET
#define RECV_PREFIX			START_SPLIT_PACKET "Recv"		SPLIT_PACKET
#define UNKNOWN_PREFIX		START_SPLIT_PACKET "Unknown"	SPLIT_PACKET


CPacketUI::CPacketUI(QWidget *i_pParent)
	: QMainWindow(i_pParent), m_oSenderUI(this), m_oRecvFilter(this, FILTER_MACRO_RECV), m_oSendFilter(this, FILTER_MACRO_SEND), m_oRecvBlocker(this, FILTER_MACRO_RECV_BLOCK), m_oSendBlocker(this, FILTER_MACRO_SEND_BLOCK)
{
	this->m_oUI.setupUi(this);

	this->setMinimumSize(this->size());
	this->setMaximumSize(this->size());

	this->m_oUI.lwPacketList->setContextMenuPolicy(Qt::CustomContextMenu);
	this->m_oUI.lwPacketList->setUniformItemSizes(true);
	this->m_oUI.lwPacketList->setMouseTracking(true);
	
	this->m_oUI.gbLoggerSettings->hide();


	this->m_pLWMenu = new QMenu(this);
	this->m_pLWMenu->addAction(new QAction(LW_MENU_COPY_SELECTED , this->m_pLWMenu));
	this->m_pLWMenu->addAction(new QAction(LW_MENU_RESEND_PACKET, this->m_pLWMenu));
	this->m_pLWMenu->addAction(new QAction(LW_MENU_SAVE_FILE, this->m_pLWMenu));
	this->m_pLWMenu->addAction(new QAction(LW_MENU_MARK_SELECTED, this->m_pLWMenu));
	connect(this->m_pLWMenu, &QMenu::triggered, this, &CPacketUI::menuTriggered);


	connect(this->m_oUI.lwPacketList, &QListWidget::customContextMenuRequested, [&](const QPoint &i_oPoint) { this->m_pLWMenu->exec(mapToGlobal(i_oPoint)); });
	connect(this, &CPacketUI::addPacket, this, &CPacketUI::onAddPacket);
}

CPacketUI::~CPacketUI()
{

}


void CPacketUI::onAdvancedLWMove(QMouseEvent *i_pEvent)
{
	const QPointF &oMousePos = i_pEvent->localPos();

#pragma region Handle Settings GroupBox
	{
		QPoint oGroupBox = this->m_oUI.gbLoggerSettings->pos();
		QSize oGroupBoxSize = this->m_oUI.gbLoggerSettings->size();
		bool fIsShown = false;

		if (oMousePos.x() >= oGroupBox.x() && oMousePos.x() <= (oGroupBox.x() + oGroupBoxSize.width() - 3)) {
			if (oMousePos.y() >= oGroupBox.y() && oMousePos.y() <= (oGroupBox.y() + oGroupBoxSize.height() - 3)) {
				if (this->m_oUI.gbLoggerSettings->isHidden()) {
					this->m_oUI.gbLoggerSettings->show();
					this->m_oUI.lwPacketList->setDisabled(true);
					this->m_oUI.lwPacketList->setSelectionMode(QAbstractItemView::SelectionMode::NoSelection);
				}

				fIsShown = true;
			}
		}

		if (!fIsShown) onAdvancedGBLeave(nullptr);
	}
#pragma endregion
}

void CPacketUI::onAdvancedGBLeave(QEvent *i_pEvent)
{
	if (!this->m_oUI.gbLoggerSettings->isHidden()) {
		this->m_oUI.gbLoggerSettings->hide();
		this->m_oUI.lwPacketList->setDisabled(false);
		this->m_oUI.lwPacketList->setSelectionMode(QAbstractItemView::SelectionMode::ExtendedSelection);
	}
}

void CPacketUI::onLogClearClicked()
{
	this->m_oUI.lwPacketList->clear();
}


void CPacketUI::closeEvent(QCloseEvent *i_pEvent)
{
	m_oRecvFilter.safe(true);
	m_oSendFilter.safe(true);
	
	QApplication::exit();
}

void CPacketUI::menuTriggered(QAction *i_pAction)
{
	if (i_pAction->text() == LW_MENU_SAVE_FILE) {
		QFileDialog oDialog;
		oDialog.setWindowTitle("Select File");
		oDialog.setNameFilter("File (*.*)");
		oDialog.setFileMode(QFileDialog::FileMode::AnyFile);

		if (oDialog.exec()) {
			QString sFile = oDialog.selectedFiles()[0];
			
			QFile oFile(sFile);
			if (oFile.open(QIODevice::OpenModeFlag::WriteOnly)) {
				QTextStream oStream(&oFile);
				for (int i = 0, iSize = this->m_oUI.lwPacketList->count(); i < iSize; i++)
					oStream << this->m_oUI.lwPacketList->item(i)->text() << "\n";

				QMessageBox::information(0, "[PacketLogger] - Information", "File saved in '" + sFile + "'!");
			}
			else
				QMessageBox::warning(0, "[PacketLogger] - Error", "Couldn't open File '" + sFile + "'!");
		}
	}
	else if (i_pAction->text() == LW_MENU_RESEND_PACKET) {
		QList<QListWidgetItem *> apItems = this->m_oUI.lwPacketList->selectedItems();
		if (apItems.size() > 0) {
			for (QListWidgetItem *pItem : apItems) {
				QStringList asRawPacket = pItem->text().split(SPLIT_PACKET);
				if (asRawPacket.size() < 3) continue;

				if (pItem->text().contains(SPLIT_PACKET SEND_PREFIX))
					SendPacket(asRawPacket[2]);
				else if (pItem->text().contains(SPLIT_PACKET RECV_PREFIX))
					RecvPacket(asRawPacket[2]);

				std::this_thread::sleep_for(std::chrono::milliseconds(3));
			}
		}
	}
	else if (i_pAction->text() == LW_MENU_COPY_SELECTED) {
		QList<QListWidgetItem *> apItems = this->m_oUI.lwPacketList->selectedItems();
		if (apItems.size() > 0) {
			if (apItems.size() > 1) {
				while (true) {
					bool fChanged = false;
					for (int i = 0; (i + 1) < apItems.size(); i++) {
						if (this->m_oUI.lwPacketList->row(apItems[i]) > this->m_oUI.lwPacketList->row(apItems[i + 1])) {
							apItems.swap(i, i + 1);
							fChanged = true;
						}
					}

					if (!fChanged) break;
				}
			}

			QString sText = "";

			for (QListWidgetItem *pItem : apItems) {
				QStringList asRawPacket = pItem->text().split(SPLIT_PACKET);
				if (asRawPacket.size() < 3) continue;

				sText += asRawPacket[2] + "\n";
			}

			QApplication::clipboard()->setText(sText);
		}
	}
	else if (i_pAction->text() == LW_MENU_MARK_SELECTED) {
		QList<QListWidgetItem *> apItems = this->m_oUI.lwPacketList->selectedItems();
		if (apItems.size() > 0) {
			for (QListWidgetItem *pItem : apItems)
				pItem->setBackground((pItem->backgroundColor() == g_oBackgroundColor) ? g_oMarkedColor : g_oBackgroundColor);
		}
	}
}


QString packetPrefix(const EPacketType i_eType) {
	switch (i_eType)
	{
		case EPacketType::PTReceive:
			return QString::fromUtf8(RECV_PREFIX);
		case EPacketType::PTSend:
			return QString::fromUtf8(SEND_PREFIX);
		default:
			return QString::fromUtf8(UNKNOWN_PREFIX);
	}
}

void CPacketUI::onAddPacket(const QString &i_sPacket, int i_iPacketType) {
#ifdef ACTIVATE_FEATURE_TCP_SERVER
	emit g_pTcpServer->broadcastPacket(i_sPacket, i_iPacketType);
#endif

	if ((i_iPacketType == EPacketType::PTReceive && (!this->m_oUI.cbLogReceivePackets->isChecked() || this->m_oRecvFilter.isFiltered(i_sPacket))) ||
		(i_iPacketType == EPacketType::PTSend	 && (!this->m_oUI.cbLogSendPackets->isChecked()	   || this->m_oSendFilter.isFiltered(i_sPacket))))
		return;

	QListWidgetItem *pItem = new QListWidgetItem(QString::fromUtf8(START_SPLIT_PACKET) + QTime::currentTime().toString("hh:mm:ss").toUtf8() + QString::fromUtf8(SPLIT_PACKET) + packetPrefix(static_cast<EPacketType>(i_iPacketType)) + i_sPacket);
	pItem->setToolTip(i_sPacket);
	pItem->setBackgroundColor(g_oBackgroundColor);
	this->m_oUI.lwPacketList->addItem(pItem);
	
	if (this->m_oUI.cbAutoScroll->isChecked())
		this->m_oUI.lwPacketList->scrollToBottom();
}