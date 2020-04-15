({
    
    AppSettings: {
		action: "locationStateSetting"
	},
    genBody: function(cmp) {
		return {
			"recordId": '',
			
		};
	},
    
    loadLocationStateData:function(cmp, evt, h)
    {
        
         this.getDispatcher(cmp)
			.action(this.AppSettings.action)
            .body(this.genBody(cmp))
			.onSuccess(function(cmp, data) {
				cmp.set("v.states", data );
			})
			.onError(this.onError)
			.run(); 
        
    },
    
    
    changed: function(cmp, evt){
        var val = cmp.find('selState').get('v.value');
        cmp.set('v.value', val);
        this._onChanged(cmp, val);
    },

    _onChanged: function(cmp, value){
        var msg = cmp.getEvent('onStateChanged');
        msg.setParams({
            context: value
        });
        msg.fire();
    }
})