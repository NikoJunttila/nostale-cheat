#pragma once
#include <QString>
#include <QList>

#define DIR_NAME				"BTPLConfig"
#define FILTER_NAME				DIR_NAME "/Filters_"
#define GET_FILTER(x)			FILTER_NAME + x + ".ini"

#define FILTER_MACRO_RECV		"Receive"
#define FILTER_MACRO_SEND		"Send"

#define FILTER_MACRO_RECV_BLOCK	"Receive_Block"
#define FILTER_MACRO_SEND_BLOCK	"Send_Block"

#define GET_FILTER_MACRO(x)		FILTER_NAME x ".ini"
#define GET_FILTER_RECV			GET_FILTER_MACRO(FILTER_MACRO_RECV)
#define GET_FILTER_SEND			GET_FILTER_MACRO(FILTER_MACRO_SEND)

#define GET_FILTER_RECV_BLOCK	GET_FILTER_MACRO(FILTER_MACRO_RECV_BLOCK)
#define GET_FILTER_SEND_BLOCK	GET_FILTER_MACRO(FILTER_MACRO_SEND_BLOCK)

struct SFilter;
class CPacketUI;
namespace Config {
	void Initialize();
	void LoadFilter(const QString &i_sName);
	void SaveFilter(const QString &i_sName, const QList<SFilter *> &i_apFilter);
}