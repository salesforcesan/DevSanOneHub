/* Crossmark commmon service API definition
 * instruction: for each visual page, you need to copy the following codes into <script> tag inside the HTML <head> section

      //todo: before deploy this file, please modify salesforce cloud related settings and copy this into the header of visual page
  
  angular.module("cmk.web.context", [])
    .factory("cmkWebContext", function() {
      return {
        staticResourcePath: "",
        applicationPath: "/assets",
        logonUserId: ""
      };
    });
  
*/

(function(A) {
  var _ID_NAME_FIELDS = ["Id", "Name"],
    _LOCATION_FIELDS = [
      "Id",
      "Name",
      "LocationNumber__c",
      "Address__c",
      "City__c",
      "State__c",
      "Retailer__c"
    ];

  //salesforce remote object factory method
  function newProject() {
    return new SObjectModel.Project__c();
  }

  function newProjectType() {
    return new SObjectModel.ProjectType__c();
  }

  function newRetailer() {
    return new SObjectModel.Retailer__c();
  }

  function newClient() {
    return new SObjectModel.Client__c();
  }

  function newLocation() {
    return new SObjectModel.Location__c();
  }

  A.module("cmk.system.async", [])
    .factory("cmkSystemAsync", ["$q", function($q) {

      function Async() {}

      Async.prototype.call = function(method, args, fields) {
        var defer = $q.defer();

        function transformRecords(records, fields) {
          var result = [];
          records.forEach(function(record) {
            var e = {};
            _.forEach(fields, function(field) {
              e[field] = record.get(field) || "-";
            });
            result[result.length] = e;
          });
          return result;
        }

        //  console.log("---ajax call----");
        //  console.log(!!args ? JSON.stringify(args) : "no args");

        if (!!args) {
          method(args, function(err, records, event) {
            if (err) {
              defer.reject(err);
            } else {
              if (!!event) {
                defer.resolve(transformRecords(records, fields), event);
              } else {
                defer.resolve(transformRecords(records, fields));
              }
            }
          });
        } else {
          method(function(err, records, event) {
            var data;
            if (err) {
              defer.reject(err);
            } else {
              data = (fields.length === 0) ? records[0] : transformRecords(records, fields);
              if (!!event) {
                defer.resolve(data);
              } else {
                defer.resolve(data, event);
              }
            }
          });
        }

        return defer.promise;
      };

      return new Async();
    }]);

  A.module("cmk.service.project", ["cmk.web.context", "cmk.system.async"])
    .factory("projectService", ["cmkWebContext", "cmkSystemAsync", function(webContext, asyncApi) {

      function transformToSalesForceQuery(query) {
        var view = "My Projects",
          sortField = "CreatedDate",
          sortDir = "DESC",
          recordLimit = 100,
          recordOffset = 1,
          queryParam = {
            orderby: [],
            limit: recordLimit
          },
          orderby = {};

        orderby[sortField] = sortDir;
        queryParam.orderby[0] = orderby;

        var CurrentUser = webContext.logonUserId;
        CurrentUser = CurrentUser.substring(0, 15);

        switch (view) {

          case "My Projects":
            queryParam.where = {
              OwnerId__c: {
                eq: CurrentUser
              }
            };
            break;
          case "Scheduled":
            queryParam.where = {
              Status__c: {
                eq: 'Scheduled'
              }
            };
            break;
          case "Planning":
            queryParam.where = {
              Status__c: {
                eq: 'Planning'
              }
            };
            break;
          case "Complete":
            queryParam.where = {
              Status__c: {
                eq: 'Complete'
              }
            };
            break;
          case "In Progress":
            queryParam.where = {
              Status__c: {
                eq: 'In Progress'
              }
            };
            break;

        }
        return queryParam;
      }

      function Model() {}
      Model.prototype.getProjects = function(query) {
        var project = newProject();
        queryParam = transformToSalesForceQuery(query);

        return asyncApi.call(project.retrieve, queryParam);
      };

      return new Model();
    }]);

  A.module("cmk.service.lookupModel", ["cmk.system.async"])
    .factory('cmkServiceLookupModel', ['cmkSystemAsync', function(asyncApi) {
      function Model() {}

      Model.prototype.projectTypes = function() {
        var projectTypes = newProjectType();
        return asyncApi.call(projectTypes.retrieve, "", _ID_NAME_FIELDS);
      };

      Model.prototype.retailers = function() {
        var retailers = newRetailer();
        return asyncApi.call(retailers.retrieve, "", _ID_NAME_FIELDS);
      };

      Model.prototype.clients = function() {
        var clients = newClient();
        return asyncApi.call(clients.retrieve, "", ["Id", "ClientName__c"]);
      };

      Model.prototype.findLocations = function(keyword) {
        var word, locations = newLocation(),
          query = {
            orderby: [{
              "LocationNumber__c": "ASC"
            }],
            limit: 50
          };
        if (!!keyword) {
          word = keyword + "%";
          query = {
            where: {
              or: {
                LocationNumber__c: {
                  like: word
                },
                or: {
                  City__c: {
                    like: word
                  },
                  State__c: {
                    like: word
                  }
                }
              }
            },
            orderby: [{
              "LocationNumber__c": "ASC"
            }],
            limit: 50
          };
        }

        return asyncApi.call(locations.retrieve, query, _LOCATION_FIELDS);
      };

      return new Model();
    }]);

})(angular);
