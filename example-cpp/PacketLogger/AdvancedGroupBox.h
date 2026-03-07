#pragma once
#include <QGroupBox>

class CAdvancedGroupBox : public QGroupBox
{
	Q_OBJECT

public:
	CAdvancedGroupBox(QWidget *parent);
	~CAdvancedGroupBox();

signals:
	void leaveEvent(QEvent *i_pEvent);
};