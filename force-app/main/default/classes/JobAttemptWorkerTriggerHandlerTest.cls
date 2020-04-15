@isTest
public class JobAttemptWorkerTriggerHandlerTest {

    @testSetup
    static void init(){
        TestDataUtil.init();
        JobAttempt__c attempt = TestUtil.setupJobTestData(CONSTANTS.JOB_ATTEMPT_STATUS_ASSIGNED, CONSTANTS.JOB_STATUS_ASSIGNED);
        TestUtil.generateJobAttemptWorkers(attempt, 3);

    }
    
    @isTest
    static void itShouldUpdateJobAttemptWorkerContact(){
        
       
    	List<JobAttemptWorker__c> jaws = [Select Id, ContactId__c, Contact__c, JobAttempt__c FROM JobAttemptWorker__c 
                                          WHERE WorkerType__c = :CONSTANTS.JOB_ATTEMPT_WORKER_WORKER_TYPE_TEAM_LEAD LIMIT 1];
        
        System.assert(jaws.size() > 0, 'No job attempt workers found');
        System.assert(jaws[0].Contact__c == null);
        
        //Assign a contact Id
        List<Contact> contacts = [Select Id, ContactId__c from Contact LIMIT 1];
        System.assert(contacts.size() > 0, 'No contacts found');
        System.assert(jaws[0].Contact__c == null);

        //Assign a contactid and make sure the corresponding contact
        //is populated
        jaws[0].ContactId__c = contacts[0].ContactId__c;
        update jaws[0];
        string jawId = jaws[0].Id;
        
        //Refresh Job Attempt Worker
        List<JobAttemptWorker__c> jaws2 = [Select Id, ContactId__c, Contact__c, JobAttempt__c, WorkerType__c, JobAttempt__r.AssignedContactId__c, 
                                           JobAttempt__r.AssignedContact__c, DateAssigned__c FROM JobAttemptWorker__c WHERE Id = :jawId LIMIT 1];
        
        if (!jaws2.IsEmpty())
        {
            System.assert(jaws2[0].ContactId__c != null);
            System.assert(jaws2[0].DateAssigned__c != null);
            System.assert(jaws2[0].Contact__c != null);
            System.assert(jaws2[0].WorkerType__c == CONSTANTS.JOB_ATTEMPT_WORKER_WORKER_TYPE_TEAM_LEAD);
			List<JobAttempt__c> jas = [Select Id, AssignedContactId__c, AssignedContact__c FROM 
                                       JobAttempt__c WHERE Id = :jaws2[0].JobAttempt__c];
            if (!jas.IsEmpty())
            {
                System.assert(jas[0].AssignedContactId__c != null);
                System.assert(jas[0].AssignedContact__c != null);
                
            }
            
        }
    }
    
    /*
    @isTest
    static void itShouldSendEmailWhenWorkerIsCanceled(){
        
    	List<JobAttemptWorker__c> jaws = [Select Id, ContactId__c, Contact__c, JobAttempt__c, Status__c FROM JobAttemptWorker__c 
                                          WHERE WorkerType__c = :CONSTANTS.JOB_ATTEMPT_WORKER_WORKER_TYPE_TEAM_LEAD LIMIT 1];
        System.assert(jaws.size() > 0, 'No job attempt workers found');
        jaws[0].Status__c = CONSTANTS.JOB_ATTEMPT_WORKER_STATUS_CANCELED;
        update jaws;
        

        List<JobAttemptWorker__c> jaws2 = [Select Id, ContactId__c, Contact__c, JobAttempt__c, Status__c FROM JobAttemptWorker__c 
                                          WHERE WorkerType__c = :CONSTANTS.JOB_ATTEMPT_WORKER_WORKER_TYPE_TEAM_LEAD LIMIT 1];
        System.assert(jaws2[0].Status__c == CONSTANTS.JOB_ATTEMPT_WORKER_STATUS_CANCELED);
    }    
    */
    
}