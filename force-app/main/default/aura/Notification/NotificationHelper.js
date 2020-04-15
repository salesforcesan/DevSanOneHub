({
  DURATION_DEFAULT: 5000,
  ERROR_TYPES: {
    'ERROR': 'error',
    'SUCCESS': 'success',
    'WARNING': 'warning',
    'INFO': 'info'
  },
  POSITION: {
    'RELATIVE': 'relative',
    'ABSOLUTE': 'absolute'
  },

  show: function(cmp, evt) {
    var params = evt.getParam('arguments');
    if (!params) {
      console.log('there is no error messages to show');
      return;
    }
    cmp.set('v.autoHide', $A.util.getBooleanValue(params.autoHide || false));
    cmp.set('v.message', params.message);
    cmp.set('v.type', params.messageType);
    cmp.set('v.duration', params.duration);
	cmp.set('v.visible', true);      
  },

  close: function(cmp) {
    cmp.set('v.visible', false);
  },

  visibleChanged: function(cmp, evt) {
    var self = this,
      duration = cmp.get('v.duration') || this.DURATION_DEFAULT;

    function hideUI(cmp) {
      cmp.set('v.position', self.POSITION.RELATIVE);
      cmp.set('v.message', '');
      cmp.set('v.type', self.ERROR_TYPES.INFO);
      cmp.set('v.duration', self.DURATION_DEFAULT);
      cmp.set('v.autoHide', false);
      cmp.set('v.visible', false);
    }

    if ($A.util.getBooleanValue(cmp.get('v.visible'))) {
      if ($A.util.getBooleanValue(cmp.get('v.autoHide'))) {
        var id = window.setTimeout(function() {
          window.clearTimeout(id);
          if (cmp.isValid()) {
            hideUI(cmp);
          }
        }, duration);
      }
    } else {
      hideUI(cmp);
    }
  }
})