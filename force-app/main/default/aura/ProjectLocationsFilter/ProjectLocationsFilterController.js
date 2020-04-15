({
  onInit: function(cmp, evt, helper) {
    helper.init(cmp, evt, helper);
  },
  onClickFilter: function(cmp, evt, helper) {
    helper.filterLocations(cmp, evt);
  },
  onClickClear: function(cmp, evt, helper) {
    helper.clearFilter(cmp, evt);
    helper.filterLocations(cmp, evt);
  },
  toggleFilters : function(cmp, evt, helper) {
    var toggleFilters = cmp.find("toggleFiltersId");
    //var hideAdv = cmp.find("hideAdv");
    $A.util.toggleClass(toggleFilters, "toggleFilters");
    //$A.util.toggleClass(hideAdv, "hideAdv");
  },
    closeFilters : function(cmp, evt, helper) {
        var closeFilters = cmp.find("toggleFiltersId");
        $A.util.toggleClass(closeFilters, "originalSize");
    }
    
  
})