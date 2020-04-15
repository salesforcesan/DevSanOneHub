({
  afterRender: function(cmp, helper) {
    this.superAfterRender();
    helper.afterRender(cmp);
  },
  rerender: function(cmp, helper) {
    this.superRerender();
    helper.rerender(cmp);
  }
})