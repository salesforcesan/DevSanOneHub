({
  onInit: function(cmp, evt, h) {
    h.init(cmp);
  },

  onNextClicked: function(cmp, evt, h) {
    h.captureEvents(evt);
    h.nextClicked(cmp);
  },

  onPrevClicked: function(cmp, evt, h) {
    h.captureEvents(evt);
    h.prevClicked(cmp);
  },

  onCancelClicked: function(cmp, evt, h) {
    h.captureEvents(evt);
    h.cancelClicked(cmp);
  },

  onShowStepper: function(cmp, evt, h) {
    h.showStepper(cmp, evt);
  },

  onNextEnabledChanged: function(cmp, evt, h) {
    h.nextEnabledChanged(cmp, evt);
  },

  onStepDefsChanged: function(cmp, evt, h) {
    h.stepDefsChanged(cmp, evt);
  }
});