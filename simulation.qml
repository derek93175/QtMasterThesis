import QtQuick 2.5
import QtQuick.Controls 1.4
import QtQuick.Layouts 1.1
import MetaModel.SimulationModel 1.0

ApplicationWindow {

    property int thickness: 180
    property int radial: 530
    property int depth: 60/appmodel.get_para_dw() // thickness/dw
    property int laser_depth: 277 + appmodel.calculate_zloc(parameter_1.value*1000,laser_para_text_2,0,0, parameter_2.value, parameter_4.value, parameter_5.value) * 100000 * depth //sliderRepeater.itemAt(0).value/5
    property double radial_ratio: 0.46
    property double laser_radial : parameter_2.value * radial_ratio//sliderRepeater.itemAt(1).value/5
    property int drilling_radial: appmodel.calculate_w0loc(0,0,0,0, parameter_2.value, parameter_4.value, parameter_5.value)*1000 * radial

    id: root
    width: 1080 ;height: 560
    color: "#0f100f"
    visible: true
    title: qsTr("DataVisualization-LaserProcess")

    SimulationModel{
        id:appmodel
    }

    Rectangle {
        x: root.width * 0.76
        y: root.height/20
        height: root.height - root.height/10
        width: 2
        color: colorGlow
        implicitWidth: 1
        Layout.fillHeight: true
    }

    Slider {
        id: timesSlider
        x: 30
        y: 279 + thickness + 45
        style: sliderStyle
        width: root.height * 1.35
        height: 30
        value: 1
        maximumValue: 50 * 10 -1 //appmodel.get_finish_run()
        minimumValue: 1
        stepSize: 1

        onValueChanged: function(){
            laser_drilling_area.clear_canvas()
            laser_drilling_area.requestPaint()
            appmodel.get_holeevolefront(timesSlider.value)
            appmodel.get_holewidenradius(timesSlider.value)
        }
    }

    Canvas {
        id: laser_drilling_area
        x: root.width/ 20
        y: root.height/20
        anchors.fill: parent

        onPaint: {
            var ctx_laser = getContext("2d");

            // Draw workpiece
            ctx_laser.fillStyle = colorWorkpoece
            ctx_laser.fillRect(30, 300 , root.height * 1.35, thickness)

            // draw laser beam
            ctx_laser.fillStyle = colorLaserBeam


            if(appmodel.get_modelGenerated()){
                drilling_radial = appmodel.get_holewidenradius(timesSlider.value)*1000 * radial
                laser_depth = 277 - appmodel.get_holeevolefront(timesSlider.value) * 100000 * depth
            } else {
                drilling_radial = appmodel.calculate_w0loc(0,0,0,0, parameter_2.value, parameter_4.value, parameter_5.value)*1000 * radial
                laser_depth = 277 + appmodel.calculate_zloc(parameter_1.value * 1000,laser_para_text_2,0,0, parameter_2.value, parameter_4.value, parameter_5.value) * 100000 * depth
            }

            laser_radial = parameter_2.value * radial_ratio
            //laser_radial = 50 + sliderRepeater.itemAt(1).value/5
            ctx_laser.fillRect((30 + root.height * 0.675), 7.5 , laser_radial/2, laser_depth)
            ctx_laser.fillRect((30 + root.height * 0.675), 7.5 , - laser_radial/2, laser_depth)

            ctx_laser.beginPath();
            ctx_laser.fillStyle = colorHeatArea
            // Draw a circle
            //ctx.moveTo((workpiece.x + workpiece.width/2) , window.height/20+laser_depth);
            ctx_laser.arc((30 + root.height * 0.675), 7.5 + laser_depth, drilling_radial/2, Math.PI, 2*Math.PI, true)
            ctx_laser.fill();
            ctx_laser.stroke();
            //x, real y, real radius, real startAngle, real endAngle, bool anticlockwise
        }
        function clear_canvas() {
            var ctx_laser = getContext("2d");
            ctx_laser.reset();
            requestPaint();
        }
    }

    ColumnLayout {
        id: rightInfoBar
        x: root.width * 0.78
        y: root.height/20
        width: root.width * 0.18
        height: root.height * 0.8

        Layout.fillWidth: false
        Layout.fillHeight: true


        RowLayout {
            //id: attributeLayout

            Label {
                text: "Beam Radius:  "
                color: colorGlow
                font.pixelSize: 12
                Layout.fillWidth: true
            }

            Text{
                text: appmodel.get_para_w0()
                color: colorGlow
                font.pixelSize: 12
            }


            Label {
                text: "mm"
                width: 4
                color: colorGlow
                Layout.alignment: Qt.AlignBaseline | Qt.AlignLeft
            }
        }

        RowLayout {
            //id: attributeLayout
            Label {
                text: "Laser Pulse Peak: "
                color: colorGlow
                font.pixelSize: 12
                Layout.fillWidth: true
            }

            Text{
                text: appmodel.get_para_PL()
                color: colorGlow
                font.pixelSize: 12
            }


            Label {
                text: "kW"
                width: 2
                color: colorGlow
                Layout.alignment: Qt.AlignBaseline | Qt.AlignLeft
            }
        }

        RowLayout {
            //id: attributeLayout
            Label {
                text: "Finish in : "
                color: colorGlow
                font.pixelSize: 12
                Layout.fillWidth: true
            }

            Text{
                text: "20" //appmodel.get_finish_run()
                color: colorGlow
                font.pixelSize: 12
            }


            Label {
                text: "ms"
                width: w
                color: colorGlow
                Layout.alignment: Qt.AlignBaseline | Qt.AlignLeft
            }
        }
    }


}
