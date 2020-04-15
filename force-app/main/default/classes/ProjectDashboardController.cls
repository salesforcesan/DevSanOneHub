public with sharing class ProjectDashboardController {
    Public string inputtext{get;set;}
    Public string SelectedET_Status{get;set;}
    Public string SelectedRS_Status{get;set;}
    public list<project__c> EventProjs{get;set;}
    public id projID{get;set;}

    /*{!URLFOR($Action.Project__c.Edit,a.id)}" styleClass="actionLink" rendered="{!OR(a.Status__c == 'Planning',a.Status__c == 'In Progress',a.Status__c == 'Booked',a.Status__c == 'Finished', a.Status__c == 'Rejected')} */

    public PageReference SetStatus() {
        PageReference ConfirmPage = new PageReference('/CancelProjectView');
        ConfirmPage.setRedirect(true);
        return ConfirmPage;
    }

    public list<SelectOption> getEventTrackStatus(){
       List<SelectOption> options = new List<SelectOption>();
       for(string str: new list<string>{'ET All','ET Draft','ET Pending Approval','ET Scheduled','ET Executed'})
       {
            options.add(new SelectOption(str,str));
       }
       return options;
    }

    public list<SelectOption> getRSStatus(){
       List<SelectOption> options = new List<SelectOption>();
       for(string str: new list<string>{'All','Planning','Pending Approval','Booked','In Progress','Finished','Canceled','Rejected'})
       {
            options.add(new SelectOption(str,str));
       }
       return options;
    }


    public List < Project__c > getMyProjects() {
        return [select id, name, status__c, owner.Id, owner.Name, OriginID__c,  StartDate__c, EndDate__c,  ProjectNumber__c, ProjectType__c,LocationTotalCount__c,isdeleted__c  from Project__c
            where ownerid = : UserInfo.getUserId() order by status__c, LastModifiedDate desc LIMIT 1000
        ];
    }

    public List < Project__c > getDraftProjects() {
        return [select id, name, status__c, owner.Id, owner.Name,  StartDate__c, EndDate__c, ProjectNumber__c, ProjectType__c, LocationTotalCount__c from Project__c
            where status__c = 'Planning' and isdeleted__c=false
            order by LastModifiedDate desc LIMIT 1000
        ];
    }

    public List < Project__c > getExternalProjects() {
        return [select id, name, status__c, owner.Id, owner.Name,  StartDate__c, EndDate__c, ProjectNumber__c, ProjectType__c, OriginID__c, LocationTotalCount__c from Project__c
            where IsExternalProject__c = true
            order by LastModifiedDate desc LIMIT 1000
        ];
    }

    public List < Project__c > getPendingProjects() {
        return [select id, name, status__c, owner.Id, owner.Name,  StartDate__c, EndDate__c, ProjectNumber__c, ProjectType__c, LocationTotalCount__c, OriginID__c  from Project__c
            where status__c = 'Pending Approval'
            order by LastModifiedDate desc LIMIT 1000
        ];
    }

    public List < Project__c > getScheduledProjects() {
        return [select id, name, status__c, owner.Id, owner.Name,  StartDate__c, EndDate__c, ProjectNumber__c, ProjectType__c, LocationTotalCount__c from Project__c
            where status__c = 'Booked'
            order by LastModifiedDate desc LIMIT 1000
        ];
    }
    
    public List < Project__c > getlaunchedProjects() {
        return [select id, name, status__c, owner.Id, owner.Name,  StartDate__c, EndDate__c, ProjectNumber__c, ProjectType__c, LocationTotalCount__c from Project__c
            where status__c = 'Launched'
            order by LastModifiedDate desc LIMIT 1000
        ];
    }

    public List < Project__c > getExecutedProjects() {
        return [select id, name, status__c, owner.Id, owner.Name,  StartDate__c, EndDate__c, ProjectNumber__c, ProjectType__c, LocationTotalCount__c from Project__c
            where status__c = 'Ended'  LIMIT 1000
        ];
    }

    public List < Project__c > getInProgressProjects() {
        return [select id, name, status__c, owner.Id, owner.Name,  StartDate__c, EndDate__c, ProjectNumber__c, ProjectType__c, LocationTotalCount__c from Project__c
            where status__c = 'In Progress'
            order by LastModifiedDate desc LIMIT 1000
        ];
    }

    public List < Project__c > getCanceledProjects() {
        return [select id, name, status__c, owner.Id, owner.Name,  StartDate__c, EndDate__c, ProjectNumber__c, ProjectType__c, LocationTotalCount__c from Project__c
            where status__c = 'Canceled'
            order by LastModifiedDate desc LIMIT 1000
        ];
    }

    public List<Project__c> getRejectedProjects() {
        return [select id, name, status__c, owner.Id, owner.Name,  StartDate__c, EndDate__c, ProjectNumber__c, ProjectType__c, LocationTotalCount__c from Project__c
            where status__c = 'Closed'
            order by LastModifiedDate desc LIMIT 1000
        ];
    }


    public List<Project__c> getDeletedProjects() {
        return [select id, name, status__c, owner.Id, owner.Name,  StartDate__c, EndDate__c, ProjectNumber__c, ProjectType__c, LocationTotalCount__c from Project__c
            where status__c = 'Planning' and isdeleted__c=true order by LastModifiedDate desc LIMIT 1000];
    }
    public void cloneProject(){
        /*Id cloneProj;// = CloneUtil.CloneAll(projID);
        PageReference pageRef = new PageReference('/apex/ProjectDetailsView?id=' + cloneProj);
        pageRef.setRedirect(true);
        return pageRef;*/
    }

}