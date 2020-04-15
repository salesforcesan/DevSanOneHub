({
  init: function(cmp) {
    this.variantChanged(cmp);
  },

  variantChanged: function(cmp) {
    var variant = cmp.get("v.variant");
    switch (variant) {
      case "horizontal":
        this._setClassName(
          cmp,
          "slds-list_horizontal slds-wrap slds-p-around_xx-small"
        );
        break;
      case "stacked":
        this._setClassName(
          cmp,
          "slds-list_stacked slds-wrap slds-p-around_xx-small"
        );
        break;
      default:
        this._setClassName(
          cmp,
          "slds-list_inline slds-wrap slds-p-around_xx-small"
        );
        break;
    }
  },

  _setClassName: function(cmp, className) {
    cmp.set("v.className", className);
  }
});