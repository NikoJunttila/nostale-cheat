#pragma once
#include <QWidget>
#include <QMutex>
#include "ui_FilterUI.h"


enum EFilter {
	FBeginsWith,
	FContains,
	FRegularExpression,
	FEndsWith,
	FPacketName,
};
struct SFilter {
public:
	QString sFilter;
	EFilter eFilter;

public:
	SFilter()
		: eFilter(EFilter::FBeginsWith)
	{ }

	SFilter(const SFilter &i_oOther) {
		this->sFilter = i_oOther.sFilter;
		this->eFilter = i_oOther.eFilter;
	}

	~SFilter() = default;
};
Q_DECLARE_METATYPE(SFilter *)


class CPacketUI;
class CFilterUI : public QWidget
{
	Q_OBJECT

public:
	CFilterUI(CPacketUI *i_pParent, const QString &i_sName);
	~CFilterUI();

public:
	void add(const QString &i_sFilter, EFilter i_eFilter, bool i_fSave = true);
	void safe(bool i_fDelete = false);
	bool isFiltered(const QString &i_sPacket);

private:
	void closeEvent(QCloseEvent *i_pEvent) override;

private slots:
	void onAddPressed();
	void onRemovePressed();
	void onReturnPressed();

private:
	Ui::CFilterUI m_oUI;

	QString m_sName;

	QMutex m_oMutex;
	QList<SFilter *> m_apFilter;
};