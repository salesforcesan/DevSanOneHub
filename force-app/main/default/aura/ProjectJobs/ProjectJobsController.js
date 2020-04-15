({
  onInit: function(cmp, evt, helper) {
    helper.init(cmp, evt);
  },
  toggleJobsList: function(component, event, helper) {
    helper.toggleJobsList(component, event);
  },
  clickSelectAll: function(cmp, evt, helper) {
    helper.handleSelectAll(cmp);
  },
  handleCheckOneJobEvent: function(cmp, evt, helper) {
    helper.handleCheckOneJobEvent(cmp, evt);
  },
  onClickRemoveAll: function(cmp, evt, helper) {
    helper.handleRemoveAll(cmp, evt);
  },
  clickSelectOne: function(cmp, evt, helper) {
    helper.handleSelectOne(cmp);
  },
  onDelete: function(cmp, evt, helper) {

    helper.handleDeleteSelected(cmp);
  },
  onDeleteOneJob: function(cmp, evt, helper) {
    helper.handleDeleteOneJob(cmp, evt);
  },
  removeSelected: function(cmp, evt, helper) {
    helper.handleRemoveSelected(cmp);
  },
  handleShowSpinnerEvent: function(cmp, evt, helper) {
    helper.handleShowSpinnerEvent(cmp, evt);
  },
  onBlurSearchKeyword: function(cmp, evt, helper) {
    helper.searchKeyword(cmp, evt);
  },

  /* App Event subscription */
  subscribeRemoteActionSuccessAppEvent: function(cmp, evt, helper) {
    helper.onAppSuccess(cmp, evt);
  },

  subscribeRemoteActionErrorAppEvent: function(cmp, evt, helper) {
    helper.onAppError(cmp, evt);
  },
  reattemptSelected: function(cmp, evt, helper) {
    helper.handleReAttemptSelected(cmp, evt);
  },
  onMessageBoxEvent: function(cmp, evt, helper) {
    helper.handleMessageBoxEvent(cmp, evt);
  },
  reloadJobs: function(cmp, evt, helper) {
    //window.location.reload();
    var msg = evt.getParam("message");
    helper.reloadJobs(cmp,msg);
  },
  onClickImportJobs: function (cmp, evt ,h ){
    h.importJobs(cmp, evt);
  },
  onEndImportJobs: function(cmp, evt, h){
    h.endImportJobs(cmp,evt);
  }
})