(function(A) {
  'use strict';
  var CALENDAR_HEIGHT = 560;
  var EVENT_FITLER_CHANGED = 'filter_changed';

  function getColor(colors, id) {
    var f = colors.filter(function(e) {
      return e.Id === id;
    });
    return (f.length > 0) ? f[0] : {
      Color: "#FFFFFF",
      Name: "undefined"
    };
  }

  function convertDate(msNumber) {
    if (isFinite(msNumber)) {
      var date = new Date(msNumber);
      return new Date(date.setDate(date.getDate() + 1))
    } else {
      return "-";
    }
  }

  function formatName(name) {
    return name.indexOf("&") !== -1 ? A.element("<span></span>").html(name).text() : name;
  }

  function colorifyScaledValue(value) {
  	if (value < 40 ) {
  		return '#F44336';
  	} else if (value < 80) {
  		return '#FF9800';
  	} else {
  		return '#4CAF50';
  	}
  }

  function mungeData(data, themes, tiers) {
    var tier, count, theme, themeDays = data["ThemeDay"],
      opportunities = data["ThemedOpportunity"];

    return _.map(themeDays, function(day) {
      var rec = {},
        theme = getColor(themes, day.Theme),
        tier = getColor(tiers, day.Tier),
        opps = _.filter(opportunities, function(o) {
          return o.ThemeDayId === day.Id;
        });
      rec.id = day.Id;
      rec.themeName = formatName(theme.Name);
      rec.themeColor = theme.Color || '#fff';
      rec.tierName = formatName(tier.Name);
      rec.tierColor = tier.Color;
      rec.themeDate = convertDate(day.Date);
      rec.themeMillisecond = day.Date;
      rec.capacity = day.Capacity || '-';
      count = 0;
      _.forEach(opps, function(o) {
        count += (o.Count || 0);
      });
      rec.count = count;
      if (rec.capacity > 0 || rec.capacity !== '-') {
        rec.scaledValue = Math.floor(100 * rec.count / rec.capacity);
        rec.percentage = rec.scaledValue + '%';
      } else {
        rec.percentage = '0%';
        rec.scaledValue = 0;
      }
      rec.percentageColor = colorifyScaledValue(rec.scaledValue);
      return rec;
    });
  }

  function routeToProjectDetail(window, event) {
    var w = window.innerWidth - 100,
      h = window.innerHeight - 50,
      title = "Dialog";
    var dualScreenLeft = window.screenLeft != undefined ? window.screenLeft : screen.left;
    var dualScreenTop = window.screenTop != undefined ? window.screenTop : screen.top;

    var width = window.innerWidth ? window.innerWidth : document.documentElement.clientWidth ? document.documentElement.clientWidth : screen.width;
    var height = window.innerHeight ? window.innerHeight : document.documentElement.clientHeight ? document.documentElement.clientHeight : screen.height;
    var url = "";
    var left = ((width / 2) - (w / 2)) + dualScreenLeft;
    var top = ((height / 2) - (h / 2)) + dualScreenTop;

    if (!!event.cmkId) {
      title = "Application Dialog - Theme";
      url = "/" + event.cmkId;
      url = url.indexOf('?') === -1 ? url + '?isdtp=vw' : url + '&isdtp=vw';
      var newWindow = window.open(url, title, 'scrollbars=yes,location=no,toolbar=no,menubar=no, width=' + w + ', height=' + h + ', top=' + top + ', left=' + left);

      // Puts focus on the newWindow
      if (window.focus) {
        newWindow.focus();
      }

    } else {
      window.alert("The project identifier is not defined. The selected record has an integrity issue. Please contact the CROSSMARK Helpdesk support if the error continues to come up.");
    }
  }

  function getOpportunityGridOption($scope) {
    var fields = [
      "id",
      "themeName",
      "themeDate",
      "percentage",
      "count",
      "capacity",
      "themeColor",
      "tierName",
      "tierColor"
    ];
    var options = {
      data: [],
      setData: function(data) {
        options.data = data;
      },
      columnDefs: [{
        displayName: "Theme",
        field: "themeName",
        cellTemplate: '<div class="cm-cell slds-truncate"><span ng-bind-html="COL_FIELD"></span></div>'
      }, {
        displayName: "Theme Color",
        field: "themeColor",
        cellTemplate: '<div class="cm-cell" ><span style="display:block;background-color:{{COL_FIELD}}; border-radius:50%; padding: 0 10px; width:1rem;">&emsp;</span></div>'
      }, {
        displayName: "Theme Date",
        field: "themeDate",
        cellTemplate: '<div class="cm-cell slds-truncate"><span>{{COL_FIELD !== null && COL_FIELD !== "-" ? COL_FIELD.format("/") : COL_FIELD}}</span></div>'
      }, {
        displayName: "Count/Capacity",
        field: "percentage",
        cellTemplate: '<div class="cm-cell"><span style="display: block;width: {{COL_FIELD}}; background-color: {{row.entity.percentageColor}};" ng-bind-html="COL_FIELD"></span></div>'
      }, {
        displayName: "Event Count",
        field: "count",
        cellTemplate: '<div class="cm-cell slds-truncate"><span ng-bind-html="COL_FIELD"></span></div>'
      }, {
        displayName: "Capacity",
        field: "capacity",
        cellTemplate: '<div class="cm-cell slds-truncate"><span ng-bind-html="COL_FIELD"></span></div>'
      }, {
        displayName: "Tier",
        field: "tierName",
        cellTemplate: '<div class="cm-cell"><span ng-bind-html="COL_FIELD"></span></div>'
      }, {
        displayName: "Tier Color",
        field: "tierColor",
        cellTemplate: '<div class="cm-cell"><span style="display:block;background-color:{{COL_FIELD}}; border-radius: 50%; padding: 0 10px; width:1rem;">&emsp;</span></div>'
      }],
      enableColumnMenu: false,
      onRegisterApi: function(gridApi) {
        $scope.gridApi = gridApi;
      },
      exporterFieldCallback: function(grid, row, col, input) {
        var v;
        if (col.name.indexOf("Date") !== -1) {
          return (input === "-") ? "" : input.format("/");
        } else {
          v = input + "";
          if (v === "-") {
            return "";
          } else {
            return v.indexOf("&") !== -1 ? A.element("<span></span>").html(v).text() : v;
          }
        }
      }
    };

    return options;
  }

  function buildCalendarEvents(themeDays) {
    var events = [],
      allDay = true,
      ms1, type, dt1, dt2, tm1, tm2, content;

    themeDays.forEach(function(rec) {
      dt1 = rec.themeMillisecond;
      tm1 = {
        hr: 0,
        min: 0
      };
      tm2 = {
        hr: 23,
        min: 59
      };

      if (!!dt1 && isFinite(dt1)) {
        dt1 = new Date(dt1);
        dt1 = new Date(dt1.getUTCFullYear(), dt1.getUTCMonth(), dt1.getUTCDate(), tm1.hr, tm1.min, 0, 0);
        dt2 = new Date(dt1.getUTCFullYear(), dt1.getUTCMonth(), dt1.getUTCDate(), tm2.hr, tm2.min, 59, 999);
        content = rec.Name;
        events.push({
          viewType: "theme",
          title: '',
          start: dt1.toLocaleString(),
          end: dt2.toLocaleString(),
          data: rec
        });
      }
    });
    return events;
  }

  function createEventHTML(event, element, view) {
    var percentage = event.data.percentage;
    var html = [
      ['<div style="min-height: 75px;min-width: 100px; margin:5px;"><div style="vertical-align:middle; line-height:1.1rem;padding: 5px; color: #444;background-color:', event.data.tierColor, '"><h2>', event.data.themeName, ' - <small>', event.data.tierName, '</small></h2>'].join('')
    ];
    if (event.data.count === 0) {
      html.push('</div></div>');
    } else {
      html.push(['<p><span>', event.data.count, '/', event.data.capacity, '</span><span style="float:right; font-size: 0.6rem;padding: 1px 4px; margin-top:-4px; border-radius:10px; display:inline-block;color:#000; border:1px solid #000; inline-block; background-color:', event.data.tierColor, '">', percentage, '</span></p>'].join(''));
      html.push('</div><div style="width: 100%; opacity:0.8; height: 20px;background-color:' + event.data.tierColor + '"><a href="#" style="font-size:0.75rem; padding: 5px;color:#000;">View More</a></div></div>');
    }
    return A.element(html.join(''));
  }

  function initCalendar(controller) {
    var calendarId = "div#themeCalendar";
    A.element(calendarId).fullCalendar('destroy');
    A.element(calendarId).fullCalendar({
      header: {
        left: 'prev,next',
        center: 'title',
        right: 'month,agendaWeek,agendaDay'
      },
      firstDay: 1,
      allDayDefault: true,
      eventLimit: 5,
      businessHours: true,
      editable: false,
      height: CALENDAR_HEIGHT,
      handleWindowResize: true,
      eventClick: function(calEvent, jsEvent, view) {
        jsEvent.preventDefault();
        if (jsEvent.toElement.innerHTML.indexOf('View More') !== -1) {
          controller.viewThemeDayDetail(calEvent, jsEvent);
        }
      },
      eventMouseover: function(calEvent, jsEvent, view) {
        A.element(this).find('>div').css("color", "#000");
      },
      eventMouseout: function(calEvent, jsEvent, view) {
        A.element(this).find('>div').css("color", "#444");
      },
      eventRender: function(event, element, view) {
        return createEventHTML(event, element, view);
      },
      dayRender: function(date, cell) {
        var bgColor = controller.getThemeDayBackgroundColor(date);
        if (!!bgColor) {
          cell.css('background-color', bgColor);
        }
      }
    });
  }

  function setMonthData(data) {
    var calendarTarget = A.element("div#themeCalendar");
    var events = buildCalendarEvents(data);
    calendarTarget.fullCalendar('removeEvents');
    calendarTarget.fullCalendar('addEventSource', events);
  }

  function buildHeatMapEvents(data) {
    var key, dt, result = [];
    _.forEach(data, function(d) {
      dt = moment(d.themeMillisecond).add(1, 'd');
      key = Math.floor(dt.valueOf() / 1000) + "";
      result[key] = d.scaledValue;
    });
    return result;
  }

  function resetHeadMapWidth() {
    setTimeout(function() {
      A.element('.cal-heatmap-container').width(200);
    }, 1000);
  }
  A.module('cmk.theme.calendar.controller', [
      "ngSanitize",
      "ui.router",
      "ui.grid.autoResize",
      "ui.grid",
      "ui.grid.selection",
      "ui.grid.exporter"
    ])
    .controller('ThemeTableController', [
      "$scope",
      "$window",
      "themes",
      "tiers",
      function($scope, $window, themes, tiers) {
        $scope.windowOnResize();
        $scope.$parent.showBusy();
        $scope.opportunityGridOptions = getOpportunityGridOption($scope);
        $scope.opportunityPageletModel = {
          title: "Theme List",
          canExpand: true,
          height: $scope.$parent.getHeight(),
          navBars: [{
            id: "app_export_csv",
            text: "Export to CSV File",
            iconUrl: $scope.$parent.path + "/assets/icons/utility-sprite/svg/symbols.svg#download"
          }],
          footerHTML: ""
        };

        $scope.export_row_type = "all";
        $scope.export_column_type = "all";
        $scope.export_format = "csv";

        $scope.$on(EVENT_FITLER_CHANGED, function(event, args) {
          $scope.appModel.findThemedOpportunities(args.query).then(function(data) {
            var themeDays = mungeData(data, themes, tiers);
            $scope.opportunityGridOptions.setData(themeDays);
            resetHeadMapWidth();
          }).finally(function() {
            $scope.$parent.hideBusy();
          })
        });

        $scope.onNavBarClick = function(href) {
          $scope.gridApi.exporter.csvExport($scope.export_row_type, $scope.export_column_type);
        };

        $scope.goDetail = function($event, row) {
          $event.preventDefault();
          if (!!row.entity["Id"]) {
            routeToProjectDetail($window, {
              viewType: "theme",
              cmkId: row.entity["Id"]
            });
          }
        };

        $scope.appModel.findThemedOpportunities($scope.$parent.getQuery()).then(function(data) {
          var themeDays = mungeData(data, themes, tiers);
          $scope.opportunityGridOptions.setData(themeDays);
          var c = A.element('.cm-col-container');
          c.width(c.width());
          resetHeadMapWidth();
        }, function(err) {
          console.log(err);
        }).finally(function() {
          $scope.$parent.hideBusy();
        })

        $scope.$parent.initPageHeader();
        $scope.$parent.setViewTypeDisplayType("theme", "table");
      }
    ]).controller('ThemeCalendarController', [
      '$scope',
      '$window',
      '$compile',
      'themes',
      'tiers',
      function($scope, $window, $compile, themes, tiers) {
        var self = this;
        self.getHeight = function() {
          return $scope.$parent.getHeight();
        };

        $scope.$parent.showBusy();
        $scope.themeCalendarPageletModel = {
          title: "Theme - Calendar",
          canExpand: true,
          height: self.getHeight(),
          navBars: [],
          footerHTML: ""
        };

        $scope.onResize = function(height) {
          var isFullScreen = A.element("body").hasClass("cm-body-full-screen");
          var h = isFullScreen ? height : CALENDAR_HEIGHT;
          A.element("div#pageBody").find(".cm-article-body").height(h);
          A.element("div#themeCalendar").fullCalendar('option', 'height', h);
        };


        $scope.$on(EVENT_FITLER_CHANGED, function(event, args) {
          $scope.appModel.findThemedOpportunities(args.query).then(function(result) {
            var events, themeDays = mungeData(result, themes, tiers);
            $scope.data = result;
            $scope.themeDays = themeDays;
            initCalendar(self);
            setMonthData(themeDays);
            setupHeatMap($scope,1);
          }).finally(function() {
            $scope.$parent.hideBusy();
          });
        });

        $scope.appModel.findThemedOpportunities($scope.$parent.getQuery($scope)).then(function(result) {
          var themeDays = mungeData(result, themes, tiers);
          $scope.data = result;
          $scope.themeDays = themeDays;
          initCalendar(self);
          setMonthData(themeDays);
          setupHeatMap($scope);
          setTimeout(function() {
            A.element('.cal-heatmap-container').width(200);
          }, 1000);
        }, function(err) {
          console.log(err);
        }).finally(function() {
          $scope.$parent.hideBusy();
        });

        function filterEvents(themeDay) {
          console.log($scope.data["ThemedOpportunity"]);
          var events = $scope.data["ThemedOpportunity"].filter(function(o) {
            return o.ThemeDayId === themeDay.id;
          });

          return events.map(function(o) {
            return {
              id: o.Id,
              name: o.Name,
              stage: o.Stage,
              count: o.Count,
              preferDate: !!o.PreferDate ? moment.utc(o.PreferDate).format('MM/DD/YYYY') : ''
            };
          });
        }

        function setUpViewMoreModel(event) {
          var data = event.data,
            model = {};
          console.log(event);
          model.themeName = data.themeName;
          model.themeColor = data.themeColor;
          model.themeDate = moment.utc(data.themeMillisecond).format('MM/DD/YYYY');
          model.tierName = data.tierName;
          model.tierColor = data.tierColor;
          model.count = data.capacity;
          model.percentage = Math.floor(100 * data.count / data.capacity) + '%';
          model.events = filterEvents(data);
          $scope.viewMoreModel = model;
        }

        self.viewThemeDayDetail = function(themeEvent, jsEvent) {
          var offset = A.element(jsEvent.currentTarget).offset();
          var diff = {
            x: $window.innerWidth - jsEvent.clientX - 400,
            y: $window.innerHeight - jsEvent.clientY - 400
          };
          if (diff.x < 0) {
            offset.left += diff.x - 20;
          }
          if (diff.y < 0) {
            offset.top += diff.y - 20;
          }
          setUpViewMoreModel(themeEvent);

          var html = A.element(A.element('script#tmplViewMoreDialog').html());
          $scope.$apply(function() {
            $compile(html)($scope);
            A.element('body')
              .css('overflow', 'hidden')
              .append(html)
          });
          setTimeout(function() {
            A.element('.cm-dlg-modal')
              .css('left', offset.left)
              .css('top', offset.top)
              .css('display', 'block')
              .animate({
                opacity: 1
              }, 500);
          }, 5);
        };
        $scope.closeViewMoreDialog = function($event) {
          $event.preventDefault();
          A.element('.cm-dlg-modal').animate({
            opacity: 0
          }, 250, function() {
            A.element('body').css('overflow', 'auto');
            A.element(this).remove();
            A.element('.cm-dlg-modal-overlay').remove();
          })
        }

        $scope.showEventDetail = function($event, $index) {
          $event.preventDefault();
          var event = $scope.viewMoreModel.events[$index];
          routeToProjectDetail($window, {
            viewType: 'theme',
            cmkId: event.id
          });
        };

        function setupHeatMap($scope, loaded) {
          var events = buildHeatMapEvents($scope.themeDays);
          var settings = {
            id: "div#themeHeatMap",
            range: 12,
            legend: [5, 25, 50, 75, 100],
            subDomainTitleFormat: {
            	empty: '{date}',
            	filled: '{count}% capacity on {date}'
            },
            legendColor: {
              max: "#4CAF50",
              min: "#B71C1C",
              empty: "#B71C1C",
              overflow: "steelblue"
            }
          };
          if (loaded === 1) {
              $scope.$parent.heatMap.setData(events);
          } else {
          $scope.$parent.heatMap.init('div#themeHeatMap', 'theme', settings).setData(events);
          }
        }

        function getDateRangeObject(date) {
          var start = date,
            end = date.clone();
          start.hour(0);
          start.minute(0);
          start.second(0);
          start.millisecond(0);

          var end = start.clone();
          end.add(1, 'd');
          return {
            start: start,
            end: end
          };
        }

        self.getThemeDayBackgroundColor = function(date) {
          var opps = $scope.themeDays || [];
          var selDay = getDateRangeObject(date);
          var sel = opps.filter(function(o) {
            return o.themeMillisecond >= selDay.start && o.themeMillisecond < selDay.end;
          });
          return sel.length > 0 ? sel[0].themeColor : '';
        };

        $scope.$parent.initPageHeader();
        $scope.$parent.setViewTypeDisplayType('theme', 'month');
      }
    ]);
})(angular);
