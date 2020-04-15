({
  onInit: function(cmp, evt, h) {
    h.init(cmp);
  },

  onFileContentReady: function(cmp, evt, h) {
    h.fileContentReady(cmp, evt);
  },

  onFileInvalid: function(cmp, evt, h) {
    h.fileInvalid(cmp, evt);
  },

  onHeightChanged: function(cmp, evt, h) {
    h.heightChanged(cmp);
  },

  onStepFooterEvent: function(cmp, evt, h) {
    h.stepFooterEvent(cmp, evt);
  },
  onStep1Event: function(cmp, evt, h) {
    h.step1Event(cmp, evt);
  },
  onStep2Event: function(cmp, evt, h) {
    h.step2Event(cmp, evt);
  },
  onStep3Event: function(cmp, evt, h) {
    h.step3Event(cmp, evt);
  },
  onSubmit: function(cmp, evt, h) {
    h.submit(cmp);
  },
  onClose: function(cmp, evt, h) {
    h.close(cmp);
  },
  onCancel: function(cmp, evt, h) {
    h.cancel(cmp);
  }
});