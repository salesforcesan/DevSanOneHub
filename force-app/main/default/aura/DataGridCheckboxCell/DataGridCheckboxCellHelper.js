({
  CHECKBOX_CLICK_EVENT: 'systemDataGridCheckboxCellClick',

  checkOne: function(cmp, evt) {
    var cmpEvt = cmp.getEvent(this.CHECKBOX_CLICK_EVENT),
      cell = cmp.get('v.field');
    cell.__parent.__selected = cell.__selected;
    cmpEvt.setParams({
      'id': this.CHECKBOX_CLICK_EVENT,
      'context': cell
    });

    cmpEvt.fire();
  }
})