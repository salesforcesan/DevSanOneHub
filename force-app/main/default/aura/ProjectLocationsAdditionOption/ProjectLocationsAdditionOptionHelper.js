({
  selectOption: function(cmp, evt) {
    var option = evt.currentTarget.getAttribute('data-value');
    var event = cmp.getEvent('selectAddLocationOptionEvent');
    event.setParams({
      id: option
    });
    event.fire();
  }
})