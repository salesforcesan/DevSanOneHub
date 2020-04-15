({
  onHelpsChanged: function(cmp, evt, h) {
    h.helpsChanged(cmp);
  },

  onSchemasChanged: function(cmp, evt, h) {
    h.schemasChanged(cmp);
  },

  onAnalyzeFile: function(cmp, evt, h) {
    h.analyzeFile(cmp, evt);
  },

  onFileContentReady: function(cmp, evt, h) {
    h.fileContentReady(cmp, evt);
  },

  onFileContentInvalid: function(cmp, evt, h) {
    h.fileContentInvalid(cmp, evt);
  }
});