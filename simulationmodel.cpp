#include "simulationmodel.h"
#include <qnetworkconfigmanager.h>
#include <qnetworksession.h>
#include <QJsonDocument>
#include <QJsonObject>
#include <QJsonArray>
#include <QStringList>
#include <QProcess>
#include <QDir>
#include <QFile>
#include <QTimer>
#include <QUrlQuery>
#include <QElapsedTimer>
#include <QLoggingCategory>
#include <math.h>
#include <fstream>
#include <iostream>
#include <dlib/dnn.h>
#include <dlib/data_io.h>
#include <stdio.h>
#include <sys/stat.h>
#include <QThread>

using namespace dlib ;
using namespace std;
//using std::vector;
//using std::cout;
//using std::endl;

// ----------------------------------------------------------------------------------------

// In dlib, most of the general purpose solvers optimize functions that take a
// column vector as input and return a double.  So here we make a typedef for a
// variable length column vector of doubles.  This is the type we will use to
// represent the input to our objective functions which we will be minimizing.
typedef matrix<double,0,1> column_vector;
std::vector<std::vector<double>> matrix_result;
std::vector<std::vector<double>> data_machine_1;
std::vector<std::vector<double>> data_machine_2;
bool modelGenerated = false ;

// ----------------------------------------------------------------------------------------
// Below we create a few functions.  When you get down into main() you will see that
// we can use the optimization algorithms to find the minimums of these functions.
// ----------------------------------------------------------------------------------------

// Units
// kg,m,J,K,s,mium,W,Pa,mol,Newton,mius,minim,minis= 1,1,1,1,1,pow(10,-6),1,1,1,1,pow(10,-6),pow(10,-3),pow(10,-3);
const double kg = 1.0;
const double m = 1.0;
const double J = 1.0;
const double K = 1.0;
const double s = 1.0;
const double mium = pow(10,-6);
const double W = 1.0;
const double Pa = 1.0;
const double mol = 1.0;
const double Newton = 1.0;
const double mius = pow(10,-6);
const double minim = pow(10,-3);
const double minis = pow(10,-3);

// derived quantities /////////////////////////////
//static double intensity=pow(10,11)*W/(m*m); // intensity
double w0z(double z,double zR,double z0, double w0){
    return w0*sqrt(1+pow(((z-z0)/zR),2.0));
}

double intens(double PL,double w0,double z,double z0,double zR){
    return PL/(3.141592653*w0*w0)*pow((w0/w0z(z,zR,z0,w0)),2.0);
}

// constant //////////////////////////////////////////
const double roul=8360.0*kg/pow(m,3);            // density of liquid melt
const double cp=440.0*J/(kg*K);              // specific heat capacity
const double lamda=32.8*W/(m*K);           // thermal conductivity
const double Ap=0.4;                       // absorption degree
const double kappas=9.88*pow(10,-6)*pow(m,2)/s;    // thermal diffusivity for solid phase
const double kinematicv=6.5*pow(10,-7)*pow(m,2)/s; // kinematic viscosity
const double dynamicv=kinematicv*roul;     // dynamic viscosity
const double Hv=6.39*pow(10,6)*J/kg;           // Evaporation entapy
const double Tv=3074.0*K;                    // Evaporation temperature
const double Tm=1800.0*K;                    // Melting temperature
const double Ta=300.0*K;                     // Ambient temperature
const double Hm=2.98*pow(10,5)*J/kg  ;          // Melting entapy
const double Am=57.23*1.66*pow(10,-27)*kg;     // atomic mass
const double Molmass=0.05723*kg/mol;       // mol mass
const double VB=4.0*1.6*pow(10,-19)/Am*J/kg;     // specific binding energy
const double sigma=0.48*Newton/m;          // surface tension
const double kappa=lamda/(roul*cp);        // themal difussivity
const double R=8.314*J/(K*mol);            // gas constant
const double kB=1.38*pow(10.0,-23);              // Boltzmann constant
const double hm=Hm/(cp*(Tm-Ta));           // Inverse Stefan number
const double Pumg=pow(10.0,5)*Pa;                // standard pressure
const double delta=1.2;                    // model parameter, length scale of the pressure gradient
const double b1=0.6;                       // b1 constant in 1 phase ablation model
const double adc=5.0/3;                      // adiabat coefficient;
const double cvg=1.0/(adc-1)*R/Molmass;
const double cvl=3.0*R/Molmass;
const double scaleTl = Tv ;
const double scaledm = pow(10,-6);
const double scalev0 = 1.0 ;

double intensity_all = 0;
double w0_all = 0 ;

double para_PL = 0;
double para_w0 = 0;
double para_dw = 0;
double finish_run = 0;



double Psat(double Tl){
    return Pumg*exp(Am*Hv/kB*(1/Tv-1/Tl));
}

double G1(double x){ // Polynomial expansion of Aoki and Sone's model
    return 1-1.8490058641191005*x+1.662985337365784*x*x-0.6107484447142846*x*x*x;
}

double Pg(double Tl){
    return G1(1)*Psat(Tl);
}

double WidenRadius(double v0,double dm,double Tl,double w0z){
    if (Psat(Tl)<Pumg){
        //cout << "Psat(Tl): " << Psat(Tl) << "; Pg(Tl): " <<Pg(Tl) <<  "; Pumg: " << Pumg << endl;
        //print("Psat(Tl)", Psat(Tl), "Pumg", Pumg);
        //print("Pg(Tl)",Pg(Tl),"Pumg",Pumg);
        return 0;
    }
    else{
        return sqrt(exp(v0*dm/(kappa*2)))*w0z;
    }
}

//For pow function
// preparing     //////////////////////////////////////////
double Rey(double v0, double dm){
    return v0*dm/kinematicv;
}

double Pes(double v0, double w0){
    return v0*w0/kappa;
}

double Pel(double v0, double dm){
    return v0*((float)dm/kappa);
}
double epsilon(double dm, double w0){
    return dm/w0 ;
}

double G2(double x){
     return 1-0.407689629841050723*x+ 0.06791840701183868*x*x-0.01772753168166515*x*x*x;
}
double g1(double x){
    return 2.0/x*(exp(x)-x-1)/(exp(x)-1);
}
double g2(double x){
    return 4.0/5.0*(6-6*exp(x)+6*x+3*exp(x)*x*x-2*pow(x,3))/((exp(x)-1)*pow(x,3));
}
double g3(double x){
    return (float)x/(exp(x)-1);
}
//  inputs //////////////////////////////////////
//  functions ///////////////////////////////////
double sonicv(double Tg){
    return sqrt(5.0*R*Tg/3.0/Molmass);
}
double ug(double Tl){
    return sonicv(Tl*G2(1));
    //return 12.472528324713481*math.sqrt(Tl)
}

//#def Pg(Tl):
//#    return 20323.10285323988*math.exp(43989.96391304347*(0.00032530904359141186 - 1/Tl))
double mstat(double v0,double va){
    return 1.0-((float)va/v0);
}

double roug(double Tl){
    return Psat(Tl)*G1(1)/(R/Molmass*Tl*G2(1.0));
}

double va(double Tl){
    return roug(Tl)*((float)ug(Tl)/(2.0*roul-roug(Tl)));
}

double qla(double Tl,double dm,double v0){
    double Pelloc=Pel(v0,dm);
    double valoc=va(Tl);
    double mstatloc=mstat(v0,valoc);
    return lamda*(Tv-Tm)/dm*(Pelloc*5.0/8.0*(Tl-Tm)/(Tv-Tm)*mstatloc*g2(Pelloc)+(Tl-Tm)/(Tv-Tm)*g3(Pelloc));
    //return lamda*(Tv-Tm)/dm*(Pelloc*5/8*(Tl-Tm)/(Tv-Tm)*mstatloc*g2(Pelloc)+(Tl-Tm)/(Tv-Tm)*g3(Pelloc));
}

double Tg(double Tl){
    return Tl*G2(1);
}

double eg(double Tl){
    return cvg*Tg(Tl)+(cvl-cvg)*Tl+pow(ug(Tl),2)/2;
}

double ul(double Tl){
    return va(Tl);
}
double el(double Tl){
    return -VB+cvl*Tl+ul(Tl)*ul(Tl)/2;
}

double Pl(double Tl){
    return roug(Tl)*ug(Tl)*(ug(Tl)+va(Tl))+Pg(Tl)-roul*ul(Tl)*(ul(Tl)+va(Tl));
}

// main equations //////////////////////////////////////////////////////////////////////////////////////////////////
double equation9(double Tl,double dm,double v0,double intensity){
    double rougl =roug(Tl) ; //Psat(Tl)*G1(1)/(R/Molmass*Tl*G2(1.0))
    double egl = eg(Tl) ; // cvg*Tg(Tl)+(cvl-cvg)*Tl+pow(ug(Tl),2)/2;
    double ugl = ug(Tl) ; // sonicv(Tl*G2(1));
    double val =va(Tl);  // roug(Tl)*((float)ug(Tl)/(2.0*roul-roug(Tl)));
    double Pgl = Pg(Tl); //G1(1)*Psat(Tl)
    double qlal = qla(Tl,dm,v0); //lamda*(Tv-Tm)/dm*(Pelloc*5.0/8.0*(Tl-Tm)/(Tv-Tm)*mstatloc*g2(Pelloc)+(Tl-Tm)/(Tv-Tm)*g3(Pelloc));
    double ell =el(Tl); //-VB+cvl*Tl+ul(Tl)*ul(Tl)/2;
    double ull = ul(Tl); //va(Tl)
    double Pll = Pl(Tl); //roug(Tl)*ug(Tl)*(ug(Tl)+va(Tl))+Pg(Tl)-roul*ul(Tl)*(ul(Tl)+va(Tl));
    double left = rougl*egl*(ugl+val)+Pgl*ugl;
    double right = Ap*intensity-qlal+(roul*ell)*(ull+val)+(Pll*ull);
    return left-right;
}


double equation11(double Tl,double dm,double v0,double w0){
    double Reyl =Rey(v0,dm);
    double val = va(Tl);
    double Pll = Pl(Tl) ;
    double mstatl = mstat(v0,val);
    double left = Reyl*(2.4*pow(mstatl,2)+1.5*mstatl*(val/v0)) ;
    double right = 2.0/pow(delta,2.0)*(pow(dm,3.0)*Pll/(pow(w0,2.0)*v0*dynamicv))-3*mstatl;
    return left-right ;
    //Reyl,mstatl,val,Pll=Rey(v0,dm),mstat(v0,va(Tl)),va(Tl),Pl(Tl)
    //left=Reyl*(12/5*mstatl*mstatl+3/2*mstatl*(val/v0))
    //right=2/(delta*delta)*(dm**3*Pll/(w0**2*v0*dynamicv))-3*mstatl;
    //return left-right

}

double equation1202(double Tl,double dm,double v0){
    double Pell = Pel(v0,dm);
    double left=(Tl-Tm)/(Tv-Tm) ;
    double right=(1+hm)*(v0*dm/kappa)*(Tm-Ta)*(exp(Pell)-1)/(Tv-Tm)/Pell ;
    return left-right ;
}

column_vector fun1(const column_vector& x){
    double Tl = x(0)*scaleTl;
    double dm = x(1)*scaledm;
    double v0 = x(2)*scalev0;
    double intensity = x(3);
    double w0 = x(4);
    return {equation9(Tl, dm, v0,intensity), equation11(Tl, dm, v0,w0), equation1202(Tl, dm, v0)};
}

/*void set_intensity (double intensity){
    ::intensity_all = intensity;
}

void set_w0 (double w0){
    ::w0_all = w0;
}*/


double loss(const column_vector& x){
    double Tl = x(0)*scaleTl ;
    double dm = x(1)*scaledm ;
    double v0 = x(2)*scalev0 ;

    double eq9 = equation9(Tl,dm,v0,intensity_all);
    double eq11= equation11(Tl,dm,v0,w0_all) ;
    double eq1202 = equation1202(Tl,dm,v0);

    double eq9_0 = equation9(scaleTl,scaledm,scalev0,intensity_all);
    double eq11_0= equation11(scaleTl,scaledm,scalev0,w0_all) ;
    double eq1202_0 = equation1202(scaleTl,scaledm,scalev0);

    //return sqrt(pow(((left9-Ap*intensity)/(left9_0-Ap*intensity)),2)+pow((left11*pow(w0,2.0)-right11)/(left11_0*pow(w0,2.0)-right11_0),2)+pow((eq1202/eq1202_0),2));
    return sqrt(pow((eq9/eq9_0),2.0)+pow((eq11/eq11_0),2.0)+pow((eq1202/eq1202_0),2.0));
}

column_vector getroot2(double intensity,double w0){
    double Tini = 0;
    double dmini = 0;
    double v0ini = 0;
    intensity_all = intensity;
    w0_all = w0;

    if (intensity < pow(10,10.5)){
        Tini = 1.1*Tv;
        dmini = 20.0*pow(10,-6);
        v0ini = 0.6 ;
    }
    else if ((intensity >= pow(10.0,10.5)) && (intensity<pow(10.0,11))){
        Tini = 1.58*Tv;
        dmini = 7.0 * pow(10,-6.0);
        v0ini = 1.0 ;
    }
    else if (intensity>=pow(10,11.0) && intensity<pow(10,12)){
        Tini = 1.7*Tv;
        dmini = 7.0*pow(10,-6.0);
        v0ini = 2.5 ;
    }
    else if (intensity>=pow(10,12.0) && intensity<pow(10,13)){
        Tini = 6200.0; //7000.0;
        dmini =  20.0*pow(10,-7.0);  //5.0*pow(10,-7.0);
        v0ini = 4.5;//5.0 ;
    }
    else if (intensity>=pow(10,13) && intensity<7*pow(10,13)){
        Tini = 19000.0;
        dmini = pow(10,-7);
        v0ini = 200.0 ;
    }
    else{
        Tini = 22000.0;
        dmini = 3.0*pow(10,-8);
        v0ini = 270.0 ;
    }


    //Tini, dmini, v0ini = 5000, 2 * 10 ** -6, 2
    //column_vector Bounds={(Tm/scaleTl,18000.0/scaleTl),(pow(10,-8)/scaledm,200*pow(10,-6)/scaledm),(0.001/scalev0,30/scalev0)};
    column_vector lowerbound = {Tm/scaleTl,pow(10,-8),0.001/scalev0};
    column_vector upperbound = {18000.0/scaleTl, 200.0*pow(10,-6)/scaledm, 30.0/scalev0};
    column_vector starting_point = {Tini*0.88 /scaleTl, dmini*0.88 /scaledm, v0ini*0.88 /scalev0 }; //, Tini/scaleTl, dmini/scaledm, v0ini/scalev0};  /* `*`some` `initial` `guess`*` */
    //res1=optimize.minimize(loss,[Tini/scaleTl,dmini/scaledm,v0ini/scalev0],method="TNC",bounds=Bounds,constraints=(),options={"maxiter":1000,"offset":[Tini/scaleTl,dmini/scaledm,v0ini/scalev0],"ftol":0.0,"gtol":1e-5})
    find_min_box_constrained(bfgs_search_strategy(),  // The 10 here is basically a measure of how much memory L-BFGS will use.
                 objective_delta_stop_strategy(1e-16),  // Adding be_verbose() causes a message to be
                 loss, derivative(loss), starting_point, lowerbound, upperbound);

    column_vector resutl = {starting_point(0),starting_point(1),starting_point(2)};

    return resutl ;
}

column_vector fun3(const column_vector& x){
    //x=x0.tolist() ;
    double Tl = x(0)*scaleTl;
    double dm = x(1)*scaledm;
    double v0 = x(2)*scalev0;
    double intensity = x(3);
    double w0 = x(4);
    return {equation9(Tl, dm, v0,intensity), equation11(Tl, dm, v0,w0), equation1202(Tl, dm, v0)};
}

/*column_vector getroot3(double intensity,double w0){

    double Tini,dmini,v0ini;
    if (intensity<pow(10,11)){
        Tini,dmini,v0ini=4500,5*pow(10,-6),0.5;
        }
    else if (intensity>=pow(10,11) and intensity<pow(10,12)){
        Tini, dmini, v0ini = 5000, 2 * pow(10,-6), 2;
        }
    else if (intensity>=pow(10,12) and intensity<pow(10,13)){
        Tini, dmini, v0ini = 7000, 5 * pow(10,-7), 5;
    }
    else if (intensity>=pow(10,13) and intensity<7*pow(10,13)){
        Tini, dmini, v0ini = 19000, pow(10,-7), 200;
    }
    else{
        Tini, dmini, v0ini = 22000, 3*pow(10,-8), 270;
    }
    //sol = optimize.newton(fun3,np.array([Tini/scaleTl,dmini/scaledm,v0ini/scalev0]),tol=1e-20,maxiter=10000);
    //sol=optimize.minimize(fun3,[Tini,dmini,v0ini],jac=None,method="Newton-CG")
    //return sol.x ;
}*/

double lossf(double x0, double x1, double x2, double intensity, double w0){
    double Tl= x0;
    double dm = x1;
    double v0 = x2 ;
    double eq9=equation9(Tl,dm,v0,intensity) ;
    double eq11=equation11(Tl,dm,v0,w0) ;
    double eq1202=equation1202(Tl,dm,v0) ;
    double eq9_0=equation9(scaleTl,scaledm,scalev0,intensity) ;
    double eq11_0=equation11(scaleTl,scaledm,scalev0,w0) ;
    double eq1202_0=equation1202(scaleTl,scaledm,scalev0) ;
    return sqrt(pow(eq9,2)/pow(eq9_0,2)+pow(eq11,2)/pow(eq11_0,2)+pow(eq1202,2)/pow(eq1202_0,2));
}

std::vector<std::vector<double>> GetResult(double PL, double tp, double nump, double dw, double w0, double z0, double zR){
        std::vector<double> holeevolefront ;
        std::vector<double> holewidenradius;
        int resolution = 50;
        double zloc=0;
        double deltalen=0;
        double deltat = double(tp/resolution);
        //
        double w0loc = 0;
        double intensloc = 0;
        column_vector solHSD;
        double v0loc = 0 ;
        double Tlloc = 0 ;
        double dmloc = 0 ;
        double widenloc = 0 ;
        //
        for (int i=0 ; i< nump;i++){
            for (int j=0 ; j <resolution; j++){
                w0loc= w0z(zloc,zR,z0,w0);
                intensloc = intens(PL,w0,zloc,z0,zR);
                solHSD= getroot2(intensloc,w0loc);
                v0loc= solHSD(2)*scalev0;
                Tlloc= solHSD(0)*scaleTl;
                dmloc= solHSD(1)*scaledm;
                widenloc= WidenRadius(v0loc,dmloc,Tlloc,w0loc);
                //cout << "intensloc :" << intensloc << "; w0loc " << w0loc*pow(10,6) << "; v0loc :" << v0loc << "; temperature :" << Tlloc << "; dm :" << dmloc*pow(10,6) << "; widenloc :" <<  widenloc*pow(10,6) << endl;
                if (v0loc<0){
                    deltalen=deltalen;
                }
                else{
                    deltalen= (deltat*v0loc);
                }

                if (widenloc>0){
                    //#zloc=zloc-deltat*v0loc
                    zloc=zloc-deltalen;
                    holeevolefront.push_back(zloc);
                    holewidenradius.push_back(widenloc);
                }
                else{
                    zloc=zloc;
                    holeevolefront.push_back(zloc);
                    holewidenradius.push_back(widenloc);
                }
            }
            if (zloc<(-dw)){
                break;
            }
        }
        std::vector<std::vector<double>> Output ={holeevolefront,holewidenradius};
        return Output;
}

std::vector<double> GetMetaData(double PL, double w0, double z0, double zR, double evap_temp){
    // Input = {"PL": PL, , "w0": w0, "z0": z0, "zR": zR}
    // PL:pulse peak power ; tp:pulse duration nump:number of pulses dw:workpiece thickness
    // W0:beam radius ; z0:focal position ;zR: rayleigh length
    std::vector<double> rowData ;
    double zloc=0.0 ;
    double w0loc=w0z(zloc,zR,z0,w0);
    double intensloc=intens(PL,w0,zloc,z0,zR);
    column_vector solHSD=getroot2(intensloc,w0loc) ;  // metamodel-A
    double v0loc=solHSD(2)*scalev0 ;
    double Tlloc=solHSD(0)*scaleTl ;
    double dmloc=solHSD(1)*scaledm ;
    double widenloc=WidenRadius(v0loc,dmloc,Tlloc,w0loc) ; // hole winden radius
    double app_1 = 0;
    if(intensloc >= evap_temp){
        app_1 = 1;
    }
    double app_2 = 0;
    if(intensloc >= pow(10,12)){
        app_2 = 1;
    }
    rowData = {intensloc, v0loc, Tlloc, dmloc, widenloc, app_1, app_2};
    return rowData;
    // Out= intensloc:Intensity , v0loc: drilling velocity, Tlloc : temperature, dmloc: dm, widenloc:WidenRadius , application_1, application_2
    // Conditions for applicable regions for this model,only by fulfilling following conditions,
    // the model is useful,otherwise, mark these data points as applicability equal to 0: #computation issue points

    // The liftup height: Llift should be always larger than depth of the hole,
    // a) Llif=0.4*w0*w0*vp/v (v is kinematic viscosity)  ??  Llif > |zloc|
    // b) surface temperature should be always larger than evaporation temperature :  temperature > evaporation -> setting
    // setting color for temperature,  set black to temperatur lower than evaporation
    // c) Intensity larger than 10^12 plasma absorption starts : Intensity> 10^12
}

void print_result(string name ,column_vector result_value){
    cout << name <<":  " << result_value(0) << " ; " << result_value(1) << " ; " <<result_value(2) << endl;
}

double set_PL (double PL) {
    if (PL >15 && PL <= 150 ){
        PL = PL * 1000 * W;
    } else {
        PL= 15000 *W ;
    }
    return PL;
}

double set_w0 (double w0) {
    if (w0 >40 && w0 <= 400 ){
        w0 = w0 * mium;
    } else {
        w0= 40 *mium;;
    }
    return w0;
}

// Machine 1:power 1KW-6KW, w0: 50µm,100µm,200µm  - ML1 applicable area
std::vector<std::vector<double>> calculate_machine_1(){
    std::vector<double> w0_machine1 = {50.0, 100.0, 200.0};
    for (int i = 1 ; i < 51 ; i++ ){
        for(int j=0 ; j < 3 ; j++){
            double zloc = 0.0;
            double PL = set_PL(10 + 1*i);
            double w0 = w0_machine1.at(j) * mium;
            double z0 = -1.0 * minim;
            double zR = 1.0 * minim;
            //cout << "intens : " << intens(PL,w0,zloc,z0,zR)/pow(10,10) << " w0  " << w0_machine1.at(j) << endl;
            data_machine_1.push_back({intens(PL,w0,zloc,z0,zR)/pow(10,10), w0_machine1.at(j)});
        }
    }
    return data_machine_1;
}

// Machine 2: power 4KW-20KW,w0:100µm,200µm,300µm - ML2 applicable area
std::vector<std::vector<double>> calculate_machine_2(){
    std::vector<double> w0_machine2 = {100.0, 200.0, 300.0};
    for (int i = 1 ; i < 161 ; i++ ){
        for(int j=0 ; j < 3 ; j++){
            double zloc = 0.0;
            double PL = set_PL(40 + 1*i);
            double w0 = w0_machine2.at(j) * mium;
            double z0 = -1.0 * minim;
            double zR = 1.0 * minim;
            //cout << "intens : " << intens(PL,w0,zloc,z0,zR)/pow(10,10) << " w0  " << w0_machine2.at(j) << endl;
            data_machine_2.push_back({intens(PL,w0,zloc,z0,zR)/pow(10,10), w0_machine2.at(j)});
        }
    }
    return data_machine_1;
}

std::vector<double> calculate_applicable_area(double PL, double dw, double w0, double z0, double zR){
    // Llif=0.4*w0*w0*v0loc/v (v is kinematic viscosity)
    // surface temperature should be always larger than evaporation temperature
    // Intensity larger than 10^12 plasma absorption starts

    // need v0loc Tlloc and intensloc

    int app_1 = 0;
    int app_2 = 0;
    int app_3 = 0;

    double zloc_min=0; //min value 0 -  max value : dw
    double zloc_max=0;
    double w0loc = 0;
    double intensloc = 0;
    column_vector solHSD;
    double v0loc = 0 ;
    double Tlloc = 0 ;
    double dmloc = 0 ;

    w0loc= w0z(zloc_min,zR,z0,w0);
    intensloc = intens(PL,w0,zloc_min,z0,zR);
    // Intensity larger than 10^12 plasma absorption starts
    if( intensloc < pow(10,12) ){
        app_1 = 1 ;
    }

    solHSD= getroot2(intensloc,w0loc);
    v0loc= solHSD(2)*scalev0;
    // Llif=0.4*w0*w0*v0loc/v (v is kinematic viscosity)
    double v = 1;
    if(0.4*w0*w0*v0loc/v < dw){
        app_2 = 1 ;
    }
    Tlloc= solHSD(0)*scaleTl;
    // surface temperature should be always larger than evaporation temperature
    int eva_tem = 10000; // assuming the material
    if (Tlloc > eva_tem){
        app_3 = 1 ;
    }

    w0loc= w0z(zloc_max,zR,z0,w0);
    intensloc = intens(PL,w0,zloc_max,z0,zR);
    // Intensity larger than 10^12 plasma absorption starts
    if( intensloc < pow(10,12) ){
        app_1 = 1 ;
    }

    solHSD= getroot2(intensloc,w0loc);
    v0loc= solHSD(2)*scalev0;
    // Llif=0.4*w0*w0*v0loc/v (v is kinematic viscosity)
    double v_conx = 1;
    if(0.4*w0*w0*v0loc/v_conx < dw){
        app_2 = 1 ;
    }
    Tlloc= solHSD(0)*scaleTl;
    // surface temperature should be always larger than evaporation temperature
    if (Tlloc > eva_tem){
        app_3 = 1 ;
    }



}

Q_LOGGING_CATEGORY(requestsLog,"wapp.requests")

simulationModel::simulationModel(QObject *parent) :
        QObject(parent) {
}

void simulationModel::startPictureGenerated()
{
    QString path = QDir::currentPath();
    path.remove("build-GUI-DataVisual-Desktop_Qt_5_12_2_MinGW_32_bit-Debug");
    path.replace("/","//");

    QProcess process;
    QString scriptFile =  "dataVisualization.py";
    process.execute("Python " + path + "simulationmodel//dataVisualization.py");
    process.start("cd " + path +"simulationmodel//");// D://sample//NewFolder//Document//simulationmodel//");
    process.start("Python " + path + "simulationmodel//dataVisualization.py");
    process.waitForFinished(3000);
}

void simulationModel::start_machine_1(){
    calculate_machine_1();
}

void simulationModel::set_para_PL(double PL){
    para_PL = PL;
}

void simulationModel::set_para_w0(double w0){
    para_w0 = w0;
}

void simulationModel::set_para_dw(double dw){
    para_dw = dw;
}

double simulationModel::get_para_PL(){
    return para_PL;
}

double simulationModel::get_para_w0(){
    return para_w0;
}

double simulationModel::get_para_dw(){
    return para_dw;
}

double simulationModel::get_machine_1_x(int times){
    return data_machine_1.at(times).at(1);
}

double simulationModel::get_machine_1_y(int times){
    return data_machine_1.at(times).at(0);
}

void simulationModel::start_machine_2(){
    calculate_machine_2();
}

double simulationModel::get_machine_2_x(int times){
    return data_machine_2.at(times).at(1);
}

double simulationModel::get_machine_2_y(int times){
    return data_machine_2.at(times).at(0);
}

double simulationModel::calculate_widenloc (double PL, double tp, double nump, double dw, double w0, double z0, double zR){
    double zloc = 0;
    PL = set_PL(PL);
    w0 = w0* mium;
    z0 = z0* minim;
    zR = zR * minim;
    double w0loc=w0z(zloc,zR,z0,w0);
    double intensloc=intens(PL,w0,zloc,z0,zR);
    column_vector solHSD=getroot2(intensloc,w0loc) ;  // metamodel-A
    double v0loc=solHSD(2)*scalev0 ;
    double Tlloc=solHSD(0)*scaleTl ;
    double dmloc=solHSD(1)*scaledm ;
    double widenloc=WidenRadius(v0loc,dmloc,Tlloc,w0loc) ; // hole winden radius
    cout << "widenloc : " << widenloc << endl;
    return widenloc * 10000;
}


double simulationModel::calculate_w0loc (double PL, double tp, double nump, double dw, double w0, double z0, double zR){
    double zloc = 0;
    w0 = w0* mium;
    z0 = z0* minim;
    zR = zR * minim;
    //cout << "New w0loc : " << w0z(zloc,zR,z0,w0) << endl;
    return w0z(zloc,zR,z0,w0);
}

int simulationModel::calculate_intensloc (double PL, double tp, double nump, double dw, double w0, double z0, double zR){
    double zloc = 0;
    PL = set_PL(PL);
    w0 = w0 * mium;
    z0 = z0 * minim;
    zR = zR * minim;
    //cout << "intens : " << intens(PL,w0,zloc,z0,zR) << endl;
    return intens(PL,w0,zloc,z0,zR)/pow(10,10);
    //return 1;
}

double simulationModel::calculate_zloc (double PL, double tp, double nump, double dw, double w0, double z0, double zR){
    double zloc = 0;
    PL = set_PL(PL);
    w0= set_w0(w0);
    z0 = z0 * minim;
    zR = zR * minim;
    zloc = getroot2(intens(PL,w0,zloc,z0,zR),w0z(zloc,zR,z0,w0))(2);
    //cout << "New zloc : " << zloc << endl;
    return zloc;
}

double simulationModel::get_holeevolefront (int times){
    cout << "holeevolefront :" << matrix_result.at(0).at(times)  << "times: " << times << endl;
    return matrix_result.at(0).at(times-1);
}

double simulationModel::get_holewidenradius (int times){
    cout << "holewidenradius :" << matrix_result.at(1).at(times) << "times: " << times << endl;
    return matrix_result.at(1).at(times-1);
}

bool simulationModel::get_modelGenerated(){
    return modelGenerated;
}

void simulationModel::startSimulation( double PL, double tp, double nump, double dw, double w0, double z0, double zR )
{
    cout << "Laser simulation Start !!" << endl;
    // pulse peak power
    PL = set_PL(PL);
    tp=0.5 *minis ; // pulse duration
    nump=10 ;   //number of pulses
    dw= dw *minim; //workpiece thickness
    w0= set_w0(w0); // beam radius
    z0= -1 *minim; // focal position
    zR= 1 *minim; // rayleigh length
    matrix_result = GetResult(PL, tp, nump, dw, w0, z0, zR);
    QThread::sleep(2);
    modelGenerated = true;

}

void simulationModel::start_meta_Simulation( double PL, double tp, double nump, double dw, double w0, double z0, double zR )
{
    cout << "MetaModel simulation Start !!" << endl;
    // pulse peak power
    PL = set_PL(PL);
    tp=0.5 *minis ; // pulse duration
    nump=10 ;   //number of pulses
    dw= dw *minim; //workpiece thickness
    w0= set_w0(w0); // beam radius
    z0= -1 *minim; // focal position
    zR= 1 *minim; // rayleigh length
    matrix_result = GetResult(PL, tp, nump, dw, w0, z0, zR);
    modelGenerated = true;
}

void simulationModel::start_range_Simulation(double PL_min, double PL_max, double tp, double nump, double dw, double w0_min, double w0_max, double z0_min, double z0_max, double zR_min, double zR_max)
{
    cout << "MetaModel simulation Start !!" << endl;
    // pulse peak power
    tp=0.5 *minis ; // pulse duration
    nump=10 ;   //number of pulses
    dw= dw *minim; //workpiece thickness

    double differ_PL = (PL_max - PL_min) / 10;
    double differ_w0 = (w0_max - w0_min) / 10;
    double z0= -1 *minim; // focal position
    double zR= 1 *minim; // rayleigh length

    for(int i= 1; i < 11; i++ ){
        double PL = set_PL(PL_min + i * differ_PL);
        for (int j =1 ; j <11 ; j++) {
            double w0= set_w0(w0_min + j * differ_w0);
            matrix_result = GetResult(PL, tp, nump, dw, w0, z0, zR);
        }
    }

    //matrix_result = GetResult(PL, tp, nump, dw, w0, z0, zR);
    //modelGenerated = true;
}

