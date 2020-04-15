(function(A){
  'use strict';

  A.module("app.projectServiceView.equipments.model",[
    "cmk.web.context",
    "cmk.system.async"
  ])
  .factory("projectServiceViewEquipmentsModel", [
    "cmkWebContext",
    "cmkSystemAsync",
    function (webContext, async) {
      return {
        getEquipments: function() {
          var projectServiceId = webContext.projectServiceId;
         console.log("please implement getEquipments() remoting call.");
        }
      };
    }
  ]);

  A.module("app.projectServiceView.equipments", [
    "ui.router",
    "cmk.web.context",
    "app.projectServiceView.equipments.model"
  ])
  .config([
    "$stateProvider",
    "cmkWebContext",
    function(_stateProvider, _webContext){
      _stateProvider.state("projectServiceView.equipments", {
        resolve: {
            equipments: [
              "projectServiceViewEquipmentsModel",
              function(model) {
                return model.getEquipments();
              }
            ]
        },
        url: "/equipments",
        templateUrl: _webContext.applicationPath + "/assets/packages/projectServiceView/projectService.equipments.html",
        controller: "ProjectServiceViewEquipmentsStateController"
      });
    }
  ])
  .controller("ProjectServiceViewEquipmentsController", [
    "$scope",
    function($scope) {
    }
  ])
  .controller("ProjectServiceViewEquipmentsStateController",[
    "$scope",
    "$log",
    "equipments",
    function($scope, $log, equipments) {
      console.log(equipments);
      //todo: add your controller logic here.
    }
  ]);
})(angular);
