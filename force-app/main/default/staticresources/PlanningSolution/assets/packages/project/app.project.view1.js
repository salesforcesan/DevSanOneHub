function bootstrap1(A){
    "use strict";
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

    A.module("app.project.model",[
      'cmk.web.context',
      'cmk.system.async'])
    .factory("projectModel",['cmkSystemAsync', 'cmkWebContext',
      function(asyncApi, webContext) {
        return {
          getProject: function() {
            var action = '{!$RemoteAction.ProjectRemoter.GetProject}';
            if (!!webContext.projectId) {
              action = '{!$RemoteAction.ProjectRemoter.GetProject}';
              return asyncApi.remoting(action, {id: webContext.projectId});
            }
            return {
              "__error": "Project Id is not assigned."
            };
          }
        };
    }]);

    A.module("app.project", [
        "app.project.model",
        "ui.router",
        "ngSanitize",
        "cmk.svg.use",
        "app.project.detail",
        "app.project.service",
        "app.project.location",
        "app.project.job"
      ])

     .config(["$stateProvider", "$urlRouterProvider", "cmkWebContext", function(_stateProvider, _urlRouterProvider, _webContext) {
       _urlRouterProvider.when("", "/project/detail");
       _urlRouterProvider.when("/project", "/project/detail");
       _urlRouterProvider.when("/", "/project/detail");

       _stateProvider.state("project",{
         resolve: {
           projectData: ["projectModel", function(model) {
             return model.getProject();
           }]
         },
         url: "/project",
         templateUrl: _webContext.applicationPath + "/assets/packages/project/project.html",
         controller: ["$scope", "$state", "cmkWebContext", "$log", "projectData", function($scope, $state, cmkWebContext, $log, projectData) {
          var scope = $scope;

           function getStatusCSS(status){
             var k = (status || "").toLowerCase();
             var css = _.find(_status_css, function(e){
               return e.key.toLowerCase().indexOf(k) !== -1;
             });
             return (!!css) ? css.value : "slds-theme--shade";
           }

           function getExecuteDateRange(fromMs, toMs){
             var start, end;
              if (isFinite(fromMs) && isFinite(toMs)){
                start = new Date(fromMs);
                end = new Date(toMs);
                return start.format("/") + " - " + end.format("/");
              } else {
                return "";
              }
           }

           function transformProject(project){
             var p = {};
             p.title = project.Title;
             p.supplier = project.Supplier;
             p.type = project.Type;
             p.status = project.Status;
             p.executeDateRange = getExecuteDateRange(project.StartDate, project.EndDate);
             p.serviceCount = project.ServiceCount;
             p.locationCount = project.LocationCount;
             p.jobCount = project.JobCount;

             return p;
           }

           function ProjectViewModel(project){
             var self = this;
             self.selDetail = ($state.$current.name === "project.detail") ? true : false;
             self.selServices = ($state.$current.name === "project.services") ? true : false;
             self.selLocations = ($state.$current.name === "project.locations") ? true : false;
             self.selJobs = ($state.$current.name === "project.jobs") ? true : false;
             self.project = project
             self.statusCSS = getStatusCSS(project.status);
             return self;
           }

           scope.projectViewModel = new ProjectViewModel(transformProject(projectData));
           scope.tabClicked = function(tabName,event){
               scope.projectViewModel.selDetail = (tabName === "detail") ? true : false;
               scope.projectViewModel.selServices = (tabName === "services") ? true : false;
               scope.projectViewModel.selLocations = (tabName === "locations") ? true : false;
               scope.projectViewModel.selJobs = (tabName === "jobs") ? true : false;
               $state.transitionTo("project." + tabName);
           };
       }]
      });
     }])
     .controller("ProjectController", ["$scope", "cmkWebContext", function($scope, webContext){
        $scope.resourcePath = !!webContext.staticResourcePath ? webContext.staticResourcePath + "/" : "";
     }]);
}
