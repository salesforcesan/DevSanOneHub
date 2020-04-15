({
  onCheckOne: function(cmp, evt, helper) {
    helper.checkOne(cmp, evt);
  },
  onCheckAll: function(cmp, evt, helper) {
    helper.checkAll(cmp, evt);
  },
  onClickDeleteCurrentJob: function(cmp, evt, helper) {
    helper.deleteCurrentJob(cmp, evt);

  },
  onClickJobDetails: function(cmp, evt, helper) {
    helper.jobDetails(cmp, evt);
  },
  unSelectCurrentCard: function(cmp, evt, helper) {
    helper.unSelectCurrentCard(cmp, evt);
  },

})