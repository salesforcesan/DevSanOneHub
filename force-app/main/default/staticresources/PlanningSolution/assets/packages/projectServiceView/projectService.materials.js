(function(A){
  'use strict';

  A.module("app.projectServiceView.materials.model", [
    "cmk.web.context",
    "cmk.system.async"
  ])
  .factory("projectServiceViewMaterialsModel",[
    "cmkSystemAsync",
    "cmkWebContext",
    function(async, webContext) {
      return {
        getMaterials: function() {
            var projectServiceId = webContext.projectServiceId;
            //todo add your js remoting call here.
            console.log("please implement your getMaterials() remoting call.");
        }
      };
    }
  ]);

  A.module("app.projectServiceView.materials",[
    "ui.router",
    "cmk.web.context",
    "app.projectServiceView.materials.model"
  ])
  .config([
    "$stateProvider",
    "cmkWebContext",
    function(stateProvider, webContext) {
      stateProvider.state("projectServiceView.materials", {
        resolve: {
          materials: [
            "projectServiceViewMaterialsModel",
            function(model){
              return model.getMaterials();
            }
          ]
        },
        url: "/materials",
        templateUrl: webContext.applicationPath + "/assets/packages/projectServiceView/projectService.materials.html",
        controller: "ProjectServiceViewMaterialsStateController"
      });
    }
  ])
  .controller("ProjectServiceViewMaterialsController",[
    "$scope",
    function($scope){
    }
  ])
  .controller("ProjectServiceViewMaterialsStateController", [
    "$scope",
    "materials",
    function($scope, materials) {
      console.log(materials);
      //todo: add your controller logic here.
    }
  ]);

})(angular);
