(function(A){
  'use strict';

  A.module("app.projectServiceView.detail",[
    "ui.router",
    "cmk.web.context",
    "cmk.system.async"
  ])
  .config(["$stateProvider", "cmkWebContext",
    function(_stateProvider, _webContext){
      _stateProvider.state("projectServiceView.detail",{
        url: "/detail",
        templateUrl: _webContext.applicationPath + "/assets/packages/projectServiceView/projectService.detail.html",
        controller: "ProjectServiceViewDetailController"
      });
  }])
  .controller("ProjectServiceViewDetailController",
    ["$scope","$log","projectServiceData", "cmkWebContext", function($scope, $log, data, webContext){
      $scope.tabVM.selDetailTab = true;
      $scope.details = [
        {
          label1: "Purchase Amount",
          value1: data.PurchaseAmount,
          label2: "Start Time",
          value2: data.StartTime,
        },
        {
          label2: "End Time",
          value2: data.EndTime,
          label1: "Cancel Reason",
          value1: data.CancelReason
        },
        {
          label1: "Objective",
          value1: data.Objective,
          label2: "Preparation Instructions",
          value2: data.Preparation
        },
        {
          label1: "Selling Point",
          value1: data.SellPoint,
          label2: "Serving Instruction",
          value2: data.Instruction
        }
      ];
      $scope.audit = [
        {
          label1: "Created By",
          value1: data.CreatedBy,
          label2: "Created Date",
          value2: !isNaN(data.CreatedDate) ? new Date(data.CreatedDate).toISOString() : data.CreatedDate
        },
        {
          label1: "Last Modified By",
          value1: data.UpdatedBy,
          label2: "Last Modified Date",
          value2:  !isNaN(data.UpdatedDate) ? new Date(data.UpdatedDate).toISOString() : data.UpdatedDate
        }
      ];
  }]);
})(angular);
