@isTest
private class TestDataVerificationTest
{
    static List<SObject> rs;
    SObject r;

    @testSetup static void init(){
        TestUtil.initBaseData();
    }

    @isTest static void testPostalCodesReady(){
        rs = TestUtil.getRecordset('PostalCode__c');
        System.assertEquals(2,rs.size(),'two postal codes are inited.');
    }
    @isTest static void testAccountsReady(){
        rs = TestUtil.getRecordset('Account');
        System.assertEquals(2,rs.size(), 'two accounts created.');
    }
    @isTest static void testContactsReady(){
        rs = TestUtil.getRecordset('Contact');
        System.assertEquals(12, rs.size(), 'two contacts created.');
    }
    @isTest static void testLanguagsReady(){
        rs = TestUtil.getRecordset('Language__c');
        System.assertEquals(1, rs.size(),'one language created.');
    }
    @isTest static void testRetailerReady(){
        rs= TestUtil.getRecordset('Retailer__c');
        System.assertEquals(1,rs.size(),'One retailer created.');
    }
    @isTest static void testProjectTypeReady(){
        rs = TestUtil.getRecordset('ProjectType__c');
        System.assertEquals(1,rs.size(),'One project type created.');
    }
    @isTest static void testCycleReady(){
        rs = TestUtil.getRecordset('Cycle__c');
        System.assertEquals(TestDataUtil.MaxCountSmall, rs.size(),'Cycles created.');
    }
    @isTest static void testProjectScheduleOptionsReady(){
        rs = TestUtil.getRecordset('ScheduleOption__c');
        System.assertEquals(3, rs.size(),'3 schedule options created.');
    }
    @isTest static void testProjectTypeCustomSettingReady(){
        rs = TestUtil.getRecordset('ProjectTypeCustomSettings__c');
        System.assertEquals('Merchandising', rs.get(0).get('Name'), 'one project type custom setting created.');
    }
    @isTest static void testEquipmentsReady(){
        rs = TestUtil.getRecordset('Equipment__c');
        System.assertEquals(TestDataUtil.MaxCountSmall,rs.size(),'equipments ready.');
    }
    @isTest static void testLocationsReady(){
        rs = TestUtil.getRecordset('Location__c');
        System.assertEquals(TestDataUtil.MaxCountLarge, rs.size(),'Locations created.');
    }
    @isTest static void testLocationAssignmentReady(){
        rs = TestUtil.getRecordset('LocationAssignment__c');
        System.assertEquals(TestDataUtil.MaxCountLarge, rs.size(),'LocationAssignment created.');
    }
    @isTest static void testCertificationsReady(){
        rs = TestUtil.getRecordset('Certification__c');
        System.assertEquals(TestDataUtil.MaxCountSmall,rs.size(),'Certifications created.');
    }
    @isTest static void testTargetsReady(){
        rs = TestUtil.getRecordset('Target__c');
        System.assertEquals(TestDataUtil.MaxCountSmall, rs.size(),'Targets Ready.');
    }
    @isTest static void testFulfillmentsReady(){
        rs = TestUtil.getRecordset('FulfillmentCenter__c');
        System.assertEquals(2, rs.size(),'fulfillmentcenters created.');
    }
    @isTest static void testMaterialReady(){
        rs = TestUtil.getRecordset('Material__c');
        System.assertEquals(2,rs.size(),'materials created.');
    }
    @isTest static void testServicesReady(){
        rs = TestUtil.getRecordset('Service__c');
        System.assertEquals(3,rs.size(),'3 services created.');
    }
    @isTest static void testProjectTypeServicesReady(){
        rs = TestUtil.getRecordset('ProjectTypeService__c');
        System.assertEquals(3, rs.size(),'3 project type services created.');
    }

    @isTest static void testRetailerServicesReady(){
        rs = TestUtil.getRecordset('RetailerService__c');
        System.assertEquals(3,rs.size(),'3 retailer services created.');
    }
    @isTest static void testQuestionsReady(){
        rs = TestUtil.getRecordset('Question__c');
        QA.isTrue(rs.size() > 0, 'question created');
    }
    
    @isTest static void testQuestionResponsesReady(){
        rs = TestUtil.getRecordset('QuestionDefinedResponse__c');
        QA.isTrue(rs.size() > 0, 'defined reponses created');
    }
    @isTest static void testAttributesReady(){
        rs = TestUtil.getRecordset('Attribute__c');
        System.assertEquals(9, rs.size(),'4 attributes created.');
    }
    @isTest static void testServiceAttributesReady(){
        rs =TestUtil.getRecordset('ServiceAttribute__c');
        System.assertEquals(27, rs.size(),'3 service attributes created.');
    }
    @isTest static void testServiceQuestionsReady(){
        rs = TestUtil.getRecordset('ServiceQuestion__c');
        QA.isTrue(rs.size() > 0, 'service question created.');
    }
    @isTest static void  testServiceQuestionResponsesReady(){
        rs = TestUtil.getRecordset('ServiceQuestionDefinedResponse__c');
        System.assertEquals(true, rs.size() > 0,'3 service question responses created.');
    }
    @isTest static void testRetailerServiceEquipmentReady(){
        rs = TestUtil.getRecordset('RetailerServiceEquipment__c');
        System.assertEquals(15, rs.size(),'retailer service equipments ready.');
    }
    @isTest static void testRetailerServiceCertificationsReady(){
        rs = TestUtil.getRecordset('RetailerServiceCertification__c');
        System.assertEquals(15,rs.size(),'retailer service certifications ready.');
    }
}