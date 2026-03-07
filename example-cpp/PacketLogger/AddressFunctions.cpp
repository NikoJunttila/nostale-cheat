#include "AddressFunctions.h"
#include "AddressManager.h"


class CNosString
{
private:
	std::size_t m_nLength;
	char m_szPacket[5192];

public:
	CNosString(char *i_szPacket)
	{
		m_nLength = strlen(i_szPacket);
		memcpy(m_szPacket, i_szPacket, m_nLength);
		m_szPacket[m_nLength] = 0;
	}

	char *data()		{ return this->m_szPacket; }
	size_t size() const { return this->m_nLength; }
};


void SendPacket(const QString &i_sString)
{
	QByteArray abData(i_sString.toLocal8Bit());
	CNosString oString(abData.data());
	char *szPacket(oString.data());

	DWORD dwPacketClass = AddressManager::Get(EAddress::APacketClassPointer);
	DWORD dwPacketCall = AddressManager::Get(EAddress::ASendPacket);

	__asm {
		mov eax, dword ptr ds : [dwPacketClass]
		mov eax, dword ptr ds : [eax]
		mov eax, dword ptr ds : [eax]
		mov edx, szPacket
		call dwPacketCall
	}
}

void RecvPacket(const QString &i_sString)
{
	QByteArray abData(i_sString.toLocal8Bit());
	CNosString oString(abData.data());
	char *szPacket(oString.data());

	DWORD dwPacketClass = AddressManager::Get(EAddress::APacketClassPointer);
	DWORD dwPacketCall = AddressManager::Get(EAddress::ARecvPacket);

	__asm {
		mov eax, dword ptr ds : [dwPacketClass]
		mov eax, dword ptr ds : [eax]
		mov eax, dword ptr ds : [eax]
		mov eax, dword ptr ds : [eax + 34h]
		mov edx, szPacket
		call dwPacketCall
	}
}