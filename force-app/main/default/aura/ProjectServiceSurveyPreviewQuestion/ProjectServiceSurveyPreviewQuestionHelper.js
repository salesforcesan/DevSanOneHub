({
	setSelectedResponse: function(cmp, e, h) {
		var selected = e.getSource().get('v.value');
        cmp.set('v.selectedResponse', selected);
	},
    
    continueResponse: function(cmp, e, h, mult) {
		var value = e.getSource().get('v.value');
        if($A.util.isEmpty(value)){
            cmp.set('v.selectedResponse', '');
        } else {
          cmp.set('v.selectedResponse', 'next');  
        }
	},
    
     numberHandler: function(cmp, e, h) {
		var value = e.getSource().get('v.value');
        var question = cmp.get('v.currentQuestion');
        if(question.MinValue != null || question.MaxValue != null) {
             if(value > parseInt(question.MaxValue) || value < parseInt(question.MinValue)) {
                cmp.set('v.error', true);
            } else {
                cmp.set('v.error', false); 
            }
        }
        cmp.set('v.updatedInput', value);
        if($A.util.isEmpty(value)){
            cmp.set('v.selectedResponse', '');
        } else {
          cmp.set('v.selectedResponse', 'next');  
        }
	},
    
    fireEvent:function(cmp, e, selected) {
        var cmpEvent = cmp.getEvent("EventResponseSelectedV2");
        cmpEvent.setParams({
            "responseId" : selected
        });
        cmpEvent.fire();
        cmp.set('v.error', false);
        cmp.set('v.selectedResponse', '');
        cmp.set('v.updatedInput', '');
        cmp.set('v.updatedInputs', []);
    }
})