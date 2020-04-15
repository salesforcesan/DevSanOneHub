(function(window) {
  'use strict';
  var _textbox_title_font_size = 16,
    _textbox_content_font_size = 40;

  function hideContainer(domId) {
    var e = document.getElementById(domId);
    e.classList.add('cmk-hide');
  }

  function formatNumber(num) {
    var arr = [],
      v = (num + '').trim(),
      len = v.length;
    while (len > 3) {
      arr.push(v.substr(len - 3));
      v = v.slice(0, len - 3);
      len = v.length;
    }
    if (len > 0) {
      arr.push(v);
    }
    return arr.reverse().join(',');
  }

  function formatDecimal(val) {
    var v = val + '',
      u, pos = v.indexOf('.');
    if (-1 === pos) {
      return formatNumber(v);
    }
    u = v.substr(pos);
    v = v.substr(0, pos);
    return formatNumber(v) + u;
  }

  function formatNumberString(val) {
    var v, prefix;
    val = (val || '').toString();

    prefix = val.indexOf('$') !== -1 ? '$' : '';
    v = val.replace(prefix, '');
    return prefix + ((v.indexOf('.') !== -1) ? formatDecimal(v) : formatNumber(v));
  }

  function drawServiceExecutionByDayChart(service) {
    var prop, data = [],
      dayCount = 0,
      totalJobCount = service.notCancelledJobCount || 0,
      executedJob = service.servicesExecutedByDay || {},
      e, data = getDefaultExecutedLocationByDay();
    for (prop in executedJob) {
      e = findElement(data, function(d) {
        return d.date == prop;
      });
      if (!!e) {
        e.duration = executedJob[prop] || 0;
      }
    }
    if (totalJobCount > 0) {
      data.forEach(function(d) {
        totalJobCount = totalJobCount - dayCount;
        d.jobs = totalJobCount;
        dayCount = d.duration;
      });
    }

    OH.charts.makeLineAreaChart('chartServicesExecutedByDay_' + service.id, {
      color: OH.colors.blue900,
      data: data,
      valueTitle: 'Executed Jobs',
      fill: OH.colors.lightBlue500,
      lineColor: OH.colors.blue,
      line2Color: OH.colors.red500,
      value2Title: "Jobs to Executed"
    });
  }

  function drawServiceCompletionChart(service) {
    var total = 0,
      percent,
      jobCompletion = service.serviceJobCompletion || [],
      data = [];
    jobCompletion.forEach(function(e) {
      data.push({
        "title": e.key,
        "value": e.value,
        "color": OH.colors[e.color || 'green']
      });
    });
    if (data.length === 0) {
      data = [{
        "title": 'Completed',
        "value": 0,
        "color": OH.colors.green
      }, {
        "title": 'No authorized items',
        "value": 0,
        "color": OH.colors.blue900
      }, {
        "title": 'Display sold through',
        "value": 0,
        "color": OH.colors.blue700
      }, {
        "title": 'Manager refused',
        "value": 0,
        "color": OH.colors.blue500
      }, {
        "title": 'Display removed',
        "value": 0,
        "color": OH.colors.blue400
      }, {
        "title": 'Display Damaged',
        "value": 0,
        "color": OH.colors.blue300
      }, {
        "title": 'Did not complete',
        "value": OHPROJECT.jobCount,
        "color": OH.colors.blue100
      }];
    }

    data.forEach(function(d) {
      d.value = d.value || 0;
      total += d.value;
    });

    data.forEach(function(d) {
      d.title = d.title || '';
      d['percent'] = total > 0 ? Math.round(d.value * 100 / total) : 0;
      d.label = [d.title.length > 20 ? d.title.substring(0, 20) + '...' : d.title, ' - ', d['percent'], '% (', d.value, ')'].join('');
    });
    var legend = {
      width: 250,
      height: 300,
      top: 40,
      title: 'Completion',
      titleFontSize: 24,
      labelFontSize: 12,
      squareSize: 15,
      color: OH.colors.label,
      data: data
    };

    OH.charts.makePieChart('chartJobCompletion_' + service.id, {
      innerRadius: '60%',
      radius: 100,
      legend: {
        color: OH.colors.label
      },
      title: {
        fontSize: 40,
        content: data[0].percent + '%',
        top: 120,
        color: OH.colors.green
      },
      subTitle: {
        content: 'Completed',
        fontSize: 12,
        top: 170,
        color: OH.colors.green
      },
      data: data
    });

    //draw legend
    OH.charts.makeChartLegend('ohJobCompletionLegend_' + service.id, legend);
  }

  function drawServiceJobExecutionChart(service) {
    var percent, total = service.notCancelledJobCount || 1,
      jobCount = service.executedJobCount || 0;
    percent = Math.round(100 * jobCount / total) + '%';
    drawSummaryTextbox('ohJobExecution_' + service.id, {
      title: percent,
      subTitle: [formatNumber(total) + ' job(s)'],
      backgroundColor: OH.colors.green
    });
  }

  function drawSummaryTextbox(domId, opt) {
    OH.charts.makeTextbox(domId, {
      backgroundColor: opt.backgroundColor,
      width: 300,
      height: 200,
      textAlign: 'center',
      y: 50,
      fontColor: OH.colors.white,
      fontSize: OH.fontSize.xxlarge,
      fontWeight: 700,
      textContent: opt.title,
      callback: function(canvas) {
        var top = 120;
        opt.subTitle.forEach(function(title) {
          OH.charts.drawTextbox(canvas, {
            fill: OH.colors.white,
            fontColor: OH.colors.white,
            content: title,
            top: top,
            left: 0,
            fontSize: OH.fontSize.normal,
            fontWeight: 700,
            verticalAlign: 'middle',
            width: 300,
            height: 50,
            textAlign: 'center'
          });
          top += 20;
        });
      }
    });
  }

  function drawExecution() {
    drawSummaryTextbox('ohExecution', {
      title: OHPROJECT.executionPercent || '0%',
      subTitle: [formatNumber(OHPROJECT.executedLocations) + ' location(s)', (OHPROJECT.services || []).length + ' service(s)'],
      backgroundColor: OH.colors.green
    });
  }

  function drawLocations() {
    drawSummaryTextbox('ohLocations', {
      title: OHPROJECT.locations,
      subTitle: [],
      backgroundColor: OH.colors.orange
    });
  }

  function drawAccounts() {
    OH.charts.makeTextbox('ohAccounts', {
      backgroundColor: 'rgb(0, 112, 210)',
      textAlign: 'center',
      verticalAlign: 'middle',
      width: 300,
      height: 200,
      fontColor: '#ffffff',
      fontSize: OH.fontSize.normal,
      fontWeight: 700,
      textContent: OHPROJECT.account
    });
  }



  function genTimelineData() {
    var step, src,
      i, data = [],
      p = OHPROJECT;

    function prepareDataItem(label, dt, color) {
      var arr, res = {
        label: label,
        color: color || OH.colors.green
      };

      if (!dt && dt.split('-').length !== 3) {
        res.data = '';
        return res;
      }
      arr = dt.split('-');
      res.data = [arr[1], arr[2], arr[0]].join('/');
      return res;
    }

    // convert date to number
    src = [];
    if (!!p.launchDate) {
      src.push(prepareDataItem('Launch Date', p.launchDate));
    }
    if (!!p.startDate) {
      src.push(prepareDataItem('Start Date', p.startDate));
    }
    if (!!p.endDate) {
      src.push(prepareDataItem('End Date', p.endDate));
    }
    if (!!p.revisedEndDate && p.revisedEndDate != p.endDate) {
      src.push(prepareDataItem('Revised End Date', p.revisedEndDate, OH.colors.orange));
    }

    if (!!p.closeDate) {
      src.push(prepareDataItem('Close Date', p.closeDate));
    }

    // transform the date number to 0-100 data domain
    step = Math.floor(100 / (src.length - 1));
    i = 0;
    src.forEach(function(e) {
      e.value = i * step;
      i++;
    });
    src[i - 1].value = 100;
    return src;
  }

  function drawProjectTimeline() {
    OH.charts.makeTimeline('projectTimeline', {
      width: document.getElementById('projectTimeline').clientWidth,
      height: 150,
      backgroundColor: OH.colors.green,
      data: genTimelineData()
    });
  }

  function getDefaultExecutedLocationByDay() {
    var p = OHPROJECT,
      data = [],
      currentDate,
      start = moment(p.startDate || p.launchDate),
      end = moment(p.closeDate || p.endDate);
    currentDate = start;

    while (currentDate <= end) {
      data.push({
        "date": currentDate.format('YYYY-MM-DD'),
        'duration': 0
      });
      currentDate.add(1, 'd');
    }
    return data;
  }

  function findElement(data, predicate) {
    var e = data.filter(function(d) {
      return predicate(d);
    });
    return (e.length > 0) ? e[0] : undefined;
  }



  function drawExecutedLocationsByDayChart() {
    var prop, executedLocation = OHPROJECT.executedLocationsByDay || {},
      total = OHPROJECT.jobCount,
      dayCount = 0,
      e, data = getDefaultExecutedLocationByDay();
    for (prop in executedLocation) {
      e = findElement(data, function(d) {
        return d.date == prop;
      });
      if (!!e) {
        e.duration = executedLocation[prop] || 0;
      }
    }
    if (total > 0) {
      data.forEach(function(d) {
        total -= dayCount;
        dayCount = d.duration;
        d.jobs = total;
      });
    }

    OH.charts.makeLineAreaChart('chartExecutedLocationsByDay', {
      color: OH.colors.blue900,
      data: data,
      valueTitle: 'Executed Jobs',
      fill: OH.colors.lightBlue500,
      lineColor: OH.colors.blue,
      line2Color: OH.colors.red500,
      value2Title: "Jobs to Executed"
    });
  }

  function initExportPDF() {
    var btn = document.getElementById('btnExport');
    btn.addEventListener('click', OH.toPDF, false);
  }

  function initImages() {
    OH.initImages();
  }

  function QuestionRenderer() {
    var _serviceId, _question;
    var _self = {};

    function id() {
      return [_question.id, _serviceId].join('_');
    }

    function makeSingleTextbox(title) {
      OH.charts.makeTextbox(id(), {
        paddingTop: 30,
        backgroundColor: OH.colors.green,
        width: 300,
        height: 200,
        textAlign: 'center',
        verticalAlign: 'middle',
        fontColor: OH.colors.white,
        fontSize: _textbox_content_font_size,
        fontWeight: 400,
        textContent: formatNumberString(_question.data + ''),
        callback: function(canvas) {
          OH.charts.drawTextbox(canvas, {
            fontSize: _textbox_title_font_size,
            fontWeight: 700,
            fill: OH.colors.green,
            textAlign: 'center',
            top: 0,
            left: 50,
            width: 200,
            content: title
          });
        }
      });
    }

    function makeDoubleTextboxes() {

      OH.charts.makeManyTextboxes(id(), {
        width: 660,
        height: 220,
        fontSize: _textbox_content_font_size,
        titleFontSize: _textbox_title_font_size,
        titleFontColor: OH.colors.blue,
        fontWeight: 400,
        fontColor: OH.colors.white,
        boxes: [{
          content: _question.data[0].value + '',
          title: _question.data[0].key + '',
          top: 30,
          left: 0,
          width: 300,
          height: 200,
          backgroundColor: OH.colors.blue,
          strokeWidth: 10,
          textAlign: 'center',
          verticalAlign: 'middle',
          fill: OH.colors.blue
        }, {
          content: formatNumberString(_question.data[1].value + ''),
          title: _question.data[1].key + '',
          titleFontColor: OH.colors.green,
          top: 30,
          left: 320,
          width: 300,
          height: 200,
          backgroundColor: OH.colors.green,
          strokeWidth: 10,
          textAlign: 'center',
          verticalAlign: 'middle',
          fill: OH.colors.green
        }]
      });
    }

    _self.draw_warn = function() {
      OH.charts.makeTextbox(id(), {
        backgroundColor: OH.colors.grey300,
        width: 400,
        height: 100,
        textAlign: 'center',
        verticalAlign: 'middle',
        fontColor: OH.colors.grey800,
        fontSize: 14,
        fontWeight: 400,
        textContent: _question.data + ''
      });
    }

    _self.draw_date = function() {
      OH.charts.makeTextbox(id(), {
        backgroundColor: OH.colors.grey300,
        width: 400,
        height: 100,
        textAlign: 'center',
        verticalAlign: 'middle',
        fontColor: OH.colors.grey800,
        fontSize: 14,
        fontWeight: 400,
        textContent: _question.data + ''
      });
    };

    _self.draw_text = function() {
      makeSingleTextbox('Total Responses');
    };

    _self.draw_picklist = function() {
      var data = [],
        i = 0,
        e,
        domId = id(),
        colors = [OH.colors.green, OH.colors.blue, OH.colors.orange, OH.colors.grey300, OH.colors.blue300];
      _question.data.forEach(function(d) {
        data.push({
          category: d.key,
          value: d.value,
          color: colors[i % 5]
        });
        i++;
      });
      //oh1533
      e = document.querySelector('#' + domId);
      e.style.height = (data.length * 60) + 'px';
      //oh1533
      OH.charts.makeBarChart(domId, {
        rotate: true,
        gridThickness: 0,
        marginLeft: e.clientWidth * 0.5,
        barWidth: 35,
        color: OH.colors.label,
        labelPosition: 'right',
        labelColor: OH.colors.label,
        valueAxis: {
          hidden: true,
          color: OH.colors.green,
          labelColor: OH.colors.activeLabel
        },
        categoryAxis: {
          color: OH.colors.white,
          textWrap: true
        },
        data: data
      });
    };

    _self.draw_yesno = function() {
      var total = 0,
        val,
        data = [{
          "title": _question.data[0].key,
          "value": _question.data[0].value,
          "color": OH.colors.green
        }, {
          "title": _question.data[1].key,
          "value": _question.data[1].value,
          "color": OH.colors.red500
        }];

      total = data[0].value + data[1].value;
      data.forEach(function(d) {
        val = (total === 0 || d.value === 0) ? 0 : Math.round(d.value * 100 / total);
        d.label = [d.title, ' (', val, '% - ', d.value, ')'].join('');
      });
      OH.charts.makePieChart(id(), {
        innerRadius: '60%',
        radius: 70,
        data: data,
        legend: {
          color: OH.colors.label,
          left: 0,
          enabled: true,
          position: 'right',
          valueAlign: 'left'
        }
      });
    };

    _self.draw_number = function() {
      makeDoubleTextboxes();
    };

    _self.draw_photo = function() {
      makeSingleTextbox('Total Photos');
    };

    _self.draw_signature = function() {
      makeSingleTextbox('Total Signatures');
    };

    _self.draw_currency = function() {
      makeDoubleTextboxes();
    };

    _self.draw_time = function() {
      makeDoubleTextboxes();
    };

    _self.render = function(serviceId, question) {
      var method = 'draw_' + question.type;
      _serviceId = serviceId;
      _question = question;

      if (!!_self[method]) {
        _self[method]();
      } else {
        console.log('The question type is not supported:' + question.type);
      }
    };

    return {
      draw: function(serviceId, question) {
        _self.render(serviceId, question);
      }
    };
  }

  function drawServices() {
    var img, service, questionRender = new QuestionRenderer();
    (OHPROJECT.services || []).forEach(function(service) {
      //handle service summary
      img = document.getElementById('servicesExecutedByDayImage_' + service.id);
      img.src = OHIMAGES['icon_calendar_green'];
      img = document.getElementById('cancelledLocationsCountImage_' + service.id);
      img.src = OHIMAGES['icon_cancel_location_blue'];
      img = document.getElementById('workerCountImage_' + service.id);
      img.src = OHIMAGES['icon_team_member_blue'];
      img = document.getElementById('estimatedMinutesImage_' + service.id);
      img.src = OHIMAGES['icon_clock_blue'];
      img = document.querySelector('#ohJobExecutionImg_' + service.id);
      img.src = OHIMAGES['icon_check_green'];

      drawServiceCompletionChart(service);
      drawServiceJobExecutionChart(service);
      drawServiceExecutionByDayChart(service);
      //handle service questions
      service.questions.forEach(function(question) {
        questionRender.draw(service.id, question);
      });
    });
  }

  function loadQuestionsLayout() {
    var template = document.getElementById('cmkQuestionTemplate').innerHTML,
      html = [],
      seq = 0,
      data,
      content = [];

    function genPicklistUI(svcId, seq, question) {
      html.push(['<div class="oh-question-card" itemtype="picklist"><h4>', 'Q', seq, ' - ', question.value, '</h4><div id="', question.id, '_', svcId, '" style="max-width: 100%; height: 260px;"></div></div>'].join(''));

    }

    function genYesNoUI(svcId, seq, question) {
      data = question.data || [];
      if (data.length === 0) {
        question.data = [{
          'key': 'YES',
          'value': 0
        }, {
          'key': 'NO',
          'value': 0
        }];
      }
      html.push(['<div class="oh-question-card" itemtype="yesno"><h4>', 'Q', seq, ' - ', question.value, '</h4><div id="', question.id, '_', svcId, '" style="max-width: 600px; height: 300px;"></div></div>'].join(''));

    }

    function genCanvasBoxUI(svcId, seq, question) {
      html.push(['<div class="oh-question-card" itemtype="', question.type, '"><h4>', 'Q', seq, ' - ', question.value, '</h4><canvas id="', question.id, '_', svcId, '" width="300" height="260"></canvas></div>'].join(''));
    }

    function genCanvasDoubleBoxUI(svcId, seq, question) {
      data = question.data || [];
      if (data.length === 0) {
        question.data = [{
          key: 'Average',
          value: question.type === 'currency' ? '$0.00' : '0'
        }, {
          key: 'Total',
          value: question.type === 'currency' ? '$0.00' : '0'
        }];
      }
      html.push(['<div class="oh-question-card" itemtype="', question.type, '"><h4>', 'Q', seq, ' - ', question.value, '</h4><canvas id="', question.id, '_', svcId, '" width="300" height="260"></canvas></div>'].join(''));
    }

    (OHPROJECT.services || []).forEach(function(service) {
      seq = 0;
      content = [];
      service.questions.forEach(function(q) {
        seq++;
        switch (q.type) {
          case 'text':
          case 'photo':
          case 'signature':
            genCanvasBoxUI(service.id, seq, q);
            break;
          case 'number':
          case 'currency':
          case 'date':
          case 'time':
            genCanvasDoubleBoxUI(service.id, seq, q);
            break;
          case 'yesno':
            genYesNoUI(service.id, seq, q);
            break;
          case 'picklist':
            genPicklistUI(service.id, seq, q);
            break;
          case 'warn':
            genCanvasBoxUI(service.id, seq, q);
            break;
        }
        if (html.length == 2) {
          content.push(template.replace('[[placeholder]]', html[0]));
          content.push(template.replace('[[placeholder]]', html[1]));
          html = [];
        }
      });

      if (html.length > 0) {
        content.push(template.replace('[[placeholder]]', html[0]));
      }
      html = [];
      document.getElementById('questionGroup_' + service.id).innerHTML = content.join('');
    });
    html = null;
  }

  OH.onReady(function() {
    loadQuestionsLayout();
    initImages();
  });
  OH.onLoad(function() {
    drawProjectTimeline();
    drawExecution();
    drawLocations();
    drawAccounts();
    drawExecutedLocationsByDayChart();
    drawServices();
    initExportPDF();
  });
})(window);
