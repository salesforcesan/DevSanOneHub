({
    loadJaworkerList : function(component, event, helper) {
        
    
        component.set("v.columns",[
            {label:"Job Attempt Worker", fieldName:"Name",type:"text",sortable:true},
            {label:"Location Number", fieldName:"LocationNumber",type:"text",sortable:true},
            {label:"Location Name", fieldName:"LocationName",type:"text",sortable:true},
            {label:"Location State", fieldName:"LocationState",type:"text",sortable:true},
            {label:"Location City", fieldName:"LocationCity",type:"text",sortable:true},
            {label:"Duration(Mins)", fieldName:"EstimatedMinutes",type:"text",sortable:true},
            {label:"Scheduled Date", fieldName:"ScheduledDate",type:"date",sortable:true}
        ]);
        
        
        helper.JobAttemptWorkerList(component, event);
        
        
    },
    selectedJaworkers: function(component,event,helper)
    {
        
        var selectedRows = event.getParam('selectedRows');
        component.set("v.selectedjaw" , selectedRows);
              
    },
    approvalbuttonClicked :function(component,event,helper)
    {
        
        var data = component.get('v.selectedjaw');
        if(data.length == 0) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type" : "Warning",
                "message": "Please select Job Attempt Worker to approve"
            });
            toastEvent.fire();
            return;
        }
        
        helper.pendingRequestslist(component,event,data);
        
    },
    RejectbuttonClicked : function(component,event,helper)
    {
        var data = component.get('v.selectedjaw');
        if(data.length == 0) {
            var toastEvent = $A.get("e.force:showToast");
            toastEvent.setParams({
                "type" : "Warning",
                "message": "Please select Job Attempt Worker to Reject"
            });
            toastEvent.fire();
            return;
        }
        
      
        helper.renderRejectionDialog(component, event, helper);
        
       // helper.pendingRequestslist(component,event,data);
    },
    onRejectionworkerEvent: function (cmp, event, helper) {
         var val = event.getParam('context');
          //console.log('Value'+ val.comment);
         var data = cmp.get('v.selectedjaw');
       // console.log('data++++++'+ data);
        
      helper.pendingRequestslist(cmp,event,data);
        
    },

    updateColumnSorting: function (cmp, event, helper) {
       // alert('hello');
        var fieldName = event.getParam('fieldName');
        alert(fieldName);
        var sortDirection = event.getParam('sortDirection');
        cmp.set("v.sortedBy", fieldName);
        cmp.set("v.sortedDirection", sortDirection);
        helper.sortData(cmp, fieldName, sortDirection);
    },
   
})