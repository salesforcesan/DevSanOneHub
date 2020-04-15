/* global _ */
/* global angular */
(function(A) {
  "use strict";
  var _PROJECT_FIELDS = [
      "Id",
      "Name",
      "Project__c",
      "ProjectTypeName__c",
      "RetailerName__c",
      "Retailer__c",
      "Client__c",
      "ClientName__c",
      "Location__c",
      "ProjectType__c",
      "ClubNumber__c",
      "StartDate__c",
      "EndDate__c",
      "ProjectStatus__c"
    ],
    _JOB_FIELDS = [
      "LocationNumber__c",
      "Id",
      "ProjectName__c",
      "Project__c",
      "ProjectTypeName__c",
      "RetailerName__c",
      "Retailer__c",
      "Client__c",
      "ClientId__c",
      "ProjectType__c",
      "Location__c",
      "ScheduleDate__c",
      "Status__c",
      "ServiceName__c",
      "StartDate__c",
      "EndDate__c"
    ],
    _PROJECT_STATUS = [
      "Scheduled",
      "Planning",
      "External Planning",
      "Finished",
      "In Progress"
    ],

    _PROJECT_TYPES = [
      "Roadshow",
      "In Store Demo & Sampling"
    ];
  var _num = 0;

  function fakeData(type, count) {
    var arr = [];
    for (var i = 0; i < count; i++) {
      arr.push({
        Id: "id:" + i,
        Name: type + "&amp;" + i
      });
    }
    return arr;
  }

  function getDate(dateDiff) {
    var reportDate = new Date();
    _num++;
    reportDate.setDate(reportDate.getDate() + dateDiff);
    return new Date(reportDate.getFullYear(), reportDate.getMonth(), reportDate.getDate(), _num % 24, _num % 12, _num % 60, 0);
  }

  function getDateNoTime(dateDiff) {
    var reportDate = new Date();
    reportDate.setDate(reportDate.getDate() + dateDiff);
    return new Date(reportDate.getFullYear(), reportDate.getMonth(), reportDate.getDate(), 0, 0, 0, 0);
  }

  function Color() {
    this.definition = {
      'Amber': '#FFC107',
      'Black': '#000000',
      'Blue': '#2196F3',
      'Brown': '#795548',
      'Cyan': '#00BCD4',
      'Indigo': '#3F51B5',
      'Green': '#4CAF50',
      'Grey': '#9E9E9E',
      'Lime': '#CDDC39',
      'Orange': '#FF9800',
      'Pink': '#E91E63',
      'Purple': '#9C27B0',
      'Red': '#F44336',
      'Teal': '#009688',
      'White': '#FFFFFF',
      'Yellow': '#FFEB3B'
    };
  }
  Color.prototype.getCode = function(colorName) {
    return this.definition[colorName] || '#FFFFFF';
  };
  Color.prototype.getNames = function() {
    var p, colors = [];
    for (p in this.definition) {
      if (typeof this[p] === 'function') continue;
      colors.push(p);
    }
    return colors;
  };


  function fakeLocations(count) {
    var location,
      addresses = ["colt rd", "legacy blvd", "main str.", "kelly road", "walgreen str.", "reno str", "reno blvd", "washington str", "aldo str"],
      cities = ["plano DFW metropolitan area", "fresco", "fremond", "san francisco east bay area", "san francisco", "waco", "irving", "dallas", "allen", "milpitas", "palo alto", "san meteo"],
      states = ["CA", "TX", "MO", "IL", "WO", "LA", "CO"],
      nums = [100, 200, 400, 999, 666, 345, 864, 392, 903, 432],
      data = [];
    for (var i = 0; i < count; i++) {
      location = {}
      location.Id = "loc" + (nums[i % 10] + i);
      location.LocationNumber__c = nums[i % 10] + i;
      location.Name = "WalmarkSuperCenter";
      location.Address__c = (1000 + i) + " " + addresses[i % 9];
      location.City__c = cities[i % 11];
      location.State__c = states[i % 7];
      location.Retailer__c = "id:" + [i % 40];
      data.push(location);
    }
    return data;
  }

  A.module("cmk.location.report.model", [])
    .factory('cmkLocationReportModel', [
      '$q',
      function($q) {
        var _themes, _tiers, _opportunities;

        function FakeModel() {}

        function genData(fields, count) {
          var e, data = [];
          for (var i = 0; i < count; i++) {
            e = {};
            fields.forEach(function(field) {
              e[field] = field + ":" + i;
            });
            data.push(e);
          }
          return data;
        }

        /* Opportunity */
        function Opportunity() {
          this.fields = ['Id', 'Name', 'Account', 'PreferDate', 'Stage', 'Count', 'Capacity', 'ThemeDate', 'ThemeName', 'ThemeColor', 'TierName', 'TierColor', 'EventType', 'ThemeId', 'TierId'];

          this.fieldIndex = function(fieldName) {
            return indexOf(fieldName);
          };
        }
        Opportunity.prototype.find = function(query) {
          var i, dt, tier, theme,
            stages = ['Drawing Board', 'Prospecting', 'Pending Market Approval', 'Planning', 'Work Order Sent', 'Work Order Signed', 'Closed Won', 'Closed Lost'],
            eventTypes = ['In Store Demo & Sampling', 'Roadshow'],
            recordset = {
              fields: this.fields,
              records: []
            },
            records = [],
            color = new Color(),
            colorNames = color.getNames();

          for (i = 0; i < 1000; i++) {
            dt = getDateNoTime(i % 10 > 5 ? i % 300 : -(i % 300));
            tier = i % 2 === 0 ? 'Grey' : 'Orange';
            theme = i % 2 === 0 ? 'Blue' : 'Teal';
            records.push([
              i,
              'name:' + i,
              'account:' + i,
              dt.getTime(),
              stages[i % 8],
              Math.floor(10 * Math.random()) + 1,
              100,
              dt.getTime(),
              i % 2 === 0 ? 'Lorem ipsum dolor sit amet, consectetur adipiscing elit' : 'Etiam consequat aliquam cursus. In sodales pretium ultrices',
              color.getCode(theme),
              'Tier' + (i % 2 + 1),
              color.getCode(tier),
              eventTypes[i % 2],
              'theme:' + (i % 2),
              'tier:' + (i % 2)
            ]);
          }
          recordset.records = records;
          return recordset;
        };


        function dateAdd(date, days) {
          var dt = new Date(date.getFullYear(), date.getMonth(), date.getDate(), 0, 0, 0, 0);
          dt.setDate(date.getDate() + days);
          return dt;
        }

        function formatDate(date) {
          var year = date.getFullYear(),
            month = date.getMonth() + 1,
            day = date.getDate();
          month = month < 10 ? "0" + month : month + "";
          day = day < 10 ? "0" + day : day + "";
          return [month, day, year].join("/");
        }

        function convertDate(v1, v2) {
          /*
          var arr1, arr2, dt1, dt2;
          arr1 = v1.split("/");
          arr2 = v2.split("/");
          dt1 = new Date(parseInt(arr1[2]), parseInt(arr1[0]), parseInt(arr1[1]), 0, 0, 0, 0);
          dt2 = new Date(parseInt(arr2[2]), parseInt(arr2[0]), parseInt(arr2[1]), 0, 0, 0, 0);
          */
          return {
            v1: Date.parse(v1),
            v2: Date.parse(v2),
          };
        }

        function isRecValid(clause) {
          var ret = true,
            i, e, v;
          for (i = 0; i < clause.length; i++) {
            e = clause[i];
            if (!!e.op) {
              if (e.op === ">=") {
                v = convertDate(e.v1, e.v2);
                if (v.v1 > v.v2) {
                  ret = false;
                  break;
                }
              } else if (e.op === "<=") {
                v = convertDate(e.v1, e.v2);
                if (v.v1 < v.v2) {
                  ret = false;
                  break;
                }
              }
            } else {
              if (e.v1 !== e.v2) {
                ret = false;
                break;
              }
            }
          }

          return ret;
        }

        FakeModel.prototype.findProjects = function(query) {
          var defer = $q.defer();
          var result = [];
          var where;
          var data = genData(_PROJECT_FIELDS, 1000);
          var locations = fakeLocations(100);
          var retailers = fakeData("Retailer", 40);
          var clients = fakeData("Client", 10);
          var projectTypes = _PROJECT_TYPES;

          var i = 0,
            locCount = locations.length,
            retailerCount = retailers.length,
            pTypeCount = projectTypes.length,
            clientCount = clients.length,
            statusCount = _PROJECT_STATUS.length;

          data.forEach(function(rec) {
            var startDate = getDate(i % 2 === 0 ? i % 300 : -(i % 300)),
              endDate = dateAdd(startDate, i % 10);
            rec.Location__c = locations[i % locCount].Id;
            rec.RetailerName__c = retailers[i % retailerCount].Name;
            rec.Retailer__c = retailers[i % retailerCount].Id;
            rec.ClubNumber__c = locations[i % locCount].LocationNumber__c;
            rec.ProjectType__c = projectTypes[i % pTypeCount];
            rec.ProjectTypeName__c = projectTypes[i % pTypeCount];
            rec.StartDate__c = startDate;
            rec.ProjectStatus__c = _PROJECT_STATUS[i % statusCount];
            rec.Client__c = clients[i % clientCount].Id;
            rec.ClientName__c = clients[i % clientCount].Name;
            rec.EndDate__c = endDate;
            i++;
          });

          if (!!query) {
            data.forEach(function(rec) {
              where = [];
              if (!!query.client) {
                where.push({
                  v1: query.client,
                  v2: rec.Client__c
                });
              }
              if (!!query.retailer) {
                where.push({
                  v1: query.retailer,
                  v2: rec.Retailer__c
                });
              }
              if (!!query.projectType) {
                where.push({
                  v1: query.projectType,
                  v2: rec.ProjectType__c
                });
              }
              if (!!query.location) {
                where.push({
                  v1: query.location,
                  v2: rec.Location__c
                });
              }
              if (!!query.startDate) {
                where.push({
                  v1: query.startDate,
                  v2: rec.StartDate__c,
                  op: ">="
                });
              }
              if (!!query.endDate) {
                where.push({
                  v1: query.endDate,
                  v2: rec.EndDate__c,
                  op: "<="
                });
              }
              if (where.length === 0) {
                result.push(rec);
              } else if (isRecValid(where)) {
                result.push(rec);
              }
            });
          } else {
            result = data;
          }

          defer.resolve(result);
          return defer.promise;
        };

        FakeModel.prototype.findJobs = function(query) {
          var defer = $q.defer();
          var result = [];
          var where;
          var data = genData(_JOB_FIELDS, 2000);
          var locations = fakeLocations(1000);
          var retailers = fakeData("Retailer", 40);
          var projectTypes = _PROJECT_TYPES;
          var clients = fakeData("Client", 10);
          var i = 0,
            locCount = locations.length,
            retailerCount = retailers.length,
            clientCount = clients.length,
            pTypeCount = projectTypes.length,

            statusCount = _PROJECT_STATUS.length;

          data.forEach(function(rec) {
            var startDate = getDate(i % 2 === 0 ? i % 300 : -(i % 300)),
              endDate = dateAdd(startDate, i % 10);
            rec.Location__c = locations[i % locCount].Id;
            rec.RetailerName__c = retailers[i % retailerCount].Name;
            rec.Retailer__c = retailers[i % retailerCount].Id;
            rec.LocationNumber__c = locations[i % locCount].LocationNumber__c;
            rec.ProjectType__c = projectTypes[i % pTypeCount];
            rec.ProjectTypeName__c = projectTypes[i % pTypeCount];
            rec.StartDate__c = startDate;
            rec.ServiceName__c = (i % 4 === 0) ? "-" : rec.ServiceName__c;
            rec.Status__c = _PROJECT_STATUS[i % statusCount];
            rec.Client__c = clients[i % clientCount].Name;
            rec.ClientId__c = clients[i % clientCount].Id;
            rec.EndDate__c = endDate;
            i++;
          });

          if (!!query) {
            data.forEach(function(rec) {
              where = [];
              if (!!query.client) {
                where.push({
                  v1: query.client,
                  v2: rec.ClientId__c
                });
              }
              if (!!query.retailer) {
                where.push({
                  v1: query.retailer,
                  v2: rec.Retailer__c
                });
              }
              if (!!query.projectType) {
                where.push({
                  v1: query.projectType,
                  v2: rec.ProjectType__c
                });
              }
              if (!!query.location) {
                where.push({
                  v1: query.location,
                  v2: rec.Location__c
                });
              }
              if (!!query.startDate) {
                where.push({
                  v1: query.startDate,
                  v2: rec.StartDate__c,
                  op: ">="
                });
              }
              if (!!query.endDate) {
                where.push({
                  v1: query.endDate,
                  v2: rec.EndDate__c,
                  op: "<="
                });
              }
              if (where.length === 0) {
                result.push(rec);
              } else if (isRecValid(where)) {
                result.push(rec);
              }
            });
          } else {
            result = data;
          }

          defer.resolve(result);
          return defer.promise;
        };

        FakeModel.prototype.findProjectCounts = function(query) {
          var defer = $q.defer();
          defer.resolve([]);
          return defer.promise;
        };

        FakeModel.prototype.findJobCounts = function(query) {
          var defer = $q.defer();
          defer.resolve([]);
          return defer.promise;
        }

        FakeModel.prototype.getRetailers = function() {
          var defer = $q.defer();
          defer.resolve([]);
          return defer.promise;
        };

        FakeModel.prototype.getClients = function() {
          var defer = $q.defer();
          defer.resolve([]);
          return defer.promise;
        };

        FakeModel.prototype.getProjectTypes = function() {
          var defer = $q.defer();
          var i = 0;
          var data = _PROJECT_TYPES.map(function(e) {
            return {
              Id: ++i,
              Name: e
            };
          });
          defer.resolve(data);
          return defer.promise;
        };

        FakeModel.prototype.getMarkets = function() {
          var defer = $q.defer();
          defer.resolve([]);
          return defer.promise;
        };

        FakeModel.prototype.getRegions = function() {
          var defer = $q.defer();
          defer.resolve([]);
          return defer.promise;
        };

        FakeModel.prototype.findLocations = function(query) {
          var defer = $q.defer();
          defer.resolve([]);
          return defer.promise;
        }

        FakeModel.prototype.getStatusList = function() {
          var defer = $q.defer();
          var i = 0;
          var data = _PROJECT_STATUS.map(function(e) {
            return {
              Id: ++i,
              Name: e
            };
          });
          defer.resolve(data);
          return defer.promise;
        }

        FakeModel.prototype.findProjectNumbers = function(query) {
          var defer = $q.defer();
          defer.resolve([]);
          return defer.promise;
        }

        FakeModel.prototype.getThemes = function() {
          var data, defer = $q.defer();
          if (!_themes) {
            data = [{
              Id: 'theme:0',
              Name: 'Theme 1',
              Color: 'red'
            }, {
              Id: 'theme:1',
              Name: 'Theme 2',
              Color: 'orange'
            }];
            _themes = data;
          } else {
            data = _themes;
          }
          defer.resolve(data);
          return defer.promise;
        }

        FakeModel.prototype.getTiers = function() {
          var data, defer = $q.defer();
          if (!_tiers) {
            data = [{
              Id: 'tier:0',
              Name: 'Tier 1',
              Color: 'blue'
            }, {
              Id: 'tier:1',
              Name: 'Tier 2',
              Color: 'navy'
            }];
            _tiers = data;
          } else {
            data = _tiers;
          }
          defer.resolve(data);
          return defer.promise;
        };

        FakeModel.prototype.findOpportunities = function(query) {
          var data, defer = $q.defer();
          if (!_opportunities) {
            var opportunity = new Opportunity();
            var i, rec, data = [],
              rs = opportunity.find();
            rs.records.forEach(function(row) {
              rec = {};
              for (i = 0; i < rs.fields.length; i++) {
                rec[rs.fields[i]] = row[i];
              }
              data.push(rec);
            });
          } else {
            data = _opportunities;
          }
          defer.resolve(data);
          return defer.promise;
        };

        return new FakeModel();

      }
    ]);

})(angular);
