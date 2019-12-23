#ifndef SIMULATIONMODEL_H
#define SIMULATIONMODEL_H
#include <QObject>
#include <QString>
#include <QNetworkReply>
#include <QQmlListProperty>

#include <QtPositioning/QGeoPositionInfoSource>

class simulationModel : public QObject
{
    Q_OBJECT
public:
    explicit simulationModel(QObject *parent = nullptr);

public slots:
    void startSimulation(double PL, double tp, double nump, double dw, double w0, double z0, double zR);
    void start_meta_Simulation(double PL, double tp, double nump, double dw, double w0, double z0, double zR);
    void start_range_Simulation(double PL_min, double PL_max, double tp, double nump, double dw, double w0_min, double w0_max, double z0_min, double z0_max, double zR_min, double zR_max);
    double calculate_w0loc(double PL, double tp, double nump, double dw, double w0, double z0, double zR);
    int calculate_intensloc(double PL, double tp, double nump, double dw, double w0, double z0, double zR);
    double calculate_zloc (double PL, double tp, double nump, double dw, double w0, double z0, double zR);
    double calculate_widenloc (double PL, double tp, double nump, double dw, double w0, double z0, double zR);
    void startPictureGenerated();
    void start_machine_1();
    void start_machine_2();

    void set_para_PL(double PL);
    void set_para_w0(double w0);
    void set_para_dw(double dw);

    double get_holeevolefront (int times);
    double get_holewidenradius (int times);
    double get_machine_1_x(int times);
    double get_machine_1_y(int times);
    double get_machine_2_x(int times);
    double get_machine_2_y(int times);
    double get_para_PL();
    double get_para_w0();
    double get_para_dw();
    bool get_modelGenerated();

};

#endif // SIMULATIONMODEL_H
