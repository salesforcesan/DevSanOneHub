(function(A) {
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
.factory("projectModel",['cmkSystemAsync', 'cmkWebContext', '$q',
  function(asyncApi, webContext, $q) {
    return {
      getProject: function() {
        var defer = $q.defer();

        defer.resolve({
            Id: "a0Lj0000000Tg2nEAC",
            Title: "test",
            Supplier: "P&G",
            Type: "In Store Demo & Sampling",
            Status: "Finished",
            StartDate: 1450656000000,
            EndDate: 1451088000000,
            ProgramId: "150612129384",
            Group: "Bear Am Dry",
            SubGroup: "Complex Pairing -4hr",
            CanReschedule: true,
            ImportedLocations: 200,
            BudgetedLocations: 12,
            CreatedBy: "David Zhao",
            CreatedDate: "10/16/2015 9:06 AM",
            UpdatedBy: "David Zhao",
            UpdatedDate: "10/17/2015 10:12 PM",
            Retailer: "Sam's Club",
            Description:"Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat tincidunt ut laoreet.",
            ServiceCount: 3,
            LocationCount: 600,
            JobCount: 780,
            Approver: "Kumar Arun",
            Owner: "David Zhao"
        });
        return defer.promise;
      }
    };
}]);


    A.module("cmk.svg.use", ["cmk.web.context", "ngSanitize"])
      .directive("cmkSvgUse", ["cmkWebContext", function(webContext){
        return {
          restrict: "EA",
          transclude: true,
          scope:{
            icon:"@"
          },
          template: function(){
            return '<use xlink:href="{{icon}}"></use>';
          }
        };
      }]);

A.module("app.project", [
    "app.project.model",
    "cmk.web.context",
    "ui.router",
    "cmk.svg.use",
    "app.project.detail",
    "app.project.service",
    "app.project.location",
    "app.project.job"
  ])

 .config(["$stateProvider", "$urlRouterProvider", "cmkWebContext", function(_stateProvider, _urlRouterProvider, _webContext) {
   _urlRouterProvider.when("/project", "/project/detail");

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
       scope.applicationPath = cmkWebContext.applicationPath;
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

.controller('ProjectController', function(){

});

})(angular);
