({
  BUTTON_CLICK_EVENT: 'systemDataGridButtonCellClick',

  click: function(cmp, evt) {
    var cmpEvt = cmp.getEvent(this.BUTTON_CLICK_EVENT),
      cell = cmp.get('v.field');
    cmpEvt.setParams({
      'id': this.BUTTON_CLICK_EVENT,
      'context': cell
    });
    cmpEvt.fire();
  }
})