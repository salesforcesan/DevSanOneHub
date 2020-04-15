@isTest
private class ProjectActionsHelperTest {
  static Date CURRENT_DATE;

  static {
    CURRENT_DATE = Date.today();
  }

  @testSetup static void setup(){
    TestDataUtil.init();
    TestDataUtil.disableTriggers();
    TestProject.create('demo').addAll();
    TestDataUtil.enableTriggers();
  }

  @isTest
  static void itShouldResetReleaseFields(){
    //given
    TriggerUtil.skipAllTriggers();
    Project__c p = TestProject.getProjects().get(0);
    p.ApexJobName__c = 'test';
    p.IsPendingChangeReleaseRequest__c = true;
    p.IsPendingChanges__c = true;
    update p;
    Set<Id> idSet = new Set<Id>{p.Id};

    //when
    test.startTest();
    ProjectActionsHelper.ResetProjectReleaseChangeFields(idSet);
    test.stopTest();

    //then
    Project__c r = TestProject.getProjects().get(0);
    QA.isTrue(r.ApexJobName__c != p.ApexJobName__c,'reset');
  }

  @isTest
  static void itShouldRunProjectHistoryGetter(){
    //given
    Project__c p = TestProject.getProjects().get(0);

    //when
    test.startTest();
    ProjectActionsHelper.LockProject(p,'test','test');
    ProjectActionsHelper.UnLockProject(p);
    ProjectActionsHelper.RunProjectHistoryGetter(); 
    test.stopTest();
    
    //then
  }

  @isTest
  static void itShouldRunProjectHistoryGetterTheOtherWay(){
    //given
    Project__c p = TestProject.getProjects().get(0);
    List<ProcessLastSyncTime__c> times = new List<ProcessLastSyncTime__c>{
        new ProcessLastSyncTime__c(
                ProcessName__c = 'ProjectChangeTracking',
                SyncTime__c = Datetime.now().addHours(-8)
            )
    };
    insert times;

    //when
    test.startTest();
    ProjectActionsHelper.RunProjectHistoryGetter(); 
    test.stopTest();
    
    //then
  }


  @isTest 
  static void itShouldMoveToLauched(){
    //given
    TriggerUtil.skipAllTriggers();
    Project__c p = TestProject.getProjects().get(0);
    p.Status__c = 'Booked';    
    update p;

    //when
    test.startTest();
    List<ActionResponse> result = ProjectActionsHelper.MoveProjectsTolaunched();
    test.stopTest();

    //then
    Project__c r = TestProject.getProjects().get(0);
    QA.EQ('Launched', r.Status__c, 'lauched');
  }

    @isTest 
  static void itShouldDeleteProject(){
    //given
    TriggerUtil.skipAllTriggers();
    Project__c p = TestProject.getProjects().get(0);
    p.Status__c = 'Booked';    
    update p;

    //when
    test.startTest();
    List<ActionResponse> result = ProjectActionsHelper.DeleteProject(p.Id, false);
    test.stopTest();

    //then
    List<Sobject> results = TestProject.getProjects();
    QA.EQ(0, results.size(), 'no projects');
  }

      @isTest 
  static void itShouldDeleteProjectInBatch(){
    //given
    TriggerUtil.skipAllTriggers();
    Project__c p = TestProject.getProjects().get(0);
    p.Status__c = 'Booked';    
    update p;

    //when
    test.startTest();
    List<ActionResponse> result = ProjectActionsHelper.DeleteProject(p.Id, true);
    test.stopTest();

    //then
    List<Sobject> results = TestProject.getProjects();
    QA.EQ(0, results.size(), 'no projects');
  }


    @isTest 
  static void itShouldCancelProject(){
    //given
    TriggerUtil.skipAllTriggers();
    Project__c p = TestProject.getProjects().get(0);
    p.Status__c = 'Booked';    
    update p;

    //when
    test.startTest();
    List<ActionResponse> result = ProjectActionsHelper.CancelProject(p.Id, 'Other','comment');
    test.stopTest();

    //then
    Project__c r = TestProject.getProjects().get(0);
    QA.EQ('Canceled', r.status__c, 'canceled');
  }

      @isTest 
  static void itShouldCancelProjectTheOtherWay(){
    //given
    TriggerUtil.skipAllTriggers();
    Project__c p = TestProject.getProjects().get(0);
    p.Status__c = 'Booked';    
    update p;

    //when
    test.startTest();
    List<ActionResponse> result = ProjectActionsHelper.CancelProject(null, 'Other','comment');
    test.stopTest();

  }


      @isTest 
  static void itShouldCancelProjectTheThirdWay(){
    //given
    TriggerUtil.skipAllTriggers();
    Project__c p = TestProject.getProjects().get(0);
    p.Status__c = 'Booked';    
    update p;
    delete [select id from job__c where project__c=:p.Id];
    delete [select id from projectlocation__c where project__c=:p.Id];
    
    TestProject tp = TestProject.get(p.Id)
        .addLocations(500)
        .addJobs();

    //when
    test.startTest();
    List<ActionResponse> result = ProjectActionsHelper.CancelProject(p.Id, 'Other','comment');
    test.stopTest();

  }


    @isTest 
  static void itShouldCloseProject(){
    //given
    TriggerUtil.skipAllTriggers();
    Project__c p = TestProject.getProjects().get(0);
    p.Status__c = 'Ended';    
    update p;

    //when
    test.startTest();
    List<ActionResponse> result = ProjectActionsHelper.CloseProject(p.Id);

    test.stopTest();

    //then
    Project__c r = TestProject.getProjects().get(0);
    QA.EQ('Closed', r.status__c, 'closed');
  }

    @isTest 
  static void itShouldCloseProjects(){
    //given
    TriggerUtil.skipAllTriggers();
    Project__c p = TestProject.getProjects().get(0);
    p.Status__c = 'Ended';    
    update p;

    //when
    test.startTest();
    List<ActionResponse> result = ProjectActionsHelper.CloseProjects(new List<Id>{p.Id});

    test.stopTest();

    //then
    Project__c r = TestProject.getProjects().get(0);
    QA.EQ('Closed', r.status__c, 'closed');
  }

      @isTest 
  static void itShouldCloseJobs(){
    //given
    TriggerUtil.skipAllTriggers();
    Project__c p = TestProject.getProjects().get(0);
    p.Status__c = 'Launched';    
    update p;

    //when
    test.startTest();
    List<ActionResponse> result = ProjectActionsHelper.CloseProjectsSansJobs(New List<Id>{p.Id});
    
    test.stopTest();

    //then
    Project__c r = TestProject.getProjects().get(0);
    QA.EQ('Closed', r.status__c, 'closed');
  }


      @isTest 
  static void itShouldLaunchProjects(){
    //given
    TriggerUtil.skipAllTriggers();
    Project__c p = TestProject.getProjects().get(0);
    p.Status__c = 'Booked';    
    update p;

    //when
    test.startTest();
    List<ActionResponse> result = ProjectActionsHelper.LaunchProjects(New List<Id>{p.Id});
    
    test.stopTest();

    //then
    Project__c r = TestProject.getProjects().get(0);
    QA.EQ('Launched', r.status__c, 'closed');
  }

  @isTest
  static void ItShouldDoCodeCoverage()
  {
        Project__c p = TestProject.getProjects().get(0);
        ProjectActionsHelper.ChangeStatus(p, 'Planning');


        integer size = ProjectActionsHelper.getUpdateSequenceChangeLogSize();
        size = ProjectActionsHelper.getMaxServicesForManualGeneration();

        ProjectActionsHelper.ReOrderProjectServiceRanks(p.Id);

        Map<String,String> rtMap = new Map<String,String>();
        rtMap.put('idname','');
        String pattern = 'id,name';
        ProjectActionsHelper.SetRecordType(p, rtMap, pattern);
  }


    @isTest 
  static void itShouldLaunchProjectSandsJobs(){
    //given
    TriggerUtil.skipAllTriggers();
    Project__c p = TestProject.getProjects().get(0);
    p.Status__c = 'Booked';    
    update p;

    //when
    test.startTest();
    List<ActionResponse> result = ProjectActionsHelper.LaunchProjectSansJobs(p.Id);
    
    test.stopTest();

    //then
    Project__c r = TestProject.getProjects().get(0);
    QA.EQ('Launched', r.status__c, 'closed');
  }


      @isTest 
  static void itShouldLaunchProject()
  {
    //given
    TriggerUtil.skipAllTriggers();
    Project__c p = TestProject.getProjects().get(0);
    p.Status__c = 'Booked';    
    update p;

    //when
    test.startTest();
    List<ActionResponse> result = ProjectActionsHelper.LaunchProject(p.Id);
    
    test.stopTest();

    //then
    Project__c r = TestProject.getProjects().get(0);
    QA.EQ('Launched', r.status__c, 'closed');
  }

        @isTest 
  static void itShouldLaunchProjectsSansJobs()
  {
    //given
    TriggerUtil.skipAllTriggers();
    Project__c p = TestProject.getProjects().get(0);
    p.Status__c = 'Booked';    
    update p;

    //when
    test.startTest();
    List<ActionResponse> result = ProjectActionsHelper.LaunchProjectsSansJobs(new Id[]{p.Id});
    
    test.stopTest();

    //then
    Project__c r = TestProject.getProjects().get(0);
    QA.EQ('Launched', r.status__c, 'closed');
  }

         @isTest 
  static void itShouldCloseProjectSansJobs()
  {
    //given
    TriggerUtil.skipAllTriggers();
    Project__c p = TestProject.getProjects().get(0);
    p.Status__c = 'Ended';    
    update p;

    //when
    test.startTest();
    List<ActionResponse> result = ProjectActionsHelper.CloseProjectSansJobs(p.Id);
    
    test.stopTest();

    //then
    Project__c r = TestProject.getProjects().get(0);
    QA.EQ('Closed', r.status__c, 'closed');
  }

         @isTest 
  static void itShouldCancelProjectSansJobs()
  {
    //given
    TriggerUtil.skipAllTriggers();
    Project__c p = TestProject.getProjects().get(0);
    p.Status__c = 'Ended';    
    update p;

    //when
    test.startTest();
    List<ActionResponse> result = ProjectActionsHelper.CancelProjectSansJobs(p.Id,'Other','comment');
    
    test.stopTest();

    //then
    Project__c r = TestProject.getProjects().get(0);
    QA.EQ('Canceled', r.status__c, 'canceled');
  }

         @isTest 
  static void itShouldDeleteAllJobsByProject()
  {
    //given
    TriggerUtil.skipAllTriggers();
    Project__c p = TestProject.getProjects().get(0);
    p.Status__c = 'Ended';    
    update p;

    //when
    test.startTest();
    List<ActionResponse> result = ProjectActionsHelper.DeleteAllJobsByProject(p.Id);
    test.stopTest();
  }

 @isTest 
  static void itShouldDeleteAllJobsByProjectInBatch()
  {
    //given
    TriggerUtil.skipAllTriggers();
    Project__c p = TestProject.getProjects().get(0);
    delete [select id from job__c where project__c=:p.Id];
    delete [select id from projectlocation__c where project__c=:p.Id];

    TestProject tP = TestProject.get(p.Id);
    tP.addLocations(500)
        .addJobs();

    integer count = [SELECT COUNT() FROM Job__c WHERE Project__c=:p.Id];

    //when
    test.startTest();
    List<ActionResponse> result = ProjectActionsHelper.DeleteAllJobsByProject(p.Id);
    test.stopTest();
  }

  @isTest
  static void itShouldProcessProjectHistoryChanges(){
    //given
     TriggerUtil.skipAllTriggers();
    Project__c p = TestProject.getProjects().get(0);
    p.Status__c = 'Ended';    
    update p;
    List<Project__History> phs = New list<Project__History>();
    

    //when
    test.startTest();
    ProjectActionsHelper.ProcessProjectHistoryChanges(phs);
    test.stopTest();
    //then

  }

  @isTest 
  static void itShouldRunProjectSequenceUpdater(){

    test.startTest();
    ProjectActionsHelper.RunProjectSequenceUpdater();
    test.stopTest();
  }
}