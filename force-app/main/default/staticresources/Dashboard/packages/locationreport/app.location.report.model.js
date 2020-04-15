  (function(A) {
  "use strict";
  var _PROJECT_FIELDS = [
      "Id",
      "ProjectName__c",
      "Project__c",
      "ProjectTypeName__c",
      "RetailerName__c",
      "Retailer__c",
      "ClientName__c",
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
      "EndDate__c"
    ];

  A.module("cmk.location.report.model", ["cmk.system.async","cmk.web.context"])
    .factory('cmkLocationReportModel', ['cmkSystemAsync', 'cmkWebContext', function(asyncApi, webContext) {

      function newProject() {
        return new SObjectModel.ProjectLocation__c();
      }

      function newJob() {
        return new SObjectModel.Job__c();
      }
      
      function convertUTCDate(dateString) {
        var arr = dateString.split("/");
        if (arr.length !== 3) { return 0; };
        return new Date(Date.UTC(parseInt(arr[2]), parseInt(arr[0]) - 1, parseInt(arr[1]), 0, 0, 0, 0));
      }
      
      function buildQueryParam(viewType,filter) {
          var dt, val,
              queryParam = {
                  orderby: [{"StartDate__c": "ASC"}], 
                  limit: 100
              };   
              
          //eval("queryParam = { orderby: [ {'StartDate__c':'ASC'}], limit: 100}");
          queryParam.where = {};
          queryParam.where.ProjectName__c = {ne:''};
          queryParam.where.StartDate__c = {gt: new Date(1900,1,1,0,0,0,0)};
          if (viewType === "project"){
              queryParam.where.ProjectStatus__c = {eq: 'Scheduled'};
              queryParam.where.ClubNumber__c = {ne:''};
          } else if (viewType === "job") {
              queryParam.where.Status__c = {eq: 'Scheduled'};
              queryParam.where.LocationNumber__c = {ne:''};
          }
          
          
          if (!!filter.startDate) {
              dt = convertUTCDate(filter.startDate);
              if (!!dt) {
                queryParam.where.StartDate__c = {gte: dt};
              }
          }
          
          if (!!filter.endDate) {
              dt = convertUTCDate(filter.endDate);
              if (!!dt) {
                queryParam.where.endDate__c = {lte: dt};
              }
          }
          
          if (!!filter.retailer){
              val = filter.retailer.substr(0,15);
              queryParam.where.Retailer__c = {eq: val};
          }
          
          if (!!filter.location) {
              val = filter.location.substr(0,15)
              queryParam.where.Location__c = {eq: val};
          }
          
          if (!!filter.client) {
              val = filter.client.substr(0,15);
              
              if (viewType === "project") {
                queryParam.where.Client__c = {eq: val};
              } else if (viewType === "job") {
                queryParam.where.ClientId__c = {eq: val};
              }
          }
          
          if (!!filter.projectType) {
              val = filter.projectType.substr(0,15);
              queryParam.where.ProjectType__c = {eq: val};
          }
          
          return queryParam;
      }

      function Model() {}
      Model.prototype.findProjects = function(filter) {
        var projects = newProject(),
          q = buildQueryParam("project",filter);
        return asyncApi.call(projects.retrieve, q, _PROJECT_FIELDS);
      };

      Model.prototype.findJobs = function(filter) {
        var jobs = newJob(),
          q = buildQueryParam("job",filter);
        return asyncApi.call(jobs.retrieve, q, _JOB_FIELDS);
      };

      return new Model();
    }]);

})(angular); 