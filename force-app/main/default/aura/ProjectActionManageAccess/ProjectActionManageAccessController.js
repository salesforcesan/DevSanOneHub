({
    doInit: function(component, event, helper) {
        
        var projectId = component.get("v.recordId");

        //To check if project data access is overridable
        helper.isOverridable(component,event)        
        
        //Fetch data access list;
        helper.getProjectAccountServiceAccessList(component, event, projectId);                
        
        setTimeout(function() {                               
            	helper.refreshDataAccessList(component, event);
			}, 1000);
        
    },
    handleIsOverride: function(component, event, helper) {       
        
       var checkbox  = event.getSource();
       component.set('v.overrideAccess', checkbox.get("v.value"));        
    },    
    fireCheckAllCheckboxes : function(component, event, helper) {        
   
       	var checkbox = event.getSource();        
      	var ProjectAccoutServiceAcesses = component.get('v.ProjectAccoutServiceAcesses');
        
        var rowLength = ProjectAccoutServiceAcesses.length;
        var horizontalLength = component.get('v.ProjectServices').length;

        var indexValue = checkbox.get("v.text").substring(1);        
        var checkboxValue = checkbox.get("v.value");      
        
        if(checkbox.get("v.text").charAt(0) == 'R')
        {                       
             for(var i = 0; i < horizontalLength; i++) {                  
            	ProjectAccoutServiceAcesses[indexValue].ProjectAccountService[i].Access = checkboxValue;
             }
        }

        if(checkbox.get("v.text").charAt(0) == 'C')
        {                        
            for(var i = 0; i < rowLength; i++) {
            	ProjectAccoutServiceAcesses[i].ProjectAccountService[indexValue].Access = checkboxValue;
            }
        }
        
        component.set('v.ProjectAccoutServiceAcesses',ProjectAccoutServiceAcesses);
        
		helper.refreshDataAccessList(component, event);
                    
	},
    refreshAcessList: function(component, event, helper){        
      	helper.refreshDataAccessList(component, event);
    },
    handleCancelClick: function(component, event, helper){              	
        helper.CancelClicked(component, event, helper);
    },
    handleSaveClick : function(component, event, helper) {         
        
        //To scroll to top of the inner div
        component.find("containerDiv").getElement().scrollIntoView(true);        
        
		helper.save(component, event);        
        
    }
})