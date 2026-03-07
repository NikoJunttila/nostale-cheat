#pragma region
#include <QListWidget>

class CAdvancedListWidget : public QListWidget
{
	Q_OBJECT

public:
	CAdvancedListWidget(QWidget *i_pParent);
	~CAdvancedListWidget();

signals:
	void mouseMoveEvent(QMouseEvent *i_pEvent);
	
};