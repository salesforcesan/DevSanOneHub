(function(A){
  A.module("app.project.model",[
    'cmk.web.context',
    'cmk.system.async'])
  .factory("projectModel",['cmkSystemAsync', 'cmkWebContext', '$q', '$timeout',
    function(asyncApi, webContext, $q, $timeout) {
      return {
        getProject: function() {
          var defer = $q.defer();
          $timeout(function(){
            var d = {};
            d.Id = "p1";
            d.Title = "project 1";
            d.Supplier = "Walmart";
            d.Type = "In Store Demo &amp; Sampling";
            d.Status = "Planning";
            d.StartDate = (new Date(2015,11,3,12,0,0,0)).getMilliseconds();
            d.EndDate = (new Date(2015,12,1,12,0,0,0)).getMilliseconds();
            d.ProjectNumber = 201511121212;
            d.ProjectGroup = "pgrup";
            d.ProjectSubGroup = "psgrup";
            d.CanReschedule = true;
            d.Retailer = "Sam's Club";
            d.Approver = "David Zhao";
            d.Description = "Lorem ipsum dolor sit amet, consectetuer adipiscing elit, sed diam nonummy nibh euismod tincidunt ut laoreet dolore magna aliquam erat volutpat.";
            d.Owner = "David Zhao";
            d.ImportedLocations = 12;
            d.BudgetedLocations = 10;
            d.JobCount= 1980;
            d.ServiceCount = 10;
            d.LocationCount = 100;
            d.CreatedBy = "Tom Souer";
            d.CreatedDate = new Date(2015,11,12,12,0,0,0).toISOString();
            d.UpdatedBy = "David Zhao";
            d.UpdatedDate = new Date(2015,11,15,12,0,0,0).toISOString();
            defer.resolve(d);
          }, 500);
          
          return defer.promise;
        }
      };
  }]);
})(angular);
