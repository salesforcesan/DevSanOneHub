({
  init: function(cmp, evt, h) {
    cmp.set(
      "v.style",
      "<style>.slds-modal__container{max-width: 70rem !important; width:80% !important;} </style>"
    );
  },

  onClose: function(cmp, evt, h) {
    $A.get("e.force:closeQuickAction").fire();
  }
});