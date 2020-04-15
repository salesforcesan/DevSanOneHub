({
  onClose: function(cmp, evt, helper) {
    helper.close(cmp, evt);
  },
  onCancel: function(cmp, evt, helper) {
    helper.close(cmp, evt);
  },
  onSave: function(cmp, evt, helper) {
    helper.save(cmp, evt);
  },
  onShow: function(cmp, evt, helper) {
    helper.show(cmp, evt);
  }
})