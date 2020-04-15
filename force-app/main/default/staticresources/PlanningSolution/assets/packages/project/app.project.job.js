(function(A) {
"use strict";
var _path, _appModel;

A.module("app.project.job", [
    "cmk.web.context",
    "cmk.system.async",
    "ui.router",
    "ui.grid"
  ])

  .factory("projectJobModel", ['cmkSystemAsync', 'cmkWebContext',
    function(asyncApi, webContext) {
      return {
        getJobs: function(projectId) {
          return [];
        }
      };
 }])

 .config(["$stateProvider", "cmkWebContext", function(_stateProvider, _webContext) {
   _stateProvider.state("project.jobs",{
     url: "/jobs",
     templateUrl:  _webContext.applicationPath + "/assets/packages/project/project.job.html",
     controller: "ProjectJobController"
   });

 }])

.controller('ProjectJobController',
      ['$scope', '$state', 'cmkWebContext', '$log', 'projectJobModel',
        function($scope, $state, webContext, $log, appModel) {
      }]
);

})(angular);
