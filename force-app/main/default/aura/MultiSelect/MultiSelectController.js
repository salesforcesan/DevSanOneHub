({
  onStartSelect: function(cmp, evt, helper) {
     
    helper.startSelect(cmp, evt);
  },

  onValueChange: function(cmp, evt, helper) {
      
    helper.valueChanged(cmp, evt);
  },

  onItemSelect: function(cmp, evt, helper) {
        
    helper.itemSelected(cmp, evt);
  },

  onDropdownEnter: function(cmp, evt, helper) {
     
    helper.enterDropdown(cmp, evt);
  },

  onDropdownLeave: function(cmp, evt, helper) {
      
    helper.leaveDropdown(cmp, evt);
  },

  onBlur: function(cmp, evt, helper) {
      
    helper.blur(cmp, evt);
  }
})