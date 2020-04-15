(function(A) {
"use strict";
var _path, _appModel;

A.module("app.project.service", [
    "cmk.web.context",
    "cmk.system.async",
    "ui.router",
    "ui.grid"
  ])

 .factory("projectServiceModel", ['cmkSystemAsync', 'cmkWebContext',
    function(asyncApi, webContext) {
      return {
        getServices: function() {
          return [];
        }
      };
 }])

 .config(["$stateProvider", "cmkWebContext", function(_stateProvider, _webContext) {
   _stateProvider.state("project.services",{
     url: "/services",
     templateUrl: _webContext.applicationPath + "/assets/packages/project/project.service.html",
     controller: "ProjectServiceController"
   });

 }])

.controller('ProjectServiceController',
      ['$scope', '$state', 'cmkWebContext', '$log', 'projectServiceModel',
        function($scope, $state, webContext, $log, dataModel) {
      }]
);

})(angular);
