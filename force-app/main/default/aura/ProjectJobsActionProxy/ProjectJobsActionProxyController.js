({
  onRequest: function(cmp, evt, helper) {
    helper.handleRequest(cmp, evt);
  },

  onRemoteRequest: function(cmp, evt, h){
    h.handleRemoteRequest(cmp, evt);
  }
})