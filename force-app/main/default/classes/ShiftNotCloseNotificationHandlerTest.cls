@isTest
private class ShiftNotCloseNotificationHandlerTest {
	
    @testSetup
    static void setup(){
        ShiftNotCloseNotificationTest.setup();
    }

    @isTest
    static void itShouldCoverUpCodes(){
        //GIVEN
        ShiftNotCloseNotificationHandler hdl = 
            ShiftNotCloseNotificationHandler.create(new List<Job__c>());

        //WHEN
        test.startTest();
        Integer errCount = hdl.ErrorCount;
        Integer total = hdl.TotalCount;
        Integer emailCount = hdl.EmailCount;
        Id emailTemplateId = ShiftNotCloseNotificationHandler.getEmailTemplateId();
        Id orgWideId = ShiftNotCloseNotificationHandler.getOrgWideEmailId();
        OrgCustomSettings__c orgSettings = ShiftNotCloseNotificationHandler.getCustomSettings(); 
        hdl.logError('job', 'test.test@test.com', 'test');
        test.stopTest();

        //THEN
        EQ(0, errCount,'err 0');
        EQ(1, hdl.ErrorCount, 'one error just added');
        EQ(0, total,'total 0');
        EQ(0, emailCount, 'email 0');
        EQ(0, hdl.shifts.size(), 'no shift');
        OK(emailTemplateId != null, 'has email template');
        
    }
/*
    @isTest 
    static void itShouldRunExecuteAndSendEmail(){
        //GIVEN
        List<SObject> shifts = getShifts();
        Project__c project= TestProject.getProjects().get(0);
        List<JobAttempt__c> attempts = TestProject.getJobAttempts(project.Id);
        ShiftNotCloseNotificationHandler hdl = 
            ShiftNotCloseNotificationHandler.create(shifts);

        //WHEN
        test.startTest();
        OK(attempts.get(0).PrimaryJobAttemptWorker__c != null, 'primary worker assigned to job');
        hdl.execute();
        hdl.validateWhoAndWhat((Job__c)shifts.get(0));
        hdl.sendEmail((Job__c)shifts.get(0));
        hdl.doExecute();
        test.stopTest();

        //THEN

    }
*/
    static List<SObject> getShifts(){
       return Database.query(BatchShiftNotCloseNotification.buildQuery());
    }

    static void EQ(object expected, object result, String msg) {
        System.assertEquals(expected, result, msg);
    }

    static void OK(Boolean condition,String msg){
        System.assertEquals(true, condition,msg);
    }
}