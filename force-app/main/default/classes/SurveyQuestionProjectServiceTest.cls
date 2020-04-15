@isTest
public class SurveyQuestionProjectServiceTest{

    public static testMethod void Test_SurveyQuestion()
    {
        
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, Date.today(),Date.today().addDays(2));         
        ProjectService__c ps = [SELECT id, Service__c FROM ProjectService__c LIMIT 1];
        
        PageReference sqpsPage = Page.SurveyQuestionsProjectService;       
        Test.setCurrentPage(sqpsPage);
        ApexPages.currentPage().getParameters().put('Id', ps.Id);
        
        ApexPages.StandardController controller = new ApexPages.StandardController(ps);        
        SurveyQuestionProjectServiceController sqpsCtrl = new SurveyQuestionProjectServiceController(controller);
        
        system.assertNotEquals(sqpsCtrl, null);
        
        
        
        List<ProjectServiceQuestion__c> sq = [SELECT Id FROM ProjectServiceQuestion__c];
        sqpsCtrl.param_surveyQuestionID = sq[sq.size() - 1].Id;
        sqpsCtrl.moveUp();
        sqpsCtrl.param_surveyQuestionID = sq[0].ID;
        sqpsCtrl.moveDown();
        sqpsCtrl.RemoveSurveyQuestion();
        sqpsCtrl.newsq.Question__c = [Select Id from Question__c LIMIT 1].Id;
        
        
        sqpsCtrl.AddSurveyBankQuestion();

    }    
}