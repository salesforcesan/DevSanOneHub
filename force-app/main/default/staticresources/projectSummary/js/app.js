(function(window) {
  'use strict';
  var _id = 0;

  function genId() {
    _id++;
    return ['chart', _id].join('_');
  }

  function Charts() {
    this.instances = {};
  }

  function registerInstance(domId, canvas) {
    OH.charts.instances[domId] = {
      'canvas': canvas,
      'dataUrl': undefined
    };
  }

  function registerAmchart(domId, chart) {
    OH.amCharts[domId] = chart;
  }

  function getNode(n, v) {
    n = document.createElementNS("http://www.w3.org/2000/svg", n);
    for (var p in v)
      n.setAttributeNS(null, p.replace(/[A-Z]/g, function(m, p, o, s) {
        return "-" + m.toLowerCase();
      }), v[p]);
    return n
  }

  function genRect(opt) {
    var rect = new fabric.Rect({
      top: opt.top,
      left: opt.left,
      lockMovementX: true,
      lockMovementY: true,
      editable: false,
      width: opt.width,
      height: opt.height,
      lockScalingX: true,
      lockScalingY: true,
      selectable: false,
      fill: opt.fill
    });
    if (!!opt.strokeWidth) {
      rect.strokeWidth = opt.strokeWidth;
      rect.stroke = opt.stroke || opt.fill;
      rect.strokeLineJoin = opt.strokeLineJoin || 'round';
    }
    return rect;
  }

  function genTextbox(opt) {
    return new fabric.Textbox(opt.content + '', {
      fontSize: opt.fontSize || 13,
      fontWeight: opt.fontWeight || 400,
      fontFamily: 'Salesforce Sans',
      lockMovementX: true,
      lockMovementY: true,
      editable: false,
      textAlign: opt.textAlign || 'left',
      width: opt.width,
      lockScalingX: true,
      lockScalingY: true,
      strokeWidth: opt.strokeWidth || 0.25,
      stroke: opt.stroke || opt.fill,
      fill: opt.fill,
      lockUnitScaling: true,
      top: opt.top,
      left: opt.left,
      selectable: false
    });
  }

  Charts.prototype.makeLineAreaChart = function(domId, config) {
    var chart, firstData, firstDate, firstMonth, data = config.data || [];
    firstData = data.length > 0 ? moment(data[0].date) : undefined;
    firstDate = !!firstData ? firstData.format('DD') : '';
    firstMonth = !!firstData ? firstData.format('MMM') : '';

    chart = AmCharts.makeChart(domId, {
      "type": "serial",
      "theme": "light",
      "fontSize": 16,
      "color": config.color,
      "dataProvider": data,
      //"creditsPosition": 'bottom-right',
      "legend": {
        "horizontalGap": 10,
        "verticalGap": 10,
        "useGraphSettings": true,
        "markerSize": 10,
        "align": "center",
        "position": "top",
        "valueAlign": "left"
      },
      "balloon": {
        "cornerRadius": 6,
        "horizontalPadding": 15,
        "verticalPadding": 10
      },
      "valueAxes": [{
        "id": 'dailyExecution',
        "axisAlpha": 0,
        "labelsEnabled": false,
        "gridThickness": 0,
        "position": "left"
      }, {
        "id": 'burndownExecution',
        "axisAlpha": 0,
        "labelsEnabled": false,
        "gridThickness": 0,
        "inside": true,
        "position": "right"
      }],
      "graphs": [{
        "id": "graph1",
        "showAllValueLabels": true,
        "balloonText": "<span style='font-size:12px;'>[[title]] on [[category]]:<br><span style='font-size:20px;'>[[value]]</span> [[additional]]</span>",
        "bullet": "round",
        "bulletBorderAlpha": 1,
        "bulletBorderThickness": 1,
        "fillAlphas": config.fillAlphas || 0.8,
        "fillColors": config.fill,
        "legendValueText": "[[value]]",
        "lineColor": config.lineColor,
        "lineThickness": config.lineThickness || 4,
        "title": "Executed Jobs",
        "valueField": "duration",
        "labelText": "[[value]]",
        "valueAxis": "dailyExecution",
      }, {
        "id": "graph2",
        "showAllValueLabels": true,
        "balloonText": "<span style='font-size:12px;'>[[title]] on [[category]]:<br><span style='font-size:20px;'>[[value]]</span> [[additional]]</span>",
        "bullet": "square",
        "lineThickness": 2,
        "lineColor": config.line2Color,
        "bulletSize": 7,
        "fillAlphas": 0,
        "bulletBorderAlpha": 1,
        "bulletColor": "#FFFFFF",
        "useLineColorForBulletBorder": true,
        "bulletBorderThickness": 3,
        "lineAlpha": 1,
        "title": "Jobs to Execute",
        "valueField": "jobs",
        "labelText": "[[value]]",
        "valueAxis": "dailyExecution"
      }],
      "chartCursor": {
        "categoryBalloonDateFormat": "YYYY MMM DD",
        "cursorAlpha": 0.1,
        "cursorColor": "#666666",
        "fullWidth": true
      },
      "dataDateFormat": "YYYY-MM-DD",
      "categoryField": "date",
      "categoryAxis": {
        "dateFormats": [{
          "period": "DD",
          "format": "DD"
        }, {
          "period": "WW",
          "format": "MMM DD"
        }, {
          "period": "MM",
          "format": "MMM"
        }, {
          "period": "YYYY",
          "format": "YYYY"
        }],
        "parseDates": true,
        "autoGridCount": true,
        "axisColor": "#fff",
        "gridAlpha": 0,
        "gridCount": 50,
        "gridThickness": 0,
        "labelFunction": function(item) {
          return (!!firstDate && firstDate == item) ? [firstMonth, item].join(' ') : item;
        }
      },
      "export": {
        "enabled": true,
        "menu": [],
        "libs": {
          autoLoad: false
        }
      }
    });
    registerAmchart(domId, chart);
  };

  Charts.prototype.makePieChart = function(domId, config) {
    var legend, data = config.data || [],
      chart = new AmCharts.AmPieChart();
    chart.startAngle = 185;
    chart.fontSize = 16;
    chart.radius = config.radius;
    chart.innerRadius = config.innerRadius;
    chart.labelsEnabled = false;
    chart.pullOutEffect = 'easeInSine';
    chart.pullOutDuration = 0;
    chart.startEffect = 'easeInSine';
    chart.startDuration = 0;
    chart.titleField = 'title';
    chart.valueField = 'value';
    chart.theme = 'light';
    chart.colorField = 'color';
    chart.creditsPosition = 'bottom-right';
    chart.percentPrecision = config.percentPrecision || 0;
    chart.precision = config.precision || 0;
    chart.balloonText = config.balloonText || "[[title]]<br><span style='font-size:14px'><b>[[value]]</b> ([[percents]]%)</span>";
    chart.export = {
      enabled: true,
      menu: [],
      "libs": {
        autoLoad: false
      }
    };

    chart.dataProvider = data;

    if (!!config.title) {
      chart.allLabels = [{
        align: "center",
        y: config.title.top,
        size: config.title.fontSize,
        bold: true,
        color: config.title.color,
        text: config.title.content
      }, {
        align: "center",
        y: config.subTitle.top,
        size: config.subTitle.fontSize,
        bold: false,
        color: config.subTitle.color,
        text: config.subTitle.content
      }];
    }
    if (!!config.legend) {
      legend = new AmCharts.AmLegend();
      legend.align = 'left';
      legend.color = config.legend.color;
      legend.enabled = config.legend.enabled;
      legend.left = config.legend.left;
      legend.position = config.legend.position;
      legend.valueAlign = config.legend.valueAlign;
      legend.labelText = '[[title]]';
      legend.right = config.legend.right;
      legend.valueText = '([[percents]]% - [[value]])';
      chart.addLegend(legend);
    }

    chart.write(domId);
    chart.invalidateSize();
    registerAmchart(domId, chart);
  };

  Charts.prototype.makeBarChart = function(domId, config) {
    var t, graph, maxLength, axis, chart = new AmCharts.AmSerialChart();
    chart.rotate = config.rotate || false;
    chart.fontSize = 16;
    chart.categoryField = 'category';
    chart.startAlpha = 0;
    chart.theme = 'light';
    chart.marginLeft = config.marginLeft || 0;
    chart.color = config.color || OH.colors.label;
    chart.gridThickness = config.gridThickness || 0;
    chart.dataProvider = config.data;
    maxLength = 180;
    // chart.creditsPosition = 'bottom-right';
    chart.export = {
      enabled: true,
      menu: [],
      "libs": {
        autoLoad: false
      }
    };
    if (!!config.categoryAxis) {
      axis = chart.categoryAxis;
      t = config.categoryAxis;
      axis.autoGridCount = true;
      axis.autoWrap = t.textWrap || false;
      axis.ignoreAxisWidth = t.textWrap || false;
      axis.axisColor = (!!t.hidden) ? OH.colors.white : (t.color || OH.colors.black);
      axis.gridPosition = t.gridPosition || 'start';
      axis.gridThickness = t.gridThickness || 0;
      axis.axisThickness = t.thickness || 1;
      axis.labelFunction = t.labelFunction || function(valueText, serialDataItem, categoryAxis) {
        return valueText.length > maxLength ? valueText.substring(0, maxLength) + '...' : valueText;
      };
    }

    graph = new AmCharts.AmGraph();
    graph.id = genId();
    graph.bulletSize = 14;
    graph.colorField = 'color';
    graph.color = config.labelColor || OH.colors.black;
    graph.fillAlphas = 1;
    graph.lineAlpha = 0; //hide column border
    graph.labelText = config.labelText || '[[value]]';
    graph.labelPosition = config.labelPosition || 'top';
    graph.type = 'column';
    graph.valueField = 'value';
    chart.addGraph(graph);
    if (!!config.legend) {
      //add legend
    }
    if (!!config.valueAxis) {
      t = config.valueAxis;
      axis = new AmCharts.ValueAxis();
      axis.id = genId();
      if (!!t.hidden) {
        axis.axisAlpha = 0;
        axis.labelsEnabled = false;
      }
      axis.gridThickness = t.gridThickness || 0;
      axis.autoWrap = true;
      if (!!t.minimum || t.minimum === 0) {
        axis.minimum = 0;
      }
      if (!!t.maximum) {
        axis.maximum = t.maximum;
      }
      axis.axisColor = t.color || OH.colors.black;
      axis.color = t.labelColor || OH.colors.black;
      axis.axisThickness = t.thickness || 1;

      if (!!t.labelFunction) {
        axis.labelFunction = t.labelFunction;
      } else {
        axis.labelFunction = function(item) {
          return !!item ? item + '%' : item;
        };
      }
      chart.addValueAxis(axis);
    }

    chart.write(domId);
    chart.invalidateSize();
    registerAmchart(domId, chart);
  };

  Charts.prototype.makeGaugeChart = function(domId, config) {
    var chart = AmCharts.makeChart(domId, {
      "type": "gauge",
      "theme": "light",
      'autoDisplay': true,
      "autoResize": true,
      "creditsPosition": "bottom-right",
      "axes": [{
        "axisAlpha": 0,
        "tickAlpha": 0,
        "labelsEnabled": false,
        "startValue": 0,
        "endValue": 100,
        "startAngle": 0,
        "endAngle": 270,
        "bands": [{
          "color": "#eee",
          "startValue": 0,
          "endValue": 100,
          "radius": "100%",
          "innerRadius": "85%"
        }, {
          "color": config.band1.color,
          "startValue": 0,
          "endValue": config.band1.value,
          "radius": "100%",
          "innerRadius": "85%",
          "balloonText": config.band1.tip
        }, {
          "color": "#eee",
          "startValue": 0,
          "endValue": 100,
          "radius": "80%",
          "innerRadius": "65%"
        }, {
          "color": config.band2.color,
          "startValue": 0,
          "endValue": config.band2.value,
          "radius": "80%",
          "innerRadius": "65%",
          "balloonText": config.band2.tip
        }]
      }],
      "allLabels": [{
        "text": config.band1.label,
        "x": "49%",
        "y": 40,
        "size": 13,
        "color": "#16325c",
        "align": "right"
      }, {
        "text": config.band2.label,
        "x": "49%",
        "y": 65,
        "size": 13,
        "color": "#16325c",
        "align": "right"
      }, {
        "align": "left",
        "id": "Label-1",
        "rotation": 0,
        color: 'rgb(75, 202, 129)',
        "size": 40,
        'bold': true,
        "text": config.title,
        "x": 65,
        "y": 120
      }, {
        "align": "left",
        "id": "Label-2",
        "rotation": 0,
        color: 'rgb(75, 202, 129)',
        "size": 13,
        "text": config.subTitle,
        "x": 90,
        "y": 170
      }],
      "export": {
        "enabled": true,
        "menu": [],
        "libs": {
          autoLoad: false
        }
      }
    });
    registerAmchart(domId, chart);
  };

  Charts.prototype.drawCircle = function(canvas, config) {
    canvas.add(new fabric.Circle({
      top: config.top,
      left: config.left,
      fill: config.fill,
      stroke: config.borderColor,
      strokeWidth: config.borderWidth,
      radius: config.radius
    }));
  }

  Charts.prototype.drawTextbox = function(canvas, config) {
    canvas.add(genTextbox(config));
  };
  // only support value from 0 to 100;
  Charts.prototype.makeTimeline = function(domId, config) {
    var rect, tColor, tLeft, tAlign, circle, canvas = new fabric.Canvas(domId),
      width = config.width,
      left = 0,
      top = Math.round(config.height / 2),
      cTop = top - 12,
      cLeft = left,
      step = config.width / 100,
      data = config.data,
      isLastItem = 0,
      endItem = data[data.length - 1];

    canvas.lockUnitScaling = true;
    canvas.setHeight(config.height);
    canvas.setWidth(width);
    rect = new fabric.Rect({
      top: top,
      left: left + 1,
      lockMovementX: true,
      lockMovementY: true,
      editable: false,
      width: width - 4,
      height: 4,
      lockScalingX: true,
      lockScalingY: true,
      selectable: false,
      fill: config.backgroundColor
    });
    canvas.add(rect);
    tAlign = 'left';
    data.forEach(function(c) {
      tColor = c.color == OH.colors.orange ? c.color : '#54698d';
      cLeft = step * c.value;
      isLastItem = endItem.value === c.value ? 1 : 0;
      if (!!isLastItem) {
        tLeft = config.width - 154;
        cLeft = config.width - 26;
        tAlign = 'right';
      } else {
        tLeft = cLeft;
      }
      canvas.add(new fabric.Circle({
        top: cTop,
        left: cLeft,
        fill: c.color,
        height: 15,
        width: 10,
        radius: 12,
        selectable: false,
        editable: false,
        lockScalingX: true,
        lockScalingY: true,
      }));
      canvas.add(new fabric.Textbox(c.label, {
        fontSize: 16,
        fontWeight: 400,
        fontFamily: 'Salesforce Sans',
        lockMovementX: true,
        lockMovementY: true,
        editable: false,
        textAlign: tAlign,
        width: 150,
        lockScalingX: true,
        lockScalingY: true,
        strokeWidth: 0.25,
        stroke: tColor,
        fill: tColor,
        lockUnitScaling: true,
        top: cTop + 30,
        left: tLeft,
        selectable: false
      }));
      canvas.add(new fabric.Textbox(c.data, {
        fontSize: 16,
        fontWeight: 400,
        fontFamily: 'Salesforce Sans',
        lockMovementX: true,
        lockMovementY: true,
        editable: false,
        textAlign: tAlign,
        width: 150,
        lockScalingX: true,
        lockScalingY: true,
        strokeWidth: 0.25,
        stroke: tColor,
        fill: tColor,
        lockUnitScaling: true,
        top: cTop + 48,
        left: tLeft,
        selectable: false
      }));
    });
    registerInstance(domId, canvas);
  };

  Charts.prototype.makeChartLegend = function(domId, config) {
    var rect, gap, left, text, squareSize, top, canvas = new fabric.Canvas(domId);
    canvas.setWidth(config.width);
    canvas.setHeight(config.height);
    top = config.top;

    //add icon and chart title
    if (!!config.svgIconId) {
      fabric.loadSVGFromString(OHIMAGES[config.svgIconId], function(objects, options) {
        options.scaleX = 0.5;
        options.scaleY = 0.5;
        options.top = 30;
        options.left = 0;
        objects.forEach(function(o) {
          o.fill = OH.colors.green
        });
        var obj = fabric.util.groupSVGElements(objects, options);
        canvas.add(obj);
      });
      left = 50;
    } else {
      left = 0;
    }

    text = genTextbox({
      fontSize: config.titleFontSize,
      fontWeight: 700,
      textAlign: 'left',
      width: 200,
      fill: OH.colors.green,
      top: top,
      left: left,
      content: config.title || 'No Title'
    });
    canvas.add(text);

    //add job executed
    top += config.titleBottomGap || 40;
    gap = config.legendGap || 20;
    squareSize = config.squareSize || 15;
    config.data.forEach(function(o) {
      rect = genRect({
        left: 0,
        top: top,
        fill: o.color,
        height: squareSize,
        width: squareSize
      });
      canvas.add(rect);
      text = genTextbox({
        fontSize: config.labelFontSize,
        fontWeight: 400,
        textAlign: 'left',
        left: 30,
        top: top,
        fill: config.color || o.color,
        content: o.label,
        width: 200
      });
      canvas.add(text);
      top += gap;
    });

    if (!!config.callback) {
      config.callback(canvas);
    }
    registerInstance(domId, canvas);
  };

  Charts.prototype.makeManyTextboxes = function(domId, config) {
    var canvas;
    if (!config) {
      console.log('configs is required for makeTextbloxes.');
      return;
    }
    this.instances[domId] = {
      'dataUrl': undefined,
      'canvas': makeManyTextboxesCanvas(domId, config)
    };
  };

  Charts.prototype.makeTextbox = function(domId, config) {
    var canvas;
    if (!config) {
      console.log('configs is required for makeTextblox.');
      return;
    }

    if (config.useSvg) {
      makeTextBoxSVG(domId, config);
    } else {
      this.instances[domId] = {
        'dataUrl': undefined,
        'canvas': makeTextboxCanvas(domId, config)
      };
    }
  };

  function makeManyTextboxesCanvas(domId, config) {
    var count, x, y, fontSize, text, rect, top, canvas = new fabric.Canvas(domId);
    canvas.lockUnitScaling = true;
    canvas.setHeight(config.height);
    canvas.setWidth(config.width);
    config.boxes.forEach(function(box) {
      top = box.top || 0;
      fontSize = config.fontSize || box.fontSize || 13;
      rect = genRect({
        top: top,
        left: box.left,
        width: box.width,
        height: box.height - top - 10,
        fill: box.backgroundColor,
        strokeWidth: box.strokeWidth || 10
      });
      canvas.add(rect);
      switch (box.verticalAlign) {
        case 'middle':
          y = Math.round((box.height + box.top - fontSize) / 2);
          break;
        case 'bottom':
          y = box.top + box.height - fontSize - 10;
          break;
        default:
          y = 10;
      }

      text = genTextbox({
        top: y,
        left: box.left,
        fontSize: config.fontSize || box.fontSize,
        fontWeight: config.fontWeight || box.fontWeight,
        textAlign: config.textAlign || box.textAlign,
        fill: config.fontColor || box.fontColor,
        width: box.width,
        content: box.content
      });
      canvas.add(text);
      if (!!box.title) {
        text = genTextbox({
          top: 0,
          left: box.left,
          fontSize: config.titleFontSize || box.titleFontSize,
          fontWeight: config.fontWeight || box.fontWeight,
          textAlign: config.textAlign || box.textAlign,
          fill: box.fill,
          width: box.width,
          content: box.title
        });
        canvas.add(text);
      }
    });
    if (!!config.callback) {
      config.callback(canvas);
    }
    return canvas;
  }

  function makeTextboxCanvas(domId, config) {
    var x, y, text, rect, vgap, top, canvas = new fabric.Canvas(domId);
    canvas.lockUnitScaling = true;
    canvas.setHeight(config.height);
    canvas.setWidth(config.width);
    top = config.paddingTop || 0;
    vgap = top || 0;
    rect = new fabric.Rect({
      top: top,
      left: config.left || 0,
      lockMovementX: true,
      lockMovementY: true,
      editable: false,
      width: config.width - 10,
      height: config.height - 10 - vgap,
      strokeLineJoin: 'round',
      strokeWidth: 10,
      stroke: !!config.borderColor || config.backgroundColor,
      lockScalingX: true,
      lockScalingY: true,
      selectable: false,
      fillAlphas: 1,
      fill: config.backgroundColor
    });
    switch (config.verticalAlign) {
      case 'middle':
        y = (config.height + vgap - config.fontSize) / 2;
        break;
      case 'bottom':
        y = config.height - config.fontSize - 10;
        break;
      default:
        y = config.y || 10;
    }

    text = genTextbox({
      content: config.textContent + '',
      fontSize: config.fontSize,
      fontWeight: config.fontWeight,
      width: config.width - 10,
      height: config.height - 10,
      textAlign: config.textAlign,
      fill: config.fontColor,
      top: y,
      left: 0
    });
    canvas.add(rect);
    canvas.add(text);
    if (!!config.callback) {
      config.callback(canvas);
    }
    return canvas;
  }

  function makeTextBoxSVG(domId, config) {
    var rect, text, svg, parent, g;
    g = getNode('g');
    svg = getNode('svg', {
      width: config.width,
      height: config.height
    });
    svg.appendChild(g);
    rect = getNode('rect', {
      'x': 0,
      'y': 0,
      'width': config.width,
      'height': config.height,
      'rx': 5,
      'ry': 5,
      'fill': config.backgroundColor
    });
    g.appendChild(rect);
    text = getNode('text', {
      'x': config.textX,
      'y': config.textY,
      'textAnchor': config.textAlignment,
      'fill': config.fontColor,
      'fontSize': config.fontSize,
      'fontWeight': config.fontWeight
    });
    text.textContent = config.textContent;
    g.appendChild(text);
    parent = document.getElementById(domId);
    parent.appendChild(svg);
  }

  function OneHub() {
    this.charts = new Charts();
    this.amCharts = {};
    this.fontSize = {
      xsmall: 12,
      small: 14,
      normal: 16,
      medium: 18,
      large: 24,
      xlarge: 40,
      xxlarge: 64
    };
    this.colors = {
      green: '#4bca81',
      orange: '#ffb75d',
      blue: '#0070d2',
      blue900: '#1A237E',
      blue800: '#283593',
      blue700: '#303F9F',
      blue600: '#3949AB',
      blue500: '#3F51B5',
      blue400: '#5C6BC0',
      blue300: '#7986CB',
      blue200: '#9FA8DA',
      blue100: '#C5CAE9',
      lightBlue400: '#29B6F6',
      lightBlue500: '#03A9F4',
      lightBlue600: '#039BE5',
      lightBlue700: '#0288D1',
      lightBlue800: '#0277BD',
      lightBlue900: '#01579B',
      grey200: '#F5F5F5',
      grey300: '#E0E0E0',
      grey400: '#BDBDBD',
      grey500: '#9E9E9E',
      grey600: '#757575',
      grey700: '#616161',
      grey800: '#424242',
      grey900: '#212121',
      label: "#54698d",
      activeLabel: '#16325c',
      white: '#ffffff',
      black: '#333333',
      secondaryBlack: '#888888',
      hintText: '#AAAAAA',
      red900: '#B71C1C',
      red800: '#C62828',
      red700: '#D32F2F',
      red600: '#E53935',
      red500: '#F44336',
      red400: '#EF5350',
      red300: '#E57373',
      red200: '#EF9A9A',
      red100: '#FFCDD2',
      azure: '#1589ee',
      scienceBlue: '#0070d2'
    };
  }
  OneHub.prototype.toPDF = function() {
    OHPDF.create();
  };

  OneHub.prototype.svgToCanvas = function(svgContainerDomId) {
    var svgString = document.getElementById(svgContainerDomId).innerHTML
    var e = document.createElement('canvas');
    var canvas = new fabric.Canvas(e);
    canvas.lockUnitScaling = true;
    canvas.setHeight(100);
    canvas.setWidth(532);
    fabric.loadSVGFromString(svgString, function(objects, options) {
      console.log(objects);
      objects.forEach(function(o) {
        switch (o.type) {
          case 'line':
            o.left = o.x1 * 532 / 100;
            o.x1 = o.x1 * 532 / 100;
            o.x2 = o.x2 * 532 / 100;
            o.width = o.x2 - o.x1;
            o.strokeWidth = 0.5;
            break;
          case 'text':
            o.fontSize = 10;
            break;
          case 'circle':
            o.radius = 5;

            break;
        }
      });
      var obj = fabric.util.groupSVGElements(objects, options);
      canvas.add(obj).renderAll();
      OH.charts.instances[svgContainerDomId] = {
        'canvas': canvas,
        'dataUrl': undefined
      };
    });
  };

  OneHub.prototype.initImages = function() {
    var img = document.getElementById('ohExecutionImg');
    img.src = OHIMAGES['icon_check_green'];
    img = document.getElementById('ohLocationsImg');
    img.src = OHIMAGES['icon_map_orange'];
    img = document.getElementById('ohAccountsImg');
    img.src = OHIMAGES['icon_account_blue'];
    img = document.getElementById('ohProjectCycleImg');
    img.src = OHIMAGES['icon_refresh_blue'];
    img = document.getElementById('ohProgramNameImg');
    img.src = OHIMAGES['icon_target_blue'];
    img = document.getElementById('ohProjectOwnerImg');
    img.src = OHIMAGES['icon_person_blue'];
    img = document.getElementById('ohProjectBuilderImg');
    img.src = OHIMAGES['icon_person_blue'];
    img = document.getElementById('locationsExecutedByDayImage');
    img.src = OHIMAGES['icon_calendar_green'];
    img = document.querySelector('#ohProjectDetailImg');
    img.src = OHIMAGES['icon_project_detail'];
    img = document.querySelector('#ohBillableTimeImg');
    img.src = OHIMAGES['icon_dollar'];
  };

  OneHub.prototype.onReady = (function() {
    var callbacks = [],
      ready = 0;

    function eventHandler(e) {
      if (!!ready) {
        return;
      }
      if ('readystatechange' === e.type && document.readyState !== 'complete') {
        return;
      }
      for (var i = 0; i < callbacks.length; i++) {
        callbacks[i].call(document);
      }
      ready = 1;
      callbacks = null;
    }

    if (document.addEventListener) {
      document.addEventListener("DOMContentLoaded", eventHandler, false);
      document.addEventListener("readystatechange", eventHandler, false);
      window.addEventListener("load", eventHandler, false);
    } else if (document.attachEvent) {
      document.attachEvent("onreadystatechange", eventHandler);
      window.attachEvent("onload", eventHandler);
    }
    return function(func) {
      if (ready) {
        func.call(document);
      } else {
        callbacks.push(func);
      }
    }
  }());

  OneHub.prototype.onLoad = function(callback) {
    if (document.addEventListener) {
      window.addEventListener("load", callback, false);
    } else if (document.attachEvent) {
      window.attachEvent("onload", callback);
    }
  };

  window['OH'] = window['OH'] || new OneHub();

})(window);
