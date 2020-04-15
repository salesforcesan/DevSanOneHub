(function(A){
  A.module("app.projectServiceView.model",['cmk.web.context','cmk.system.async'])
  .factory("projectServiceViewModel", ['cmkSystemAsync', 'cmkWebContext', '$q','$timeout',
    function(asyncApi, webContext, $q, $timeout){
      return {
        getProjectService: function(){
          var defer = $q.defer();
          $timeout(function(){
            var data = {};
            data.Id = "1";
            data.ProjectId = "p1";
            data.ProjectTitle ="p1:test";
            data.ServiceId= "s1";
            data.ServiceName = "s1:name";
            data.StartTime = "11am";
            data.EndTime = "14pm";
            data.Duration = "3 hours";
            data.PurchaseAmount = 123.12;
            data.CancelReason = "";
            data.Executor = "Execution Company";
            data.TargetType  = "Product";
            data.CreatedBy = "David, Zhao";
            data.CreatedDate = new Date(2015,11,11,12,0,0,0);
            data.UpdatedBy = "David Zhao";
            data.UpdatedDate = new Date(2015,11,11,14,0,0,0);
            data.Preparation = "Prepare: Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.";
            data.Objective = "Objective: Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.";
            data.Instruction = "Instruction: Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.";
            data.SellPoint = "SellingPoint: Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.";
            data.Status = "Planning";
            defer.resolve(data);
          }, 1200);

          return defer.promise;
        }
      };
    }]);

    A.module("app.projectServiceView.items.model",[])
    .factory("projectServiceViewItemsModel", [
      "$q",
      "$timeout",
      function ($q, $timeout){
        return {
          getItems: function() {
            var defer = $q.defer();
            $timeout(function(){
              var data = {};
              data.id = "111";
              data.name = "nm 1111";
              defer.resolve(data);

            },1500);
           return defer.promise;
          }
        };
      }
    ]);

    A.module("app.projectServiceView.materials.model", [])
    .factory("projectServiceViewMaterialsModel",[
      "$q",
      "$timeout",
      function($q, $timeout) {
        return {
          getMaterials: function() {
              var defer = $q.defer();
              $timeout(function(){
                var data = {};
                data.id = "material 1",
                data.name = "material name 1";
                defer.resolve(data);
              },1000);

              return defer.promise;
          }
        };
      }
    ]);

    A.module("app.projectServiceView.surveyQuestions.model",[
    ])
    .factory("projectServiceViewSurveyQuestionsModel",[
      "$q",
      "$timeout",
      function($q, $timeout){
        return {
          getQuestions: function() {
            var defer = $q.defer();
            $timeout(function(){
              var data = {};
              data.id = "survey 1";
              data.name = "survey name 1";
              defer.resolve(data);
            },1000);

            return defer.promise;
          }
        };
      }
    ]);

    A.module("app.projectServiceView.equipments.model",[
    ])
    .factory("projectServiceViewEquipmentsModel",[
      "$q",
      "$timeout",
      function($q, $timeout){
        return {
          getEquipments: function() {
            var defer = $q.defer();
            $timeout(function(){
              var data = {};
              data.id = "equipment 1";
              data.name = "equipment name 1";
              defer.resolve(data);
            },1000);

            return defer.promise;
          }
        };
      }
    ]);

})(angular);
