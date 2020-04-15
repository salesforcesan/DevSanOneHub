({
  onCheckOne: function(cmp, evt, helper) {
    helper.checkOne(cmp, evt);
  },

  onCheckAll: function(cmp, evt, helper) {
    helper.checkAll(cmp, evt);
  },


  gotoDetail: function(cmp, evt, helper) {
    helper.gotoDetail(cmp, evt);
  },

  subscribeRemoteActionErrorAppEvent: function(cmp, evt, helper) {
    helper.onAppError(cmp, evt);
  }
})