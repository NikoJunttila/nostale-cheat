#include "Defines.h"
#include <Windows.h>
#include <QApplication>
#include <iostream>

#include "AddressManager.h"
#include "HookManager.h"
#include "TcpServer.h"
#include "PacketUI.h"
#include "Config.h"


CPacketUI *g_pUi;
HANDLE g_oDllMutex;

#ifdef ACTIVATE_FEATURE_TCP_SERVER
CTcpServer *g_pTcpServer;
#endif

DWORD WINAPI Main()
{
	g_oDllMutex = CreateMutexA(nullptr, true, ("BTPLNOSTALE" + std::to_string(GetCurrentProcessId())).c_str());
	if (g_oDllMutex == nullptr || GetLastError() == ERROR_ALREADY_EXISTS) {
		if (g_oDllMutex)
			CloseHandle(g_oDllMutex);

		return 0;
	}

#ifdef ACTIVATE_CONSOLE
	FILE *stream; AllocConsole(); freopen_s(&stream, "CONOUT$", "w+", stdout);
#endif

	QApplication app(__argc, __argv);
	QObject::connect(&app, &QApplication::aboutToQuit, []() {
#ifdef ACTIVATE_FEATURE_TCP_SERVER
		if (g_pTcpServer)
		{
			g_pTcpServer->stop();
		}
#endif

		HookManager::Unhook();
		CloseHandle(g_oDllMutex);
		delete g_pUi;
	});

	AddressManager::Initialize();
	
	g_pUi = new CPacketUI();
	Config::Initialize();
	g_pUi->show();

#ifdef ACTIVATE_FEATURE_TCP_SERVER
	g_pTcpServer = new CTcpServer();
	if (g_pTcpServer->isListening())
	{
		g_pUi->setWindowTitle(g_pUi->windowTitle() + " - Server: " + g_pTcpServer->serverAddress().toString() + ":" + QString::number(g_pTcpServer->serverPort()));
	} else
	{
		g_pUi->setWindowTitle(g_pUi->windowTitle() + " - Couldn't start server! Error: " + g_pTcpServer->errorString());
	}
#endif

	return app.exec();
}
#include <thread>

BOOL APIENTRY DllMain(const HMODULE i_hModule, const DWORD i_ulReasonForCall, LPVOID /*i_lpReserved*/)
{
	switch (i_ulReasonForCall)
	{
		case DLL_PROCESS_ATTACH:
			CreateThread(nullptr, 0, reinterpret_cast<LPTHREAD_START_ROUTINE>(Main), nullptr, 0, nullptr);
			DisableThreadLibraryCalls(i_hModule);
			break;
		default: break;
	}
	return TRUE;
}