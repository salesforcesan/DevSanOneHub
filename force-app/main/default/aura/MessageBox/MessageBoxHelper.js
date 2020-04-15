({
  MSGBOX_EVENT: 'messageBoxEvent',
  THEME_CLASS: {
    'info': 'slds-theme--info',
    'success': 'slds-theme--success',
    'warning': 'slds-theme--warning',
    'error': 'slds-theme--error'
  },
  NO_OVERLOW_CLASS: 'cmk-no-overflow1',
  DIALOG_OPEN_CLASS: 'slds-fade-in-open',
  DIALOG_CLOSE_CLASS: 'fade-out-close',
  DIALOG_BACKDROP_OPEN_CLASS: 'slds-backdrop--open',

  onShow: function(cmp, evt) {
    var option, dlg = cmp.find('dialog'),
      backDrop = cmp.find('dialogBackdrop'),
      params = evt.getParam('arguments') || {};
    option = params.option || {};

    cmp.set('v.id', option.id || '');
    cmp.set('v.title', option.title || 'Prompt Dialog');
    cmp.set('v.body', option.body || '<p>No Content Specified.</p>');
    cmp.set('v.themeClass', this.THEME_CLASS[option.severity || 'error']);
    cmp.set('v.positiveLabel', option.positiveLabel || 'Ok');
    cmp.set('v.negativeLabel', option.negativeLabel || 'Cancel');
    cmp.set('v.negativeButtonClass', option.hideNegative ? 'msgbox-hide' : '');
    cmp.set('v.style', '<style>.viewport .stage {z-index:5 !important;}.cmk-no-overflow {overflow: hidden !important;overflow-y: hidden !important;}</style>');

    if (!$A.util.hasClass(dlg, this.DIALOG_OPEN_CLASS)) {
      $A.util.addClass(dlg, this.DIALOG_OPEN_CLASS);
    }
    if (!$A.util.hasClass(backDrop, this.DIALOG_BACKDROP_OPEN_CLASS)) {
      $A.util.addClass(backDrop, this.DIALOG_BACKDROP_OPEN_CLASS);
    }
    this._bodyNoOverflow();
  },

  onClose: function(cmp, evt) {
    var self = this,
      dlg = cmp.find('dialog'),
      backDrop = cmp.find('dialogBackdrop');

    $A.util.addClass(dlg, self.DIALOG_CLOSE_CLASS);

    function doClose(cmp) {
      cmp.set('v.style', '');
      self._bodyOverflow(self);
      $A.util.removeClass(dlg, self.DIALOG_OPEN_CLASS);
      $A.util.removeClass(backDrop, self.DIALOG_BACKDROP_OPEN_CLASS);
      $A.util.removeClass(dlg, self.DIALOG_CLOSE_CLASS);
    }
    self._async(cmp, doClose, 100);
  },

  doPositiveThing: function(cmp, evt) {
    this._raiseEvent(cmp, 1);
    this.onClose(cmp, evt);
  },

  _raiseEvent: function(cmp, value) {
    var msgEvent = cmp.getEvent(this.MSGBOX_EVENT);
    msgEvent.setParams({
      'id': cmp.get('v.id'),
      'context': value
    });
    msgEvent.fire();
  },

  doNegativeThing: function(cmp, evt) {
    this._raiseEvent(cmp, 0);
    this.onClose(cmp, evt);
  },

  _bodyNoOverflow: function(self) {
    var body = document.body;
    var domTokenList = body.classList;
    self = self || this;
    if (!domTokenList.contains(self.NO_OVERLOW_CLASS)) {
      domTokenList.add(self.NO_OVERLOW_CLASS);
    }
  },

  _bodyOverflow: function(self) {
    var body = document.body;
    var domTokenList = body.classList;
    self = self || this;
    if (domTokenList.contains(self.NO_OVERLOW_CLASS)) {
      domTokenList.remove(self.NO_OVERLOW_CLASS);
    }
  },

  _async: function(cmp, callback, duration) {
    if (!callback) {
      return;
    }
    duration = duration || 200;
    var id = window.setTimeout($A.getCallback(function() {
      window.clearTimeout(id);
      if (cmp.isValid()) {
        callback(cmp);
      }
    }), duration);
  }
})