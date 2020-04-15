({
  LINK_CLICK_EVENT: 'systemDataGridLinkCellClick',

  onClick: function(cmp, evt) {
    var cell = cmp.get('v.field'),
      cmpEvt = cmp.getEvent(this.LINK_CLICK_EVENT);
    cmpEvt.setParams({
      'id': this.LINK_CLICK_EVENT,
      'context': cell
    });
    cmpEvt.fire();
  }
})