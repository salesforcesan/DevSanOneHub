({
  rerender: function(component, helper) {
    this.superRerender();
    helper.applySecurity(component);
  }
})