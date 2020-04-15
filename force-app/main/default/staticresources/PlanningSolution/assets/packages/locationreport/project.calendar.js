(function(A) {
    "use strict";
    var _busyIndicatorService;
    var CALENDAR_HEIGHT = 560;
    var EVENT_FITLER_CHANGED = 'filter_changed';
    var DEFAULT_VIEW_TYPE = 'job';
    var DEFAULT_VIEW_TYPE_VALUE = 'Job View';
    var _path, _appModel, _calendarHeatMapManager;
    var _fullCalendarId = undefined;
    var _defaultRecordState = {
        key: 'BOTH',
        value: 'Both'
    };
    var _dataAdapter = new DataAdapter();

    function showBusy(scope) {
        _busyIndicatorService.show(scope, {
            containerId: "div#pageBody"
        });
    }

    function hideBusy() {
        _busyIndicatorService.hide();
    }

    function getHeight() {
        var h = window.innerHeight - A.element("div#pageBody").offset().top;
        return (h > 400) ? h : 400;
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
        query.recordState = m.recordState || "";
        query.theme = m.theme || "";
        query.tier = m.tier || "";
        query.projectOwner = m.projectOwner || "";
        query.executionCompany = m.executionCompany || "";

        return query;
    }

    function assignReservceLocationCount(data) {
        var rs1 = data[0],
            rs2 = data[1];
        var i, counts, rec, result = [];
        rs1.pItems.forEach(function(r) {
            rec = {};
            for (i = 0; i < rs1.pFields.length; i++) {
                rec[rs1.pFields[i]] = r[i];
            }
            counts = rs2.pItems.filter(function(e) {
                return e[0] === rec['Id'];
            });
            if (counts.length > 0) {
                rec['Count'] = counts[0][1];
                rec['Capacity'] = counts[0][2];
            }
            result.push(rec);
        });
        return result;
    }

    function DataAdapter() {
        this.source = undefined;
    }

    DataAdapter.toDate = function(dbDate) {
        if (isFinite(dbDate)) {
            return moment(dbDate).add(1,'days').toDate();

        } else {
            return "-";
        }
    }

    DataAdapter.prototype.setSource = function(source) {
        this.source = source;
        return this;
    };

    DataAdapter.prototype.normalize = function(fields) {
        var val, rec, rs;

        rs = _.map(this.source, function(e) {
            rec = {};
            fields.forEach(function(colName) {
                if (colName.indexOf('Date') !== -1) {
                    rec[colName] = DataAdapter.toDate(e[colName]);
                } else {
                    if (isFinite(e[colName])) {
                        rec[colName] = e[colName];
                    } else {
                        val = e[colName] + '';
                        rec[colName] = val.indexOf("&") !== -1 ? A.element("<span></span>").html(val).text() : val;
                    }
                }
            });
            return rec;
        });
        return rs;
    }

    DataAdapter.prototype.normalizeForHeatmap = function() {
        var counts = [],
            logs = [],
            data = this.source,
            cursor,
            year, month, day, dt, key, dtFrom, dtTo;
        //step 1: flatout date range
        function flatoutDateRange(startDate, endDate) {
            var flatoutResult = [],
                flatoutDate = startDate;
            while (flatoutDate <= endDate) {
                key = Math.floor(flatoutDate.getTime() / 1000) + '';
                flatoutResult.push(key);
                flatoutDate.setDate(flatoutDate.getDate() + 1);
            }
            return flatoutResult;
        }

        //step 2: counnt
        _.forEach(this.source, function(r) {
            dtFrom = DataAdapter.toDate(r.StartDate);
            dtTo = DataAdapter.toDate(r.EndDate);
            if (dtFrom !== '-' && dtTo !== '-') {
                _.forEach(flatoutDateRange(dtFrom, dtTo), function(key) {
                    if (isFinite(counts[key])) {
                        counts[key] += 1;
                    } else {
                        counts[key] = 1;
                    }
                });
            }
        });
        return counts;
    };
    DataAdapter.prototype.normalizeForFullCalendar = function(viewType) {
        var events = [],
            isJob = viewType === "project" ? 0 : 1,
            allDay = isJob ? false : true;

        function transformTime(time) {
            var tm, hr, min, dif = 0,
                isAM = 0;
            if (!!time) {
                if (time.indexOf("am") !== -1) {
                    time = time.replace("am", "");
                    isAM = 1;
                } else if (time.indexOf("pm") !== -1) {
                    time = time.replace("pm", "");
                }
                var tm = time.match(/\d{1,2}/g);
                if (tm.length === 2) {
                    hr = parseInt(tm[0]);
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
        _.forEach(this.source, function(rec) {
            var ms1, type, dt1, dt2, tm1, tm2, title;

            dt1 = rec.StartDate;
            dt2 = rec.EndDate;
            if (!allDay) {
                tm1 = transformTime(rec.StartTime);
                tm2 = transformTime(rec.EndTime);
            } else {
                tm1 = {
                    hr: 0,
                    min: 0
                };
                tm2 = {
                    hr: 23,
                    min: 59
                };
            }


            if ((!!dt1 && isFinite(dt1)) && (!!dt2 && isFinite(dt2))) {
                dt1 = moment(dt1).add(1,'days').hours(tm1.hr).minutes(tm1.min).seconds(0).milliseconds(0).toISOString();
                dt2 = moment(dt2).add(1,'days').hours(tm2.hr).minutes(tm2.min).seconds(0).milliseconds(0).toISOString();
               
                if (isJob) {
                    title = rec.LocationNumber + ': ' + rec.ProjectName;
                } else {
                    title = rec.Name || '-';
                }

                title = (title.indexOf("&") !== -1) ? A.element("<span></span>").html(title).text() : title;

                events.push({
                    cmkId: rec.Id || "",
                    viewType: viewType,
                    title: '',
                    start: dt1,
                    end: dt2,
                    color: 'steelblue',
                    allDay: allDay,
                    data: {
                        title: title
                    }
                });
            }
        });
        return events;
    };

    function getProjectGridOption($scope) {
        var fields = _appModel.getProjectFields();

        var options = {
            data: [],
            setData: function(data) {
                options.data = _dataAdapter.setSource(data).normalize(fields);
            },
            columnDefs: [{
                displayName: "Project Id",
                field: "ProjectNumber",
                type: 'number',
                cellTemplate: '<div class="cm-cell"><a href="#" ng-click="grid.appScope.goDetail($event, row)"><span ng-bind-html="COL_FIELD"></span></a></div>'
            }, {
                displayName: "Project Name",
                field: "Name",
                cellTemplate: '<div class="cm-cell"><span ng-bind-html="COL_FIELD"></span></div>'
            }, {
                displayName: "Owner",
                field: "Owner",
                cellTemplate: '<div class="cm-cell"><span ng-bind-html="COL_FIELD"></span></div>'
            }, {
                displayName: "Retailer",
                field: "RetailerName",
                cellTemplate: '<div class="cm-cell"><span ng-bind-html="COL_FIELD"></span></div>'
            }, {
                displayName: "Account",
                field: "ClientName",
                cellTemplate: '<div class="cm-cell"><span ng-bind-html="COL_FIELD"></span></div>'
            }, {
                displayName: "Proj. Start Date",
                field: "StartDate",
                type: 'date',
                cellTemplate: '<div class="cm-cell"><span>{{COL_FIELD !== null && COL_FIELD !== "-" ? COL_FIELD.format("/") : COL_FIELD}}</span></div>'
            }, {
                displayName: "Proj. End Date",
                field: "EndDate",
                type: 'date',
                cellTemplate: '<div class="cm-cell"><span>{{COL_FIELD !== null && COL_FIELD !== "-" ? COL_FIELD.format("/") : COL_FIELD}}</span></div>'
            }, {
                displayName: "Status",
                field: "Status",
                cellTemplate: '<div class="cm-cell"><span ng-bind="COL_FIELD"></span></div>'
            }, {
                displayName: "Split Type",
                field: "SplitType",
                cellTemplate: '<div class="cm-cell"><span ng-bind="COL_FIELD"></span></div>'
            }, {
                displayName: "Reserved Locations",
                field: "ReservedLocationsCount",
                type: 'number',
                cellTemplate: '<div class="cm-cell"><span ng-bind="COL_FIELD"></span></div>'
            }, {
                displayName: "Total Locations",
                field: "TotalProjectLocations",
                type: 'number',
                cellTemplate: '<div class="cm-cell"><span ng-bind="COL_FIELD"></span></div>'
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
        var fields = _appModel.getJobFields();
        var options = {
            data: [],
            setData: function(data) {
                options.data = _dataAdapter.setSource(data).normalize(fields);
            },
            columnDefs: [{
                displayName: "Location #",
                field: "LocationNumber",
                cellTemplate: '<div class="cm-cell"><a href="#" ng-click="grid.appScope.goDetail($event,row)"><span ng-bind-html="COL_FIELD"></span></a></div>'
            }, {
                displayName: "Address",
                field: "Address",
                cellTemplate: '<div class="cm-cell"><span ng-bind-html="COL_FIELD"></span></div>'
            }, {
                displayName: "City",
                field: "City",
                cellTemplate: '<div class="cm-cell"><span ng-bind-html="COL_FIELD"></span></div>'
            }, {
                displayName: "State",
                field: "State",
                cellTemplate: '<div class="cm-cell"><span ng-bind-html="COL_FIELD"></span></div>'
            }, {
                displayName: "Project Id",
                field: "ProjectId",
                cellTemplate: '<div class="cm-cell"><span ng-bind="COL_FIELD"></span></div>'
            }, {
                displayName: "Project Title",
                field: "ProjectName",
                cellTemplate: '<div class="cm-cell"><span ng-bind-html="COL_FIELD"></span></div>'
            }, {
                displayName: "Owner",
                field: "ProjectOwner",
                cellTemplate: '<div class="cm-cell"><span ng-bind="COL_FIELD"></span></div>'
            }, {
                displayName: "Source Id",
                field: "ProjectSourceId",
                cellTemplate: '<div class="cm-cell"><span ng-bind-html="COL_FIELD"></span></div>'
            }, {
                displayName: "Account",
                field: "AccountName",
                cellTemplate: '<div class="cm-cell"><span ng-bind-html="COL_FIELD"></span></div>'
            }, {
                displayName: "Orig Sched Date",
                field: "StartDate",
                type: 'date',
                cellTemplate: '<div class="cm-cell"><span>{{COL_FIELD !== null && COL_FIELD !== "-" ? COL_FIELD.format("/") : COL_FIELD}}</span></div>'
            }, {
                displayName: "ReSched Date",
                field: "ScheduledDate",
                type: 'date',
                cellTemplate: '<div class="cm-cell"><span>{{COL_FIELD !== null && COL_FIELD !== "-" ? COL_FIELD.format("/") : COL_FIELD}}</span></div>'
            }, {
                displayName: "Status",
                field: "Status",
                cellTemplate: '<div class="cm-cell"><span ng-bind="COL_FIELD"></span></div>'
            }, {
                displayName: "Exec. Status",
                field: "ExecuteStatus",
                cellTemplate: '<div class="cm-cell"><span ng-bind="COL_FIELD"></span></div>'
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

            if (!model[self.eventId + "Model"]) {
                self.title = self.dataId;
            } else if (!!model[self.eventId + "Model"].selRow) {
                self.title = model[self.eventId + "Model"].selRow.value
            } else if (!!model[self.eventId + "Model"].option) {
                self.title = model[self.eventId + "Model"].option.value;
            } else {
                self.title = self.dataId;
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
            _themes,
            _tiers,
            _self = {};

        function initDate() {
            var month, startMonth, endMonth, endDate, today = new Date();
            startMonth = today.getMonth();
            month = "0" + (startMonth + 1);
            _self.startDate = [month.length < 3 ? month : month.substr(1, 2), "01", today.getFullYear() + ""].join("/");

            var selDt = 28;
            var e = new Date(today.setMonth(startMonth + 2, selDt));
            var result = e;
            endMonth = e.getMonth();
            while (e.getMonth() === endMonth) {
                selDt++;
                result = new Date(e.getTime());
                e = new Date(e.setDate(selDt));
            }
            month = "0" + (result.getMonth() + 1);
            endDate = "0" + result.getDate();
            _self.endDate = [month.length < 3 ? month : month.substr(1, 2), endDate.length < 3 ? endDate : endDate.substr(1, 2), result.getFullYear() + ""].join("/");
        }

        _self.client = "";
        _self.retailer = "";
        _self.location = "";
        _self.projectTitle = "";
        _self.projectOwner = "";
        _self.projectType = "";
        _self.startDate = "";
        _self.endDate = "";
        _self.projectStatus = "";
        _self.projectNumber = "";
        _self.market = "";
        _self.region = "";
        _self.theme = "";
        _self.tier = "";
        _self.canSchedule = true;
        _self.executionCompany = "";
        _self.recordState = _defaultRecordState.key;
        _self.clientModel = undefined;
        _self.retailerModel = undefined;
        _self.locationModel = undefined;
        _self.projectOwnerModel = undefined;
        _self.projectTypeModel = undefined;
        _self.projectStatusModel = undefined;
        _self.projectNumberModel = undefined;
        _self.marketModel = undefined;
        _self.regionModel = undefined;
        _self.themeModel = undefined;
        _self.tierModel = undefined;
        _self.recordStateModel = new RecordStateViewModel(_defaultRecordState);
        _self.executionCompanyModel = new ExecutionCompanyViewModel();
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

        _self.findProjectStatus = function(keyword) {
            if (!_statusList) {
                _model.getStatusList().then(function(data) {
                    _statusList = data;
                    _self.projectStatusModel = {
                        rowset: data,
                        selRow: {
                            key: "",
                            value: ""
                        }
                    };
                    _self.projectStatusModel.rowset = doLookup(_statusList, keyword);
                });
            } else {
                _self.projectStatusModel.rowset = doLookup(_statusList, keyword);
            }
        };

        _self.findProjectNumbers = function(query) {
            _model.findProjectNumbers(query).then(function(data) {
                _self.projectNumberModel.rowset = _.map(data, function(d) {
                    return {
                        Id: d.ProjectNumber__c,
                        ProjectNumber: d.ProjectNumber__c,
                        Name: d.Name,
                        Status: d.Status__c
                    };
                });
                if (!_self.projectNumberModel.selRow) {
                    _self.projectNumberModel.selRow = {
                        key: "",
                        value: ""
                    };
                }
            });
        };

        _self.findUsers = function(name) {
            _model.findUsers(name).then(function(data) {
                _self.projectOwnerModel.rowset = data.users || [];
                if (!_self.projectOwnerModel.selRow) {
                    _self.projectOwnerModel.selRow = {
                        key: "",
                        value: ""
                    };
                }
            })
        }

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
            if (!_projectTypes) {
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

        _self.findThemes = function(keyword) {
            if (!!_themes) {
                _self.themeModel.rowset = doLookup(_themes, keyword);
            } else {
                _model.getThemes()
                    .then(
                        function(data) {
                            _themes = data;
                            _self.themeModel = {
                                selRow: {
                                    key: '',
                                    value: ''
                                },
                                rowset: []
                            };
                            _self.themeModel.rowset = doLookup(_themes, keyword);
                        }
                    );
            }
        };

        _self.findTiers = function(keyword) {
            if (!!_tiers) {
                _self.tierModel.rowset = doLookup(_tiers, keyword);
            } else {
                _model.getTiers()
                    .then(function(data) {
                        _tiers = data;
                        _self.tierModel = {
                            selRow: {
                                key: '',
                                value: ''
                            },
                            rowset: []
                        };
                        _self.tierModel.rowset = doLookup(_tiers, keyword);
                    });
            }
        };
        /*
        _self.findMarkets = function(keyword) {
            if (!!_markets) {
                _self.marketModel.rowset = doLookup(_markets, keyword);
            } else {
                _model.getMarkets().then(function(data) {
                    _markets = data;
                    _self.marketModel = {
                        selRow: {
                            key: "",
                            value: ""
                        },
                        rowset: data
                    };
                    _self.marketModel.rowset = doLookup(_markets, keyword);
                });
            }
        };

        _self.findRegions = function(keyword) {
            if (!!_regions) {
                _self.regionModel.rowset = doRegionLookup(keyword);
            } else {
                _model.getRegions().then(function(data) {
                    _regions = data;
                    _self.regionModel = {
                        selRow: {
                            key: "",
                            value: ""
                        },
                        rowset: []
                    };
                    _self.regionModel.rowset = doRegionLookup(keyword);
                });
            }
        };
        */
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
            key: DEFAULT_VIEW_TYPE,
            value: DEFAULT_VIEW_TYPE_VALUE
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

    function ExecutionCompanyViewModel() {
        var self = this;
        this.option = {
            key: '',
            value: ''
        };
        this.options = [{
            key: 'CROSSMARK',
            value: 'CROSSMARK'
        }, {
            key: 'ASM',
            value: 'ASM'
        }, {
            key: 'BOTH',
            value: 'Both'
        }];

        this.reset = function(key) {
            _.forEach(self.options, function(opt) {
                if (opt.key === key) {
                    opt.selected = true;
                } else {
                    opt.selected = false;
                }
            });
        };
    }

    function RecordStateViewModel(option) {
        var self = this;
        this.options = [{
            key: 'LOCKED',
            value: 'Locked'
        }, {
            key: 'UNLOCKED',
            value: 'Unlocked'
        }, {
            key: 'BOTH',
            value: 'Both'
        }];
        this.option = option || {
            key: '',
            value: ''
        };
        this.reset = function(key) {
            _.forEach(self.options, function(opt) {
                if (opt.key === key) {
                    opt.selected = true;
                } else {
                    opt.selected = false;
                }
            });
        };
    }

    function resetHeadMapWidth() {
        setTimeout(function() {
            A.element('.cal-heatmap-container').width(200);
        }, 1000);
    }


    function setHeatMap(data, viewType) {
        var counts = _dataAdapter.setSource(data).normalizeForHeatmap();
        _calendarHeatMapManager.render(counts);
        resetHeadMapWidth();
    }

    function getHeatMapCustomSettings(viewType) {

        if (viewType === 'project') {
            return {
                id: "div#projectHeatMap",
                legend: [10, 20, 30, 40, 50],
                legendColor: {
                    max: "#1A237E",
                    min: "#E8EAF6",
                    empty: "white",
                    overflow: "#B71C1C"
                },
                itemName: ['project', 'projects']
            };
        }

        if (viewType === 'job') {
            return {
                id: "div#jobHeatMap",
                legend: [10, 50, 80, 120, 200, 300, 500],
                legendColor: {
                    max: "#1A237E",
                    min: "#E8EAF6",
                    empty: "white",
                    overflow: "#B71C1C"
                },
                itemName: ['job', 'jobs']
            };
        }
    }


    function CalendarHeatMapManager(selId, viewType, custSettings) {
        var legend, legendColor, cal = undefined,
            calendarId = ["div#", viewType, "Calendar"].join(""),
            prevSelId = ["#", viewType, "HeatMap", "-g-PreviousDomain-selector"].join(""),
            nextSelId = ["#", viewType, "HeatMap", "-g-NextDomain-selector"].join(""),
            custSettings = custSettings || getHeatMapCustomSettings(viewType),
            heatMapId = custSettings.id;

        function HeatMap() {}
        HeatMap.prototype.render = function(data) {
            if (!!cal) {
                cal.update(data);
                return;
            }
            cal = new CalHeatMap();
            cal.init({
                itemSelector: selId,
                domain: "month",
                subDomain: "x_day",
                data: data,
                weekStartOnMonday: true,
                legend: custSettings.legend,
                legendColors: custSettings.legendColor,
                itemName: custSettings.itemName || '',
                legendVerticalPosition: "top",
                legendMargin: [0, 0, 5, 0],
                cellSize: 24,
                cellPadding: 4,
                verticalOrientation: true,
                cellRadius: 0,
                considerMissingDataAsZero: false,
                range: custSettings.range || 3,
                displayLabel: false,
                domainLabelFormat: '%m-%Y',
                domainDynamicDimension: true,
                subDomainTitleFormat: custSettings.subDomainTitleFormat || {},
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
                onComplete: function() {
                    A.element(heatMapId).slimScroll({
                        position: "right",
                        color: "#aaa",
                        railColor: "#ddd",
                        railVisible: true,
                        size: "10px",
                        height: 560,
                        alwaysVisible: false
                    });
                },
                subDomainTextFormat: "%d"
            });
        };

        return new HeatMap();
    }

    function fullCalendarResize() {
        if (!_fullCalendarId) {
            return; }
        window.setTimeout(function() {
            var height = A.element('.cm-article-body').height() - 50;
            A.element(_fullCalendarId).fullCalendar('option', 'contentHeight', height);
        }, 100);
    }

    function setMonthData(viewType, data) {
        var calendarId = ["div#", viewType, "Calendar"].join(""),
            events,
            calendarTarget = A.element(calendarId);
        events = _dataAdapter.setSource(data).normalizeForFullCalendar(viewType);
        calendarTarget.fullCalendar('removeEvents');
        calendarTarget.fullCalendar('addEventSource', events);
        fullCalendarResize();
    }

    function createEventHTML(event, element, view) {
        return A.element(['<span class="cm-job-item">', event.data.title, "</span>"].join(''));
    }

    function initCalendar(viewType, controller) {
        var calendarId = ["div#", viewType, "Calendar"].join("");
        _fullCalendarId = calendarId;
        A.element(calendarId).fullCalendar({
            header: {
                left: 'prev,next',
                center: 'title',
                right: 'month,agendaWeek,agendaDay'
            },
            timezone: 'UTC',
            allDayDefault: true,
            eventLimit: 5,
            businessHours: true,
            editable: false,
            handleWindowResize: true,
            height: getHeight(),
            eventRender: function(event, element, view) {
                return createEventHTML(event, element, view);
            },
            eventClick: function(calEvent, jsEvent, view) {
                jsEvent.preventDefault();
                controller.goDetail(calEvent);
            },
            eventMouseover: function(calEvent, jsEvent, view) {
                A.element(this).css("background-color", "#00396B")
                    .css("color", "#FFFFFF");
            },
            eventMouseout: function(calEvent, jsEvent, view) {
                A.element(this).css("background-color", "steelblue");
            },
            windowResize: function(view) {
                fullCalendarResize();
            }
        });
    }

    function initHeatMap(viewType) {
        var heatMapId = ["div#", viewType, "HeatMap"].join("");
        _calendarHeatMapManager = new CalendarHeatMapManager(heatMapId, viewType);
    }

    function downloadCSVFromServer(viewType, window, scope) {
        var url, params = [],
            query = getQuery(scope);
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
        if (!!query.projectStatus) {
            params.push("projectStatus=" + encodeURIComponent(query.projectStatus));
        }
        if (!!query.startDate) {
            params.push("startDate=" + encodeURIComponent(query.startDate));
        }
        if (!!query.endDate) {
            params.push("endDate=" + encodeURIComponent(query.endDate));
        }
        if (!!query.project) {
            params.push("project=" + query.project);
        }
        if (!!query.market && !isNaN(parseInt(query.market))) {
            params.push("market=" + query.market);
        }
        if (!!query.region && isNan(parseInt(query.region))) {
            params.push("region=" + query.region);
        }
        if (!!query.projectTitle) {
            params.push("projectTitle=" + encodeURIComponent(query.projectTitle));
        }
        if (!!query.canSchedule && query.canSchedule === "1") {
            params.push("canSchedule=1");
        }

        url = window.location.protocol + "//" + window.location.host + "/apex/LocationReportCSV?" + params.join("&");
        window.open(url, "_blank");
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
            if (event.viewType === "project") {
                title = "Application Dialog - Project";
                url = "/apex/ProjectDetailsView?id=" + event.cmkId;
            } else {
                title = "Application Dialog - " + event.viewType;
                url = "/" + event.cmkId;
            }
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

    function windowOnResize($window) {
        A.element($window).off('resize').on('resize', function() {
            var width = A.element(this).width();
            A.element('.cm-col-container').width(width - 50);
            A.element('.cm-grid').width(width - 60);
        });
    }

    function initPageHeader(scope) {

        if (!!scope.filterModel.projectNumber) {
            scope.filterModel.startDate = '';
            scope.filterModel.endDate = '';
            scope.filterModel.projectNumberModel.selRow = {
                key: scope.filterModel.projectNumber,
                value: scope.filterModel.projectNumber
            };
            scope.projectNumberPillModel.setData(scope.filterModel);
        } else {
            scope.dateRangePillModel.setData(scope.filterModel);
            scope.recordStatePillModel.setData(scope.filterModel);
        }
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

            _urlRouter.otherwise("/jobs-table-viewer");
            //_urlRouter.otherwise("/projectcalendar-calendar-viewer");
                      
            DEFAULT_VIEW_TYPE = 'job';
            _stateProvider
                .state("projects-table-viewer", {
                    url: "/projects-table-viewer",
                    template: '<div class="cm-col-container">' +
                        '<div cmk-pagelet="1" options="projectPageletModel" navbar-click="onNavBarClick(href)">' +
                        '<div ui-grid="projectGridOptions" class="cm-grid" ui-grid-exporter="" ui-grid-auto-resize=""></div>' +
                        '</div></div>',
                    controller: [
                        "$scope",
                        "$window",
                        function($scope, $window) {
                            _fullCalendarId = undefined;
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
                            showBusy($scope);
                            windowOnResize($window);

                            _appModel.findProjects(getQuery($scope)).then(function(data) {
                                $scope.projectGridOptions.setData(data);
                                hideBusy();
                                var c = A.element('.cm-col-container');
                                c.width(c.width());
                            }, function(err) {
                                console.log(err);
                                hideBusy();
                            });
                            $scope.projectGridOptions = getProjectGridOption($scope);
                            $scope.export_row_type = "all";
                            $scope.export_column_type = "all";
                            $scope.export_format = "csv";

                            $scope.$on(EVENT_FITLER_CHANGED, function(event, args) {
                                _appModel.findProjects(args.query).then(function(data) {
                                    $scope.projectGridOptions.setData(data);
                                }).finally(function() {
                                    hideBusy();
                                });
                            });

                            $scope.onNavBarClick = function(href) {
                                $scope.gridApi.exporter.csvExport($scope.export_row_type, $scope.export_column_type);
                            };
                            $scope.goDetail = function($event, row) {
                                $event.preventDefault();
                                if (!!row.entity["Id"]) {
                                    routeToProjectDetail($window, {
                                        viewType: "project",
                                        cmkId: row.entity["Id"]
                                    });
                                }
                            };

                            initPageHeader($scope);
                            setViewTypeDisplayType($scope, "project", "table");
                        }
                    ]
                })
                .state("jobs-table-viewer", {
                    url: "/jobs-table-viewer",
                    template: '<div class="cm-col-container">' +
                        '<div cmk-pagelet="1" options="jobPageletModel" navbar-click="onNavBarClick(href)">' +
                        '<div ui-grid="jobGridOptions" class="cm-grid" ui-grid-exporter="" ui-grid-auto-resize=""></div>' +
                        '</div></div>',
                    controller: ["$scope", "$window",
                        function($scope, $window) {
                            _fullCalendarId = undefined;
                            windowOnResize($window);
                            showBusy($scope);
                            $scope.jobPageletModel = {
                                title: "Scheduled Store List",
                                canExpand: true,
                                height: getHeight(),
                                navBars: [{
                                    id: "app_export_csv",
                                    text: "Export to CSV File",
                                    iconUrl: _path + "/assets/icons/utility-sprite/svg/symbols.svg#download"
                                }],
                                footerHTML: ""
                            };
                            $scope.jobGridOptions = getJobGridOption($scope);
                            $scope.export_row_type = "all";
                            $scope.export_column_type = "all";
                            $scope.export_format = "csv";

                            $scope.$on(EVENT_FITLER_CHANGED, function(event, args) {
                                _appModel.findJobs(args.query).then(function(data) {
                                    $scope.jobGridOptions.setData(data);
                                }).finally(function() {
                                    hideBusy();
                                });
                            });

                            $scope.onNavBarClick = function(href) {
                                $scope.gridApi.exporter.csvExport($scope.export_row_type, $scope.export_column_type);
                                /*
                                if ($scope.jobGridOptions.data.length < 50) {
                                  $scope.gridApi.exporter.csvExport($scope.export_row_type, $scope.export_column_type);
                                } else {
                                  downloadCSVFromServer("job", $window, $scope);
                                } */
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
                            initPageHeader($scope);

                            _appModel.findJobs(getQuery($scope)).then(function(data) {
                                $scope.jobGridOptions.setData(data);
                                var c = A.element('.cm-col-container');
                                c.width(c.width());
                                hideBusy();
                            }, function(err) {
                                console.log(err);
                                hideBusy();
                            });


                            setViewTypeDisplayType($scope, "job", "table");
                        }
                    ]
                })
                .state("projects-calendar-viewer", {
                    url: "/projects-calendar-viewer",
                    template: '<div class="cm-col-container">' +
                        '<div cmk-pagelet="1" options="projectCalendarPageletModel" on-resize="onResize(height)">' +
                        '<div class="slds-grid cm-row slds-wrap">' +
                        '<div class="cm-heatmap"><div id="projectHeatMap"></div></div>' +
                        '<div class="cm-full-cal"><div id="projectCalendar"></div></div>' +
                        '</div></div></div>',
                    controller: ["$scope", "$window", function($scope, $window) {
                        var self = this;
                        showBusy($scope);
                        self.goDetail = function(event) {
                            routeToProjectDetail($window, event);
                        };

                        $scope.projectCalendarPageletModel = {
                            title: "Projects - Calendar ",
                            canExpand: true,
                            height: getHeight(),
                            navBars: [],
                            footerHTML: ""
                        };

                        $scope.$on(EVENT_FITLER_CHANGED, function(event, args) {
                            _appModel.findProjectsForCalendar(args.query).then(function(data) {
                                setMonthData("project", data);
                                setHeatMap(data);
                            }, function(err) {
                                console.log(err);
                            }).finally(function() {
                                hideBusy();
                            });
                        });

                        _appModel.findProjectsForCalendar(getQuery($scope)).then(function(data) {
                            initCalendar("project", self);
                            setMonthData("project", data);
                            initHeatMap("project");
                            setHeatMap(data);
                        }, function(err) {
                            console.log(err);
                        }).finally(function() {
                            hideBusy();
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
                    controller: ["$scope", "$window", function($scope, $window) {
                        var self = this;
                        showBusy($scope);
                        self.goDetail = function(event) {
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

                        $scope.$on(EVENT_FITLER_CHANGED, function(event, args) {
                            _appModel.findJobs(args.query).then(function(data) {
                                setMonthData("job", data);
                                setHeatMap(data);
                            }, function(err) {
                                console.log(err);
                            }).finally(function() {
                                hideBusy();
                            });
                        });

                        _appModel.findJobs(getQuery($scope)).then(function(data) {
                            initCalendar("job", self);
                            setMonthData("job", data);
                            initHeatMap("job");
                            setHeatMap(data);
                        }, function(err) {
                            console.log(err);
                        }).finally(function() {
                            hideBusy();
                        })
                        initPageHeader($scope);
                        setViewTypeDisplayType($scope, "job", "month");
                    }]
                })
        }])
        .controller('LocationReportController', [
            '$scope',
            '$state',
            'cmkWebContext',
            '$log',
            'cmkLocationReportModel',
            '$timeout',
            '$window',
            'cmkBusyIndicatorService',
            function($scope, $state, webContext, $log, appModel, $timeout, $window, busyIndicatorService) {
                var scope = $scope;
                _busyIndicatorService = busyIndicatorService;
                _path = webContext.staticResourcePath;
                _appModel = appModel;

                scope.path = webContext.staticResourcePath;
                scope.appModel = appModel;
                scope.showBusy = function() {
                    _busyIndicatorService.show(scope, {
                        containerId: "div#pageBody"
                    });
                };
                scope.hideBusy = function() {
                    _busyIndicatorService.hide();
                };
                scope.getHeight = function() {
                    var h = A.element($window).innerHeight - A.element("div#pageBody").offset().top;
                    return (h > 400) ? h : 400;
                };
                scope.getQuery = function() {
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
                    query.projectOwner = m.projectOwner || "";
                    query.market = m.market || "";
                    query.region = m.region || "";
                    query.projectTitle = m.projectTitle || "";
                    query.recordState = m.recordState || "";
                    query.theme = m.theme || "";
                    query.tier = m.tier || "";
                    query.executionCompany = m.executionCompany || "";

                    return query;
                };
                $scope.setViewTypeDisplayType = function(viewType, displayType) {
                    $scope.objectTypeViewModel.setSelKey(viewType);
                    $scope.displayActionModel.setSelKey(displayType);
                };
                $scope.initPageHeader = function() {
                    scope.dateRangePillModel.setData(scope.filterModel);
                    scope.recordStatePillModel.setData(scope.filterModel);
                };
                $scope.windowOnResize = function() {
                    windowOnResize($window);
                };
                $scope.calendar = {
                    init: function() {

                    },
                    setData: function(data) {

                    }
                };

                $scope.heatMap = {};
                $scope.heatMap.init = function(heapMapSelId, viewType, custSettings) {
                    _calendarHeatMapManager = new CalendarHeatMapManager(heapMapSelId, viewType, custSettings);
                    return $scope.heatMap;
                };
                $scope.heatMap.setData = function(data) {
                    _calendarHeatMapManager.render(data);
                };
                $scope.dashboard = {
                    projectQueryId: DEFAULT_VIEW_TYPE
                };
                $scope.objectTypeViewModel = new ViewTypeModel();
                scope.displayActionModel = new DisplayActionModel();
                scope.filterModel = new FilterModel(appModel);
                scope.filterModel.retailer = webContext.defaultRetailer;
                scope.filterModel.projectNumber = webContext.projectNumber || '';
                scope.themePillModel = new PillModel('theme', '', '', true);
                scope.tierPillModel = new PillModel('tier', '', '', true);
                scope.projectTitlePillModel = new PillModel("projectTitle", "", "", true);
                scope.executionCompanyPillModel = new PillModel("executionCompany", "", "", true);
                scope.clientPillModel = new PillModel("client", "", "", true);
                scope.retailerPillModel = new PillModel("retailer", "", "", true);
                scope.locationPillModel = new PillModel("location", "", "", true);
                scope.projectNumberPillModel = new PillModel("projectNumber", "", "", true);
                scope.recordStatePillModel = new PillModel("recordState", "", "", true);
                scope.marketPillModel = new PillModel("market", "", "", true);
                scope.regionPillModel = new PillModel("region", "", "", true);
                scope.projectTypePillModel = new PillModel("projectType", "", "", true);
                scope.dateRangePillModel = new DateRangePillModel("", "", true);
                scope.projectStatusPillModel = new PillModel("projectStatus", "", "", true);
                scope.projectOwnerPillModel = new PillModel("projectOwner", "", "", true);

                function routeToViewer(viewType, layoutType) {
                    if (viewType === "project") {
                        if (layoutType === "table") {
                            $state.go("projects-table-viewer");
                        } else {
                            $state.go("projects-calendar-viewer");
                        }
                    } else if (viewType === 'job') {
                        if (layoutType === "table") {
                            $state.go("jobs-table-viewer");
                        } else {
                            $state.go("jobs-calendar-viewer");
                        }
                    } else if (viewType === 'theme') {
                        if (layoutType === "table") {
                            $state.go("themes-table-viewer");
                        } else {
                            $state.go("themes-calendar-viewer");
                        }
                    } else if (viewType == 'projectCalendar') {
                        if (layoutType === 'table') {
                            $state.go('projectcalendar-table-viewer');
                        } else {
                            $state.go('projectcalendar-calendar-viewer');
                        }
                    }
                }

                function watchFilterModelProperty(name, minChars) {
                    var size = minChars || 0;
                    scope.$watch("filterModel." + name, function(newValue, oldValue) {
                        var isRun = 0;
                        if (newValue !== oldValue) {
                            if (typeof newValue === "boolean") {
                                isRun = 1;
                            } else if (typeof newValue === "string") {
                                if (size < 1) {
                                    isRun = 1;
                                } else {
                                    if (!newValue || newValue.length >= size) {
                                        isRun = 1;
                                    }
                                }
                            } else {
                                isRun = 1;
                            }
                            if (isRun) {
                                scope[name + "PillModel"].setData(scope.filterModel);
                                handleFilter();
                            }
                        }

                    });
                }

                function bootstrap($scope, webContext) {
                    watchFilterModelProperty("projectTitle", 3);
                    watchFilterModelProperty("market");
                    watchFilterModelProperty("region");
                    watchFilterModelProperty("executionCompany");
                    watchFilterModelProperty("recordState");

                    $scope.isJobView = function() {
                        return $scope.objectTypeViewModel.option.key === 'job';
                    };

                    $scope.isThemeCalendar = function() {
                        return $scope.objectTypeViewModel.option.key === 'theme' || $scope.objectTypeViewModel.option.key === 'projectCalendar';
                    };
                    $scope.isSuperUser = function() {
                        return webContext.accessCode === '1' ? true : false;
                    }
                }

                function handleFilter() {
                    var key = $scope.objectTypeViewModel.getSelKey(),
                        actionKey = $scope.displayActionModel.getSelKey(),
                        query = getQuery($scope);
                    showBusy($scope);
                    $scope.$broadcast(EVENT_FITLER_CHANGED, {
                        query: query,
                        viewType: key,
                        displayType: actionKey
                    });
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
                    handleFilter();
                };

                scope.onRetailerRemove = function() {
                    scope.retailerPillModel.hide();
                    scope.filterModel.resetSelection("retailer");
                    handleFilter();
                };

                scope.lookupProjectOwner = function(keyword) {
                    scope.filterModel.findUsers(keyword);
                };

                scope.projectOwnerChanged = function() {
                    scope.projectOwnerPillModel.setData(scope.filterModel);
                    handleFilter();
                };

                scope.onProjectOwnerRemove = function() {
                    scope.projectOwnerPillModel.hide();
                    scope.filterModel.resetSelection("projectOwner");
                    handleFilter();
                };

                scope.lookupClients = function(keyword) {
                    scope.filterModel.findClients(keyword);
                };

                scope.clientChanged = function() {
                    scope.clientPillModel.setData(scope.filterModel);
                    handleFilter();
                };

                scope.lookupProjectStatus = function(keyword) {
                    scope.filterModel.findProjectStatus(keyword);
                };

                scope.projectStatusChanged = function(keyword) {
                    scope.projectStatusPillModel.setData(scope.filterModel);
                    handleFilter();
                };

                scope.onProjectStatusRemove = function() {
                    scope.projectStatusPillModel.hide();
                    scope.filterModel.resetSelection("projectStatus");
                    handleFilter();
                };

                scope.onProjectTitleRemove = function() {
                    scope.projectTitlePillModel.hide();
                    scope.filterModel.projectTitle = "";
                    handleFilter();
                };

                scope.onClientRemove = function() {
                    scope.clientPillModel.hide();
                    scope.filterModel.resetSelection("client");
                    handleFilter();
                };

                scope.lookupThemes = function(keyword) {
                    scope.filterModel.findThemes(keyword);
                };

                scope.themeChanged = function() {
                    scope.themePillModel.setData(scope.filterModel);
                    handleFilter();
                };

                scope.onThemeRemove = function() {
                    scope.themePillModel.hide();
                    scope.filterModel.resetSelection("theme");
                    handleFilter();
                };

                scope.lookupTiers = function(keyword) {
                    scope.filterModel.findTiers(keyword);
                };

                scope.tierChanged = function() {
                    scope.tierPillModel.setData(scope.filterModel);
                    handleFilter();
                };

                scope.onTierRemove = function() {
                    scope.tierPillModel.hide();
                    scope.filterModel.resetSelection("tier");
                    handleFilter();
                };

                scope.lookupProjectTypes = function(keyword) {
                    scope.filterModel.findProjectTypes(keyword);
                };

                scope.projectTypeChanged = function() {
                    scope.projectTypePillModel.setData(scope.filterModel);
                    handleFilter();
                };

                scope.onProjectTypeRemove = function() {
                    scope.projectTypePillModel.hide();
                    scope.filterModel.resetSelection("projectType");
                    handleFilter();
                };

                scope.lookupProjectNumbers = function(keyword) {
                    var q = getQuery(scope);
                    q.ProjectNumber = keyword;
                    scope.filterModel.findProjectNumbers(q);
                };

                scope.projectNumberChanged = function() {
                    scope.projectNumberPillModel.setData(scope.filterModel);
                    handleFilter();
                };

                scope.onProjectNumberRemove = function() {
                    scope.projectNumberPillModel.hide();
                    scope.filterModel.resetSelection("projectNumber");
                    handleFilter();
                };

                scope.lookupLocations = function(keyword) {
                    scope.filterModel.findLocations({
                        keyword: keyword,
                        retailer: scope.filterModel.retailer
                    });
                };

                scope.locationChanged = function() {
                    scope.locationPillModel.setData(scope.filterModel);
                    handleFilter();
                };

                scope.onLocationRemove = function() {
                    scope.locationPillModel.hide();
                    scope.filterModel.resetSelection("location");
                    handleFilter();
                };

                scope.onMarketRemove = function() {
                    scope.marketPillModel.hide();
                    scope.filterModel.market = "";
                    handleFilter();
                };

                scope.onRegionRemove = function() {
                    scope.regionPillModel.hide();
                    scope.filterModel.region = "";
                    handleFilter();
                };

                scope.onExecutionCompanyRemove = function() {
                    scope.executionCompanyPillModel.hide();
                    scope.filterModel.executionCompany = "";
                    scope.filterModel.executionCompanyModel.option = {
                        key: "BOTH",
                        value: "Both"
                    };
                    scope.filterModel.executionCompanyModel.reset("BOTH");
                };

                scope.onRecordStateRemove = function() {
                    scope.recordStatePillModel.hide();
                    scope.filterModel.recordState = '';
                    scope.filterModel.canSchedule = "";
                    scope.filterModel.recordStateModel.option = {
                        key: 'BOTH',
                        value: 'Both'
                    }
                    scope.filterModel.recordStateModel.reset("BOTH");
                };

                scope.startDateChanged = function() {
                    scope.dateRangePillModel.setData(scope.filterModel);
                    handleFilter();
                };

                scope.onDateRangeRemove = function() {
                    scope.filterModel.startDate = "";
                    scope.filterModel.endDate = "";
                    scope.dateRangePillModel.setData(scope.filterModel);
                    handleFilter();
                };

                scope.endDateChanged = function() {
                    scope.dateRangePillModel.setData(scope.filterModel);
                    handleFilter();
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

                scope.showCalendar = function(selDate) {
                    A.element(selDate).datepicker('show');
                };

                bootstrap($scope, webContext);
            }
        ]);

})(angular);
