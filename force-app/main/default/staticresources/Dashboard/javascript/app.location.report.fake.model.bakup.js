(function(A) {
  "use strict";
  var _PROJECT_FIELDS = [
      "Id",
      "ProjectName__c",
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
      ""
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

  function fakeData(type, count) {
    var arr = [];
    for (var i = 0; i < count; i++) {
      arr.push({
        Id: "id:" + i,
        Name: type + ":" + i
      });
    }
    return arr;
  }

  function fakeLocations(count) {
    var location,
      addresses = ["colt rd", "legacy blvd", "main str.", "kelly road", "walgreen str.", "reno str", "reno blvd", "washington str", "aldo str"],
      cities = ["plano", "fresco", "fremond", "san francisco", "waco", "irving", "dallas", "allen", "milpitas", "palo alto", "san meteo"],
      states = ["CA", "TX", "MO", "IL", "WO", "LA", "CO"],
      nums = [100, 200, 400, 999, 666, 345, 864, 392, 903, 432],
      data = [];
    for (var i = 0; i < count; i++) {
      location = {}
      location.Id = "loc" + (nums[i % 10] + i);
      location.Num = nums[i % 10] + i;
      location.Name = "WalmarkSuperCenter";
      location.Address = (1000 + i) + " " + addresses[i % 9];
      location.City = cities[i % 11];
      location.State = states[i % 7];
      location.Retailer__c = "id:" + [i % 40];
      data.push(location);
    }
    return data;
  }

  A.module("cmk.service.lookupModel")
    .factory('cmkServiceLookupModel', ["$q", function($q) {
      function FakeModel() {}

      function genData(type, count) {
        var defer = $q.defer(),
          arr = fakeData(type, count);
        defer.resolve(arr);
        return defer.promise;
      }

      function genLocations(count, keyword) {
        var defer = $q.defer(),
          keyword = !!keyword ? keyword.toLowerCase() : "",
          data = fakeLocations(count);

        if (!!keyword) {
          data = data.filter(function(l) {
            return (l.Num + "").indexOf(keyword) !== -1 ||
              l.Address.toLowerCase().indexOf(keyword) !== -1 ||
              l.City.toLowerCase().indexOf(keyword) !== -1 ||
              l.State.toLowerCase().indexOf(keyword) !== -1;
          });
        }

        defer.resolve(data);
        return defer.promise;
      }

      FakeModel.prototype.clients = function() {
        return genData("Client", 10);
      };

      FakeModel.prototype.projectTypes = function() {
        var defer = $q.defer(),
          data = [];
        _PROJECT_TYPES.forEach(function(t) {
          data.push({
            Id: t,
            Name: t
          });
        });
        defer.resolve(data);
        return defer.promise;
      };

      FakeModel.prototype.retailers = function() {
        return genData("Retailer", 40);
      };

      FakeModel.prototype.findLocations = function(keyword) {
        return genLocations(1000, keyword);
      };

      return new FakeModel();
    }]);

  A.module("cmk.location.report.model", ["cmk.service.lookupModel"])
    .factory('cmkLocationReportModel', ['$q', 'cmkServiceLookupModel', function($q, lookupModel) {
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

      function getDate(dateDiff) {
        var reportDate = new Date();
        reportDate.setDate(reportDate.getDate() + dateDiff);
        return new Date(reportDate.getFullYear(), reportDate.getMonth(), reportDate.getDate(), 0, 0, 0, 0);
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
        var arr1, arr2, dt1, dt2;
        arr1 = v1.split("/");
        arr2 = v2.split("/");
        dt1 = new Date(parseInt(arr1[2]), parseInt(arr1[0]), parseInt(arr1[1]), 0, 0, 0, 0);
        dt2 = new Date(parseInt(arr2[2]), parseInt(arr2[0]), parseInt(arr2[1]), 0, 0, 0, 0);
        return {
          v1: dt1,
          v2: dt2,
        };
      }

      function isRecValid(clause) {
        var ret = true, i, e, v;
        for(i=0; i < clause.length; i++){
          e = clause[i];
          if (!!e.op) {
            if (e.op === ">=") {
              v = convertDate(e.v1,e.v2);
              if (v.v1 > v.v2) {
                ret = false;
                break;
              }
            } else if (e.op === "<=") {
              v = convertDate(e.v1,e.v2);
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
        var data = genData(_PROJECT_FIELDS, 2000);
        var locations = fakeLocations(1000);
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
          var startDate = getDate(i % 2 === 0 ? i : -i),
            endDate = getDate(i % 2 === 0 ? i + 10 + i % 50 : -i + 5 + i % 40);
          rec.Location__c = locations[i % locCount].Id;
          rec.RetailerName__c = retailers[i % retailerCount].Name;
          rec.Retailer__c = retailers[i % retailerCount].Id;
          rec.ClubNumber__c = locations[i % locCount].Num;
          rec.ProjectType__c = projectTypes[i % pTypeCount];
          rec.ProjectTypeName__c = projectTypes[i % pTypeCount];
          rec.StartDate__c = formatDate(startDate);
          rec.ProjectStatus__c = _PROJECT_STATUS[i % statusCount];
          rec.Client__c = clients[i % clientCount].Id;
          rec.ClientName__c = clients[i % clientCount].Name;
          rec.EndDate__c = formatDate(endDate);
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
            if (where.length === 0){
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
          var startDate = getDate(i % 2 === 0 ? i : -i),
            endDate = getDate(i % 2 === 0 ? i + 10 + i % 50 : -i + 5 + i % 40);
          rec.Location__c = locations[i % locCount].Id;
          rec.RetailerName__c = retailers[i % retailerCount].Name;
          rec.Retailer__c = retailers[i % retailerCount].Id;
          rec.LocationNumber__c = locations[i % locCount].Num;
          rec.ProjectType__c = projectTypes[i % pTypeCount];
          rec.ProjectTypeName__c = projectTypes[i % pTypeCount];
          rec.StartDate__c = formatDate(startDate);
          rec.ServiceName__c = (i % 4 === 0) ? "-" : rec.ServiceName__c;
          rec.Status__c = _PROJECT_STATUS[i % statusCount];
          rec.Client__c = clients[i % clientCount].Name;
          rec.ClientId__c = clients[i % clientCount].Id;
          rec.EndDate__c = formatDate(endDate);
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
            if (where.length === 0){
              result.push(rec);
            }else if (isRecValid(where)) {
              result.push(rec);
            } 
          });
        } else {
          result = data;
        }

        defer.resolve(result);
        return defer.promise;
      };

      return new FakeModel();

    }]);

})(angular);
