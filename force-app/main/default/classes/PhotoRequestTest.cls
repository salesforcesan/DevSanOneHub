@isTest
private class PhotoRequestTest
{
    @testSetup
    static void setup(){
        TriggerUtil.SkipAllTriggers();
        TestDataUtil.init();
        TestProject tp = TestProject.create('demo').addAll();
        tp.TestProjectServiceList[0].addAll();
        tp.addJobImages();
    }

    @isTest
    static void itShouldGetPhoto()
    {
        //GIVEN
        Project__c p = TestProject.getProjects()[0];
        JobImage__c img = TestProject.getJobImages(p.Id)[0];

        Map<String,Object> query = new Map<String,Object>();
        query.put('id', img.Id);
        LightningRequestBase req = new PhotoRequest();

        //WHEN
        test.startTest();
        Map<String,Object> result = (Map<String,Object>) req.get(query);
        test.stopTest();

        //THEN
        QA.EQ(img.Id, result.get('id'), 'same id');
    }

    @isTest
    static void itShouldUpdatePhoto() {
        //GIVEN
         Project__c p = TestProject.getProjects()[0];
        JobImage__c img = TestProject.getJobImages(p.Id)[0];

        Map<String,Object> query = new Map<String,Object>();
        query.put('id', img.Id);
        query.put('favorite', 1);
        query.put('qc',1);
        LightningRequestBase req = new PhotoRequest();

        //WHEN
        test.startTest();
        Map<String,Object> result = (Map<String,Object>) req.modify(query);
        test.stopTest();

        //THEN
        QA.EQ(1, result.get('qc'), 'qc is checked');
    }
}