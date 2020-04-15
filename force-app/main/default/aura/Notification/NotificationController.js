({
  onShow: function(cmp, evt, helper) {
    helper.show(cmp, evt);
  },

  onClose: function(cmp, evt, helper) {
    helper.close(cmp);
  },

  onChangeVisible: function(cmp, evt, helper) {
    helper.visibleChanged(cmp, evt);
  }
})