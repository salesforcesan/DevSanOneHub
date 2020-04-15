({
    doInit: function(component, event, helper) {
        //helper.getReportUrl(component, event, helper);
        helper.onInt(component, event, helper);
       helper._getLoggedInUser3PlAgency(component, event, helper);
      
    },
    onClickImport3PlWorkers:function(component, event, helper) {
            
       helper.import3PLWorkers(component, event,helper);
 
    },
    openActionWindow : function(component, event, helper) {
        window.open(component.get('v.thirdPartyReportURL'));
    },
     onEndImportJobs: function(cmp, evt, helper){
          helper.endImportJobs(cmp,evt);
      }

})