(function(A) {
"use strict";
var _path, _appModel;

A.module("app.project.location", [
    "cmk.web.context",
    "cmk.system.async",
    "ui.router",
    "ui.grid"
  ])

  .factory("projectLocationModel", ['cmkSystemAsync', 'cmkWebContext',
    function(asyncApi, webContext) {
      return {
        getLocations: function(projectId) {
          return [];
        }
      };
 }])

 .config(["$stateProvider", "cmkWebContext" ,function(_stateProvider, _webContext) {
   _stateProvider.state("project.locations",{
     url: "/locations",
     templateUrl: _webContext.applicationPath + "/assets/packages/project/project.location.html",
     controller: "ProjectLocationController"
   });

 }])

.controller('ProjectLocationController',
      ['$scope', '$state', 'cmkWebContext', '$log', 'projectLocationModel',
        function($scope, $state, webContext, $log, appModel) {

      }]
);

})(angular);
