@isTest
private class BuikImportTest
{
    @testSetup
    static void setup(){
        TestDataUtil.init();
    }

    @isTest
    static void itShouldAssignValue(){
        //given
        ImportRequest ir = new ImportRequest();

        //when
        ir.ParentId = '1';
        ir.ServiceName = 'sn';
        ir.AttachmentName = 'an';
        ir.JobName = 'jn';
        ir.StartImport = 0;
        ir.EndImport = 0;
        ir.Data = new List<String>();

        //then
        QA.EQ('1', ir.ParentId,'parent id is 1');
        QA.EQ('sn', ir.ServiceName, 'svc name is ok');
        QA.EQ('an', ir.AttachmentName, 'attname is ok');
        QA.EQ('jn', ir.JobName, 'jobname is ok');
        QA.EQ(0, ir.StartImport, 'start import is 0');
        QA.EQ(0, ir.EndImport, 'end import is 0');
        QA.EQ(0, ir.Data.size(), 'no data');
    }

    static ImportRequest newRequest(String parentId){
        ImportRequest ir = new ImportRequest();
        String projectId = parentId;

        ir.ParentId = projectId;
        ir.ServiceName = 'LocationImportRequestService';
        ir.AttachmentName = 'import_location';
        ir.JobName = 'Import Locations';
        ir.StartImport = 0;
        ir.EndImport = 0;
        ir.Data = getBody();
        return ir;
    }

    static List<String> getBody(){
        List<String> data = new List<String>();
        data.add('1,david,12');
        data.add('2,tom,23');
        return data;
    }


    @isTest
    static void itShouldReturnRightSettingsWhenCallToGetImportSetttings() {
        //given
        TriggerUtil.skipAllTriggers();
        TestProject.create('demo').addAll();
        integer chunk = 5000;
        String projectId = String.valueOf(TestProject.getProjects()[0].Id);
        String query = JSON.serialize(newRequest(projectId));

        //when
        test.startTest();
        Map<String,Object> res = ImportRequestController.getImportSettings(query);
        test.stopTest();
        
        //then
        QA.EQ(chunk, integer.valueOf(res.get('chunkSize')), 'chunk size matched');
    }

    @isTest
    static void itShouldInsertAttachmentWhenCallImortData(){
        //given
        TriggerUtil.skipAllTriggers();
        TestProject.create('demo').addAll();
        String projectId = String.valueOf(TestProject.getProjects()[0].Id);
        ImportRequest ir = newRequest(projectId);
        ir.EndImport = 1;
        String query = JSON.serialize(ir);
        String body = JSON.serialize(ir.Data);

        //when
        test.startTest();
        ImportRequestController.importData(query);
        test.stopTest();

        //then
        Project__c p = TestProject.getProject(projectId);
        Attachment att = [SELECT Name, Body from attachment where ParentId = :projectId Limit 1];
        QA.EQ(ir.AttachmentName, att.Name, 'name matched');
        QA.EQ(body, att.Body.toString(),'body mathced');
        QA.EQ(ir.JobName, p.ApexJobName__c, 'job name matched.');
        QA.EQ('Location', p.PendingBulkImport__c, 'bulkimport picklist matched');
    }

    @isTest
    static void itShouldThrowErrorIfCanNotImport(){
        //given
        TriggerUtil.skipAllTriggers();
        TestProject.create('demo').addAll();
        Project__c p = TestProject.getProjects()[0];
        p.PendingBulkImport__c = 'Location';
        update p;
        ImportRequest ir = newRequest(p.Id);
        ir.StartImport = 1;
        String query = JSON.serialize(ir);
        Exception err = null;

        //when
        try{
            test.startTest();
            ImportRequestController.importData(query);
            test.stopTest();
        } catch(Exception ex){
            err= ex;
        }
        
        //then
        QA.isTrue(err != null, 'an error thrown:' + err.getCause());
    }
}