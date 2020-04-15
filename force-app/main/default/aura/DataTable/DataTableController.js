({
  onInit: function(cmp, evt, helper) {
    helper.onInit(cmp, evt);
  },

  onDataChange: function(cmp, evt, helper) {
    helper.onDataChange(cmp, evt);
  },

  onCheckboxChange: function(cmp, evt, helper) {
    evt.preventDefault();
    evt.stopPropagation();
    helper.onCheckboxChange(cmp, evt);
  },

  showSpinner: function(cmp, evt, helper) {
    helper.showSpinner(cmp);
  },

  hideSpinner: function(cmp, evt, helper) {
    helper.hideSpinner(cmp);
  },

  onClickSelectAll: function(cmp, evt, helper) {
    helper.onSelectAll(cmp, evt);
  },

  onSort: function(cmp, evt, helper) {
    helper.onSort(cmp, evt);
  },

  assignSelectedValue: function(cmp, evt, helper) {
    helper.calculateValue(cmp, evt);
  }
})