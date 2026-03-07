#include "Config.h"
#include "PacketUI.h"
#include "FilterUI.h"

#include <QSettings>
#include <QFile>
#include <QDir>


extern CPacketUI *g_pUi;



void CheckConfigFolder()
{
	QDir oDirConfig(DIR_NAME);
	if (!oDirConfig.exists())
	{
		// ReSharper disable once CppExpressionWithoutSideEffects
		oDirConfig.mkdir(".");
	}
}

void Config::Initialize()
{
	CheckConfigFolder();
	LoadFilter(FILTER_MACRO_SEND);
	LoadFilter(FILTER_MACRO_RECV);

	LoadFilter(FILTER_MACRO_SEND_BLOCK);
	LoadFilter(FILTER_MACRO_RECV_BLOCK);
}

void Config::LoadFilter(const QString &i_sName)
{
	QSettings oSettings(GET_FILTER(i_sName), QSettings::IniFormat);
	CFilterUI *pFilterUi = nullptr;

	if (i_sName == FILTER_MACRO_SEND)		pFilterUi = &g_pUi->sendFilter();
	if (i_sName == FILTER_MACRO_RECV)		pFilterUi = &g_pUi->recvFilter();

	if (i_sName == FILTER_MACRO_SEND_BLOCK) pFilterUi = &g_pUi->sendBlocker();
	if (i_sName == FILTER_MACRO_RECV_BLOCK) pFilterUi = &g_pUi->recvBlocker();
	
	if (pFilterUi) {
		QStringList asGroups(oSettings.childGroups());
		for (const QString &sGroup : asGroups) {
			oSettings.beginGroup(sGroup);
			pFilterUi->add(
				oSettings.value("Filter").toString(),
				static_cast<EFilter>(oSettings.value("Compare").toInt()),
				false
			);
			oSettings.endGroup();
		}
	}
}

void Config::SaveFilter(const QString &i_sName, const QList<SFilter *> &i_apFilter)
{
	CheckConfigFolder();

	QFile::remove(GET_FILTER(i_sName));
	QSettings oSettings(GET_FILTER(i_sName), QSettings::IniFormat);

	int i = 0;
	for (SFilter *pFilter : i_apFilter) {
		oSettings.beginGroup(QString::number(i++));
		oSettings.setValue("Filter", pFilter->sFilter);
		oSettings.setValue("Compare", pFilter->eFilter);
		oSettings.endGroup();
	}
}