({
  onInit: function(cmp, evt, helper) {
    helper.onInit(cmp, evt);
  },
  watchPagesChange: function(cmp, evt, helper) {
    helper.watchPagesChanged(cmp, evt);
  },
  selectPage: function(cmp, evt, helper) {
    helper.selectPage(cmp, evt);
  },
  nextPage: function(cmp, evt, helper) {
    helper.nextPage(cmp, evt);
  },
  prevPage: function(cmp, evt, helper) {
    helper.prevPage(cmp, evt, helper);
  },
  gotoFirstPage: function(cmp, evt, helper) {
    helper.gotoFirstPage(cmp, evt);
  }
})