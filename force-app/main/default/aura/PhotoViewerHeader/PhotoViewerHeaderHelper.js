({
    toggleFilter: function(cmp, evt){
        var toggleState = !cmp.get('v.toggled');
        this._dispatch(cmp, toggleState);
    },

    toggleChanged: function(cmp, evt){
        this._setState(cmp, !!cmp.get('v.toggled'));
    },

    _setState: function(cmp, state){        
        var btn = cmp.find('btnToggle');
        var label = !!state ? 'Collapse Filter' : 'Exapnd Filter';
        btn.set('v.label', label);
        btn.set('v.title', label);
    },

    _dispatch: function(cmp, state){
        var msg = cmp.getEvent('onToggleFilter');

        msg.setParams({
            context: state
        });
        msg.fire();  
    }
})