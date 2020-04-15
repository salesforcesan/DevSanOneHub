({
    doInit: function(cmp, e, h) {
       var question = cmp.get('v.currentQuestion');
        if(question.MinValue != null) {
           cmp.set('v.updatedInput', question.MinValue);
        }
    },
	inputChangeRadio : function(cmp, e, h) {  	
        h.setSelectedResponse(cmp, e, h);
    },
    
    inputChange : function(cmp, e, h) {  	
        h.continueResponse(cmp, e);
    },
    inputChangeMulti : function(cmp, e, h) { 
        var checked = e.getSource().get('v.checked');
        var inputs = cmp.get('v.updatedInputs');
        var value = e.getSource().get('v.value');
        if(checked){
            inputs.push(value);
            cmp.set('v.selectedResponse', 'next');
        } else {
            var fil = inputs.filter(item => item != value);
            inputs = fil;
            if($A.util.isEmpty(inputs)){
               cmp.set('v.selectedResponse', ''); 
            }
        }
        cmp.set('v.updatedInputs', inputs);
   
    },
    
     inputChangePhoto : function(cmp, e, h) {  
        cmp.set('v.updatedInput', 'Photo');
        cmp.set('v.selectedResponse', 'next');  
    },
    
    inputNumberChange : function(cmp, e, h) {  	
        h.numberHandler(cmp, e, h);
    },
    
    nextQuestionHandler : function(cmp, e, h) {  	
        var selected = cmp.get('v.selectedResponse');
        if(!selected) {
            selected = 'next';
        }
        h.fireEvent(cmp, e, selected);
    },
    
    previousQuestionHandler : function(cmp, e, h) {  	
        h.fireEvent(cmp, e, 'previous');
    },
        
})