({
  NO_OVERLOW_CLASS: 'cmk-no-overflow1',
  _dlg_open_class: 'slds-fade-in-open',
  _dlg_close_class: 'fade-out-close',
  _dlg_backdrop_open_class: 'slds-backdrop--open',
  _dlg_dialog_save_event: 'dialogModalSaveComponentEvent',
  _supported_modal_size: ['slds-modal--small', 'slds-modal--medium', 'slds-modal--x-medium', 'slds-modal--large'],

  _bodyNoOverflow: function() {
    var body = document.body;
    var domTokenList = body.classList;
    if (!domTokenList.contains(this.NO_OVERLOW_CLASS)) {
      domTokenList.add(this.NO_OVERLOW_CLASS);
    }
  },

  _bodyOverflow: function() {
    var body = document.body;
    var domTokenList = body.classList;
    if (domTokenList.contains(this.NO_OVERLOW_CLASS)) {
      domTokenList.remove(this.NO_OVERLOW_CLASS);
    }
  },


  close: function(cmp, evt) {
    var dlg = cmp.find('dialog'),
      self = this,
      backDrop = cmp.find('dialogBackDrop');

    $A.util.addClass(dlg, self._dlg_close_class);

    function doClose(cmp) {
      cmp.set('v.style', '');
      cmp.set('v.body', '');
      self._bodyOverflow();
      $A.util.removeClass(dlg, self._dlg_open_class);
      $A.util.removeClass(dlg, self._dlg_close_class);
      $A.util.removeClass(backDrop, self._dlg_backdrop_open_class);
    }

    self._async(cmp, doClose, 100);
  },

  show: function(cmp, evt) {
    var dlg = cmp.find('dialog'),
      backDrop = cmp.find('dialogBackDrop');
    cmp.set('v.style', '<style>.viewport .stage {z-index:5 !important;}.cmk-no-overflow {overflow: hidden !important;overflow-y: hidden !important;}</style>');
    this._setTheme(cmp);
    if (!$A.util.hasClass(dlg, this._dlg_open_class)) {
      $A.util.addClass(dlg, this._dlg_open_class);
    }
    if (!$A.util.hasClass(backDrop, this._dlg_backdrop_open_class)) {
      $A.util.addClass(backDrop, this._dlg_backdrop_open_class);
    }
    this._bodyNoOverflow();
  },

  _setTheme: function(cmp) {
    var themeClass = '',
      brand = cmp.get('v.brand');
    switch (brand) {
      case 'error':
        themeClass = 'slds-theme--error slds-theme--alert-texture';
        break;
      case 'warning':
        themeClass = 'slds-theme--warning slds-theme--alert-texture';
        break;
      case 'info':
        themeClass = 'slds-theme--info slds-theme--alert-texture';
        break;
      case 'success':
        themeClass = 'slds-theme--success slds-theme--alert-texture';
        break;
    }
    cmp.set('v.themeClass', themeClass);
  },

  save: function(cmp, evt) {
    var saveEvent = cmp.getEvent(this._dlg_dialog_save_event);
    saveEvent.setParams({ 'id': cmp.get('v.id') });
    saveEvent.fire();
  },

  rerender: function(cmp) {
    var dlg = cmp.find('dialog'),
      size = cmp.get('v.size') || 'medium',
      cssClass = 'slds-modal--' + size;
    this._supported_modal_size
      .forEach(function(css) {
        $A.util.removeClass(dlg, css);
      });
    $A.util.addClass(dlg, cssClass);
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