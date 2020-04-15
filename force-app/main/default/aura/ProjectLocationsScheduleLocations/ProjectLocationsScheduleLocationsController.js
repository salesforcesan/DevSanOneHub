({
  onInit: function(cmp, evt, helper) {
    helper.onInit(cmp, evt);
  },
  onSuccess: function(cmp, evt, helper) {
    helper.onSuccess(cmp, evt)
  },
  onError: function(cmp, evt, helper) {
    helper.onError(cmp, evt);
  },
  onSelectDate: function(cmp, evt, helper) {
    helper.selectDate(cmp, evt);
  },
  onSchedule: function(cmp, evt, helper) {
    helper.scheduleLocations(cmp, evt);
  },
  onCancel: function(cmp, evt, helper) {
    helper.cancel(cmp);
  }
})