({
  doInit: function(component, event, helper) {
	
    if (component.get("v.recordId") == null)  
    {
        component.set("v.recordId","a16110000013SdsAAE");
    }

    helper.getService(component);
  },
})