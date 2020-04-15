@isTest
public class ShiftNotCloseNotificationTest
{
    @testSetup
    public static void setup(){
        TriggerUtil.skipAllTriggers();
        TestDataUtil.init();
        TestProject.create('shift')
            .addAccount()
            .addAttributes()
            .addShiftService()
            .addLocations(1)
            .addJobs()
            .addJobAttempts()
            .addJobAttemptWorkers();
        tweakShiftsForTest();
        initTest();
    }

    static void tweakShiftsForTest(){
        Project__c p = TestProject.getProjects().get(0);
        Datetime endDTTM = Datetime.now().addMinutes(-30);
        List<Job__c> shifts = [
            SELECT Id, JobUTCEndTime__c FROM JOB__c WHERE Project__c = :p.Id];
        for(Job__c shift: shifts){
            shift.JobUTCEndTime__c = endDTTM;
        }
        update shifts;
    }

    public static void initTest(){
        initEmailTemplate();
    }

    @Future
    static void initEmailTemplate(){
        EmailTemplate et = new EmailTemplate();
        et.IsActive = true;
        et.Name = 'non_closed_shift_email_template';
        et.UIType= 'Aloha';
        et.DeveloperName = 'test';
        et.TemplateType = 'text';
        et.FolderId = UserInfo.getUserId();
        insert et;
        
    }

    @isTest 
    static void itShouldInitProperly(){
        //GIEVN
        BatchShiftNotCloseNotification notify = new BatchShiftNotCloseNotification();
        
        //WHEN
        test.startTest();
        Project__c testP = TestProject.getProjects().get(0);
        List<Job__c> testJ = TestProject.getJobs(testP.Id);
        OrgCustomSettings__c settings = TestDataUtil.getOrgCustomSettings();
        notify.start(null);
        notify.execute(null, new List<Job__c>());
        test.stopTest();
        
        //THEN
        EQ(1, testJ.size(), 'one job created');
        EQ(true, testJ.get(0).IsShift__c,'A shift job');
        EQ('no.reply@crossmark.com',settings.ErrorNotificationEmail__c,'error email setup');
        EQ('non_closed_shift_email_template',settings.NonClosedShiftEmailTemplate__c,'non closed shift email template setup');
    }

    @isTest
    static void itShouldRetrieveExpectedShifts(){
        //GIVEN
        Project__c p = TestProject.getProjects().get(0);
        List<Job__c> shifts = TestProject.getJobs(p.Id);

        //WHEN
        test.startTest();
        string sql = BatchShiftNotCloseNotification.buildQuery();
        List<Job__c> results = Database.Query(sql);
        test.stopTest();

        //THEN
        OK(shifts.get(0).ActiveJobAttempt__c != null, 'shift has An active attempt');
        EQ(shifts.size(), results.size(),'expect number of shifts returned');

    }

    @isTest
    static void isShouldCoverUpCodes(){
        //GIVEN
        BatchShiftNotCloseNotification notify = new BatchShiftNotCloseNotification();
        
        Map<String,String>error = new Map<String,String>();
        error.put('job','job');
        error.put('user','user');
        error.put('message','message');
        notify.Errors.add(error);

        //WHEN
        test.startTest();
        String errorStr = notify.genErrorString();
        String errorEmail = BatchShiftNotCloseNotification.getEmailDistribution();
        String errorRow = notify.genRow(error);
        String html = notify.genHtmlBody();
        Integer total = notify.totalCount;
        Integer errCount = notify.errorCount;
        Integer emailCount = notify.sendEmailCount;
        test.stopTest();

        //THEN
        EQ(0, total, 'total 0');
        EQ(0, errCount, ' error 0');
    }


    static void EQ(object expected, object result, String msg) {
        System.assertEquals(expected, result, msg);
    }

    static void OK(Boolean condition,String msg){
        System.assertEquals(true, condition,msg);
    }
}