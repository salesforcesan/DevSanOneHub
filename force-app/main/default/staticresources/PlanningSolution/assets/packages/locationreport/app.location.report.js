/*
(function(A){
   A.module("cmk.location.report.model", ["cmk.system.async","cmk.web.context"])
    .factory('cmkLocationReportModel', ['cmkSystemAsync', 'cmkWebContext', '$q', function(asyncApi, webContext, $q) {

     function Model() {}

     Model.prototype.findProjects = function(query) {
        var action = '{!$RemoteAction.LocationReportRemoter.FindProjects}';
        return asyncApi.remoting(action, query);
     };

     Model.prototype.findJobs = function(query) {
        var action = '{!$RemoteAction.LocationReportRemoter.FindJobs}';
        return asyncApi.remoting(action, query);
     };


     Model.prototype.findProjectCounts = function(query) {
        var action = '{!$RemoteAction.LocationReportRemoter.GetProjectCounts}';
        return asyncApi.remoting(action, query);
     };

     Model.prototype.findJobCounts = function(query) {
        var action = '{!$RemoteAction.LocationReportRemoter.GetJobCounts}';
        return asyncApi.remoting(action, query);
     };

     Model.prototype.getRetailers = function () {
        var action = '{!$RemoteAction.LocationReportRemoter.GetRetailers}';
        return asyncApi.remoting(action);
     };

     Model.prototype.getClients = function () {
        var action = '{!$RemoteAction.LocationReportRemoter.GetClients}';
        return asyncApi.remoting(action);
     };

     Model.prototype.getProjectTypes = function () {
        var action = '{!$RemoteAction.LocationReportRemoter.GetProjectTypes}';
        return asyncApi.remoting(action);
     };

     Model.prototype.getMarkets = function(){
        var action = '{!$RemoteAction.LocationReportRemoter.GetMarkets}';
        return asyncApi.remoting(action);
     };

     Model.prototype.getRegions = function(){
     var action = '{!$RemoteAction.LocationReportRemoter.GetRegions}';
        return asyncApi.remoting(action);
     };

     Model.prototype.findLocations = function (query) {
        var action = '{!$RemoteAction.LocationReportRemoter.FindLocation}';
        return asyncApi.remoting(action, query);
     };

     Model.prototype.getStatusList = function () {
        var action = '{!$RemoteAction.LocationReportRemoter.GetProjectStatusList}';
        return asyncApi.remoting(action);
     };

     Model.prototype.findProjectNumbers = function(query){
        var action = '{!$RemoteAction.LocationReportRemoter.FindProjectNumbers}';
        return asyncApi.remoting(action, query);
     };

     return new Model();
   }]);
    })(angular);
    */

(function(A) {
  "use strict";
  var _busyIndicatorService;
  var _path, _appModel, _calendarHeatMapManager;

  function showBusy(scope){
    _busyIndicatorService.show(scope,{
      containerId: "div#pageBody"
    });
  }

  function hideBusy(){
    _busyIndicatorService.hide();
  }


  function getHeight() {
    var h = window.innerHeight - A.element("div#pageBody").offset().top;
    return (h > 400) ? h - 150 : 400;
  }

  function getQuery($scope) {
    var query = {},
        m = $scope.filterModel;
    query.client = m.client || "";
    query.retailer = m.retailer || "";
    query.projectType = m.projectType || "";
    query.location = m.location || "";
    query.startDate = m.startDate || "";
    query.endDate = m.endDate || "";
    query.projectStatus = m.projectStatus || "";
    query.project = m.projectNumber || "";
    query.market = m.market || "";
    query.region = m.region || "";
    query.projectTitle = m.projectTitle || "";
    query.canSchedule = m.canSchedule ? "1": "0";
    query.executionCompany = m.executionCompany || "";

    return query;
  }

  function handleFilter($scope, $log, reportModel, busyIndicatorService) {
    var key = $scope.objectTypeViewModel.getSelKey(),
      actionKey = $scope.displayActionModel.getSelKey(),
      query = getQuery($scope);
      showBusy($scope);
    if (key === "project") {
      reportModel.findProjects(query).then(function(data) {
        $scope.projectGridOptions.setData(data);
        if (actionKey === "month") {
          setMonthData(key, data);
        } else {
          hideBusy();
        }
      });

      if (actionKey === "month") {
       _appModel.findProjectCounts(getQuery($scope)).then(function(data){
                setHeatMap(data);
                hideBusy();
            }, function(err){
                console.log(err);
                hideBusy();
            });
      }

    } else if (key === "job") {
      reportModel.findJobs(query).then(function(data) {
        $scope.jobGridOptions.setData(data);
        if (actionKey === "month") {
          setMonthData(key, data);
        } else {
          hideBusy();
        }
      });

       if (actionKey === "month") {
       _appModel.findJobCounts(getQuery($scope)).then(function(data){
                setHeatMap(data);
                hideBusy();
            }, function(err){
                console.log(err);
                hideBusy();
            });
      }
    } else {
      $log.log("The app is in invalid state");
      $log.log($scope.objectTypeViewModel);
      hideBusy();
    }
  }

  function transformData(data,fields){
    var val,ref, min, rec, startDate, endDate, date;
    var rs = _.map(data, function(e){
        rec = {};
        fields.forEach(function(colName){
            if (colName.indexOf("__r") !== -1){
                ref = e[colName] || {};
                ref.Id = ref.Id || ""
                ref.Name = ref.Name || "-";

                if (isFinite(ref["StartDate__c"])){
                  startDate = new Date(ref["StartDate__c"]);
                  rec["StartDate__c"] = new Date(startDate.setDate(startDate.getDate() +1))
                } else {
                  rec["StartDate__c"] = "-";
                }
                if (isFinite(ref.EndDate__c)){
                  endDate = new Date(ref.EndDate__c);
                  rec["EndDate__c"] = new Date(endDate.setDate(endDate.getDate() +1));
                } else {
                  rec["EndDate__c"] = "-";
                }
                rec[colName] = ref;
            } else if (colName.indexOf("Date") !== -1){
            } else if (!e[colName]) {
                rec[colName] = "-";
            } else {
                val = e[colName] + "";
                rec[colName] =  val.indexOf("&") !== -1 ? A.element("<span></span>").html(val).text() : val;
            }
        });
        return rec;
    });

    return rs;
  }

  function getProjectGridOption($scope) {
    var fields = [
      "Id",
      "Project__r",
      "ProjectName__c",
      "RetailerName__c",
      "Retailer__c",
      "AccountName__c",
      "AccountId__c",
      "Location__c",
      "ClubNumber__c",
      "StartDate__c",
      "EndDate__c",
      "ProjectStatus__c"
    ];

    var options = {
      data: [],
      setData: function(data){
        options.data = transformData(data, fields);
      },
      columnDefs: [{
        displayName: "Location #",
        field: "ClubNumber__c"
      }, {
        displayName: "Retailer",
        field: "RetailerName__c",
        cellTemplate: '<div class="cm-cell slds-truncate"><span ng-bind-html="COL_FIELD"></span></div>'
      }, {
        displayName: "Project Title",
        field: "ProjectName__c",
        cellTemplate: '<div class="cm-cell slds-truncate"><a href="#" ng-click="grid.appScope.goDetail($event, row)"><span ng-bind-html="COL_FIELD"></span></a></div>'
      }, {
        displayName: "Account",
        field: "AccountName__c",
        cellTemplate: '<div class="cm-cell slds-truncate"><span ng-bind-html="COL_FIELD"></span></div>'
      }, {
        displayName: "Start Date",
        field: "StartDate__c",
        cellTemplate: '<div class="cm-cell slds-truncate"><span>{{COL_FIELD !== null && COL_FIELD !== "-" ? COL_FIELD.format("/") : COL_FIELD}}</span></div>'
      }, {
        displayName: "End Date",
        field: "EndDate__c",
        cellTemplate: '<div class="cm-cell slds-truncate"><span>{{COL_FIELD !== null && COL_FIELD !== "-" ? COL_FIELD.format("/") : COL_FIELD}}</span></div>'
      },{
        displayName: "Status",
        field: "ProjectStatus__c"
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

  function getJobGridOption($scope) {
   var fields = [
      "Id",
      "Project__r",
      "Project__c",
      "ProjectName__c",
      "RetailerName__c",
      "Retailer__c",
      "ClientId__c",
      "ProjectType__c",
      "Location__c",
      "LocationNumber__c",
      "ScheduleDate__c",
      "Status__c",
      "ServiceName__c",
      "StartDate__c",
      "EndDate__c"
    ];
    var options = {
      data: [],
      setData: function(data){
        options.data = transformData(data, fields);
      },
      columnDefs: [{
        displayName: "Location #",
        field: "LocationNumber__c",
        cellTemplate: '<div class="cm-cell slds-truncate"><a href="#" ng-click="grid.appScope.goDetail($event,row)"><span ng-bind-html="COL_FIELD"></span></a></div>'
      }, {
        displayName: "Retailer",
        field: "RetailerName__c",
        cellTemplate: '<div class="cm-cell slds-truncate"><span ng-bind-html="COL_FIELD"></span></div>'
      }, {
        displayName: "Project Title",
        field: "ProjectName__c",
        cellTemplate: '<div class="cm-cell slds-truncate"><span ng-bind-html="COL_FIELD"></span></div>'
      }, {
        displayName: "Account",
        field: "ClientId__c",
        cellTemplate: '<div class="cm-cell slds-truncate"><span ng-bind-html="COL_FIELD"></span></div>'
      }, {
        displayName: "Service",
        field: "ServiceName__c",
        cellTemplate: '<div class="cm-cell slds-truncate"><span ng-bind-html="COL_FIELD"></span></div>'
      }, {
        displayName: "Start Date",
        field: "StartDate__c",
        cellTemplate: '<div class="cm-cell slds-truncate"><span>{{COL_FIELD !== null && COL_FIELD !== "-" ? COL_FIELD.format("/") : COL_FIELD}}</span></div>'
      }, {
        displayName: "End Date",
        field: "EndDate__c",
        cellTemplate: '<div class="cm-cell slds-truncate"><span>{{COL_FIELD !== null && COL_FIELD !== "-" ? COL_FIELD.format("/") : COL_FIELD}}</span></div>'
      }, {
        displayName: "Status",
        field: "Status__c"
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
      if (self.eventId === "canSchedule"){
        self.title = "CanReSchedule";
      } else {
        self.title = ((self.eventId.indexOf("Date") !== -1)
          || !model[self.eventId + "Model"]
          || !model[self.eventId + "Model"].selRow)
          ? model[self.eventId] : model[self.eventId + "Model"].selRow.value;
      }
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
      _statusList,
      _markets,
      _regions,
      _self = {};

     function initDate(){
        var month, startMonth, endMonth, endDate, today = new Date();
        startMonth = today.getMonth();
        month = "0" + (startMonth + 1);
        _self.startDate = [month.length < 3 ? month : month.substr(1,2), "01", today.getFullYear() + ""].join("/");

        var selDt = 28;
        var e = new Date(today.setMonth(startMonth + 2, selDt));
        var result = e;
        endMonth = e.getMonth();
        while(e.getMonth() === endMonth){
            selDt++;
            result = new Date(e.getTime());
            e = new Date(e.setDate(selDt));
        }
        month = "0" + (result.getMonth() + 1);
        endDate = "0" + result.getDate();
        _self.endDate = [month.length < 3 ? month : month.substr(1,2), endDate.length < 3 ? endDate : endDate.substr(1,2), result.getFullYear() + ""].join("/");
     }

    _self.client = "";
    _self.retailer = "";
    _self.location = "";
    _self.projectTitle = "";
    _self.projectType = "";
    _self.startDate = "";
    _self.endDate = "";
    _self.projectStatus = "";
    _self.projectNumber = "";
    _self.market = "";
    _self.region = "";
    _self.canSchedule = true;
    _self.executionCompany = "";
    _self.clientModel = undefined;
    _self.retailerModel = undefined;
    _self.locationModel = undefined;
    _self.projectTypeModel = undefined;
    _self.projectStatusModel = undefined;
    _self.projectNumberModel = undefined;
    _self.marketModel = undefined;
    _self.regionModel = undefined;
    _self.canScheduleModel = undefined;
    _self.showMarketRequired = 0;

    initDate();

    function doLookup(rowset, keyword) {
      var name, src, data = rowset;
      if (!!keyword) {
        name = keyword.toLowerCase();
        data = [];
        rowset.forEach(function(row) {
          src = row["Name"] || "";
          if (src.toLowerCase().indexOf(name) !== -1) {
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
        if (!_clients) {
            _model.getClients().then(function(data) {
                _clients = data;
                _self.clientModel = {
                  selRow: {
                    key: "",
                    value: ""
                  },
                  rowset: data
                };
           _self.clientModel.rowset = doLookup(_clients, keyword);
           });
        } else {
            _self.clientModel.rowset = doLookup(_clients, keyword);
        }
    };

    _self.findRetailers = function(keyword) {
        if (!!_retailers) {
            _self.retailerModel.rowset = doLookup(_retailers, keyword);
        } else {
            _model.getRetailers().then(function(data) {
                _retailers = data;
                _self.retailerModel = {
                  selRow: {
                    key: "",
                    value: ""
                  },
                  rowset: data
                };
                _self.retailerModel.rowset = doLookup(_retailers, keyword);
            });
        }
    };

    _self.findProjectStatus = function(keyword){
        if (!_statusList){
                _model.getStatusList().then(function(data){
                _statusList = data;
                _self.projectStatusModel = {
                    rowset: data,
                    selRow: {key: "", value:""}
                };
                _self.projectStatusModel.rowset = doLookup(_statusList, keyword);
            });
        } else {
            _self.projectStatusModel.rowset = doLookup(_statusList, keyword);
        }
    };

    _self.findProjectNumbers = function(query){
        _model.findProjectNumbers(query).then(function(data){
            _self.projectNumberModel.rowset = _.map(data, function(d){
                return {
                    Id: d.Id,
                    ProjectNumber: d.ProjectNumber__c,
                    Name: d.Name,
                    Status: d.Status__c
                };
            });
            if (!_self.projectNumberModel.selRow){
                _self.projectNumberModel.selRow = {key:"", value:""};
            }
        });
    };

    _self.findLocations = function(keyword) {
      _model.findLocations(keyword).then(function(data) {
        var item, items = [];

        if (!!data) {
          data.forEach(function(rec) {
            item = {};
            item.Id = rec.Id;
            item.Num = rec.LocationNumber__c;
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
        if (!_projectTypes){
            _model.getProjectTypes().then(function(data) {
                _projectTypes = data;
                _self.projectTypeModel = {
                  selRow: {
                    key: "",
                    value: ""
                  },
                  rowset: data
                };
                _self.projectTypeModel.rowset = doLookup(_projectTypes, keyword);
              });
        } else {
            _self.projectTypeModel.rowset = doLookup(_projectTypes, keyword);
        }
    };

    _self.findMarkets = function(keyword){
        if (!!_markets) {
            _self.marketModel.rowset = doLookup(_markets, keyword);
        } else {
            _model.getMarkets().then(function(data){
                _markets = data;
                _self.marketModel = {
                    selRow: { key: "", value:""},
                    rowset: data
                };
                _self.marketModel.rowset = doLookup(_markets, keyword);
            });
        }
    };

    _self.findRegions = function(keyword){
        if (!!_regions){
            _self.regionModel.rowset = doRegionLookup(keyword);
        } else {
            _model.getRegions().then(function(data){
                _regions = data;
                _self.regionModel = {
                    selRow: {key:"", value:""},
                    rowset: []
                };
                _self.regionModel.rowset = doRegionLookup(keyword);
            });
        }
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

    function transformTime(time){
        var tm, hr, min,dif = 0, isAM = 0;
        if (!!time) {
            if (time.indexOf("am") !== -1){
                time = time.replace("am","");
                isAM = 1;
            } else if (time.indexOf("pm") !== -1) {
                time = time.replace("pm","");
            }
            var tm = time.match(/\d{1,2}/g);
            if (tm.length === 2) {
                hr =  parseInt(tm[0]);
                min = parseInt(tm[1]);
                if (isAM === 0 && hr < 12) {
                    hr += 12;
                }
            }
            return {
                hr: hr,
                min: min
            };
        }
        return {
            hr: 0,
            min: 0
        };
    }


    function transformEvents(viewType, rowset) {
        var events = [], isJob = viewType === "project" ? false : true,
            locNumField = (viewType === "project") ? "ClubNumber__c" : "LocationNumber__c",
            allDay = isJob ? false : true;

    rowset.forEach(function(rec) {
      var ms1, type, ref, dt1, dt2, tm1, tm2;

      dt1 = rec.StartDate__c,
      dt2 = rec.EndDate__c;
      if (isJob){

        tm1 =  transformTime(rec.StartTime__c);
        tm2 = transformTime(rec.EndTime__c);
      } else {
        tm1 = { hr: 0, min: 0};
        tm2 = { hr: 23, min: 59};
      }


      if ((!!dt1 && isFinite(dt1)) && (!!dt2 && isFinite(dt2))) {
        dt1 =  new Date(dt1);
        dt2 =  new Date(dt2);
        dt1 = new Date(dt1.getUTCFullYear(), dt1.getUTCMonth(), dt1.getUTCDate(), tm1.hr, tm1.min, 0, 0);
        dt2 = new Date(dt2.getUTCFullYear(), dt2.getUTCMonth(), dt2.getUTCDate(), tm2.hr, tm2.min, 0, 0);

        ref = rec.Project__r || {};
        name = rec.ProjectName__c || "-";
        name = name.indexOf("&") !== -1 ? A.element("<span></span>").html(name).text() : name;
        events.push({
          cmkId: (viewType === "project") ? (ref.Id || "") : (rec.Id || ""),
          viewType: viewType,
          title: [rec[locNumField], name].join(": "),
          start: dt1.toLocaleString(),
          end: dt2.toLocaleString(),
          color: 'steelblue',
          allDay: allDay
        });
      }
    });
    return events;
  }

  function transformHeatMapData(data){
    var counts = [], year, month, day, dt, key;
    for(var p in data){
        if (data.hasOwnProperty(p)){
            p = p + "";
            if (p.length === 8 ){
                year = parseInt(p.substr(0,4));
                month = parseInt(p.substr(4,2));
                day = parseInt(p.substr(6,2));
                dt = new Date(year, month -1, day, 0, 0, 0, 0);
                key = Math.floor(dt.getTime() / 1000) + "";
                counts[key] = data[p];
            }
        }
    }
    return counts;
  }

  function setMonthData(viewType, data) {
    var calendarId = ["div#", viewType, "Calendar"].join(""),
      events = transformEvents(viewType, data),
      calendarTarget = A.element(calendarId);

    calendarTarget.fullCalendar('removeEvents');
    calendarTarget.fullCalendar('addEventSource', events);
  }

  function setHeatMap(data){
    var counts = transformHeatMapData(data);
    _calendarHeatMapManager.render(counts);
  }

  function CalendarHeatMapManager(selId, viewType) {
    var cal = undefined,
      heatMapId = viewType === "job" ? "div#jobHeatMap" : "div#projectHeatMap",
      calendarId = ["div#", viewType, "Calendar"].join(""),
      prevSelId = ["#", viewType, "HeatMap", "-g-PreviousDomain-selector"].join(""),
      nextSelId = ["#", viewType, "HeatMap", "-g-NextDomain-selector"].join("");

    function HeatMap() {}
    HeatMap.prototype.render = function(data) {
      moment.locale("en");
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
          cellSize: 24,
          cellPadding: 4,
          verticalOrientation: true,
          cellRadius: 0,
          considerMissingDataAsZero: true,
          domainGutter: 0,
          range: 3,
          domainDynamicDimension: true,
          previousSelector: prevSelId,
          nextSelector: nextSelId,
          domainLabelFormat: function(date) {
            return moment(date).format("MMMM").toUpperCase();
          },
          label: {
            position: "top"
          },
          onClick: function(date, nb) {
            A.element(calendarId).fullCalendar('changeView', 'agendaDay');
            A.element(calendarId).fullCalendar('gotoDate', date);
          },
          onComplete: function () {
            A.element(heatMapId).slimScroll({
                position: "right",
                color: "#aaa",
                railColor: "#ddd",
                railVisible: true,
                size: "10px",
                height: getHeight() + 35,
                alwaysVisible: true
            });
          },
          subDomainTextFormat: "%d"
        });
      }
      var arr = []
      for(var i=0; i < 10; i++){
       var dt = new Date();
       dt.setDate(dt.getDate() + i);
       arr.push(dt);
      }
      cal.highlight(arr);
    };
    return new HeatMap();
  }

  function initCalendar(viewType, controller) {
    var calendarId = ["div#", viewType, "Calendar"].join("");

    A.element(calendarId).fullCalendar({
      header: {
        left: 'prev,next',
        center: 'title',
        right: 'month,agendaWeek,agendaDay'
      },
      allDayDefault: true,
      eventLimit: 5,
      businessHours: true,
      editable: false,
      handleWindowResize: true,
      height: getHeight() + 30,
      eventClick: function(calEvent, jsEvent, view) {
        controller.goDetail(calEvent);
     },
     eventMouseover: function(calEvent, jsEvent, view) {
        A.element(this).css("background-color","#00396B")
            .css("color","#FFFFFF");
     },
     eventMouseout: function(calEvent, jsEvent, view) {
        A.element(this).css("background-color","steelblue");
     }
    });
    A.element("div#pageBody").find("div.cm-article-body").height(getHeight() + 30);
  }

  function initHeatMap(viewType){
    var heatMapId = ["div#", viewType, "HeatMap"].join("");
    _calendarHeatMapManager = new CalendarHeatMapManager(heatMapId, viewType);
  }

  function downloadCSVFromServer(viewType, window, scope) {
    var url, params = [], query = getQuery(scope);
    params.push("type=" + viewType);
    if (!!query.client) {
        params.push("client=" + query.client);
    }
    if (!!query.retailer) {
        params.push("retailer=" + query.retailer);
    }
    if (!!query.location) {
        params.push("location=" + query.location);
    }
    if (!!query.projectType) {
        params.push("projectType=" + query.projectType);
    }
    if (!!query.projectStatus){
        params.push("projectStatus=" + encodeURIComponent(query.projectStatus));
    }
    if (!!query.startDate) {
        params.push("startDate=" + encodeURIComponent(query.startDate));
    }
    if (!!query.endDate) {
        params.push("endDate=" + encodeURIComponent(query.endDate));
    }
    if (!!query.project){
        params.push("project=" + query.project);
    }
    if (!!query.market && !isNaN(parseInt(query.market))){
        params.push("market=" + query.market);
    }
    if (!!query.region && isNan(parseInt(query.region))){
        params.push("region=" + query.region);
    }
    if (!!query.projectTitle){
        params.push("projectTitle=" + encodeURIComponent(query.projectTitle));
    }
    if (!!query.canSchedule && query.canSchedule === "1"){
        params.push("canSchedule=1");
    }

    url = window.location.protocol + "//" + window.location.host + "/apex/LocationReportCSV?" + params.join("&");
    window.open(url, "_blank");
  }

  function routeToProjectDetail(window,event){
    var w = window.innerWidth - 100, h = window.innerHeight - 50, title = "Dialog";
    var dualScreenLeft = window.screenLeft != undefined ? window.screenLeft : screen.left;
    var dualScreenTop = window.screenTop != undefined ? window.screenTop : screen.top;

    var width = window.innerWidth ? window.innerWidth : document.documentElement.clientWidth ? document.documentElement.clientWidth : screen.width;
    var height = window.innerHeight ? window.innerHeight : document.documentElement.clientHeight ? document.documentElement.clientHeight : screen.height;
    var url = "";
    var left = ((width / 2) - (w / 2)) + dualScreenLeft;
    var top = ((height / 2) - (h / 2)) + dualScreenTop;

    if (!!event.cmkId){
       if (event.viewType === "project") {
            title = "Application Dialog - Project";
            url = "/apex/ProjectDetailsView?id=" + event.cmkId;
        } else {
            title = "Application Dialog - Job";
            url = "/" + event.cmkId;
        }

        var newWindow = window.open(url, title, 'scrollbars=yes,location=no,toolbar=no,menubar=no, width=' + w + ', height=' + h + ', top=' + top + ', left=' + left);

        // Puts focus on the newWindow
        if (window.focus) {
            newWindow.focus();
        }

    } else {
      window.alert("The project identifier is not defined. The selected record has an integrity issue. Please contact the CROSSMARK Helpdesk support if the error continues to come up.");
    }
  }

  function initPageHeader(scope){
    scope.dateRangePillModel.setData(scope.filterModel);
    scope.canSchedulePillModel.setData(scope.filterModel);
  }

  A.module("app.location.report", [
      "cmk.web.context",
      "cmk.system.async",
      "cmk.location.report.model",
      "cmk.ui.picklist",
      "cmk.ui.dropdown",
      "cmk.ui.dropdown.area",
      "cmk.ui.lookup",
      "cmk.ui.pill",
      "cmk.ui.pagelet",
      "cmk.ui.busyIndicatorService",
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
          controller: [
            "$scope",
            "$window",
            function($scope, $window) {
            $scope.projectPageletModel = {
              title: "Project List",
              canExpand: true,
              height: getHeight(),
              hi: function($event) {
                alert("hi");
              },
              navBars: [{
                id: "app_export_csv",
                text: "Export to CSV File",
                iconUrl: _path + "/assets/icons/utility-sprite/svg/symbols.svg#download"
              }],
              footerHTML: ""
            };
            showBusy($scope);

            _appModel.findProjects(getQuery($scope)).then(function(data) {
              $scope.projectGridOptions.setData(data);
              hideBusy();
            },function(err){
              console.log(err);
              hideBusy();
            });
            $scope.export_row_type = "all";
            $scope.export_column_type = "all";
            $scope.export_format = "csv";

            $scope.onNavBarClick = function(href) {
              if ($scope.projectGridOptions.data.length < 50) {
                $scope.gridApi.exporter.csvExport($scope.export_row_type, $scope.export_column_type);
              } else {
                downloadCSVFromServer("project", $window, $scope);
              }
            };
            $scope.goDetail = function($event, row) {
                $event.preventDefault();
                if (!!row.entity["Project__r"] && !!row.entity["Project__r"]["Id"]) {
                    routeToProjectDetail($window, {
                        viewType: "project",
                        cmkId: row.entity["Project__r"]["Id"]
                    });
                }
            };

            initPageHeader($scope);
            setViewTypeDisplayType($scope, "project", "table");
          }]
        })
        .state("jobs-table-viewer", {
          url: "/jobs-table-viewer",
          template: '<div class="cm-col-container">' +
            '<div cmk-pagelet="1" options="jobPageletModel" navbar-click="onNavBarClick(href)">' +
            '<div ui-grid="jobGridOptions" class="cm-grid" ui-grid-exporter ui-grid-auto-resize></div>' +
            '</div></div>',
          controller: ["$scope","$window",
            function($scope, $window) {

            showBusy($scope);
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
              if ($scope.jobGridOptions.data.length < 50) {
                $scope.gridApi.exporter.csvExport($scope.export_row_type, $scope.export_column_type);
              } else {
                 downloadCSVFromServer("job", $window, $scope);
              }
            };

            $scope.goDetail = function($event, row) {
                $event.preventDefault();
                if (!!row.entity["Id"]) {
                    routeToProjectDetail($window, {
                        viewType: "job",
                        cmkId: row.entity["Id"]
                    });
                }
            };

            _appModel.findJobs(getQuery($scope)).then(function(data) {
              $scope.jobGridOptions.setData(data);
              hideBusy();
            }, function(err){
              console.log(err);
              hideBusy();
            });

            initPageHeader($scope);
            setViewTypeDisplayType($scope, "job", "table");
          }]
        })
        .state("projects-calendar-viewer", {
          url: "/projects-calendar-viewer",
          template: '<div class="cm-col-container">' +
            '<div cmk-pagelet="1" options="projectCalendarPageletModel" on-resize="onResize(height)">' +
            '<div class="slds-grid cm-row slds-wrap">' +
            '<div class="cm-heatmap"><div id="projectHeatMap"></div></div>' +
            '<div class="cm-full-cal"><div id="projectCalendar"></div></div>' +
            '</div></div></div>',
          controller: ["$scope","$window", function($scope, $window) {
            var self = this;
            showBusy($scope);
            self.goDetail = function(event){
                routeToProjectDetail($window,event);
            };

            $scope.projectCalendarPageletModel = {
              title: "Projects - Calendar ",
              canExpand: true,
              height: getHeight(),
              navBars: [],
              footerHTML: ""
            };
            $scope.onResize = function(height) {
              A.element("div#pageBody").find("div.cm-article-body").height(height);
              A.element("div#projectCalendar").fullCalendar('option', 'height', height - 30);
            };

            _appModel.findProjects(getQuery($scope)).then(function(data) {
              initCalendar("project", self);
              setMonthData("project", data);
              hideBusy();
            }, function (err) {
                console.log(err);
                hideBusy();
            });


            _appModel.findProjectCounts(getQuery($scope)).then(function(data){
                initHeatMap("project");
                setHeatMap(data);
            }, function (err) {
                console.log(err);
            });

            initPageHeader($scope);
            setViewTypeDisplayType($scope, "project", "month");
          }]
        })
        .state("jobs-calendar-viewer", {
          url: "/jobs-calendar-viewer",
          template: '<div class="cm-col-container">' +
            '<div cmk-pagelet="1" options="jobCalendarPageletModel" on-resize="onResize(height)">' +
            '<div class="slds-grid cm-row slds-wrap">' +
            '<div class="cm-heatmap"><div id="jobHeatMap"></div></div>' +
            '<div class="cm-full-cal"><div id="jobCalendar"></div></div>' +
            '</div></div></div>',
          controller: ["$scope","$window", function($scope, $window) {
            var self = this;
            showBusy($scope);
            self.goDetail = function (event){
                routeToProjectDetail($window, event);
            };

            $scope.jobCalendarPageletModel = {
              title: "Jobs - Calendar",
              canExpand: true,
              height: getHeight(),
              navBars: [],
              footerHTML: ""
            };
            $scope.onResize = function(height) {
              A.element("div#pageBody").find("div.cm-article-body").height(height);
               A.element("div#jobCalendar").fullCalendar('option', 'height', height - 30);
            };

            _appModel.findJobs(getQuery($scope)).then(function(data) {
              initCalendar("job", self);
              setMonthData("job", data);
              hideBusy();
            }, function(err){
                console.log(err);
                hideBusy();
            });

             _appModel.findJobCounts(getQuery($scope)).then(function(data){
                initHeatMap("job");
                setHeatMap(data);
                hideBusy();
            }, function (err) {
                console.log(err);
                hideBusy();
            });

            initPageHeader($scope);
            setViewTypeDisplayType($scope, "job", "month");
          }]
        });
    }])
  .controller('LocationReportController', [
    '$scope',
    '$state',
    'cmkWebContext',
    '$log',
    'cmkLocationReportModel',
    '$timeout',
    'cmkBusyIndicatorService',
    function($scope, $state, webContext, $log, appModel, $timeout, busyIndicatorService) {
    var scope = $scope;
    _busyIndicatorService = busyIndicatorService;

    _path = webContext.staticResourcePath;
    _appModel = appModel;
    scope.objectTypeViewModel = new ViewTypeModel();
    scope.displayActionModel = new DisplayActionModel();
    scope.filterModel = new FilterModel(appModel);
    scope.filterModel.retailer = webContext.defaultRetailer;
    scope.projectTitlePillModel = new PillModel("projectTitle", "", "", true);
    scope.executionCompanyPillModel = new PillModel("executionCompany","","",true);
    scope.clientPillModel = new PillModel("client", "", "", true);
    scope.retailerPillModel = new PillModel("retailer", "", "", true);
    scope.locationPillModel = new PillModel("location", "", "", true);
    scope.projectNumberPillModel = new PillModel("projectNumber","","",true);
    scope.canSchedulePillModel = new PillModel("canSchedule","","",true);
    scope.marketPillModel = new PillModel("market","","",true);
    scope.regionPillModel = new PillModel("region","","",true);
    scope.projectTypePillModel = new PillModel("projectType", "", "", true);
    scope.dateRangePillModel = new DateRangePillModel("", "", true);
    scope.projectStatusPillModel = new PillModel("projectStatus","","",true);
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

    function watchFilterModelProperty(name, minChars){
      var size = minChars || 0;
      scope.$watch("filterModel." + name, function(newValue, oldValue){
        var isRun = 0;
            if (newValue !== oldValue) {
            if (typeof newValue === "boolean"){
              isRun = 1;
            } else if (typeof newValue === "string"){
              if (size < 1) {
                isRun = 1;
              } else {
                if (!newValue || newValue.length >= size){
                  isRun = 1;
                }
              }
            } else {
              isRun = 1;
            }
            if (isRun){
              scope[name + "PillModel"].setData(scope.filterModel);
              handleFilter(scope, $log, appModel,busyIndicatorService);
            }
        }

      });
    }

    function bootstrap() {
      watchFilterModelProperty("projectTitle",3);
      watchFilterModelProperty("market");
      watchFilterModelProperty("region");
      watchFilterModelProperty("canSchedule");
      watchFilterModelProperty("executionCompany");
   }

    scope.initFilter = function() {
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
      handleFilter(scope, $log, appModel,busyIndicatorService);
    };

    scope.onRetailerRemove = function() {
      scope.retailerPillModel.hide();
      scope.filterModel.resetSelection("retailer");
      handleFilter(scope, $log, appModel, busyIndicatorService);
    };

    scope.lookupClients = function(keyword) {
      scope.filterModel.findClients(keyword);
    };

    scope.clientChanged = function() {
      scope.clientPillModel.setData(scope.filterModel);
      handleFilter(scope, $log, appModel,busyIndicatorService);
    };

    scope.lookupProjectStatus = function(keyword){
        scope.filterModel.findProjectStatus(keyword);
    };

    scope.projectStatusChanged = function(keyword){
        scope.projectStatusPillModel.setData(scope.filterModel);
        handleFilter(scope, $log, appModel, busyIndicatorService);
    };

    scope.onProjectStatusRemove = function(){
        scope.projectStatusPillModel.hide();
        scope.filterModel.resetSelection("projectStatus");
        handleFilter(scope, $log, appModel, busyIndicatorService);
    };

    scope.onProjectTitleRemove = function() {
        scope.projectTitlePillModel.hide();
        scope.filterModel.projectTitle = "";
        handleFilter(scope, $log, appModel, busyIndicatorService);
    };

    scope.onClientRemove = function() {
      scope.clientPillModel.hide();
      scope.filterModel.resetSelection("client");
      handleFilter(scope, $log, appModel, busyIndicatorService);
    };

    scope.lookupProjectTypes = function(keyword) {
      scope.filterModel.findProjectTypes(keyword);
    };

    scope.projectTypeChanged = function() {
      scope.projectTypePillModel.setData(scope.filterModel);
      handleFilter(scope, $log, appModel, busyIndicatorService);
    };

    scope.onProjectTypeRemove = function() {
      scope.projectTypePillModel.hide();
      scope.filterModel.resetSelection("projectType");
      handleFilter(scope, $log, appModel, busyIndicatorService);
    };

    scope.lookupProjectNumbers = function(keyword){
        var q = getQuery(scope);
        q.ProjectNumber = keyword;
        scope.filterModel.findProjectNumbers(q);
    };

    scope.projectNumberChanged = function(){
        scope.projectNumberPillModel.setData(scope.filterModel);
        handleFilter(scope, $log, appModel, busyIndicatorService);
    };

    scope.onProjectNumberRemove = function(){
        scope.projectNumberPillModel.hide();
        scope.filterModel.resetSelection("projectNumber");
        handleFilter(scope, $log, appModel, busyIndicatorService);
    };

    scope.lookupLocations = function(keyword) {
      scope.filterModel.findLocations({
        keyword: keyword,
        retailer: scope.filterModel.retailer
      });
    };

    scope.locationChanged = function() {
      scope.locationPillModel.setData(scope.filterModel);
      handleFilter(scope, $log, appModel, busyIndicatorService);
    };

    scope.onLocationRemove = function() {
      scope.locationPillModel.hide();
      scope.filterModel.resetSelection("location");
      handleFilter(scope, $log, appModel, busyIndicatorService);
    };

    scope.onMarketRemove = function() {
        scope.marketPillModel.hide();
        scope.filterModel.market = "";
        handleFilter(scope, $log, appModel, busyIndicatorService);
    };

    scope.onRegionRemove = function() {
        scope.regionPillModel.hide();
        scope.filterModel.region = "";
        handleFilter(scope, $log, appModel, busyIndicatorService);
    };

    scope.onCanScheduleRemove = function(){
        scope.canSchedulePillModel.hide();
        scope.filterModel.canSchedule = "";
    };

    scope.startDateChanged = function() {
      scope.dateRangePillModel.setData(scope.filterModel);
      handleFilter(scope, $log, appModel, busyIndicatorService);
    };

    scope.onDateRangeRemove = function() {
      scope.filterModel.startDate = "";
      scope.filterModel.endDate = "";
      scope.dateRangePillModel.setData(scope.filterModel);
      handleFilter(scope, $log, appModel, busyIndicatorService);
    };

    scope.endDateChanged = function() {
      scope.dateRangePillModel.setData(scope.filterModel);
      handleFilter(scope, $log, appModel, busyIndicatorService);
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
    };


    bootstrap();

  }]);

})(angular);
