({
  NAMESPACE: 'c',
  ERROR_EVENT: 'e.c:ActionResponseErrorAppEvent',
  SUCCESS_EVENT: 'e.c:ActionResponseSuccessAppEvent',

  handleRemoteRequest: function(cmp, evt){
    var args = evt.getParam('arguments') || {},
      eventId = args.id || '',
      action = args.action || '',
      params = args.parameters || '';
      
    this.doRequest(cmp, eventId, action, params);
  },

  handleRequest: function(cmp, evt){
    var eventId = evt.getParam('id') || '',
      action = evt.getParam('action') || '',
      params = evt.getParam('parameters') || '';

    this.doRequest(cmp, eventId, action, params);
  },

  doRequest: function(cmp, eventId, action, params) {
    var request;

    if (!eventId || !action) {
      console.log(['eventId and action are required: eventId=', eventId, ' action=', action].join(''));
      this._error(cmp, eventId, 'The event id and action are required.');
      return;
    }

    try {
      request = cmp.get(this.NAMESPACE + '.' + action);
      if (!!params) {
        request.setParams(params);
      }
      request.setCallback(this, function(response) {
        var errors, state = response.getState();
        if (!cmp.isValid()) {
          console.log('The proxy component is out of scope eventId:' + eventId + ' action:' + action);
          return;
        }
        if ('SUCCESS' === state) {
          this._success(cmp, eventId, response.getReturnValue());
          return;
        }
        if ('ERROR' === state) {
          errors = response.getError();
          if (!!errors && !!errors[0] && !!errors[0].message) {
            this._error(cmp, eventId, errors[0].message);
          } else {
            this._error(cmp, eventId, 'The system run into an unknown error.')
          }
          return;
        }
        if ('INCOMPLETE' === state) {
          this._error(cmp, eventId, 'The system run into an incomplete state: eventId:' + eventId + ' action:' + action);
        }
        console.log('The system run into an unknown state: eventId:' + eventId + ' action:' + action)
      });
      $A.enqueueAction(request);
    } catch (ex) {
      console.log(ex);
      this._error(cmp, eventId, ex.toString());
    }
  },

  _success: function(cmp, eventId, value) {
    console.log('value'+ value);
    var success = $A.get(this.SUCCESS_EVENT);
    success.setParams({
      'id': eventId,
      'value': value
    });
    success.fire();
  },

  _error: function(cmp, eventId, message) {
    var error = $A.get(this.ERROR_EVENT);
    error.setParams({
      'id': eventId,
      'error': message
    });
    error.fire();
  }
})