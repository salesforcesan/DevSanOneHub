(function(A){
  'use strict';
  var _default_url = "/projectServiceView/detail";
  var _status_css = [{
    key: "Planning",
    value: "slds-theme--alt-inverse"
  },{
    key: "Scheduled",
    value: "slds-theme--shade"
  },{
    key: "Finished",
    value: "slds-theme--success"
  },{
    key: "Cancelled",
    value: "slds-theme--shade"
  },{
    key: "Executed",
    value: "slds-theme--success"
  },{
    key: "In Progress",
    value: "slds-theme--warning"
  },{
    key: "Rejected",
    value: "slds-theme--error"
  }];

  // register MVC's model
  A.module("app.projectServiceView.model",['cmk.web.context','cmk.system.async'])
  .factory("projectServiceViewModel", ['cmkSystemAsync', 'cmkWebContext',
    function(asyncApi, webContext){
      return {
        getProjectService: function(){
          var action;
          if (!!webContext.projectServiceId) {
            action = '{!$RemoteAction.ProjectRemoter.GetProjectService}';
            return asyncApi.remoting(action, {id: webContext.projectServiceId});
          } else {
            return {
              "__error": "Project Service Id is not assigned."
            }
          }
        }
      };
    }]);

    A.module("app.projectServiceView", [
      "app.projectServiceView.model",
      "ui.router",
      "ngSanitize",
      "cmk.ui.busyIndicatorService",
      "cmk.web.context",
      "app.projectServiceView.detail",
      "app.projectServiceView.items",
      "app.projectServiceView.equipments",
      "app.projectServiceView.materials",
      "app.projectServiceView.surveyQuestions"
    ])
    .config(["$stateProvider", "$urlRouterProvider", "cmkWebContext", function(_stateProvider, _urlRouterProvider, _webContext){
      _urlRouterProvider.when("", _default_url);
      _urlRouterProvider.when("/", _default_url);
      _urlRouterProvider.when("/projectServiceView", _default_url);

      _stateProvider.state("projectServiceView", {
        resolve: {
          projectServiceData: ["projectServiceViewModel", function(model){
            return model.getProjectService();
          }]
        },
        url: "/projectServiceView",
        templateUrl: _webContext.applicationPath + "/assets/packages/projectServiceView/projectService.html",
        controller: "ProjectServiceViewStateController"
      });
    }])
    .controller("ProjectServiceViewController",["$scope", "cmkWebContext",
      function($scope, webContext){
        $scope.resourcePath = !!webContext.staticResourcePath ? webContext.staticResourcePath + "/" : "";
    }])
    .controller("ProjectServiceViewStateController", ["$scope", "$state", "$location", "$window", "cmkWebContext", "$log", "projectServiceData","cmkBusyIndicatorService",
      function($scope, $state, $location, $window, webContext, $log, data, busyIndicatorService){

        function getStatusCSS(status){
          var k = (status || "").toLowerCase();
          var css = _.find(_status_css, function(e){
            return e.key.toLowerCase().indexOf(k) !== -1;
          });
          return (!!css) ? css.value : "slds-theme--shade";
        }

        function newHeaderViewModel(){
          var self = {};
          self.title = data.ServiceName
          self.id = data.ServiceId;
          self.projectId = data.ProjectId;
          self.projectTitle = data.ProjectTitle;
          self.status = data.Status;
          self.statusCSS = getStatusCSS(data.Status);
          self.executor = data.Executor;
          self.duration = data.Duration;
          self.targetType = data.TargetType;
          self.previewManual = function(){
            $log.log("preview event manual");
          };
          self.edit = function (){
            $log.log("edit");
          };

          return self;
        }

        function newTabViewModel() {
          var self = {};

          self.selDetailTab = ($state.$current.name === "projectServiceView.detail") ? true : false;
          self.selSurveyTab = ($state.$current.name === "projectServiceView.surveyQuestions") ? true : false;
          self.selItemTab = ($state.$current.name === "projectServiceView.items") ? true : false;
          self.selMaterialTab = ($state.$current.name === "projectServiceView.materials") ? true : false;
          self.selEquipmentTab = ($state.$current.name === "projectServiceView.equipments") ? true : false;
          self.surveyCount = 10;
          self.itemCount = 4;
          self.materialCount = 7;
          self.equipmentCount = 15;
          return self;
        }

        $scope.headerVM = newHeaderViewModel();
        $scope.previewEventManual = function(){
          $scope.headerModel.previewManual();
        };
        $scope.editService = function() {
            $scope.headerModel.edit();
        };

        $scope.tabVM = newTabViewModel();
        $scope.tabClicked = function (tabName) {
            var busyIndicatorOptions = {
              containerId: "div#tab-default-1"
            };
            var stateName = "projectServiceView." + tabName;
            if ($state.is(stateName)){
              return;
            }

            busyIndicatorService.show($scope, busyIndicatorOptions);

            $scope.tabVM.selDetailTab = (tabName === "detail") ? true : false;
            $scope.tabVM.selSurveyTab = (tabName === "surveyQuestions") ? true : false;
            $scope.tabVM.selItemTab = (tabName === "items") ? true : false;
            $scope.tabVM.selMaterialTab = (tabName === "materials") ? true : false;
            $scope.tabVM.selEquipmentTab = (tabName === "equipments") ? true : false;
            $state.go(stateName);
        };

        $scope.$on(
          "$stateChangeSuccess",
          function(event, toState, toParams, fromState, fromParams) {
            busyIndicatorService.hide();
          }
        );

        $scope.onEditProject = function(){
          var url = ["ProjectServiceAddEditView?id=", webContext.projectServiceId, "&retURL=", encodeURIComponent($location.absUrl())].join("");
          $window.location.href = url;
        };

        $scope.onPreviewEventManual = function(){
          var url = ["/apex/factcard?psId=", webContext.projectServiceId].join("");
          $window.location.href = url;
        };

        $scope.goBackProjectView = function(){
          var url = ["/apex/ProjectView?id=", webContext.projectId, "#/project/services"].join("");
          $window.location.href = url;
        };
    }]);

})(angular);
