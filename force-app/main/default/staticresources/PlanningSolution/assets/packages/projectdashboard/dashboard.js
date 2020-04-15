(function(A) {
  A.module("cmk.app.dashboard", ["cmk.web.context", "cmk.system.async", "cmk.service.project", "cmk.service.projectType"])
    .factory("dashboardService", ["asyncApi", "webContext", function(asyncApi, webContext) {

      function newCustomQuery() {
        return new SObjectModel.ProjectCustomQuery();
      }

      function Model() {};
      Model.prototype.getFilterQueries = function() {
        var fieldMaps = [{
            from: "Query__c",
            to: "key"
          }, {
            from: "Query__c",
            to: "value"
          }],
          projectQueries = newCustomQuery(),
          userId = _app.LogonUser.userId;

        var queryParam = {
          orderby: [{
            Name: 'ASC'
          }]
        };

        queryParam.where = {
          or: {
            IsCustom__c: {
              eq: false
            },
            OwnerId: {
              eq: userId
            }
          }
        };

        return asyncApi.call(projectQueries.retrieve, queryParam, fieldMaps);
      };

      return new Model();
    }])
    .controller("DashboardController", ["$scope", "dashboardService", "projectService", "projectTypeService",
      function($scope, dashboardModel, projectModel, projectTypeModel) {


      }
    ]);

})(angular);
