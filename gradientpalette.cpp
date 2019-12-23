#include "gradientpalette.h"
#include <QImage>
#include <QPainter>
#include <QDebug>

/*
 * 构造函数
 * @param width 渐变调色板宽度
 */
gradientpalette::gradientpalette(int width)
    : gradient_(0, 0, width, 1),
      width_(width)
{
    canvas_ = new QImage(width, 1, QImage::Format_ARGB32);
}

/*
 * 析构函数
 */
gradientpalette::~gradientpalette()
{
    delete canvas_;
    canvas_ = NULL;
}

/*
 * 用指定颜色在指定位置创建一个停止点
 * @param index 指定位置，对应位置为 (0, index)
 * @param color 颜色
 */
void gradientpalette::setColorAt(qreal index, const QColor &color)
{
    gradient_.setColorAt(index, color);

    QPainter painter(canvas_);
    painter.setBrush(gradient_);
    painter.setPen(Qt::NoPen);
    painter.fillRect(canvas_->rect(), gradient_);
}

/*
 * 获得指定点颜色值
 * @param index 取值位置
 * @return 返回指定索引处的颜色值
 */
QColor gradientpalette::getColorAt(qreal index)
{
    index -= 1;
    if (index > width_)
        return Qt::color0;
    return canvas_->pixel(index, 0);
}
