({
	doInit : function(component, event, helper) {		
        var timelinePoint;
        helper.getProjectDetails(component);
	},
    
    toggleTimeline : function(component, event, helper) {        
        var togTimeline = document.querySelectorAll('.timeline'), i;
        var togBtn = document.querySelectorAll('.toggleBtn'), i;
        for (var i = 0; i < togTimeline.length; i ++) {
          togTimeline[i].classList.toggle("hide");     
    	}
         for (var i = 0; i < togBtn.length; i ++) {
          togBtn[i].classList.toggle("down");     
    	}
        
    },
    onMessageBoxEvent: function(component,event,helper){
        var result={id:event.getParam('id'),
                    value:event.getParam('context')
                   };
		if (result.id==='releaseChanges' && result.value===1)
        {
            console.log("releaseProjectChanges event!");
            helper.cReleaseProjectChanges(component, event, helper);
        }
 		else if (result.id==='oocf' && result.value===1) {
            
            console.log("oocf event!");
            helper.cReleaseOOCF(component, event, helper);
            
        }        
    },
    
})