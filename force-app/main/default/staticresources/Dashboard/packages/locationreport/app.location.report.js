 (function(A) {
  "use strict";
  var _path, _appModel, _calendarHeatMapManager;

  function getHeight() {
    var h = A.element("body").height() - A.element("div#pageBody").offset().top;
    return (h > 400) ? h - 150 : 400;
  }

  function getQuery($scope) {
    var query = {};
    query.client = $scope.filterModel.client || "";
    query.retailer = $scope.filterModel.retailer || "";
    query.projectType = $scope.filterModel.projectType || "";
    query.location = $scope.filterModel.location || "";
    query.startDate = $scope.filterModel.startDate || "";
    query.endDate = $scope.filterModel.endDate || "";

    return query;
  }

  function handleFilter($scope, $log, reportModel) {
    var eventSet, key = $scope.objectTypeViewModel.getSelKey(),
      query = getQuery($scope);

    if (key === "project") {
      reportModel.findProjects(query).then(function(data) {
        $scope.projectGridOptions.data = data;
        if ($scope.displayActionModel.getSelKey() === "month") {
          setMonthData(key, data);
        }
      })
    } else if (key === "job") {
      reportModel.findJobs(query).then(function(data) {
        $scope.jobGridOptions.data = data;
        if ($scope.displayActionModel.getSelKey() === "month") {
          setMonthData(key, data);
        }
      });
    } else {
      $log.log("The app is in invalid state");
      $log.log($scope.objectTypeViewModel);
    }
  }

  function getProjectGridOption($scope) {
    return {
      data: [],
      columnDefs: [{
        displayName: "Location #",
        field: "ClubNumber__c",
        cellTemplate: '<div class="cm-cell"><span class="label label--success">{{COL_FIELD}}</span></div>'
      }, {
        displayName: "Retailer",
        field: "RetailerName__c",
        cellTemplate: '<div class="cm-cell truncate"><span ng-bind-html="COL_FIELD"></span></div>'
      }, {
        displayName: "Project Title",
        field: "ProjectName__c",
        cellTemplate: '<div class="cm-cell truncate"><span ng-bind-html="COL_FIELD"></span></div>'
      }, {
        displayName: "Client",
        field: "ClientName__c",
        cellTemplate: '<div class="cm-cell truncate"><span ng-bind-html="COL_FIELD"></span></div>'
      }, {
        displayName: "Project Type",
        field: "ProjectTypeName__c",
        cellTemplate: '<div class="cm-cell truncate"><span ng-bind-html="COL_FIELD"></span></div>'
      }, {
        displayName: "Execute Date",
        field: "StartDate__c",
        cellTemplate: '<div class="cm-cell truncate"><span>{{COL_FIELD.toISOString()}}</span></div>'
      }, {
        displayName: "Status",
        field: "ProjectStatus__c"
      }],
      enableColumnMenu: false,
      onRegisterApi: function(gridApi) {
        $scope.gridApi = gridApi;
      },
      exporterFieldCallback: function(grid, row, col, input) {
        if (col.name == 'ServiceName__c') {
          return (input === "-") ? "" : input;
        } else {
          return input;
        }
      }
    };
  }

  function getJobGridOption($scope) {
    return {
      data: [],
      columnDefs: [{
        displayName: "Location #",
        field: "LocationNumber__c",
        cellTemplate: '<div class="cm-cell"><span class="label label--success">{{COL_FIELD}}</span></div>'
      }, {
        displayName: "Retailer",
        field: "RetailerName__c",
        cellTemplate: '<div class="cm-cell truncate"><span ng-bind-html="COL_FIELD"></span></div>'
      }, {
        displayName: "Project Title",
        field: "ProjectName__c",
        cellTemplate: '<div class="cm-cell truncate"><span ng-bind-html="COL_FIELD"></span></div>'
      }, {
        displayName: "Client",
        field: "Client__c",
        cellTemplate: '<div class="cm-cell truncate"><span ng-bind-html="COL_FIELD"></span></div>'
      }, {
        displayName: "Project Type",
        field: "ProjectTypeName__c",
        cellTemplate: '<div class="cm-cell truncate"><span ng-bind-html="COL_FIELD"></span></div>'
      }, {
        displayName: "Service",
        field: "ServiceName__c",
        cellTemplate: '<div class="cm-cell truncate"><span ng-bind-html="COL_FIELD"></span></div>'
      }, {
        displayName: "Execute Date",
        field: "StartDate__c",
        cellTemplate: '<div class="cm-cell truncate"><span>{{COL_FIELD.toISOString()}}</span></div>'
      }, {
        displayName: "Status",
        field: "Status__c"
      }],
      enableColumnMenu: false,
      onRegisterApi: function(gridApi) {
        $scope.gridApi = gridApi;
      },
      exporterFieldCallback: function(grid, row, col, input) {
        if (col.name == 'ServiceName__c') {
          return (input === "-") ? "" : input;
        } else {
          return input;
        }
      }
    };
  }

  function setViewTypeDisplayType($scope, viewType, displayType) {
    $scope.objectTypeViewModel.setSelKey(viewType);
    $scope.displayActionModel.setSelKey(displayType);
  }

  function PillModel(forWho, key, value, hidden) {
    var self = this;
    self.dataId = key;
    self.eventId = forWho;
    self.title = value;
    self.isHidden = hidden ? 1 : 0;
    self.displayMode = "text";

    self.show = function() {
      self.isHidden = 0;
    };

    self.hide = function() {
      self.isHidden = 1;
      self.dataId = "";
    }

    self.setData = function(model) {
      self.dataId = model[self.eventId];
      self.title = (self.eventId.indexOf("Date") !== -1) ? model[self.eventId] : model[self.eventId + "Model"].selRow.value;
      self.isHidden = (!!self.dataId) ? 0 : 1;
    };
  }

  function DateRangePillModel(startDate, endDate, hidden) {
    var self = this;
    self.startDate = startDate;
    self.endDate = endDate;
    self.title = "";
    self.isHidden = hidden ? 1 : 0;
    self.displayMode = "text";

    function setTitle() {
      if (!!self.startDate && !!self.endDate) {
        self.title = [self.startDate, self.endDate].join(" - ");
      } else if (!!self.startDate) {
        self.title = ["Exec.Date >=", self.startDate].join(" ");
      } else if (!!self.endDate) {
        self.title = ["Exec.Date <=", self.endDate].join(" ");
      } else {
        self.title = "";
      }
    }

    self.setData = function(model) {
      self.startDate = model.startDate;
      self.endDate = model.endDate;
      setTitle();
      self.isHidden = (!!self.startDate || !!self.endDate) ? 0 : 1;
    };
  }


  function FilterModel(model) {
    var _model = model,
      _retailers,
      _clients,
      _projectTypes,
      _self = {};

    _self.client = "";
    _self.retailer = "";
    _self.location = "";
    _self.projectType = "";
    _self.startDate = "";
    _self.endDate = "";
    _self.clientModel = undefined;
    _self.retailerModel = undefined;
    _self.locationModel = undefined;
    _self.projectTypeModel = undefined;

    function doLookup(rowset, keyword) {
      var name, data = rowset;
      if (!!keyword) {
        name = keyword.toLowerCase();
        data = [];
        rowset.forEach(function(row) {
          if (row["Name"].indexOf(name) !== -1) {
            data.push(row);
          }
        });
      }
      return data;
    }

    _self.resetSelection = function(dataType) {
      var m;
      _self[dataType] = "";
      m = _self[dataType + "Model"];
      m.selRow.key = "";
      m.selRow.value = "";
    };

    _self.findClients = function(keyword) {
      _self.clientModel.rowset = doLookup(_clients, keyword);
    };

    _self.findRetailers = function(keyword) {
      _self.retailerModel.rowset = doLookup(_retailers, keyword);
    };

    _self.findLocations = function(keyword) {
      _model.findLocations(keyword).then(function(data) {
        var item, items = [];

        if (!!data) {
          data.forEach(function(rec) {
            item = {};
            item.Id = rec.Id;
            item.Num = "<span class='label label--success'>" + rec.LocationNumber__c + "</span>"; 
            item.Name = rec.Name;
            item.Address = rec.Address__c;
            item.retailerId = rec.Retailer__c;
            item.City = rec.City__c;
            item.State = rec.State__c;
            items.push(item);
          });
        }
        _self.locationModel.rowset = items;
        if (!_self.locationModel.selRow) {
          _self.locationModel.selRow = {
            key: "",
            value: ""
          };
        }
      });
    };

    _self.findProjectTypes = function(keyword) {
      _self.projectTypeModel.rowset = doLookup(_projectTypes, keyword);
    };

    function initRetailers() {
      _model.getRetailers().then(function(data) {
        _retailers = data;
        _self.retailerModel = {
          selRow: {
            key: "",
            value: ""
          },
          rowset: data
        };
      });
    }

    function initClients() {
      var clients = [];
      _model.getClients().then(function(data) {
        data.forEach(function(rec){
          clients.push({
            Id: rec.Id,
            Name: rec.ClientName__c
          });
        });
        _clients = clients;
        _self.clientModel = {
          selRow: {
            key: "",
            value: ""
          },
          rowset: clients
        };
      });
    }

    function initProjectTypes() {
      _model.getProjectTypes().then(function(data) {
        _projectTypes = data;
        _self.projectTypeModel = {
          selRow: {
            key: "",
            value: ""
          },
          rowset: data
        };
      });
    }

    _self.init = function() {
      initRetailers();
      initClients();
      initProjectTypes();
    };

    return _self;
  }

  function DisplayActionModel() {
    var _self = this;
    _self.title = "DISPLAY AS";
    _self.helpText = "Data Layout Options";
    _self.buttonUrl = _path + "/assets/icons/utility-sprite/svg/symbols.svg#monthlyview";
    _self.canSelect = 1;
    _self.showSelectIcon = 1;
    _self.setSelectIcon = 1;
    _self.menuItems = [{
      key: "table",
      value: "Table",
      leftIconUrl: "",
      rightIconUrl: _path + "/assets/icons/utility-sprite/svg/symbols.svg#table",
      disabled: 0
    }, {
      key: "month",
      value: "Month",
      leftIconUrl: "",
      rightIconUrl: _path + "/assets/icons/utility-sprite/svg/symbols.svg#monthlyview",
      selected: 1,
      disabled: 0
    }];
    _self.getSelKey = function() {
      var sel = _.find(_self.menuItems, function(e) {
        return e.selected === 1;
      });
      return !!sel ? sel.key : "table";
    };
    _self.setSelKey = function(key) {
      _self.menuItems.forEach(function(item) {
        item.selected = (item.key === key) ? 1 : 0;
      });
    };
  }

  function ViewTypeModel() {
    var _self = this;
    _self.option = {
      key: "project",
      value: "Project View"
    };
    _self.options = [{
      key: "project",
      value: "Project View"
    }, {
      key: "job",
      value: "Job View"
    }];
    _self.getSelKey = function() {
      return _self.option.key;
    };
    _self.setSelKey = function(key) {
      if (_self.option.key !== key) {
        var opt = _.find(_self.options, function(opt) {
          return opt.key === key;
        })
        if (!!opt) {
          _self.option.key = opt.key;
          _self.option.value = opt.value;
        }
      }
    };
  }

  function transformEvents(viewType, rowset) {
    var events = [],
      startDate, endDate,
      eventCounts = [],
      diffDays,
      locNumField = (viewType === "project") ? "ClubNumber__c" : "LocationNumber__c";

    rowset.forEach(function(rec) {
      startDate = Date.parse(rec.StartDate__c);
      endDate = Date.parse(rec.EndDate__c);
      events.push({
        title: [rec[locNumField], rec["ProjectTypeName__c"]].join(": "),
        start: moment(startDate).toISOString(),
        end: moment(endDate).toISOString(),
        color: 'steelblue'
      });

      var item, diffDays = moment(endDate).diff(moment(startDate), 'days');
      for (var i = 0; i < diffDays; i++) {
        item = moment(startDate).add(i, 'days').unix() + "";
        if (!!item) {
          if (!!eventCounts[item]) {
            eventCounts[item] += 1;
          } else {
            eventCounts[item] = 1;
          }
        }
      }
    });

    return {
      events: events,
      eventCounts: eventCounts
    };
  }

  function setMonthData(viewType, data) {
    var calendarId = ["div#", viewType, "Calendar"].join(""),
      eventSet = transformEvents(viewType, data),
      calendarTarget = A.element(calendarId);

    calendarTarget.fullCalendar('removeEvents');
    calendarTarget.fullCalendar('addEventSource', eventSet.events);
    _calendarHeatMapManager.render(eventSet.eventCounts);
  }

  function CalendarHeatMapManager(selId, viewType) {
    var cal = undefined,
      calendarId = ["div#", viewType, "Calendar"].join(""),
      prevSelId = ["#", viewType, "HeatMap", "-g-PreviousDomain-selector"].join(""),
      nextSelId = ["#", viewType, "HeatMap", "-g-NextDomain-selector"].join("");

    function HeatMap() {}
    HeatMap.prototype.render = function(data) {

      if (!!cal) {
        cal.update(data)
      } else {
        cal = new CalHeatMap();
        cal.init({
          itemSelector: selId,
          domain: "month",
          subDomain: "x_day",
          data: data,
          weekStartOnMonday: false,
          legend: [1, 3, 5, 10],
          legendColors: {
            min: "#efefef",
            max: "steelblue",
            empty: "white",
            overflow: "red"
          },
          cellSize: 25,
          cellPadding: 5,
          verticalOrientation: true,
          cellRadius: 0,
          considerMissingDataAsZero: true,
          domainGutter: 0,
          range: 3,
          domainDynamicDimension: true,
          previousSelector: prevSelId,
          nextSelector: nextSelId,
          domainLabelFormat: function(date) {
            moment.locale("en");
            return moment(date).format("MMMM").toUpperCase();
          },
          label: {
            position: "top"
          },
          onClick: function(date, nb) {
            A.element(calendarId).fullCalendar('changeView', 'agendaDay');
            A.element(calendarId).fullCalendar('gotoDate', date);
          },
          subDomainTextFormat: "%d"
        });
      };
    }
    return new HeatMap();
  }

  function initCalendar(viewType) {
    var calendarId = ["div#", viewType, "Calendar"].join(""),
      heatMapId = ["div#", viewType, "HeatMap"].join("");

    A.element(calendarId).fullCalendar({
      header: {
        left: 'prev,next',
        center: 'title',
        right: 'month,agendaWeek,agendaDay'
      },
      allDayDefault: true,
      eventLimit: 5,
      businessHours: true,
      editable: true,
      height: getHeight() + 40
    });
    _calendarHeatMapManager = new CalendarHeatMapManager(heatMapId, viewType);
  }

  A.module("app.location.report", [
      "cmk.web.context",
      "cmk.system.async",
      "cmk.service.lookupModel",
      "cmk.location.report.model",
      "cmk.ui.picklist",
      "cmk.ui.dropdown",
      "cmk.ui.dropdown.area",
      "cmk.ui.lookup",
      "cmk.ui.pill",
      "cmk.ui.pagelet",
      "ngSanitize",
      "ui.router",
      "ui.grid.autoResize",
      "ui.grid",
      "ui.grid.selection",
      "ui.grid.exporter"
    ])
    .config(["$stateProvider", "$urlRouterProvider", function(_stateProvider, _urlRouter) {

      _urlRouter.otherwise("/projects-calendar-viewer");
      _stateProvider
        .state("projects-table-viewer", {
          url: "/projects-table-viewer",
          template: '<div class="cm-col-container">' +
            '<div cmk-pagelet="1" options="projectPageletModel" navbar-click="onNavBarClick(href)">' +
            '<div ui-grid="projectGridOptions" class="cm-grid" ui-grid-exporter ui-grid-auto-resize></div>' +
            '</div></div>',
          controller: function($scope) {
            $scope.projectPageletModel = {
              title: "Project List",
              canExpand: true,
              height: getHeight(),
              navBars: [{
                id: "app_export_csv",
                text: "Export to CSV File",
                iconUrl: _path + "/assets/icons/utility-sprite/svg/symbols.svg#download"
              }],
              footerHTML: ""
            };
            _appModel.findProjects(getQuery($scope)).then(function(data) {
              $scope.projectGridOptions.data = data;
            });
            $scope.export_row_type = "all";
            $scope.export_column_type = "all";
            $scope.export_format = "csv";

            $scope.onNavBarClick = function(href) {
              $scope.gridApi.exporter.csvExport($scope.export_row_type, $scope.export_column_type);
            };
            setViewTypeDisplayType($scope, "project", "table");
          }
        })
        .state("jobs-table-viewer", {
          url: "/jobs-table-viewer",
          template: '<div class="cm-col-container">' +
            '<div cmk-pagelet="1" options="jobPageletModel" navbar-click="onNavBarClick(href)">' +
            '<div ui-grid="jobGridOptions" class="cm-grid" ui-grid-exporter ui-grid-auto-resize></div>' +
            '</div></div>',
          controller: function($scope) {
            $scope.jobPageletModel = {
              title: "Job List",
              canExpand: true,
              height: getHeight(),
              navBars: [{
                id: "app_export_csv",
                text: "Export to CSV File",
                iconUrl: _path + "/assets/icons/utility-sprite/svg/symbols.svg#download"
              }],
              footerHTML: ""
            };

            $scope.export_row_type = "all";
            $scope.export_column_type = "all";
            $scope.export_format = "csv";

            $scope.onNavBarClick = function(href) {
              $scope.gridApi.exporter.csvExport($scope.export_row_type, $scope.export_column_type);
            };
            _appModel.findJobs(getQuery($scope)).then(function(data) {
              $scope.jobGridOptions.data = data;
            });
            setViewTypeDisplayType($scope, "job", "table");
          }
        })
        .state("projects-calendar-viewer", {
          url: "/projects-calendar-viewer",
          template: '<div class="cm-col-container">' +
            '<div cmk-pagelet="1" options="projectCalendarPageletModel" on-resize="onResize(height)">' +
            '<div class="grid cm-row wrap">' +
            '<div class="cm-heatmap"><div id="projectHeatMap"></div></div>' +
            '<div class="cm-full-cal"><div id="projectCalendar"></div></div>' +
            '</div></div></div>',
          controller: function($scope) {
            $scope.projectCalendarPageletModel = {
              title: "Projects - Calendar",
              canExpand: true,
              height: getHeight(),
              navBars: [],
              footerHTML: ""
            };
            $scope.onResize = function(height) {
              A.element("div#pageBody").find("div.cm-article-body").height(height);
            };
            _appModel.findProjects(getQuery($scope)).then(function(data) {
              initCalendar("project");
              setMonthData("project", data);
            });
            setViewTypeDisplayType($scope, "project", "month");
          }
        })
        .state("jobs-calendar-viewer", {
          url: "/jobs-calendar-viewer",
          template: '<div class="cm-col-container">' +
            '<div cmk-pagelet="1" options="jobCalendarPageletModel" on-resize="onResize(height)">' +
            '<div class="grid cm-row wrap">' +
            '<div class="cm-heatmap"><div id="jobHeatMap"></div></div>' +
            '<div class="cm-full-cal"><div id="jobCalendar"></div></div>' +
            '</div></div></div>',
          controller: function($scope) {
            $scope.jobCalendarPageletModel = {
              title: "Jobs - Calendar",
              canExpand: true,
              height: getHeight(),
              navBars: [],
              footerHTML: ""
            };
            $scope.onResize = function(height) {
              A.element("div#pageBody").find("div.cm-article-body").height(height);
            };
            _appModel.findJobs(getQuery($scope)).then(function(data) {
              initCalendar("job");
              setMonthData("job", data);
            });
            setViewTypeDisplayType($scope, "job", "month");
          }
        });
    }])

  .factory('appLocationReportModel', ['cmkSystemAsync', 'cmkServiceLookupModel', 'cmkLocationReportModel', 'cmkWebContext', function(asyncApi, lookupModel, reportModel, webContext) {
    function Model() {}

    Model.prototype.getClients = function() {;
      return lookupModel.clients();
    };

    Model.prototype.getRetailers = function() {
      return lookupModel.retailers();
    };

    Model.prototype.getProjectTypes = function() {
      return lookupModel.projectTypes();
    };

    Model.prototype.findLocations = function(keyword) {
      return lookupModel.findLocations(keyword);
    };

    Model.prototype.findProjects = function(query) {
      return reportModel.findProjects(query);
    };

    Model.prototype.findJobs = function(query) {
      return reportModel.findJobs(query);
    };

    return new Model();
  }])

  .controller('LocationReportController', ['$scope', '$state', 'cmkWebContext', '$log', 'appLocationReportModel', '$timeout', function($scope, $state, webContext, $log, appModel, $timeout) {
    var scope = $scope;
    _path = webContext.staticResourcePath;
    _appModel = appModel;
    scope.objectTypeViewModel = new ViewTypeModel();
    scope.displayActionModel = new DisplayActionModel();
    scope.filterModel = new FilterModel(appModel);
    scope.clientPillModel = new PillModel("client", "", "", true);
    scope.retailerPillModel = new PillModel("retailer", "", "", true);
    scope.locationPillModel = new PillModel("location", "", "", true);
    scope.projectTypePillModel = new PillModel("projectType", "", "", true);
    scope.dateRangePillModel = new DateRangePillModel("", "", true);
    scope.jobGridOptions = getJobGridOption(scope);
    scope.projectGridOptions = getProjectGridOption(scope);

    function routeToViewer(viewType, layoutType) {
      if (viewType === "project") {
        if (layoutType === "table") {
          $state.go("projects-table-viewer");
        } else {
          $state.go("projects-calendar-viewer");
        }
      } else {
        if (layoutType === "table") {
          $state.go("jobs-table-viewer");
        } else {
          $state.go("jobs-calendar-viewer");
        }
      }
    }

    scope.initFilter = function() {
      scope.filterModel.init();
      A.element('input[data-role="date"]').datepicker({
        changeMonth: true,
        changeYear: true,
        showOtherMonths: true,
        selectOtherMonths: false
      });
    };

    scope.lookupRetailers = function(keyword) {
      scope.filterModel.findRetailers(keyword);
    };

    scope.retailerChanged = function() {
      scope.retailerPillModel.setData(scope.filterModel);
      handleFilter(scope, $log, appModel);
    };

    scope.onRetailerRemove = function() {
      scope.retailerPillModel.hide();
      scope.filterModel.resetSelection("retailer");
      handleFilter(scope, $log, appModel);
    };

    scope.lookupClients = function(keyword) {
      scope.filterModel.findClients(keyword);
    };

    scope.clientChanged = function() {
      scope.clientPillModel.setData(scope.filterModel);
      handleFilter(scope, $log, appModel);
    };

    scope.onClientRemove = function() {
      scope.clientPillModel.hide();
      scope.filterModel.resetSelection("client");
      handleFilter(scope, $log, appModel);
    };

    scope.lookupProjectTypes = function(keyword) {
      scope.filterModel.findProjectTypes(keyword);
    };

    scope.projectTypeChanged = function() {
      scope.projectTypePillModel.setData(scope.filterModel);
      handleFilter(scope, $log, appModel);
    };

    scope.onProjectTypeRemove = function() {
      scope.projectTypePillModel.hide();
      scope.filterModel.resetSelection("projectType");
      handleFilter(scope, $log, appModel);
    };

    scope.lookupLocations = function(keyword) {
      scope.filterModel.findLocations(keyword);
    };

    scope.locationChanged = function() {
      scope.locationPillModel.setData(scope.filterModel);
      handleFilter(scope, $log, appModel);
    };

    scope.onLocationRemove = function() {
      scope.locationPillModel.hide();
      scope.filterModel.resetSelection("location");
      handleFilter(scope, $log, appModel);
    };

    scope.startDateChanged = function() {
      scope.dateRangePillModel.setData(scope.filterModel);
      handleFilter(scope, $log, appModel);
    };

    scope.onDateRangeRemove = function() {
      scope.filterModel.startDate = "";
      scope.filterModel.endDate = "";
      scope.dateRangePillModel.setData(scope.filterModel);
      handleFilter(scope, $log, appModel);
    };

    scope.endDateChanged = function() {
      scope.dateRangePillModel.setData(scope.filterModel);
      handleFilter(scope, $log, appModel);
    };

    scope.locationRowSelected = function(row) {

      var num = row.Num.replace("</span>", "");
      return num.substr(num.indexOf(">") + 1) + " " + row.Name + " " + row.Address + " " + row.City + " " + row.State;
    }

    scope.displayActionClicked = function(layoutType) {
      routeToViewer(scope.objectTypeViewModel.getSelKey(), layoutType)
    };

    scope.onViewTypeChanged = function() {
      routeToViewer(scope.objectTypeViewModel.getSelKey(), scope.displayActionModel.getSelKey());
    }

  }]);

})(angular);
 