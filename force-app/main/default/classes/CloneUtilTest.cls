@isTest
public class CloneUtilTest {

    @testSetup static void setup() {
        TestDataUtil.init();
        TestProject tP = TestProject.create('demo');
        tP.addAccount()
        .addServices(3)
        .addLocations(2);
        for(TestProjectService tPs: tP.TestProjectServiceList) {
            tPs.addSurvey();
        }
    }

    static void add100ServiceToProject(Project__c project) {
        TestDataUtil.disableTriggers();
        //step1 create 100 service
        List<String> names = new List<String>();
        for (Integer i = 0; i < 200; i++) {
            names.add('name' + String.valueOf(i));
        }

        List<Service__c> rs = TestDataUtil.initServicesByNames(names);

        //step2 add to retailer service
        Retailer__c retailer = [select id from Retailer__c limit 1];
        TestDataUtil.initRetailerServicesByServiceList(retailer, rs);
        List<RetailerService__c> retailerServices = [SELECT Id,Service__r.Name, Service__c,Retailer__c FROM RetailerService__c];

        //step3 add to project services
        List<ProjectService__c> psList = new List<ProjectService__c>();

        for (RetailerService__c service : retailerServices) {
            ProjectService__c ps = new ProjectService__c(
                Project__c = project.Id,
                Service__c = service.Service__c,
                ServiceTitle__c = service.Service__r.Name,
                TargetType__c = 'Brand',
                JobManual__c = 'Standard',
                NumberOfWorkers__c = 1,
                OneHubRetailerId__c = 'OH' + String.valueOf(service.Retailer__c)
            );
            psList.add(ps);
        }
        TestDataUtil.enableTriggers();
        insert psList;
    }

    static Integer getProjectServiceCount(string projectId){
        List<AggregateResult> results = [Select Count(Id) total FROM ProjectService__c
         WHERE Project__c=:projectId];
         return Integer.valueOf(results.get(0).get('total'));
    }

    static Integer getProjectLocationCount(string projectId){
        list<AggregateResult> results = [SELECT Count(Id) total FROM ProjectLocation__c 
        WHERE Project__c=:projectId];
        return Integer.valueOf(results.get(0).get('total'));
    }

    
    @istest static void itShouldCloneMoreThan100Services() {
        //GIVEN
        Project__c p = [SELECT Id from Project__c WHERE Name = 'demo' LIMIT 1];
        TestProject tP = TestProject.get(p.Id);
        add100ServiceToProject(tP.ProjectInstance);

        Integer expectedProjectServiceCount = getProjectServiceCount(p.Id);
        integer expectedProjectLocationCount = getProjectLocationCount(p.Id);

        //WHEN
        test.startTest();
        Id projectId = CloneUtil.CloneAll(p.Id);
        test.stopTest();

        //THEN
        List<Project__c> cPList = [SELECT Id from Project__c WHERE id = :projectId];
        QA.isTrue(cPList.size() > 0, 'Cloned project created');

        Integer resultProjectServiceCount = getProjectServiceCount(cPList[0].Id);
        QA.EQ(expectedProjectServiceCount, resultProjectServiceCount, 'The same number of project services created.' + resultProjectServiceCount);
        integer resultProjectLocationCount = getProjectLocationCount(p.Id);
        QA.EQ(expectedProjectLocationCount, resultProjectLocationCount, 'The same number of project locations created.' + resultProjectLocationCount);
    }

    static Map<String, List<ProjectServiceQuestionDefinedResponse__c>> groupResponses(String pId) {
        Set<Id> psIdSet = new Set<Id>();
        for(ProjectServiceQuestion__c s: 
            [SELECT Id from ProjectServiceQuestion__c
            WHERE ProjectService__r.Project__c = :pId]) {
            psIdSet.add(s.Id);
        }

        Map<String, List<ProjectServiceQuestionDefinedResponse__c>>
        answerMap = new Map<String, List<ProjectServiceQuestionDefinedResponse__c>>();
        List<ProjectServiceQuestionDefinedResponse__c> deleteList = new List<ProjectServiceQuestionDefinedResponse__c>();
        List<ProjectServiceQuestionDefinedResponse__c> items;
        
        for(ProjectServiceQuestionDefinedResponse__c a: [
            SELECT ProjectServiceQuestion__c, Id, Active__c FROM ProjectServiceQuestionDefinedResponse__c
            WHERE ProjectServiceQuestion__c in :psIdSet 
            AND ProjectServiceQuestion__r.Question__r.QuestionType__c = 'Single-Select List' ORDER BY ProjectServiceQuestion__c]) {
            if (answerMap.containsKey(a.ProjectServiceQuestion__c)) {
                items = answerMap.get(a.ProjectServiceQuestion__c);
            }
            else {
                items = new List<ProjectServiceQuestionDefinedResponse__c>();
            }
            items.add(a);
            answerMap.put(a.ProjectServiceQuestion__c, items);
        }
        return answerMap;
    }

    static void setupTestDataForProjectServiceQuestions(String pId) {

        Map<String, List<ProjectServiceQuestionDefinedResponse__c>> answerMap = groupResponses(pId);
        List<ProjectServiceQuestionDefinedResponse__c> deleteList = new List<ProjectServiceQuestionDefinedResponse__c>();
        List<ProjectServiceQuestionDefinedResponse__c> items;
        
        integer index = 0;
        integer cursor = 0;
        integer len = 0;

        List<ProjectServiceQuestionDefinedResponse__c> updates = 
            new  List<ProjectServiceQuestionDefinedResponse__c>();
         List<ProjectServiceQuestionDefinedResponse__c> deletes = 
         new  List<ProjectServiceQuestionDefinedResponse__c>();

        for(List<ProjectServiceQuestionDefinedResponse__c> aList: answerMap.values()) {
            len= aList.size() - 2;
            if (Math.mod(cursor, 2) == 0) {
            cursor++;
                for (integer i=0; i < len; i++) {
                    deletes.add(aList.get(i));                    
                }
            } else {
                for(integer i = 0; i < len; i++){
                 aList.get(i).Active__c = false;       
                 updates.add(aList.get(i));
                }
            }
        }
        if (deletes.isEmpty()){
            throw new CustomException('no answer to delete');
        }
        if (updates.isEmpty()){
         throw new CustomException('no answer to update');   
        }
        delete deletes;
        update updates;
    }



    static void ensureEachQuestionHasTwoAnswers(string pId) {
        Map<String, List<ProjectServiceQuestionDefinedResponse__c>> answerMap = groupResponses(pId);
        integer size = 0;

        for (List<ProjectServiceQuestionDefinedResponse__c> aList: answerMap.values()){
            size = 0;
            for(ProjectServiceQuestionDefinedResponse__c a: aList){
                if (a.Active__c == true) {
                    size++;
                }
            }
            if (size != 2) {
                throw new CustomException('there are more answers:' + string.valueOf(size));
            }
        }
    }

    @istest static void itShouldCloneProjectWithTwoTrueQuestionResponses() {
        //GIVEN
        Project__c p = [SELECT Id from Project__c LIMIT 1];
        setupTestDataForProjectServiceQuestions(p.Id);
        ensureEachQuestionHasTwoAnswers(p.Id);

        //WHEN
        test.startTest();
        String pId = CloneUtil.CloneAll(p.Id);
        test.stopTest();

        //THEN
        ensureEachQuestionHasTwoAnswers(pId);
    }
}