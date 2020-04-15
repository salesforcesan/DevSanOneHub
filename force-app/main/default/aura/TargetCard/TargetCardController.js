({
      doInit : function(component, event, helper) {
      
        
    },
	onCheck : function(component, event, helper) {
        console.log('onCheck');
		var Selected = component.get("v.target.Selected");
        console.log('Selected', Selected);
        if(Selected === true)
        {
            component.set("v.target.Selected", false); 
            
        }
        else
        {
            component.set("v.target.Selected", true);            
        }
	}
})