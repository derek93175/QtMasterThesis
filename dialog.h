#ifndef DIALOG_H
#define DIALOG_H

class QImage;
class HeatMapper;
class GradientPalette;
using namespace std;

namespace Ui {
class Dialog;
}

class Dialog
{
public:
    enum {
        CANVAS_WIDTH = 1000,
        CANVAS_HEIGHT = 700,
        DEFAULT_RADIUS = 45,
        DEFAULT_OPACITY = 128,
        DEFAULT_WIDTH = 255
    };
    explicit Dialog(QWidget *parent = 0);
    virtual ~Dialog();
    void addpoints(vector<double> x_vector, vector<double> y_vector, vector<double> z_vector);

protected:
    void paintEvent(QPaintEvent *);
    void mouseReleaseEvent(QMouseEvent *e);

private:
    // 绘图对象指针
    HeatMapper *mapper_;
    // 用于显示输出的图像
    QImage *canvas_;
    // 调色板
    GradientPalette *palette_;
};

#endif // DIALOG_H
