({
	goToProjectService: function(component, event, helper, serviceTab) {
        var navEvent = $A.get("e.force:navigateToURL"),
        	url = "/one/one.app#/sObject/"+component.get("v.service").Id+"/view?slideDevName="+serviceTab+'&v=' + Date.now();
        	console.log(url, "service url");
        navEvent.setParams({
            "url": url
        });
        navEvent.fire();

    }
})