({
  onInit: function(cmp, evt, h) {
    h.init(cmp);
  },

  onErrorChanged: function(cmp, evt, h) {
    h.errorChanged(cmp);
  },

  onResultsChanged: function(cmp, evt, h) {
    h.resultsChanged(cmp);
  },

  onFileChanged: function(cmp, evt, h) {
    h.fileChanged(cmp, evt);
  },

  onFileSelected: function(cmp, evt, h) {
    h.fileSelected(cmp, evt);
  }
});