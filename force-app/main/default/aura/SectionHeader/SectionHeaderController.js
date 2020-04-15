({
    doInit : function(component, event, helper) {
        var psID = component.get("v.ProjServiceID");
        console.log('PSOverView   -   psid  --' + psID);
        helper.LoadMethod(component, psID);
        var serv = component.get("v.service");
        
        
    }
})