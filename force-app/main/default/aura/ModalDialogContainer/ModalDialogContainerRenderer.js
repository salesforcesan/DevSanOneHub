({
  rerender: function(cmp, helper) {
    this.superRerender();
    helper.rerender(cmp);
  }
})