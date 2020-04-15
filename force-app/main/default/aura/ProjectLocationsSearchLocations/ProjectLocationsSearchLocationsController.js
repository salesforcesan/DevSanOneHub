({
  init: function(cmp, evt, helper) {
    helper.init(cmp, evt);
  },

  blurSearchKeyword: function(cmp, evt, helper) {
    helper.searchKeyword(cmp, evt);
  },

  clickCancel: function(cmp, evt, helper) {
    helper.cancel(cmp);
  },

  clickAddLocations: function(cmp, evt, helper) {
    helper.addLocations(cmp);
  },

  clickFilter: function(cmp, evt, helper) {
    helper.applyFilter(cmp, evt);
  },

  clickClear: function(cmp, evt, helper) {
    helper.clearFilter(cmp, evt);
  },

  onDataTableRendered: function(cmp, evt, helper) {
    helper.dataTableRendered(cmp, evt);
  },

  onSuccess: function(cmp, evt, helper) {
    helper.onSuccess(cmp, evt);
  },

  onError: function(cmp, evt, helper) {
    helper.onError(cmp, evt)
  }
})