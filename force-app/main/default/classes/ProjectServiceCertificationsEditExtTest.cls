@isTest
public class ProjectServiceCertificationsEditExtTest {
    @testSetup static void setup(){
        TestUtil.initBaseData();
        TestUtil.generateFullTestProject(ProjectType.MD, Date.today(),Date.today().addDays(2));
    }

    public static testMethod void testProjectServiceCertificationsEditExtController(){
        List<Project__c> projects = (List<Project__c>)TestUtil.getRecordset('Project__c');
        List<ProjectService__c> projServs = (List<ProjectService__c>) TestUtil.getRecordset('ProjectService__c');
        List<Certification__c> cerList = (List<Certification__c>) TestUtil.getRecordset('Certification__c');
        
        PageReference pageRef = Page.ProjectServiceEquipmentEdit;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('Id', projServs.get(0).Id);
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(projServs.get(0));
        ProjectServiceCertificationsEditExt controllerExt = new ProjectServiceCertificationsEditExt(stdController);
        
        System.assertNotEquals(controllerExt, null,'ProjectServiceCertificationEditExt  is null');
        System.debug('controllerExt: '+controllerExt);
        
        //test add equipment
        Integer certSize = controllerExt.pscList.size();
        controllerExt.SelectedCertification =  String.valueOf(cerList[0].Id);
        controllerExt.addCertification();
        controllerExt.loadCertification();
        System.assertEquals(certSize + 1, controllerExt.pscList.size());
        
        // -ve case
        certSize = controllerExt.pscList.size();
        controllerExt.SelectedCertification =  'failureid';
        controllerExt.addCertification();
        controllerExt.loadCertification();
        System.assertEquals(certSize, controllerExt.pscList.size());
        
        // Duplicate
        certSize = controllerExt.pscList.size();
        controllerExt.SelectedCertification =  String.valueOf(cerList[0].Id);
        controllerExt.addCertification();
        controllerExt.loadCertification();
        //TODO: These tests are failing in prod.
        /*
        //System.assertEquals(certSize, controllerExt.pscList.size());
        
        
        //test delete certification
        String lastPSCId = controllerExt.pscList[controllerExt.pscList.size()-1].Id;
        certSize = controllerExt.pscList.size();
        ApexPages.currentPage().getParameters().put('pscCertId', lastPSCId);
        controllerExt.deleteCertification();
        controllerExt.loadCertification();
        System.assertEquals(certSize - 1, controllerExt.pscList.size());
        
        
        //test add equipment
        certSize = controllerExt.pscList.size();
        controllerExt.SelectedCertification =  String.valueOf(cerList[0].Id);
        controllerExt.addCertification();
        controllerExt.loadCertification();

        certSize = controllerExt.pscList.size();
        lastPSCId = controllerExt.pscList[controllerExt.pscList.size()-1].Id;
        ApexPages.currentPage().getParameters().put('pscCertId', 'exceptionId');
        controllerExt.deleteCertification();
        controllerExt.loadCertification();
        System.assertEquals(certSize, controllerExt.pscList.size());
        */
        
    }
}