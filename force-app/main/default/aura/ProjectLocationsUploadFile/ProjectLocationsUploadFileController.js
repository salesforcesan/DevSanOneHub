({
  onInit: function(cmp, evt, helper) {
    helper.onInit(cmp);
  },

  onAdd: function(cmp, evt, helper) {
    helper.add(cmp);
  },

  onSelectFile: function(cmp, evt, helper) {
    helper.selectFile(cmp, evt);
  },

  clickSelectOne: function(cmp, evt, helper) {
    helper.selectOne(cmp, evt);
  },

  onChangeFile: function(cmp, evt, helper) {
      console.log('onchnaged');
      
    helper.onChangeFile(cmp, evt);
  },

  onLocationChanged: function(cmp, evt, helper) {
    helper.handleLocationChanged(cmp, evt);
  },

  clickSelectAll: function(cmp, evt, helper) {
    helper.selectAll(cmp, evt);
  },

  onCancel: function(cmp, evt, helper) {
    helper.closeDialog(cmp);
  },

  onSuccess: function(cmp, evt, helper) {
    helper.onSuccess(cmp, evt);
  },

  onError: function(cmp, evt, helper) {
    helper.onError(cmp, evt);
  }
})