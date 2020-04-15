({
    changed: function(cmp, evt){
        var val = cmp.find('optionControl').get('v.value');
        cmp.set('v.value', val);
        this._onChanged(cmp, val);
    },

    _onChanged: function(cmp, value){
        var msg = cmp.getEvent('onDropdownListOptionChanged');
        msg.setParams({
            context: {
                'id': cmp.get('v.id'),
                'value': value
            }
        });
        msg.fire();
    }
})