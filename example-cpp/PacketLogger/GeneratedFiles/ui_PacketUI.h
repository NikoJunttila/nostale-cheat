/********************************************************************************
** Form generated from reading UI file 'PacketUI.ui'
**
** Created by: Qt User Interface Compiler version 5.15.2
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_PACKETUI_H
#define UI_PACKETUI_H

#include <QtCore/QVariant>
#include <QtWidgets/QApplication>
#include <QtWidgets/QCheckBox>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QWidget>
#include "AdvancedGroupBox.h"
#include "AdvancedListWidget.h"

QT_BEGIN_NAMESPACE

class Ui_CPacketUI
{
public:
    CAdvancedListWidget *lwPacketList;
    CAdvancedGroupBox *gbLoggerSettings;
    QCheckBox *cbAutoScroll;
    QCheckBox *cbLogSendPackets;
    QCheckBox *cbLogReceivePackets;
    QPushButton *pbClearLog;
    QPushButton *pbRecvFilter;
    QPushButton *pbSendFilter;
    QPushButton *pbSendBlocker;
    QPushButton *pbRecvBlocker;
    QPushButton *pbSender;

    void setupUi(QWidget *CPacketUI)
    {
        if (CPacketUI->objectName().isEmpty())
            CPacketUI->setObjectName(QString::fromUtf8("CPacketUI"));
        CPacketUI->resize(701, 401);
        CPacketUI->setStyleSheet(QString::fromUtf8("QTextEdit,QGroupBox,QListWidget,QLabel,QCheckBox,QRadioButton,QPushButton,QLineEdit {\n"
"	background-color: #1E1E1E;\n"
"	font: 9pt \"Verdana\";\n"
"	color: white;\n"
"}\n"
"\n"
"QPushButton {\n"
"	background-color: rgb(70, 70, 70);\n"
"}"));
        lwPacketList = new CAdvancedListWidget(CPacketUI);
        lwPacketList->setObjectName(QString::fromUtf8("lwPacketList"));
        lwPacketList->setGeometry(QRect(0, 0, 701, 401));
        lwPacketList->setLineWidth(1);
        lwPacketList->setVerticalScrollBarPolicy(Qt::ScrollBarAlwaysOn);
        lwPacketList->setHorizontalScrollBarPolicy(Qt::ScrollBarAlwaysOff);
        lwPacketList->setSizeAdjustPolicy(QAbstractScrollArea::AdjustIgnored);
        lwPacketList->setEditTriggers(QAbstractItemView::NoEditTriggers);
        lwPacketList->setSelectionMode(QAbstractItemView::ExtendedSelection);
        lwPacketList->setVerticalScrollMode(QAbstractItemView::ScrollPerItem);
        lwPacketList->setHorizontalScrollMode(QAbstractItemView::ScrollPerItem);
        lwPacketList->setWordWrap(false);
        lwPacketList->setSelectionRectVisible(false);
        gbLoggerSettings = new CAdvancedGroupBox(CPacketUI);
        gbLoggerSettings->setObjectName(QString::fromUtf8("gbLoggerSettings"));
        gbLoggerSettings->setGeometry(QRect(460, 290, 205, 101));
        cbAutoScroll = new QCheckBox(gbLoggerSettings);
        cbAutoScroll->setObjectName(QString::fromUtf8("cbAutoScroll"));
        cbAutoScroll->setGeometry(QRect(12, 74, 51, 17));
        QFont font;
        font.setFamily(QString::fromUtf8("Verdana"));
        font.setPointSize(9);
        font.setBold(false);
        font.setItalic(false);
        font.setWeight(50);
        cbAutoScroll->setFont(font);
        cbAutoScroll->setChecked(true);
        cbLogSendPackets = new QCheckBox(gbLoggerSettings);
        cbLogSendPackets->setObjectName(QString::fromUtf8("cbLogSendPackets"));
        cbLogSendPackets->setGeometry(QRect(10, 20, 81, 17));
        cbLogSendPackets->setFont(font);
        cbLogSendPackets->setChecked(true);
        cbLogReceivePackets = new QCheckBox(gbLoggerSettings);
        cbLogReceivePackets->setObjectName(QString::fromUtf8("cbLogReceivePackets"));
        cbLogReceivePackets->setGeometry(QRect(10, 40, 81, 17));
        cbLogReceivePackets->setFont(font);
        cbLogReceivePackets->setChecked(true);
        pbClearLog = new QPushButton(gbLoggerSettings);
        pbClearLog->setObjectName(QString::fromUtf8("pbClearLog"));
        pbClearLog->setGeometry(QRect(90, 70, 51, 21));
        pbClearLog->setFont(font);
        pbRecvFilter = new QPushButton(gbLoggerSettings);
        pbRecvFilter->setObjectName(QString::fromUtf8("pbRecvFilter"));
        pbRecvFilter->setGeometry(QRect(90, 40, 51, 21));
        pbRecvFilter->setFont(font);
        pbRecvFilter->setStyleSheet(QString::fromUtf8(""));
        pbSendFilter = new QPushButton(gbLoggerSettings);
        pbSendFilter->setObjectName(QString::fromUtf8("pbSendFilter"));
        pbSendFilter->setGeometry(QRect(90, 20, 51, 21));
        pbSendFilter->setFont(font);
        pbSendFilter->setStyleSheet(QString::fromUtf8(""));
        pbSendBlocker = new QPushButton(gbLoggerSettings);
        pbSendBlocker->setObjectName(QString::fromUtf8("pbSendBlocker"));
        pbSendBlocker->setGeometry(QRect(145, 20, 55, 21));
        pbSendBlocker->setFont(font);
        pbSendBlocker->setStyleSheet(QString::fromUtf8(""));
        pbRecvBlocker = new QPushButton(gbLoggerSettings);
        pbRecvBlocker->setObjectName(QString::fromUtf8("pbRecvBlocker"));
        pbRecvBlocker->setGeometry(QRect(145, 40, 55, 21));
        pbRecvBlocker->setFont(font);
        pbRecvBlocker->setStyleSheet(QString::fromUtf8(""));
        pbSender = new QPushButton(gbLoggerSettings);
        pbSender->setObjectName(QString::fromUtf8("pbSender"));
        pbSender->setGeometry(QRect(145, 70, 55, 21));
        pbSender->setFont(font);
        pbSender->setStyleSheet(QString::fromUtf8(""));
        QWidget::setTabOrder(cbLogSendPackets, pbSendFilter);
        QWidget::setTabOrder(pbSendFilter, cbLogReceivePackets);
        QWidget::setTabOrder(cbLogReceivePackets, pbRecvFilter);
        QWidget::setTabOrder(pbRecvFilter, cbAutoScroll);
        QWidget::setTabOrder(cbAutoScroll, pbClearLog);
        QWidget::setTabOrder(pbClearLog, lwPacketList);

        retranslateUi(CPacketUI);
        QObject::connect(lwPacketList, SIGNAL(mouseMoveEvent(QMouseEvent*)), CPacketUI, SLOT(onAdvancedLWMove(QMouseEvent*)));
        QObject::connect(pbClearLog, SIGNAL(clicked()), CPacketUI, SLOT(onLogClearClicked()));
        QObject::connect(gbLoggerSettings, SIGNAL(leaveEvent(QEvent*)), CPacketUI, SLOT(onAdvancedGBLeave(QEvent*)));
        QObject::connect(pbSendFilter, SIGNAL(clicked()), CPacketUI, SLOT(onSendFilter()));
        QObject::connect(pbRecvFilter, SIGNAL(clicked()), CPacketUI, SLOT(onRecvFilter()));
        QObject::connect(pbSendBlocker, SIGNAL(clicked()), CPacketUI, SLOT(onSendBlocker()));
        QObject::connect(pbRecvBlocker, SIGNAL(clicked()), CPacketUI, SLOT(onRecvBlocker()));
        QObject::connect(pbSender, SIGNAL(clicked()), CPacketUI, SLOT(onSenderPressed()));

        QMetaObject::connectSlotsByName(CPacketUI);
    } // setupUi

    void retranslateUi(QWidget *CPacketUI)
    {
        CPacketUI->setWindowTitle(QCoreApplication::translate("CPacketUI", "[BladeTiger12] - NosTale PacketLogger", nullptr));
        gbLoggerSettings->setTitle(QCoreApplication::translate("CPacketUI", "Settings", nullptr));
        cbAutoScroll->setText(QCoreApplication::translate("CPacketUI", "Scroll", nullptr));
        cbLogSendPackets->setText(QCoreApplication::translate("CPacketUI", "Log Send", nullptr));
        cbLogReceivePackets->setText(QCoreApplication::translate("CPacketUI", "Log Recv", nullptr));
        pbClearLog->setText(QCoreApplication::translate("CPacketUI", "Clear", nullptr));
        pbRecvFilter->setText(QCoreApplication::translate("CPacketUI", "Filter", nullptr));
        pbSendFilter->setText(QCoreApplication::translate("CPacketUI", "Filter", nullptr));
        pbSendBlocker->setText(QCoreApplication::translate("CPacketUI", "Blocker", nullptr));
        pbRecvBlocker->setText(QCoreApplication::translate("CPacketUI", "Blocker", nullptr));
        pbSender->setText(QCoreApplication::translate("CPacketUI", "Sender", nullptr));
    } // retranslateUi

};

namespace Ui {
    class CPacketUI: public Ui_CPacketUI {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_PACKETUI_H
