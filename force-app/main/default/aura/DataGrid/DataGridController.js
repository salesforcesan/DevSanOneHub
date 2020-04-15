({
  onInit: function(cmp, evt, helper) {
    helper.onInit(cmp, evt);
  },

  onSort: function(cmp, evt, helper) {
    helper.onSort(cmp, evt);
  },

  onClickSelectAll: function(cmp, evt, helper) {
    helper.selectAll(cmp, evt);
  },

  onDataChange: function(cmp, evt, helper) {
    helper.dataChanged(cmp, evt);
  },

  onCellButtonClick: function(cmp, evt, helper) {
    helper.onCellButtonClick(cmp, evt);
  },

  onCellLinkClick: function(cmp, evt, helper) {
    helper.onCellLinkClick(cmp, evt);
  },

  onCellCheckboxClick: function(cmp, evt, helper) {
    helper.onCellCheckboxClick(cmp, evt);
  },

  assignSelectedValue: function(cmp, evt, helper) {
    helper.assignSelectedValue(cmp, evt);
  },

  gotoPage: function(cmp, evt, helper) {
    helper.gotoPage(cmp, evt);
  }
})