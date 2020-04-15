({
	onInit: function(cmp, evt, helper) {
    helper.init(cmp, evt);
  },

 /* onBlurSearchKeyword: function(cmp, evt, helper) {
    helper.searchKeyword(cmp, evt);
  },*/

  onClickFilter: function(cmp, evt, helper) {
    helper.filterJobs(cmp, evt);
  },

  onClickClear: function(cmp, evt, helper) {
    helper.clearFilter(cmp, evt);
  },
    
 toggleFilters : function(cmp, evt, helper) {
    var toggleFilters = cmp.find("toggleFiltersId");
    $A.util.toggleClass(toggleFilters, "toggleFilters");
  }
})