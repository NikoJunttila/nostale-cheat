/********************************************************************************
** Form generated from reading UI file 'PacketSenderUI.ui'
**
** Created by: Qt User Interface Compiler version 5.15.2
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_PACKETSENDERUI_H
#define UI_PACKETSENDERUI_H

#include <QtCore/QVariant>
#include <QtWidgets/QApplication>
#include <QtWidgets/QGroupBox>
#include <QtWidgets/QLabel>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QSpinBox>
#include <QtWidgets/QTextEdit>

QT_BEGIN_NAMESPACE

class Ui_CPacketSenderUI
{
public:
    QTextEdit *teSendPackets;
    QPushButton *pbSend;
    QPushButton *pbSpam;
    QSpinBox *sbTime;
    QLabel *lTime;

    void setupUi(QGroupBox *CPacketSenderUI)
    {
        if (CPacketSenderUI->objectName().isEmpty())
            CPacketSenderUI->setObjectName(QString::fromUtf8("CPacketSenderUI"));
        CPacketSenderUI->resize(409, 180);
        teSendPackets = new QTextEdit(CPacketSenderUI);
        teSendPackets->setObjectName(QString::fromUtf8("teSendPackets"));
        teSendPackets->setGeometry(QRect(10, 20, 391, 121));
        pbSend = new QPushButton(CPacketSenderUI);
        pbSend->setObjectName(QString::fromUtf8("pbSend"));
        pbSend->setGeometry(QRect(10, 150, 81, 23));
        pbSpam = new QPushButton(CPacketSenderUI);
        pbSpam->setObjectName(QString::fromUtf8("pbSpam"));
        pbSpam->setGeometry(QRect(160, 150, 81, 23));
        pbSpam->setAutoDefault(false);
        pbSpam->setFlat(false);
        sbTime = new QSpinBox(CPacketSenderUI);
        sbTime->setObjectName(QString::fromUtf8("sbTime"));
        sbTime->setGeometry(QRect(290, 150, 111, 22));
        sbTime->setMinimum(50);
        sbTime->setMaximum(2000000000);
        sbTime->setValue(100);
        lTime = new QLabel(CPacketSenderUI);
        lTime->setObjectName(QString::fromUtf8("lTime"));
        lTime->setGeometry(QRect(250, 152, 38, 16));

        retranslateUi(CPacketSenderUI);
        QObject::connect(pbSend, SIGNAL(clicked()), CPacketSenderUI, SLOT(onSendPacket()));
        QObject::connect(pbSpam, SIGNAL(clicked()), CPacketSenderUI, SLOT(onSpamPacket()));

        pbSpam->setDefault(false);


        QMetaObject::connectSlotsByName(CPacketSenderUI);
    } // setupUi

    void retranslateUi(QGroupBox *CPacketSenderUI)
    {
        CPacketSenderUI->setWindowTitle(QString());
        pbSend->setText(QCoreApplication::translate("CPacketSenderUI", "Send", nullptr));
        pbSpam->setText(QCoreApplication::translate("CPacketSenderUI", "Start", nullptr));
        sbTime->setSuffix(QCoreApplication::translate("CPacketSenderUI", "ms", nullptr));
        lTime->setText(QCoreApplication::translate("CPacketSenderUI", "Time:", nullptr));
    } // retranslateUi

};

namespace Ui {
    class CPacketSenderUI: public Ui_CPacketSenderUI {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_PACKETSENDERUI_H
