({
  onPositive: function(cmp, evt, helper) {
    helper.doPositiveThing(cmp, evt);
  },
  onNegative: function(cmp, evt, helper) {
    helper.doNegativeThing(cmp, evt);
  },
  onShow: function(cmp, evt, helper) {
    helper.onShow(cmp, evt);
  },
  onClose: function(cmp, evt, helper) {
    helper.onClose(cmp, evt);
  }
})