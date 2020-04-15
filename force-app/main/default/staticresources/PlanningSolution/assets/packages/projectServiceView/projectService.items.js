(function(A){
  'use strict';

  A.module("app.projectServiceView.items.model",[
    "cmk.web.context",
    "cmk.system.async"
  ])
  .factory("projectServiceViewItemsModel", [
    "cmkSystemAsync",
    "cmkWebContext",
    function (async, webContext){
      return {
        getItems: function() {
          var projectServiceId = webContext.projectServiceId;
          //todo: add your remoting call here.
          console.log("please impelement getItems() javascript remoting call");
        }
      };
    }
  ]);


  A.module("app.projectServiceView.items",[
    "ui.router",
    "cmk.web.context",
    "app.projectServiceView.items.model"
  ])
  .config(["$stateProvider","cmkWebContext",
    function(_stateProvider, _webContext){
        _stateProvider.state("projectServiceView.items",{
          resolve: {
            items: ["projectServiceViewItemsModel", function (model){
              return model.getItems();
            }]
          },
          url: "/items",
          templateUrl: _webContext.applicationPath + "/assets/packages/projectServiceView/projectService.items.html",
          controller: "ProjectServiceViewItemsStateController"
        });
    }
  ])
  .controller("ProjectServiceViewItemsController",[
    "$scope",
    function($scope){
  }])
  .controller("ProjectServiceViewItemsStateController",[
    "$scope",
    "$log",
    "items",
    function($scope, $log, items){
      console.log(items);
      //todo: add your controller logic here.
    }
  ]);
})(angular);
