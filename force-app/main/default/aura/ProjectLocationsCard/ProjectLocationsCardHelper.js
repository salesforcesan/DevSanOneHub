({
  checkOne: function(cmp, evt) {
    var checkOneEvent = cmp.getEvent('checkOneLocationEvent');
    checkOneEvent.fire();
  },

  checkAll: function(cmp, evt) {
    var locations = cmp.get('v.data');
    locations.forEach(function(loc) {
      location.selected = true;
    });
    cmp.set('v.data', locations);
  },

  gotoDetail: function(cmp, evt) {
    var plId = evt.currentTarget.getAttribute('data-id');
    var navEvt = $A.get("e.force:navigateToSObject");
    navEvt.setParams({

      "recordId": plId
    });
    navEvt.fire();
  }
})