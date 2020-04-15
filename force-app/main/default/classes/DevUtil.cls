public class DevUtil{
    
    public static void deleteProject(String projectid){
        TriggerUtil.SkipAllTriggers();
        DELETE [SELECT id FROM Job__c WHERE Project__c = :projectid];
        DELETE [SELECT id FROM Project__c WHERE Id = :projectid];
    }
    
    public static void deleteProjects(List<Project__c> projects){
        Set<Id> projectIds = new Set<Id>();
        for(Project__c proj : projects){
            projectIds.Add(proj.Id);
        }
        
        TriggerUtil.SkipAllTriggers();
        DELETE [SELECT id FROM Job__c WHERE Project__c IN:projectIds];
        DELETE [SELECT id FROM Project__c WHERE Id IN:projectIds];
        
    }

    public static void createTestProjectData() {

        Id retailerId = [SELECT Id FROM Retailer__c LIMIT 1].Id;
        Id accountId = [SELECT Id FROM Account LIMIT 1].Id;
        Id scheduleOptionId = [SELECT Id from ScheduleOption__c LIMIT 1].Id;
        Id projectTypeId = [Select Id FROM ProjectType__c LIMIT 1].Id;
        Id locationId = [SELECT Id FROM Location__c LIMIT 1].Id;

        Project__c project = new Project__c(
            Name = 'Project ' + retailerID
            , Status__c = 'Planning'
            , StartDate__c = System.today().addDays(60)
            , EndDate__c = System.today().addDays(90)
            , ProjectType__c =  projectTypeId
            , Retailer__c = retailerID
            , ProjectScheduleOption__c = scheduleOptionId
        );
        insert project;

        insert new ProjectAccount__c(
            Account__c = accountId
            , IsPrimary__c = true
            , Project__c = project.Id
            , SplitValue__c = 100
        );

        insert new ProjectLocation__c(
            Project__c = project.Id
            , Location__c = locationId
        );
        
        ProjectService__c projectService = new ProjectService__c(
            Project__c = project.Id
            , Service__c = [SELECT Id FROM Service__c LIMIT 1].Id
            , TargetType__c = 'Brand'
            , OneHubRetailerId__c ='WALMARTUS'
        );
        insert projectService;
        
        insert new ProjectServiceTarget__c(
            ProjectService__c = projectService.Id
            , Target__c = [SELECT Id FROM Target__c LIMIT 1].Id
            , Type__c = 'Primary'
            , Quantity__c = 0
            , Price__c = 0
            , YieldPerUnit__c = 0
        );    
        
        List<ProjectServiceAttribute__c> projectServAttributes = new List<ProjectServiceAttribute__c>();
        for (ServiceAttribute__c serviceAttribute : [SELECT Id, Name, Attribute__c, Service__c, Attribute__r.AttributeType__c FROM ServiceAttribute__c LIMIT 6]) {

            projectServAttributes.add(new ProjectServiceAttribute__c(
                Attribute__c = serviceAttribute.Attribute__c
                , AttributeValue__c   = ''
                , ProjectService__c = projectService.Id
                , Service__c = serviceAttribute.Service__c
                , ServiceAttribute__c = serviceAttribute.Id
            ));
        }
        insert projectServAttributes;

        Attachment[] attachmentsForInsert = new Attachment[]{};
        for (Attribute__c attachAttribute : [SELECT Id, Name, AttributeType__c FROM Attribute__c WHERE Description__c LIKE '%attachment%']) {
        
            attachmentsForInsert.add(new Attachment(
                Body = blob.valueOf('iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAACXBIWXMAAAsTAAALEwEAmpwYAAAKT2lDQ1BQaG90b3Nob3AgSUNDIHByb2ZpbGUAAHjanVNnVFPpFj333vRCS4iAlEtvUhUIIFJCi4AUkSYqIQkQSoghodkVUcERRUUEG8igiAOOjoCMFVEsDIoK2AfkIaKOg6OIisr74Xuja9a89')
                , Name = 'delete.png'
                , ParentId = attachAttribute.Id
            ));

            attachmentsForInsert.add(new Attachment(
                Body = blob.valueOf('iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAACXBIWXMAAAsTAAALEwEAmpwYAAAKT2lDQ1BQaG90b3Nob3AgSUNDIHByb2ZpbGUAAHjanVNnVFPpFj333vRCS4iAlEtvUhUIIFJCi4AUkSYqIQkQSoghodkVUcERRUUEG8igiAOOjoCMFVEsDIoK2AfkIaKOg6OIisr74Xuja9a89')
                , Name = 'delete.jpg'
                , ParentId = attachAttribute.Id
            ));

            attachmentsForInsert.add(new Attachment(
                Body = blob.valueOf('iVBORw0KGgoAAAANSUhEUgAAABQAAAAUCAYAAACNiR0NAAAACXBIWXMAAAsTAAALEwEAmpwYAAAKT2lDQ1BQaG90b3Nob3AgSUNDIHByb2ZpbGUAAHjanVNnVFPpFj333vRCS4iAlEtvUhUIIFJCi4AUkSYqIQkQSoghodkVUcERRUUEG8igiAOOjoCMFVEsDIoK2AfkIaKOg6OIisr74Xuja9a89')
                , Name = 'delete.pdf'
                , ParentId = attachAttribute.Id
            ));
        }
        insert attachmentsForInsert;

        insert new ImageServiceSettings__c(
            Name = 'ImageService'
            , URL__c ='https://api.crossmark.com/ImageService/PlanningSoln'
            , Password__c ='external\\m3.testing'
        );
    }

    public static void createJobTestData(Id projectId){
        createJobTestData(projectId, '');
    }

    public static void regenerateTestJobs(Id projectId, Integer count) {

        delete [SELECT Id FROM Job__c WHERE Project__c = :projectId];

        Project__c project = [SELECT Id, StartDate__c, EndDate__c FROM Project__c WHERE Id = :projectId];
        ProjectLocation__c projectLocation = [SELECT Id, Location__c FROM ProjectLocation__c WHERE Project__c = :projectId LIMIT 1];
        ProjectService__c projectService = [SELECT Id, Service__c FROM ProjectService__c WHERE Project__c = :projectId LIMIT 1];

        Job__c[] testJobs = new Job__c[]{};
        for (Integer i=0; i<count; i++) {

            testJobs.add(new Job__c(
                Project__c = project.Id
                , Location__c = projectLocation.Location__c
                , ProjectLocation__c = projectLocation.Id
                , ProjectService__c = projectService.Id
                , Service__c = projectService.Service__c
                , JobStartDate__c = project.StartDate__c
                , JobEndDate__c = project.StartDate__c
            ));
        }
        insert testJobs;
    }
    
    public static void createJobTestData(Id projectId, String status){
        Integer jobCount = [SELECT Count() FROM Job__c WHERE Project__c = :projectId];
        
        Decimal scheduledPercent = 100;
        Decimal assignedPercent = 98;
        Decimal executedPercent = 95;
        
        Project__c p = [SELECT Id, Status__c, StartDate__c, EndDate__c FROM Project__c WHERE Id = :projectId ORDER BY Name];
        List<Job__c> scheduledJobs = [SELECT Id, JobStatus__c, ProjectService__c FROM Job__c WHERE Project__c = :projectId];
        List<Job__c> assignedJobs = Database.query('SELECT Id, JobStatus__c, ProjectService__c FROM Job__c WHERE Project__c = :projectId ORDER BY Name LIMIT ' + Integer.valueOf(jobCount * (assignedPercent/100.0)));
        List<Job__c> executedJobs = Database.query('SELECT Id, JobStatus__c, ProjectService__c FROM Job__c WHERE Project__c = :projectId ORDER BY Name LIMIT ' + Integer.valueOf(jobCount * (executedPercent/100.0)));
        
        if(status != ''){
            TriggerUtil.SkipProjectTrigger = true;
            p.Status__c = status;
            update p;
        }
        
        List<ProjectServiceQuestion__c> sqs = [Select Id, Name, QuestionText__c, QuestionNumber__c, QuestionType__c, ProjectService__c, Question__c FROM ProjectServiceQuestion__c WHERE ProjectService__c IN (Select Id from ProjectService__c WHERE Project__c = :projectId) Order By QuestionNumber__c];
        Set<Id> sqIds = (new Map<Id,ProjectServiceQuestion__c>(sqs)).keySet();
        
        for(Job__c job :assignedJobs){
            job.JobStatus__c = 'Assigned';
        }
        update assignedJobs;
        
        for(Job__c job :executedJobs){
            job.JobStatus__c = 'Completed';
        }
        update executedJobs;
        
        system.debug('scheduledJobs.size(): ' + scheduledJobs.size());
        system.debug('assignedJobs.size(): ' + assignedJobs.size());
        system.debug('executedJobs.size(): ' + executedJobs.size());
        
    }
    
    
    public static void UpdateProjectsStatus(List<Project__c> projects,String status){        
        List<Project__c> projList = new List<Project__c>();
        if(status!='reserved'){
            for(Project__c proj : projects){
                proj.status__c = status;
                projList.add(proj);
            }
            upsert projList;
        }
        else{
            for(Project__c proj : projects){
                 project__c projTemp= [SELECT Id, Name,  EndDate__c, Status__c, ProjectType__c, ProjectType__r.Name FROM Project__c WHERE ID =: proj.id];
                 BatchReserveHandler batch = new BatchReserveHandler(projTemp);
                 Database.ExecuteBatch(batch, 500);
            }
        }
    }

    public static void UpdateProjectStatus(id proj,String status){        
        project__c projTemp = [SELECT Id, Name,  EndDate__c, Status__c, ProjectType__c, ProjectType__r.Name FROM Project__c WHERE ID =: proj];

        if(status!='reserved'){
            projTemp.status__c = status;
            upsert projTemp;
        }
        else
        {
             BatchReserveHandler batch = new BatchReserveHandler(projTemp);
             Database.ExecuteBatch(batch, 500);
        }        
    }
}