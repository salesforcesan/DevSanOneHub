public class ProjectApprovalEmailTemplateController {

    public Id projectId {
        get;
        set;
    }
   
    public Project__c project {
        get {
            project = [SELECT name, StartDate__c, EndDate__c, Retailer__r.Name, ProjectType__r.Name from Project__c where Id = : projectId];
            return project;
        }

        set;
    }
    
    public Integer reservedLocations {
        get {

            Integer counter = [Select count() FROM ProjectLocation__c Where Status__c = 'Booked'
            and Project__c = : projectId];
            return counter;
        }

        set;
    }

    public String ServicesPerformed {
        get {

            List < ProjectService__c > projectServices = [Select Service__r.Name FROM ProjectService__c Where Project__c = : projectId];
            List < String > serviceList = new List < String > ();

            for (ProjectService__c ps: projectServices) {

                serviceList.add(ps.Service__r.Name);
            }
            String result = String.join(serviceList, ',');

            return result;
        }

        set;
    }
    
    public List<ProjectServiceTarget__c> items{
        get {
            List < ProjectServiceTarget__c> items= [SELECT Type__c,Target__r.name,Target__r.StockCode__c,Target__r.UPC__c,TotalPrice__c,Quantity__c  
            FROM ProjectServiceTarget__c where ProjectService__c in (select id from ProjectService__c  where project__c=: projectId )];  
            return items;
        }

        set;
    }
    
     public List<Job__c> locations{
        get {
            List < Job__c> locations= [SELECT LocationNumber__c,Location__r.City__c,LocationState__c,/*ServiceName__c,*/JobStartDate__c FROM Job__c where project__c=: projectId LIMIT 1000];  
            return locations;
        }

        set;
    }


}