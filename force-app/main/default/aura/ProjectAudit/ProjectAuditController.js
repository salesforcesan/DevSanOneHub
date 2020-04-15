({
	doInit : function(component, event, helper) {
        //var compEvent = component.getEvent("init");
        //compEvent.fire();
        /* Call javascript helper class to get TimelineWrapper custom object from "getTimeline" method */
        helper.getTimeline(component);
    }
})