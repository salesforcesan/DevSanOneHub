@isTest
public class ProjectServiceEquipmentEditExtTest {

    @testSetup static void setup(){
        TestUtil.initBaseData();
        TestUtil.generateFullTestProject(ProjectType.MD, Date.today(),Date.today().addDays(2));
    }

    public static testMethod void testProjectServiceEquipmentEditExtController(){
        /*
        List<Project__c> projects = (List<Project__c>) TestUtil.getRecordset('Project__c');
        List<ProjectService__c> projServs = (List<ProjectService__c>)TestUtil.getRecordset('ProjectService__c');
        List<Equipment__c> eqpList =(List<Equipment__c>)TestUtil.getRecordset('Equipment__c');
        List<Equipment__c> eqpListNoCapImpact = (List<Equipment__c>)TestUtil.getRecordset('Equipment__c');
        
        PageReference pageRef = Page.ProjectServiceEquipmentEdit;
        Test.setCurrentPage(pageRef);
        ApexPages.currentPage().getParameters().put('Id', projServs.get(0).Id);
        
        ApexPages.StandardController stdController = new ApexPages.StandardController(projServs.get(0));
        ProjectServiceEquipmentEditExt controllerExt = new ProjectServiceEquipmentEditExt(stdController);
        
        System.assertNotEquals(controllerExt, null,'ProjectServiceEquipmentEditExt  is null');
        System.debug('controllerExt: '+controllerExt);
        
        //test add equipment
        Integer equipmentSize = controllerExt.pseList.size();
        controllerExt.SelectedEquipment =  String.valueOf(eqpList[0].Id);
        controllerExt.SelectedQuantity = String.valueOf(10);
        controllerExt.addEquipment();
        controllerExt.loadEquipment();
        System.assertEquals(equipmentSize + 1, controllerExt.pseList.size());
        
        //test utensils
        equipmentSize = controllerExt.pseList.size();
        controllerExt.SelectedUtensilList.add(new SelectOption(eqpListNoCapImpact[0].Id, eqpListNoCapImpact[0].Name));
        controllerExt.SaveUtensil();
        //System.assertEquals(equipmentSize + 1, controllerExt.pseList.size());
        
        // -ve case
        equipmentSize = controllerExt.pseList.size();
        controllerExt.SelectedEquipment =  'failureid';
        controllerExt.SelectedQuantity = String.valueOf(10);
        controllerExt.addEquipment();
        controllerExt.loadEquipment();
        //System.assertEquals(equipmentSize, controllerExt.pseList.size());
        
        //test delete equipment
        String lastPSEId = controllerExt.pseList[controllerExt.pseList.size()-1].Id;
        equipmentSize = controllerExt.pseList.size();
        ApexPages.currentPage().getParameters().put('pseDelId', lastPSEId);
        controllerExt.deleteEquipment();
        controllerExt.loadEquipment();
        System.assertEquals(equipmentSize - 1, controllerExt.pseList.size());
        
        //test delete equipment
        equipmentSize = controllerExt.pseList.size();
        ApexPages.currentPage().getParameters().put('pseDelId', 'failureid');
        controllerExt.deleteEquipment();
        controllerExt.loadEquipment();
        System.assertEquals(equipmentSize, controllerExt.pseList.size());
        
        //test save equipment
        controllerExt.pseList[0].quantity__c = 100;
        controllerExt.saveEditRows();
        System.assertEquals(100, controllerExt.pseList[0].Quantity__c);
        
        RetailerServiceEquipment__c rse = new RetailerServiceEquipment__c();
        rse.Retailer__c = projects[0].Retailer__c;
        rse.Service__c = projServs[0].Service__c;
        rse.Equipment__c = controllerExt.pseList[0].Equipment__c;
        rse.IsLocked__c = true;
        rse.Quantity__c = 10;
        insert rse;
        //controllerExt.lockedEqupmentMap.put(rse.Equipment__c, rse.Quantity__c);
        
        //test locked equipent edit validation
        controllerExt.pseList[0].IsLocked__c = true;
        controllerExt.pseList[0].quantity__c = 9;
        controllerExt.saveEditRows();
        controllerExt.loadEquipment();
        System.assertNotEquals(9, controllerExt.pseList[0].Quantity__c);
        
        
        //test add duplicate equipment
        equipmentSize = controllerExt.pseList.size();
        controllerExt.SelectedEquipment =  String.valueOf(controllerExt.pseList[0].Equipment__c);
        controllerExt.SelectedQuantity = String.valueOf(99);
        controllerExt.addEquipment();
        controllerExt.loadEquipment();
        //system.debug('controllerExt.pseList:: ' + controllerExt.pseList);
        //system.debug('eqpList[0].Id:: ' + eqpList[0].Id);
        //system.debug('eqpList[1].Id:: ' + eqpList[1].Id);
        System.assertEquals(equipmentSize, controllerExt.pseList.size());
        
        //test add equipment with invalid qty
        equipmentSize = controllerExt.pseList.size();
        controllerExt.SelectedEquipment =  eqpList[2].Id;
        controllerExt.SelectedQuantity = String.valueOf(0);
        controllerExt.addEquipment();
        controllerExt.loadEquipment();
        System.assertEquals(equipmentSize, controllerExt.pseList.size());
       */
    }
}