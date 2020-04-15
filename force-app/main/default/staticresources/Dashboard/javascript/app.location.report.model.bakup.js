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
      "Location__c",
      "ProjectType__c",
      "ClubNumber__c",
      "StartDate__c",
      "EndDate__c",
      "ProjectStatus__c"
    ],
    _JOB_FIELDS = [
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
      "LocationNumber__c",
      "ScheduleDate__c",
      "Status__c",
      "ServiceName__c",
      "StartDate__c",
      ""
    ];

  A.module("cmk.location.report.model", ["cmk.system.async"])
    .factory('cmkLocationReportModel', ['cmkSystemAsync', function(asyncApi) {

      function newProject() {
        return new SObjectModel.ProjectLocation__c();
      }

      function newJob() {
        return SObjectModel.Job__c();
      }

      function Model() {}
      Model.prototype.findProjects = function(query) {
        var projects = newProject(),
          q = {};
        return asyncApi.call(projects.retrieve, q, _PROJECT_FIELDS);
      };

      Model.prototype.findJobs = function(query) {
        var jobs = newJob(),
          q = {};
        return asyncApi.call(jobs.retrieve, q, _JOB_FIELDS);
      };

      return new Model();
    }]);

})(angular);
