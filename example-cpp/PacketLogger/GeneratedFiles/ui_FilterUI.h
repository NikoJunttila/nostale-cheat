/********************************************************************************
** Form generated from reading UI file 'FilterUI.ui'
**
** Created by: Qt User Interface Compiler version 5.15.2
**
** WARNING! All changes made in this file will be lost when recompiling UI file!
********************************************************************************/

#ifndef UI_FILTERUI_H
#define UI_FILTERUI_H

#include <QtCore/QVariant>
#include <QtWidgets/QApplication>
#include <QtWidgets/QButtonGroup>
#include <QtWidgets/QCheckBox>
#include <QtWidgets/QLabel>
#include <QtWidgets/QLineEdit>
#include <QtWidgets/QListWidget>
#include <QtWidgets/QPushButton>
#include <QtWidgets/QRadioButton>
#include <QtWidgets/QWidget>

QT_BEGIN_NAMESPACE

class Ui_CFilterUI
{
public:
    QListWidget *lwFilter;
    QLineEdit *leFilterData;
    QLabel *lFilter;
    QRadioButton *rbContains;
    QRadioButton *rbRegular;
    QRadioButton *rbBeginWith;
    QRadioButton *rbEndsWith;
    QPushButton *pbAdd;
    QPushButton *pbRemove;
    QRadioButton *rbWhitelist;
    QRadioButton *rbBlacklist;
    QCheckBox *cbActivated;
    QRadioButton *rbPacketName;
    QButtonGroup *bg1;
    QButtonGroup *bg2;

    void setupUi(QWidget *CFilterUI)
    {
        if (CFilterUI->objectName().isEmpty())
            CFilterUI->setObjectName(QString::fromUtf8("CFilterUI"));
        CFilterUI->resize(328, 372);
        CFilterUI->setStyleSheet(QString::fromUtf8("QTextEdit,QGroupBox,QListWidget,QLabel,QCheckBox,QRadioButton,QPushButton,QLineEdit {\n"
"	background-color: #1E1E1E;\n"
"	font: 8pt \"Verdana\";\n"
"	color: white;\n"
"}\n"
"\n"
"QPushButton {\n"
"	background-color: rgb(70, 70, 70);\n"
"}\n"
"\n"
"#CFilterUI {\n"
"	background-color: #1E1E1E;\n"
"}"));
        lwFilter = new QListWidget(CFilterUI);
        lwFilter->setObjectName(QString::fromUtf8("lwFilter"));
        lwFilter->setGeometry(QRect(0, 0, 161, 371));
        leFilterData = new QLineEdit(CFilterUI);
        leFilterData->setObjectName(QString::fromUtf8("leFilterData"));
        leFilterData->setGeometry(QRect(170, 50, 151, 24));
        lFilter = new QLabel(CFilterUI);
        lFilter->setObjectName(QString::fromUtf8("lFilter"));
        lFilter->setGeometry(QRect(170, 30, 47, 13));
        lFilter->setStyleSheet(QString::fromUtf8("font-size: 14px;"));
        rbContains = new QRadioButton(CFilterUI);
        bg2 = new QButtonGroup(CFilterUI);
        bg2->setObjectName(QString::fromUtf8("bg2"));
        bg2->addButton(rbContains);
        rbContains->setObjectName(QString::fromUtf8("rbContains"));
        rbContains->setGeometry(QRect(170, 120, 71, 17));
        rbContains->setChecked(false);
        rbRegular = new QRadioButton(CFilterUI);
        bg2->addButton(rbRegular);
        rbRegular->setObjectName(QString::fromUtf8("rbRegular"));
        rbRegular->setGeometry(QRect(170, 150, 131, 17));
        rbBeginWith = new QRadioButton(CFilterUI);
        bg2->addButton(rbBeginWith);
        rbBeginWith->setObjectName(QString::fromUtf8("rbBeginWith"));
        rbBeginWith->setGeometry(QRect(170, 90, 91, 17));
        rbBeginWith->setChecked(true);
        rbEndsWith = new QRadioButton(CFilterUI);
        bg2->addButton(rbEndsWith);
        rbEndsWith->setObjectName(QString::fromUtf8("rbEndsWith"));
        rbEndsWith->setGeometry(QRect(170, 180, 81, 17));
        pbAdd = new QPushButton(CFilterUI);
        pbAdd->setObjectName(QString::fromUtf8("pbAdd"));
        pbAdd->setGeometry(QRect(177, 290, 141, 31));
        pbRemove = new QPushButton(CFilterUI);
        pbRemove->setObjectName(QString::fromUtf8("pbRemove"));
        pbRemove->setGeometry(QRect(177, 330, 141, 31));
        rbWhitelist = new QRadioButton(CFilterUI);
        bg1 = new QButtonGroup(CFilterUI);
        bg1->setObjectName(QString::fromUtf8("bg1"));
        bg1->addButton(rbWhitelist);
        rbWhitelist->setObjectName(QString::fromUtf8("rbWhitelist"));
        rbWhitelist->setGeometry(QRect(250, 250, 71, 17));
        rbWhitelist->setChecked(false);
        rbBlacklist = new QRadioButton(CFilterUI);
        bg1->addButton(rbBlacklist);
        rbBlacklist->setObjectName(QString::fromUtf8("rbBlacklist"));
        rbBlacklist->setGeometry(QRect(170, 250, 71, 17));
        rbBlacklist->setChecked(true);
        cbActivated = new QCheckBox(CFilterUI);
        cbActivated->setObjectName(QString::fromUtf8("cbActivated"));
        cbActivated->setGeometry(QRect(170, 5, 111, 17));
        cbActivated->setChecked(true);
        rbPacketName = new QRadioButton(CFilterUI);
        bg2->addButton(rbPacketName);
        rbPacketName->setObjectName(QString::fromUtf8("rbPacketName"));
        rbPacketName->setGeometry(QRect(170, 210, 101, 17));
        QWidget::setTabOrder(lwFilter, leFilterData);
        QWidget::setTabOrder(leFilterData, rbBeginWith);
        QWidget::setTabOrder(rbBeginWith, rbContains);
        QWidget::setTabOrder(rbContains, rbRegular);
        QWidget::setTabOrder(rbRegular, rbEndsWith);
        QWidget::setTabOrder(rbEndsWith, pbAdd);
        QWidget::setTabOrder(pbAdd, pbRemove);

        retranslateUi(CFilterUI);
        QObject::connect(leFilterData, SIGNAL(returnPressed()), CFilterUI, SLOT(onReturnPressed()));
        QObject::connect(pbAdd, SIGNAL(clicked()), CFilterUI, SLOT(onAddPressed()));
        QObject::connect(pbRemove, SIGNAL(clicked()), CFilterUI, SLOT(onRemovePressed()));

        QMetaObject::connectSlotsByName(CFilterUI);
    } // setupUi

    void retranslateUi(QWidget *CFilterUI)
    {
        CFilterUI->setWindowTitle(QCoreApplication::translate("CFilterUI", "Filter", nullptr));
        leFilterData->setText(QString());
        lFilter->setText(QCoreApplication::translate("CFilterUI", "Filter:", nullptr));
        rbContains->setText(QCoreApplication::translate("CFilterUI", "Contains", nullptr));
        rbRegular->setText(QCoreApplication::translate("CFilterUI", "Regular Expression", nullptr));
        rbBeginWith->setText(QCoreApplication::translate("CFilterUI", "Begins with", nullptr));
        rbEndsWith->setText(QCoreApplication::translate("CFilterUI", "Ends with", nullptr));
        pbAdd->setText(QCoreApplication::translate("CFilterUI", "Add", nullptr));
        pbRemove->setText(QCoreApplication::translate("CFilterUI", "Remove Selected", nullptr));
        rbWhitelist->setText(QCoreApplication::translate("CFilterUI", "Whitelist", nullptr));
        rbBlacklist->setText(QCoreApplication::translate("CFilterUI", "Blacklist", nullptr));
        cbActivated->setText(QCoreApplication::translate("CFilterUI", "Filter activated", nullptr));
        rbPacketName->setText(QCoreApplication::translate("CFilterUI", "PacketName", nullptr));
    } // retranslateUi

};

namespace Ui {
    class CFilterUI: public Ui_CFilterUI {};
} // namespace Ui

QT_END_NAMESPACE

#endif // UI_FILTERUI_H
