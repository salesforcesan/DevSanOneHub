({
    doInit : function(component, event, helper) {

        var psID = component.get("v.recordId");
        component.set("v.serviceId", psID);
        component.set("v.securityelements", "Project__c.RL_Certifications.Add");
        
        helper.getCerts(component, psID);  
		helper.getNameSpace(component, event, helper);        
    }, 
    AddCert : function(component, event, helper) {

        var cmp = component.find("CertsList"),
            SelectedVal = cmp.get("v.value"),
            psID = component.get("v.serviceId"); 
        
        if(SelectedVal!=null  && SelectedVal!="--" ){ 
            helper.AddCert(component, psID, SelectedVal);   
            cmp.set("v.value","");
        }
        else{
            alert("Please select a value");
        }
    },
    handleDeleteCertClick : function(component, event, helper) {

        component.set("v.certId", event.target.id);
        helper.openMessageBoxDeleteCert(component);           
    },
    handleMessageBoxEvent : function(component, event, helper) {
        
        if (event.getParam("id") === "deleteCert" && event.getParam("context")) {
            helper.deleteCert(component, event, helper);    
        }
    }
})