#include "FilterUI.h"
#include "PacketUI.h"
#include "Config.h"

#include <QTimer>
#include <QMessageBox>
#include <iostream>


CFilterUI::CFilterUI(CPacketUI *i_pParent, const QString &i_sName)
	: QWidget(i_pParent, Qt::Window), m_sName(i_sName)
{
	this->m_oUI.setupUi(this);

	this->setMinimumSize(this->size());
	this->setMaximumSize(this->size());

	this->setWindowTitle("[PacketLogger] " + i_sName + " Filter");
}

CFilterUI::~CFilterUI()
{

}


void CFilterUI::closeEvent(QCloseEvent *i_pEvent)
{
	i_pEvent->ignore();
	this->hide();
}

void CFilterUI::add(const QString &i_sFilter, const EFilter i_eFilter, const bool i_fSave)
{
	QMutexLocker oLocker(&this->m_oMutex);

	if (i_sFilter.isEmpty()) {
		QTimer::singleShot(1, []() { QMessageBox::warning(nullptr, "[PacketLogger] - Error", "Filter is empty!"); });
		return;
	}
	
	for (int i = 0, iSize = this->m_apFilter.size(); i < iSize; i++) {
		SFilter *pFilter = this->m_apFilter[i];
		if (pFilter && pFilter->sFilter == i_sFilter && pFilter->eFilter == i_eFilter) {
			QTimer::singleShot(1, []() { QMessageBox::warning(nullptr, "[PacketLogger] - Error", "Filter does already exist!"); });
			return;
		}
	}

	QListWidgetItem *pItem = new QListWidgetItem(i_sFilter);
	pItem->setToolTip(i_sFilter);

	this->m_oUI.lwFilter->addItem(pItem);

	SFilter *pFilter = new SFilter();
	pFilter->sFilter = i_sFilter;
	pFilter->eFilter = i_eFilter;

	pItem->setData(Qt::UserRole, QVariant::fromValue<SFilter *>(pFilter));

	this->m_apFilter << pFilter;

	if (i_fSave) this->safe();
}

void CFilterUI::safe(const bool i_fDelete)
{
	Config::SaveFilter(this->m_sName, this->m_apFilter);

	if (i_fDelete) {
		QMutexLocker oLocker(&this->m_oMutex);
		for (SFilter *pFilter : this->m_apFilter)
			delete pFilter;

		this->m_apFilter.clear();
	}
}


bool CFilterUI::isFiltered(const QString &i_sPacket)
{
	if (!this->m_oUI.cbActivated->isChecked()) return false;

	QMutexLocker oLocker(&this->m_oMutex);

	for (int i = 0, iSize = this->m_apFilter.size(); i < iSize; i++) {
		SFilter *pFilter = this->m_apFilter[i];
		if (pFilter) {
			bool fFound = false;

			switch (pFilter->eFilter)
			{
				case EFilter::FBeginsWith:
					fFound = i_sPacket.startsWith(pFilter->sFilter, Qt::CaseInsensitive);
					break;
				case EFilter::FContains:
					fFound = i_sPacket.contains(pFilter->sFilter, Qt::CaseInsensitive);
					break;
				case EFilter::FRegularExpression:
					fFound = i_sPacket.contains(QRegularExpression(pFilter->sFilter));
					break;
				case EFilter::FEndsWith:
					fFound = i_sPacket.endsWith(pFilter->sFilter, Qt::CaseInsensitive);
					break;
				case EFilter::FPacketName:
				{
					QStringList asPacket = i_sPacket.split(' ');
					fFound = (asPacket.size() > 0 ? asPacket[0] == pFilter->sFilter : false);
					break;
				}
			}

			if ((this->m_oUI.rbBlacklist->isChecked() && fFound))
				return true;

			if (this->m_oUI.rbWhitelist->isChecked() && fFound)
				return false;
		}
	}

	return (this->m_oUI.rbBlacklist->isChecked() ? false : true);
}


void CFilterUI::onAddPressed()
{
	EFilter eFilter = EFilter::FBeginsWith;
	//if (this->m_oUI.rbBeginWith->isChecked()) eFilter = EFilter::FBeginsWith;
	if (this->m_oUI.rbContains->isChecked()) eFilter = EFilter::FContains;
	if (this->m_oUI.rbRegular->isChecked()) eFilter = EFilter::FRegularExpression;
	if (this->m_oUI.rbEndsWith->isChecked()) eFilter = EFilter::FEndsWith;
	if (this->m_oUI.rbPacketName->isChecked()) eFilter = EFilter::FPacketName;

	this->add(this->m_oUI.leFilterData->text(), eFilter);

	this->m_oUI.leFilterData->clear();
	this->m_oUI.leFilterData->setFocus();
}

void CFilterUI::onRemovePressed()
{
	QMutexLocker oLocker(&this->m_oMutex);

	QList<QListWidgetItem *> apItems = this->m_oUI.lwFilter->selectedItems();
	if (apItems.size() > 0) {
		SFilter *pFilter = apItems[0]->data(Qt::UserRole).value<SFilter *>();
		
		qDeleteAll(apItems);

		this->m_apFilter.removeOne(pFilter);
		delete pFilter;

		this->safe();
	}
}

void CFilterUI::onReturnPressed()
{
	this->onAddPressed();
}