public with sharing class BirstReportExt {
    
    public string urlValue{get;set;}
    
    public string collectionName{get;set;}
    public string DashBoardName{get;set;}
    public string SpaceID{get;set;}
    
    public BirstReportExt(ApexPages.StandardController controller) {
        GetPermissionSetInfo();
    }
    
    public void GetPermissionSetInfo()
    {
        try
        {
            List<PermissionSetAssignment> lstcurrentUserPerSet =    [SELECT Id, PermissionSet.Name,AssigneeId FROM PermissionSetAssignment WHERE AssigneeId = :Userinfo.getUserId() ];
            system.debug('##lstcurrentUserPerSet' + lstcurrentUserPerSet);
                
            set<string> permSets = new set<string>();
            for (PermissionSetAssignment psa: lstcurrentUserPerSet)
            {
                permSets.add(psa.PermissionSet.Name.toLowerCase());           
            }
            permSets.add('default');
            
            string rptName='';
            
            list<BirstSetting__c > rtnVals = [SELECT CollectionName__c, DashBoardName__c,SpaceID__c  FROM BirstSetting__c where PermissionSetName__c in:permSets order by Priority__c];
            if(rtnVals!=null&&rtnVals.size()>0)
            {
                collectionName = rtnVals[0].CollectionName__c;
                DashBoardName= rtnVals[0].DashBoardName__c;                
                SpaceID = rtnVals[0].SpaceID__c;
            }   
            system.debug('##rptName' + collectionName +  '    ##DashBoardName__c ' + DashBoardName );
            
            //urlValue = 'https://login.bws.birst.com/AppExchangeSSO.aspx?serverurl='+!$API.Partner_Server_URL_250+'&sessionid='+!$API.Session_ID+'&birst.useSFDCEmailForBirstUsername=true&birst.spaceId=8acb5a65-83dd-4333-af8d-e623d424c82f&birst.hideDashboardNavigation=false&birst.hideDashboardPrompts=false&birst.module=newDashboards&birst.page=Execution%20Dashboard&birst.dashboard=Corporate%20Manager';
            urlValue = 'https://login.bws.birst.com/AppExchangeSSO.aspx?serverurl={!$Api.Partner_Server_URL_250}&sessionid={!$Api.Session_ID}&birst.useSFDCEmailForBirstUsername=true&birst.spaceId=8b30316a-61c9-4695-8c46-08a72aa9b421&birst.hideDashboardNavigation=false&birst.hideDashboardPrompts=false&birst.module=newDashboards&birst.page=Execution%20Dashboard&birst.dashboard=Corporate%20Manager';
            system.debug('##urlValue ' + urlValue );
            
        }
        catch(exception ex)
        {
            ApexPages.Message myMsg = new ApexPages.Message(ApexPages.Severity.FATAL,ex.getmessage());
            ApexPages.addMessage(myMsg);    
        }
    }
    

}