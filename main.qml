import QtQuick 2.5
import QtQuick.Window 2.2
import QtQuick.Layouts 1.1
import QtQuick.Controls 1.4
import QtQuick.Controls.Styles 1.2
import QtQuick.Dialogs 1.2
import QtCharts 2.2
import MetaModel.SimulationModel 1.0

ApplicationWindow {
    id: window
    width: 1080
    height: 560
    color: "#0f100f"
    visible: true
    title: qsTr("DataVisualization-MataModel")

    readonly property color colorGlow: "#1d6d64"
    readonly property color colorWarning: "#d5232f"
    readonly property color colorMain: "#6affcd"
    readonly property color colorBright: "#a9a9a9"
    readonly property color colorLightGrey: "#a9a9a9"
    readonly property color colorDarkGrey: "#696969"
    readonly property color colorWorkpoece: "#a9a9a9" //darkgray
    readonly property color colorLaserBeam: "#87cefa" //cyan
    readonly property color colorHeatArea: "#f08080" //lightcoral

    property double h_ratio: sliderLayout.height / (sliderMax - sliderMin)
    property double w_ratio: 1 //dataVisualization2.width / (sliderMax - sliderMin)
    property int sliderMin: 0
    property int sliderMax: 450
    property int slider_ini: 50
    property int bias: 12


    property real sliderVal
    property int sliderNumber: 5 //backend.read()

    property int y_ratio: 1
    property double x_ratio: 1.8
    property int x_position: dataVisualization.x + parameter_2.value * x_ratio//(appmodel.calculate_zloc(parameter_1.value, 0, 0,parameter_3.value, parameter_2.value,parameter_4.value, parameter_5.value)*x_ratio)
    property int y_position: sliderLayout.y + (appmodel.calculate_intensloc(parameter_1.value, 0, 0,parameter_3.value, parameter_2.value,parameter_4.value, parameter_5.value)/y_ratio)

    property int depth: 10
    property int laser_depth: 277 + appmodel.calculate_zloc(parameter_1.value*1000,laser_para_text_2,0,0, parameter_2.value, parameter_4.value, parameter_5.value) * 100000 * depth //sliderRepeater.itemAt(0).value/5
    //property int laser_depth: 285 + appmodel.get_holeevolefront(timesSlider.value) * 100000 * depth

    property int radial: 530
    property double radial_ratio: 0.46
    property double laser_radial : parameter_2.value * radial_ratio//sliderRepeater.itemAt(1).value/5
    property int drilling_radial: appmodel.calculate_w0loc(0,0,0,0, parameter_2.value, parameter_4.value, parameter_5.value)*1000 * radial
    //property int drilling_radial: appmodel.get_holewidenradius()*1000 * radial
    property int columnFactor: 1.0

    property int resolution: 50
    property int laser_pulse: 5

    SimulationModel{
        id:appmodel
    }

    FileDialog {
        id: fileOpenDialog
        title: "Select an image file"
        folder: shortcuts.documents
        nameFilters: [
            "Image files (*.png *.jpeg *.jpg)",
        ]
        onAccepted: {
            image.source = fileOpenDialog.fileUrl
        }
    }

    Rectangle {
        x: window.width * 0.8
        y: window.height/20
        height: window.height - window.height/10
        width: 2
        color: colorGlow
        implicitWidth: 1
        Layout.fillHeight: true
    }

    Rectangle {
        x: window.width/ 9
        y: window.height/20
        height: window.height - window.height/10
        width: 2
        color: colorGlow
        implicitWidth: 1
        Layout.fillHeight: true
    }

    Image {
        id: dataVisualization
        x: window.width/9
        y: window.height/10
        height: (window.height /4) * 3
        width: height * 1.78
        anchors.leftMargin: window.width / 9
        anchors.topMargin: window.height / 10
        fillMode: Image.PreserveAspectCrop
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 10
        visible: false
        source: "image/testdata-diagram_01.png"
    }

    Canvas {
        id: machine_1_area
        x: window.width/9
        y: window.height/10
        height: (window.height /4) * 3
        width: height * 1.78
        anchors.leftMargin: window.width / 9
        anchors.topMargin: window.height / 10
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 10
        visible: false
        onPaint: {
            var ctx = getContext("2d");
            ctx.fillStyle = colorMain
            // Render all the points as small black-circles
            ctx.strokeStyle = Qt.rgba(0, 1, 1, 0)
            appmodel.start_machine_1()
            for(var i=0; i < 50*3 ; i++){
                ctx.ellipse(appmodel.get_machine_1_x(i)*x_ratio, appmodel.get_machine_1_y(i), 10, 10)
            }
            context.fill()
            context.stroke()
        }
    }

    Canvas {
        id: machine_2_area
        x: window.width/9
        y: window.height/10
        height: (window.height /4) * 3
        width: height * 1.78
        anchors.leftMargin: window.width / 9
        anchors.topMargin: window.height / 10
        anchors.top: parent.top
        anchors.left: parent.left
        anchors.margins: 10
        visible: false
        onPaint: {
            var ctx = getContext("2d");
            ctx.fillStyle = colorLaserBeam
            // Render all the points as small black-circles
            ctx.strokeStyle = Qt.rgba(0, 1, 1, 0)
            appmodel.start_machine_2()
            for(var i=0; i < 160*3 ; i++){
                ctx.ellipse(appmodel.get_machine_2_x(i)*x_ratio, appmodel.get_machine_2_y(i), 10, 10)
            }
            context.fill()
            context.stroke()
        }
    }

    RowLayout {
        id: sliderLayout
        x: window.width * 0.825
        y: dataVisualization.y
        height: dataVisualization.height* 0.992
        width: window.width * 0.165
        spacing: 6
        visible: false
        // PL:pulse peak power ; tp:pulse duration nump:number of pulses dw:workpiece thickness
        // W0:beam radius ; z0:focal position ;zR: rayleigh length

        // intensity= peak_power/(pi*w0*w0)
        // peak_power range from (2 KW to 20 KW)
        // w0 range from 20µm to 400µm
        // Machine 1:power 1KW-6KW, w0: 50µm,100µm,200µm
        // Machine 2: power 4KW-20KW,w0:100µm,200µm,300µm

        Slider {
            id: parameter_1
            y: 0
            height: dataVisualization.height* 0.862
            implicitHeight: dataVisualization.height* 0.862
            orientation: Qt.Vertical
            // peak_power range from (2 KW to 20 KW)
            // Machine 1:power 1KW-6KW,
            // Machine 2: power 4KW-20KW,
            maximumValue: maxText_1.text.valueOf()
            minimumValue: minText_1.text.valueOf()
            stepSize: 2
            value: 142
            style: sliderStyle

            onValueChanged: function(){
                moving_circle.clear_canvas()
                moving_circle.requestPaint()
                x_position = dataVisualization.x + parameter_2.value * x_ratio//(appmodel.calculate_zloc(parameter_1.value, 0, 0,parameter_3.value, parameter_2.value,parameter_4.value, parameter_5.value)*x_ratio)
                y_position = sliderLayout.y + (appmodel.calculate_intensloc(parameter_1.value, 0, 0,parameter_3.value, parameter_2.value,parameter_4.value, parameter_5.value)/y_ratio)
            }

            Text{
                y: parameter_1.height + 10
                text: Math.floor(parameter_1.value)
                color: colorMain
                font.pointSize: 9
            }
            Text{
                y: - 30
                text: "PL" //PL:pulse peak power
                color: colorMain
                font.pointSize: 9
            }
        }

        Slider {
            id: parameter_2
            y: 0
            height: dataVisualization.height* 0.862
            implicitHeight: dataVisualization.height* 0.862
            orientation: Qt.Vertical
            // w0 range from 20µm to 400µm
            maximumValue: maxText_4.text.valueOf()
            minimumValue: minText_4.text.valueOf()
            value: 270
            stepSize: 5
            style: sliderStyle

            onValueChanged: function(){
                moving_circle.clear_canvas()
                moving_circle.requestPaint()
                x_position = dataVisualization.x + parameter_2.value * x_ratio// (appmodel.calculate_zloc(parameter_1.value, 0, 0,parameter_3.value, parameter_2.value,parameter_4.value, parameter_5.value)*x_ratio)
                y_position = sliderLayout.y + (appmodel.calculate_intensloc(parameter_1.value, 0, 0,parameter_3.value, parameter_2.value,parameter_4.value, parameter_5.value)/y_ratio)
            }

            Text{
                y: parameter_2.height + 10
                text: Math.floor(parameter_2.value)
                color: colorMain
                font.pointSize: 9
            }
            Text{
                y: - 30 //
                text: "W0" // W0:beam radius
                color: colorMain
                font.pointSize: 9
            }
        }

        Slider {
            id: parameter_5
            y: 0
            height: dataVisualization.height* 0.862
            implicitHeight: dataVisualization.height* 0.862
            orientation: Qt.Vertical


            // Rayleigh Length zR [mm] 1 mm – 35 mm
            maximumValue: maxText_6.text.valueOf()
            minimumValue: minText_6.text.valueOf()
            value: 35
            stepSize: 1

            style: sliderStyle

            onValueChanged: function(){
                moving_circle.clear_canvas()
                moving_circle.requestPaint()
                x_position = dataVisualization.x + parameter_2.value * x_ratio// (appmodel.calculate_zloc(parameter_1.value, 0, 0,parameter_3.value, parameter_2.value,parameter_4.value, parameter_5.value)*x_ratio)
                y_position = sliderLayout.y + (appmodel.calculate_intensloc(parameter_1.value, 0, 0,parameter_3.value, parameter_2.value,parameter_4.value, parameter_5.value)/y_ratio)
            }

            Text{
                y: parameter_5.height + 10
                text: Math.floor(parameter_5.value)
                color: colorMain
                font.pointSize: 9
            }
            Text{
                y: - 30
                text: "zR" //zR: rayleigh length
                color: colorMain
                font.pointSize: 9
            }
        }

        Slider {
            id: parameter_4
            y: 0
            height: dataVisualization.height* 0.862
            implicitHeight: dataVisualization.height* 0.862
            orientation: Qt.Vertical
            // Focal position z0 [mm]	-8mm – 8mm
            maximumValue: maxText_5.text.valueOf()
            minimumValue: minText_5.text.valueOf()
            value: 1
            stepSize: 1
            style: sliderStyle
            //visible: false

            onValueChanged: function(){
                moving_circle.clear_canvas()
                moving_circle.requestPaint()
                x_position = dataVisualization.x + parameter_2.value * x_ratio//(appmodel.calculate_zloc(parameter_1.value, 0, 0,parameter_3.value, parameter_2.value,parameter_4.value, parameter_5.value)*x_ratio)
                y_position =  sliderLayout.y + (appmodel.calculate_intensloc(parameter_1.value, 0, 0,parameter_3.value, parameter_2.value,parameter_4.value, parameter_5.value)/y_ratio)
            }

            Text{
                y: parameter_4.height + 10
                text: Math.floor(parameter_4.value)
                color: colorMain
                font.pointSize: 9
            }
            Text{
                y: - 30
                text: "z0" // z0:focal position
                color: colorMain
                font.pointSize: 9
            }
        }

        Slider {
            id: parameter_3
            y: 0
            height: dataVisualization.height* 0.862
            implicitHeight: dataVisualization.height* 0.862
            orientation: Qt.Vertical            
            //workpiece thickness
            maximumValue: maxText_3.text.valueOf()
            minimumValue: minText_3.text.valueOf()
            value: 26
            stepSize: 0.5
            style: sliderStyle

            onValueChanged: function(){
                moving_circle.clear_canvas()
                moving_circle.requestPaint()
                x_position = dataVisualization.x + parameter_2.value * x_ratio// (appmodel.calculate_zloc(parameter_1.value, 0, 0,parameter_3.value, parameter_2.value,parameter_4.value, parameter_5.value)*x_ratio)
                y_position = sliderLayout.y + (appmodel.calculate_intensloc(parameter_1.value, 0, 0,parameter_3.value, parameter_2.value,parameter_4.value, parameter_5.value)/y_ratio)
            }

            Text{
                y: parameter_3.height + 10
                text: Math.floor(parameter_3.value)
                color: colorMain
                font.pointSize: 9
            }
            Text{
                y: - 30
                text: "dw" //dw:workpiece thickness
                color: colorMain
                font.pointSize: 9
            }
        }
    }

    Canvas {
        id: parameter_machine_1
        visible: false
        anchors {
            left: sliderLayout.left
            right: sliderLayout.right
            top: sliderLayout.top
            bottom: sliderLayout.bottom
        }
        property real lastX
        property real lastY
        property color color: colorMain
        height: 464
        anchors.bottomMargin: 7

    // Machine 1:power 1KW-6KW, w0: 50µm,100µm,200µm  - ML1 applicable area
        onPaint: {
            var ctx_limit_min = getContext('2d')
            ctx_limit_min.lineWidth = 1.5
            ctx_limit_min.strokeStyle = colorMain


            ctx_limit_min.beginPath()
            ctx_limit_min.moveTo(  10 , 365 )
            ctx_limit_min.lineTo(  11 + (sliderLayout.width/5)*1,  355 ) // 50
            ctx_limit_min.lineTo(  12 + (sliderLayout.width/5)*2,  385 )
            ctx_limit_min.lineTo(  13 + (sliderLayout.width/5)*3,  230 )
            ctx_limit_min.stroke()



            ctx_limit_min.beginPath()
            ctx_limit_min.moveTo(  10 , 245 )
            ctx_limit_min.lineTo(  11 + (sliderLayout.width/5)*1,  220 ) // 200
            ctx_limit_min.lineTo(  12 + (sliderLayout.width/5)*2,  385 )
            ctx_limit_min.lineTo(  13 + (sliderLayout.width/5)*3,  230 )
            ctx_limit_min.stroke()

        }
        function clear_canvas() {
            var ctx_limit_min = getContext("2d");
            ctx_limit_min.reset();
            parameter_machine_1.requestPaint();
        }
    }

    Canvas {
        id: parameter_machine_2
        visible: false
        anchors {
            left: sliderLayout.left
            right: sliderLayout.right
            top: sliderLayout.top
            bottom: sliderLayout.bottom
        }
        property real lastX
        property real lastY
        property color color: colorMain
        height: 464
        anchors.bottomMargin: 7
    // Machine 2: power 4KW-20KW,w0:100µm,200µm,300µm - ML2 applicable area
        onPaint: {
            var ctx_limit_min = getContext('2d')
            //ratio = sliderLayout.y / (sliderMax - sliderMin)
            ctx_limit_min.lineWidth = 1.5
            ctx_limit_min.strokeStyle = colorLaserBeam
            ctx_limit_min.beginPath()
            ctx_limit_min.moveTo(  10 , 315 ) // 4
            ctx_limit_min.lineTo(  11 + (sliderLayout.width/5)*1,  310 ) // 100
            ctx_limit_min.lineTo(  12 + (sliderLayout.width/5)*2,  385 )
            ctx_limit_min.lineTo(  13 + (sliderLayout.width/5)*3,  230 )
            ctx_limit_min.stroke()

            ctx_limit_min.beginPath()
            ctx_limit_min.moveTo(  10 , 35 ) // 20
            ctx_limit_min.lineTo(  11 + (sliderLayout.width/5)*1,  130 ) // 300
            ctx_limit_min.lineTo(  12 + (sliderLayout.width/5)*2,  385 )
            ctx_limit_min.lineTo(  13 + (sliderLayout.width/5)*3,  230 )
            ctx_limit_min.stroke()
        }
        function clear_canvas() {
            var ctx_limit_min = getContext("2d");
            ctx_limit_min.reset();
            parameter_machine_2.requestPaint();
        }
    }

    Text {
        id:text_y
        visible: false
        x: dataVisualization.x + dataVisualization.width *0.45
        y: dataVisualization.y + dataVisualization.height
        wrapMode: Text.WordWrap
        color: "white"
        text: "Beam radius(μm)"
        font.pointSize: window.height/35
    }
    Text {
        id:text_x
        visible: false
        x : dataVisualization.x - 20
        y : dataVisualization.y + dataVisualization.height/2
        wrapMode: Text.WordWrap
        color: "white"
        text: "Intensity "
        font.pointSize: window.height/35
        rotation: 270
    }

    ColumnLayout{
        id: textLayout
        visible: false
        x: window.width * 0.845
        y: dataVisualization.y + dataVisualization.height* 0.862 + 55
        height: 50
        width: window.width * 0.150
        spacing: 6

        RowLayout {
            width: parent ? parent.width : 100
            Label {
               id:laser_para_label_1
               text: "Number_of_Pulses: "
               Layout.columnSpan: 2
               font.pixelSize: 9
               Layout.fillWidth: true
               color: colorMain
            }

            TextInput{
                id: laser_para_text_1
                text: qsTr("10")
                width: 6
                font.pixelSize: 18
                color: colorMain
            }

            Label {
                text: "times"
                width: 4
                Layout.alignment: Qt.AlignBaseline | Qt.AlignLeft
                color: colorMain
            }
        }

        RowLayout {
            width: parent ? parent.width : 100
            Label {
                id:laser_para_label_2
                text: "Pulse Duration:  "
                Layout.columnSpan: 2
                font.pixelSize: 9
                Layout.fillWidth: true
                color: colorMain
            }

            TextInput{
                id: laser_para_text_2
                text: qsTr("0.5")
                width: 6
                font.pixelSize: 18
                color: colorMain
            }

            Label {
                text: "ms"
                width: 4
                Layout.alignment: Qt.AlignBaseline | Qt.AlignLeft
                color: colorMain
            }
        }
    }


    ColumnLayout {
        id: leftTabBar
        x: (window.width /32)
        y: (window.height/8)
        width: (window.width /18)
        height: (window.height/8) *6

        Layout.fillWidth: false
        Layout.fillHeight: true

        Button {
            style: buttonStyle
            checkable: true
            checked: true
            Layout.fillHeight: true
            onClicked: {
                appmodel.startSimulation(parameter_1.value ,laser_para_text_2,laser_para_text_1 ,parameter_3.value, parameter_2.value, parameter_4.value, parameter_5.value)
                //appmodel.startPictureGenerated()
            }
            Text {
                text: qsTr("laserModel")
                font.pointSize: 10
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                transformOrigin: Item.Center
                color: colorGlow
            }
        }

        Button {
            style: buttonStyle
            checkable: true
            checked: true
            Layout.fillHeight: true

            //parameter_1.value,laser_para_text_2,0,, parameter_2.value, parameter_4.value, parameter_5.value
            onClicked: {
                appmodel.start_meta_Simulation(parameter_1.value ,laser_para_text_2,laser_para_text_1 ,parameter_3.value, parameter_2.value, parameter_4.value, parameter_5.value)
                if(dataVisualization.visible){
                    text_x.visible = false
                    text_y.visible = false
                    sliderLayout.visible = false
                    dataVisualization.visible = false
                    parameter_machine_1.visible = false
                    parameter_machine_2.visible = false
                    machine_1_area.visible = false
                    machine_2_area.visible = false
                    textLayout.visible = false
                }
                else {
                    text_x.visible = true
                    text_y.visible = true
                    sliderLayout.visible = true
                    dataVisualization.visible = true
                    parameter_machine_1.visible = true
                    parameter_machine_2.visible = true
                    machine_1_area.visible = true
                    machine_2_area.visible = true
                    textLayout.visible = true
                }
            }

            Text {
                text: qsTr("metaModel")
                font.pointSize: 10
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                transformOrigin: Item.Center
                color: colorGlow
            }
        }

        Button {
            style: buttonStyle
            checkable: true
            checked: true
            Layout.fillHeight: true

            onClicked: simulationDialog.open()
            Text {
                text: qsTr("Simulation")
                font.pointSize: 10
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                transformOrigin: Item.Center
                color: colorGlow
            }
        }

        Button {
            style: buttonStyle
            checkable: true
            Layout.fillHeight: true

            onClicked: settingDialog.open()

            Text {
                text: qsTr("Settings")
                font.pointSize: 10
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                transformOrigin: Item.Center
                color: colorGlow
            }
        }

        Button {
            style: buttonStyle
            checkable: true
            Layout.fillHeight: true

            onClicked: {
                fileOpenDialog.open();
            }
            Text {
                text: qsTr("File")
                font.pointSize: 10
                anchors.horizontalCenter: parent.horizontalCenter
                anchors.verticalCenter: parent.verticalCenter
                transformOrigin: Item.Center
                color: colorGlow
            }
        }
    }

    Canvas {
        id: moving_circle
        x: x_position
        y: y_position
        width: 50
        height: 50
        anchors.fill: parent
        onPaint: {
            var ctx = getContext("2d");
            ctx.fillStyle = "lightslategray"
            ctx.beginPath();
            x_position = dataVisualization.x + parameter_2.value * x_ratio //(appmodel.calculate_zloc(parameter_1.value, 0, 0,parameter_3.value, parameter_2.value,parameter_4.value, parameter_5.value)*x_ratio)
            y_position = sliderLayout.y + (appmodel.calculate_intensloc(parameter_1.value, 0, 0,parameter_3.value, parameter_2.value,parameter_4.value, parameter_5.value)/y_ratio)
            // PL, tp, nump, dw, w0,  z0, zR
            //- (sliderRepeater.itemAt(0).value + sliderRepeater.itemAt(3).value/15 - sliderRepeater.itemAt(4).value/15)*h_ratio
            ctx.ellipse(x_position, y_position, window.height/22, window.height/22);
            ctx.fill();
        }
        function clear_canvas() {
            var ctx = getContext("2d");
            ctx.reset();
            requestPaint();
        }
    }

    Button {
        id: playButton
        x: window.width * 0.67
        y: window.height * 0.88
        text: qsTr("Start Simulation")
        onClicked: {
            if(appmodel.get_modelGenerated()){
                appmodel.set_para_PL(parameter_1.value)
                appmodel.set_para_dw(parameter_3.value)
                appmodel.set_para_w0(parameter_2.value)

                var component = Qt.createComponent("simulation.qml")
                var window    = component.createObject(window)
                window.show()
            }
        }
    }


    // Style delegates:

    Component {
        id: buttonStyle

        ButtonStyle {
            background: Rectangle {
                color: control.pressed ? colorGlow : "transparent"
                antialiasing: true
                border.color: colorGlow
                implicitWidth: 60
                implicitHeight: 90
            }
        }
    }

    Component {
        id: sliderStyle
        SliderStyle {
            handle: Rectangle {
                width: window.width/55
                height: width
                color: control.pressed ? "darkgray" : "lightGray"
                border.color: "black"
                antialiasing: true
                radius: height/2
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    color: "transparent"
                    antialiasing: true
                    border.color: "#eee"
                    radius: height/2
                }
            }
            groove: Rectangle {
                height: 8
                implicitWidth: window.width
                implicitHeight: 22

                antialiasing: true
                color: "#ccc"
                border.color: "#777"
                radius: height/2
                Rectangle {
                    anchors.fill: parent
                    anchors.margins: 1
                    color: "transparent"
                    antialiasing: true
                    border.color: "#66ffffff"
                    radius: height/2
                }
            }
        }
    }

    Dialog {
        id: settingDialog
        width: 450
        height: 250
        //modality: dialogModal.checked ? Qt.WindowModal : Qt.NonModal
        //title: customizeTitle.checked ? windowTitleField.text : "Spinbox"
        onHelp: {
            lastChosen.text = "No help available, sorry.  Please answer the question."
            visible = true
        }
        onButtonClicked: {

        }
        // PL:pulse peak power ; tp:pulse duration nump:number of pulses dw:workpiece thickness
        // W0:beam radius ; z0:focal position ;zR: rayleigh length

        // intensity= peak_power/(pi*w0*w0)
        // peak_power range from (2 KW to 20 KW)
        // w0 range from 20µm to 400µm
        // Machine 1:power 1KW-6KW, w0: 50µm,100µm,200µm
        // Machine 2: power 4KW-20KW,w0:100µm,200µm,300µm

        ColumnLayout{

            RowLayout {
                //id: attributeLayout
                width: parent ? parent.width : 100
                Label {
                   id:attID
                   text: "Pulse Peak Power: "
                   Layout.columnSpan: 2
                   font.pixelSize: 18
                   Layout.fillWidth: true
                   //wrapMode: Text.WordWrap
                }

                TextInput{
                    id: minText_1
                    text: qsTr("2")
                    width: 6
                    font.pixelSize: 18
                    anchors.left: attID.right
                }

                Text{
                    id: symple_1
                    text: "  --  "
                    font.pixelSize: 18
                    anchors.left: minText_1.right
                }

                TextInput{
                    id: maxText_1
                    text: qsTr("200")
                    width: 6
                    font.pixelSize: 18
                    anchors.left: symple_1.right
                }

                Label {
                    text: "kW"
                    width: 4
                    Layout.alignment: Qt.AlignBaseline | Qt.AlignLeft
                }
            }

            RowLayout {
                //id: attributeLayout
                width: parent ? parent.width : 100
                Label {
                    id:attID_2
                    text: "Pulse Duration:  "
                    Layout.columnSpan: 2
                    font.pixelSize: 18
                    Layout.fillWidth: true
                    //wrapMode: Text.WordWrap
                }

                TextInput{
                    id: minText_2
                    text: qsTr("2")
                    width: 6
                    font.pixelSize: 18
                    anchors.left: attID_2.right
                }

                Text{
                    id: symple_2
                    text: "  --  "
                    font.pixelSize: 18
                    anchors.left: minText_2.right
                }

                TextInput{
                    id: maxText_2
                    text: qsTr("20")
                    width: 6
                    font.pixelSize: 18
                    anchors.left: symple_2.right
                }

                Label {
                    text: "ms"
                    width: 4
                    Layout.alignment: Qt.AlignBaseline | Qt.AlignLeft
                }
            }

            //dw:workpiece thickness
            RowLayout {
                //id: attributeLayout
                width: parent ? parent.width : 100
                Label {
                    id:attID_3
                    text: "Workpiece Thickness:  "
                    Layout.columnSpan: 2
                    font.pixelSize: 18
                    Layout.fillWidth: true
                    //wrapMode: Text.WordWrap
                }

                TextInput{
                    id: minText_3
                    text: qsTr("1")
                    width: 6
                    font.pixelSize: 18
                    anchors.left: attID_3.right
                }

                Text{
                    id: symple_3
                    text: "  --  "
                    font.pixelSize: 18
                    anchors.left: minText_3.right
                }

                TextInput{
                    id: maxText_3
                    text: qsTr("30")
                    width: 6
                    font.pixelSize: 18
                    anchors.left: symple_3.right
                }

                Label {
                    text: "mm"
                    width: 4
                    Layout.alignment: Qt.AlignBaseline | Qt.AlignLeft
                }
            }

            // W0:beam radius ;

            RowLayout {
                //id: attributeLayout
                width: parent ? parent.width : 100
                Label {
                    id:attID_4
                    text: "Beam Radius:  "
                    Layout.columnSpan: 2
                    font.pixelSize: 18
                    Layout.fillWidth: true
                    //wrapMode: Text.WordWrap
                }

                TextInput{
                    id: minText_4
                    text: qsTr("20")
                    width: 6
                    font.pixelSize: 18
                    anchors.left: attID_4.right
                }

                Text{
                    id: symple_4
                    text: "  --  "
                    font.pixelSize: 18
                    anchors.left: minText_4.right
                }

                TextInput{
                    id: maxText_4
                    text: qsTr("400")
                    width: 6
                    font.pixelSize: 18
                    anchors.left: symple_4.right
                }

                Label {
                    text: "mm"
                    width: 4
                    Layout.alignment: Qt.AlignBaseline | Qt.AlignLeft
                }
            }

            //z0:focal position ;
            RowLayout {
                //id: attributeLayout
                width: parent ? parent.width : 100
                Label {
                    id:attID_5
                    text: "Focal Position:  "
                    Layout.columnSpan: 2
                    font.pixelSize: 18
                    Layout.fillWidth: true
                    //wrapMode: Text.WordWrap
                }

                TextInput{
                    id: minText_5
                    text: qsTr("-8")
                    width: 6
                    font.pixelSize: 18
                    anchors.left: attID_5.right
                }

                Text{
                    id: symple_5
                    text: "  --  "
                    font.pixelSize: 18
                    anchors.left: minText_5.right
                }

                TextInput{
                    id: maxText_5
                    text: qsTr("8")
                    width: 6
                    font.pixelSize: 18
                    anchors.left: symple_5.right
                }

                Label {
                    text: "mm"
                    width: 4
                    Layout.alignment: Qt.AlignBaseline | Qt.AlignLeft
                }
            }
            //zR: rayleigh length
            RowLayout {
                //id: attributeLayout
                width: parent ? parent.width : 100
                Label {
                    id:attID_6
                    text: "Rayleigh Length:  "
                    Layout.columnSpan: 2
                    font.pixelSize: 18
                    Layout.fillWidth: true
                    //wrapMode: Text.WordWrap
                }

                TextInput{
                    id: minText_6
                    text: qsTr("1")
                    width: 6
                    font.pixelSize: 18
                    anchors.left: attID_6.right
                }

                Text{
                    id: symple_6
                    text: "  --  "
                    font.pixelSize: 18
                    anchors.left: minText_6.right
                }

                TextInput{
                    id: maxText_6
                    text: qsTr("35")
                    width: 6
                    font.pixelSize: 18
                    anchors.left: symple_6.right
                }

                Label {
                    text: "mm"
                    width: 4
                    Layout.alignment: Qt.AlignBaseline | Qt.AlignLeft
                }
            }
        }
    }


    Dialog {
        id: simulationDialog
        width: 450
        height: 250
        //modality: dialogModal.checked ? Qt.WindowModal : Qt.NonModal
        //title: customizeTitle.checked ? windowTitleField.text : "Spinbox"
        onHelp: {
            lastChosen.text = "No help available, sorry.  Please answer the question."
            visible = true
        }
        onButtonClicked: {
            appmodel.startSimulation(sim_para_Text_1.text.valueOf(), sim_para_Text_2.text.valueOf(), 0, sim_para_Text_3.text.valueOf(),sim_para_Text_4.text.valueOf(),
                                     sim_para_Text_5.text.valueOf(), sim_para_Text_6.text.valueOf(), sim_para_Text_7.text.valueOf())
        }
        // PL:pulse peak power ; tp:pulse duration nump:number of pulses dw:workpiece thickness
        // W0:beam radius ; z0:focal position ;zR: rayleigh length

        // intensity= peak_power/(pi*w0*w0)
        // peak_power range from (2 KW to 20 KW)
        // w0 range from 20µm to 400µm
        // Machine 1:power 1KW-6KW, w0: 50µm,100µm,200µm
        // Machine 2: power 4KW-20KW,w0:100µm,200µm,300µm

        ColumnLayout{

            RowLayout {
                //id: attributeLayout
                width: parent ? parent.width : 100
                Label {
                   id:sim_para_1_label
                   text: "Pulse Peak Power: "
                   Layout.columnSpan: 2
                   font.pixelSize: 18
                   Layout.fillWidth: true
                   //wrapMode: Text.WordWrap
                }

                TextInput{
                    id: sim_para_Text_1
                    text: qsTr("6")
                    width: 6
                    font.pixelSize: 18
                    //anchors.left: sim_para_1_label.right
                }

                Label {
                    text: "kW"
                    width: 4
                    Layout.alignment: Qt.AlignBaseline | Qt.AlignLeft
                }
            }

            RowLayout {
                //id: attributeLayout
                width: parent ? parent.width : 100
                Label {
                    id:sim_para_2_label
                    text: "Pulse Duration:  "
                    Layout.columnSpan: 2
                    font.pixelSize: 18
                    Layout.fillWidth: true
                }

                TextInput{
                    id: sim_para_Text_2
                    text: qsTr("3")
                    width: 6
                    font.pixelSize: 18
                }

                Label {
                    text: "ms"
                    width: 4
                    Layout.alignment: Qt.AlignBaseline | Qt.AlignLeft
                }
            }

            //dw:workpiece thickness
            RowLayout {
                //id: attributeLayout
                width: parent ? parent.width : 100
                Label {
                    id:sim_para_3_label
                    text: "Workpiece Thickness:  "
                    Layout.columnSpan: 2
                    font.pixelSize: 18
                    Layout.fillWidth: true
                    //wrapMode: Text.WordWrap
                }

                TextInput{
                    id: sim_para_Text_3
                    text: qsTr("5")
                    width: 6
                    font.pixelSize: 18
                }

                Label {
                    text: "mm"
                    width: 4
                    Layout.alignment: Qt.AlignBaseline | Qt.AlignLeft
                }
            }

            // W0:beam radius ;

            RowLayout {
                //id: attributeLayout
                width: parent ? parent.width : 100
                Label {
                    id:sim_para_4_label
                    text: "Beam Radius:  "
                    Layout.columnSpan: 2
                    font.pixelSize: 18
                    Layout.fillWidth: true
                    //wrapMode: Text.WordWrap
                }

                TextInput{
                    id: sim_para_Text_4
                    text: qsTr("40")
                    width: 6
                    font.pixelSize: 18
                }

                Label {
                    text: "mm"
                    width: 4
                    Layout.alignment: Qt.AlignBaseline | Qt.AlignLeft
                }
            }

            //z0:focal position ;
            RowLayout {
                //id: attributeLayout
                width: parent ? parent.width : 100
                Label {
                    id:sim_para_5_label
                    text: "Focal Position:  "
                    Layout.columnSpan: 2
                    font.pixelSize: 18
                    Layout.fillWidth: true
                    //wrapMode: Text.WordWrap
                }

                TextInput{
                    id: sim_para_Text_5
                    text: qsTr("-1")
                    width: 6
                    font.pixelSize: 18
                }

                Label {
                    text: "mm"
                    width: 4
                    Layout.alignment: Qt.AlignBaseline | Qt.AlignLeft
                }
            }
            //zR: rayleigh length
            RowLayout {
                //id: attributeLayout
                width: parent ? parent.width : 100
                Label {
                    id:sim_para_6_label
                    text: "Rayleigh Length:  "
                    Layout.columnSpan: 2
                    font.pixelSize: 18
                    Layout.fillWidth: true
                }

                TextInput{
                    id: sim_para_Text_6
                    text: qsTr("1")
                    width: 6
                    font.pixelSize: 18
                }
                Label {
                    text: "mm"
                    width: 4
                    Layout.alignment: Qt.AlignBaseline | Qt.AlignLeft
                }
            }
            Button {
                id: simButton
                text: qsTr("Start Simulation")
                onClicked: {
                    appmodel.startSimulation()
                }
            }
        }
    }
}

