public with sharing class AddEditProjectAccountExt {

     
     
     public boolean ShowSplitAmount {get; set;}
     public void addMessage(ApexPages.Severity severity, String message){
     Apexpages.addMessage(new ApexPages.Message(severity, message));} 
     public Project__c project{get; set;}
     
    ApexPages.StandardController con;
    public AddEditProjectAccountExt(ApexPages.StandardController controller) {
           con= controller;
           
           ProjectAccount__c pa = (ProjectAccount__c) con.getRecord();
           Project= [SELECT Id,Name,SplitType__c FROM Project__c where id =: pa.project__c];
           if(Project.SplitType__c == 'Solo')
           {
               ShowSplitAmount = false;
           }
           else
           {
               ShowSplitAmount = true;
           }
           
           
    }


    public PageReference save()
     {        
        try
        {
            ProjectAccount__c pa = (ProjectAccount__c) con.getRecord();
            string tmp = pa.Project__c +'_'+  pa.Account__c +'_'+ pa.BillToAddress__c;//should be same as unique key
            integer cnt  = [select count() from projectaccount__c where UniqueKey__c =: tmp and project__c =: pa.project__c];
            
            system.debug('~~~~~pa.id~~~');
            
            if(cnt>0){
              addMessage(ApexPages.Severity.ERROR, 'The Account/Bill To Address selected has already been added to the project. Please select another Bill To Address for the selected Account.'); 
              return null; 
            }
            
            Project__c Project= [SELECT SplitType__c FROM Project__c where id =: pa.project__c];
            if(Project.SplitType__c == 'Solo')
            {
               pa.SplitValue__c = 100;
            }
            pa.UniqueKey__c = pa.Project__c +'_'+  pa.Account__c +'_'+ pa.BillToAddress__c;  //please update tmp variable before updating unique key
            con.save();
            
            pa = (ProjectAccount__c) con.getRecord();
            
            system.debug('~~~~~pa.id~~~'+pa.id);
            if(pa.id <> null)
            {
              return new PageReference(ApexPages.currentPage().getParameters().get('retURL'));
            }
            else
            {
              return null;
            }
        }         
        catch(Exception ex){
            system.debug('~~~inside ex'+ex.getMessage());        
            if (ex.getMessage().Contains('duplicate'))
            {
                addMessage(ApexPages.Severity.ERROR, 'Account already added. Please check and try again.');
            }
            else if(ex.getMessage().Contains('UniqueKey__c duplicates value')){
                addMessage(ApexPages.Severity.ERROR, 'Account already added. Please check and try again.');
            }
            else
            {
                addMessage(ApexPages.Severity.ERROR, ex.getMessage());
            }            
        }
        return null;
    }
}