({
  onInit: function(cmp, evt, helper) {
    helper.onInit(cmp);
  },

  onChangeYear: function(cmp, evt, helper) {
    helper.onChangeYear(cmp, evt);
  },

  onPrevious: function(cmp, evt, helper) {
    helper.goPreviousMonth(cmp, evt);
  },

  onNext: function(cmp, evt, helper) {
    helper.goNextMonth(cmp, evt);
  },

  onSelectToday: function(cmp, evt, helper) {
    helper.selectToday(cmp, evt);
  },

  onSelectDate: function(cmp, evt, helper) {
    helper.selectDate(cmp, evt);
  },

  onValueChanged: function(cmp, evt, helper) {
    helper.valueChanged(cmp, evt);
  }
})