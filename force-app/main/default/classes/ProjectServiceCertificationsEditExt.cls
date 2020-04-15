public with sharing class ProjectServiceCertificationsEditExt {
    
    public ProjectService__c ps{get;set;}
    public List<ProjectServiceCertification__c> pscList {get;set;}
    public List<SelectOption> CertificationSelectOptions {get;set;}
    public string SelectedCertification{get;set;}
    public Boolean showAddButton{get;set;}
    public Map<String,Boolean> editableMap {get;set;}
    
    private void addMessage(ApexPages.Severity severity, String message){
        Apexpages.addMessage(new ApexPages.Message(severity, message));
    }

    public ProjectServiceCertificationsEditExt(ApexPages.StandardController controller) {
        ps = [SELECT Id, Name, Project__r.Retailer__c, Service__c FROM ProjectService__c where id =:ApexPages.CurrentPage().getParameters().get('id') ];
        loadCertification();
        CertificationSelectOptions = new List<SelectOption>();
        CertificationSelectOptions.add(new SelectOption('','-None-'));
        for(Certification__c ct : [SELECT Id, Name FROM Certification__c WHERE ID NOT IN (SELECT Certification__c FROM RetailerServiceCertification__c WHERE Retailer__c =: ps.Project__r.Retailer__c AND Service__c =: ps.Service__c)]){
            CertificationSelectOptions.add(new SelectOption(ct.Id, ct.Name));
        }
        
        Project__c proj = [SELECT Id, Status__c FROM Project__c WHERE Id IN (Select Project__c from ProjectService__c where Id = :ps.Id ) LIMIT 1];
        
        Set<String> editableFields = new Set<String>{'Project__c.RL_Certifications'};
        editableMap = UIConfig.isEditale(proj.Status__c, editableFields);
        showAddButton = editableMap.get('Project__c.RL_Certifications') && Schema.sObjectType.ProjectServiceCertification__c.isUpdateable();
    }
    
    public void loadCertification(){
        pscList = [SELECT Id, Certification__c, ProjectService__c, IsLocked__c FROM ProjectServiceCertification__c WHERE ProjectService__c =:ps.Id ORDER BY IsLocked__c DESC];
    }
    
    
    
    public PageReference addCertification() {
    if(String.isBlank(SelectedCertification)){
                Apexpages.addMessage(new ApexPages.Message(ApexPages.Severity.ERROR, 'Please select a certification.'));
                return null;
            }

        try {
           
            ProjectServiceCertification__c psc = new ProjectServiceCertification__c();
            psc.ProjectService__c = ps.Id;
            psc.Certification__c = SelectedCertification;
            psc.IsLocked__c = false;
            insert psc;
            loadCertification();
            SelectedCertification = '';
            addMessage(ApexPages.Severity.CONFIRM, 'Certification(s) saved successfully.');  
            return null;
        }
        catch(Exception e){
            if (e.getMessage().Contains('duplicate'))
            {
                addMessage(ApexPages.Severity.ERROR, 'This certification has already been added. Please check and try again.');
                return null;
            
            }
            addMessage(ApexPages.Severity.ERROR, e.getmessage());
            return null;
        }
    }
    
    public PageReference deleteCertification(){
        try {  
            string pscDelId = ApexPages.currentpage().getParameters().get('pscCertId');
            for (ProjectServiceCertification__c psc : pscList) {
                if (pscDelId == psc.Id) {
                    
                    delete psc;
                    break;
                }
            }
            addMessage(ApexPages.Severity.CONFIRM, 'Certification deleted.');
            loadCertification();
            SelectedCertification = '';
            return null;
        }
        catch(Exception e) {
            addMessage(ApexPages.Severity.ERROR, e.getmessage());
            return null;
        }
    }
    
}