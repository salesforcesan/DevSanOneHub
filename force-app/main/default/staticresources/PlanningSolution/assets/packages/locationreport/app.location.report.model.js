(function(A) {
"use strict";

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

   Model.prototype.findPrograms = function(query){
    var action = '{!$RemoteAction.LocationReportRemoter.FindPrograms}';
      return asyncApi.remoting(action, query);
   };

   return new Model();
 }]);

})(angular);
