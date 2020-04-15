@isTest
public class ProjectServiceMaterialsAddExtTest {

    @testSetup static void setup(){
        TestUtil.initBaseData();
        TestUtil.generateFullTestProject(ProjectType.MD, Date.today().addDays(10), Date.today().addDays(20));
    }

    public static testMethod void Test_ProjServiceMaterialsAdd()
    {
        Project__c project = (Project__c) TestUtil.getRecord('Project__c');
        List<ProjectService__c> projServs = [SELECT Id FROM ProjectService__c WHERE Project__c = :project.Id];
        List<Material__c> mts = (List<Material__c>) TestUtil.getRecordset('Material__c');
        
        // create a new standard controller by passing it the account record
        ApexPages.StandardController controller = new ApexPages.StandardController(projServs[0]);
        ApexPages.currentPage().getParameters().put('id', projServs[0].Id);
        
        // now pass it to the extension
        ProjectServiceMaterialsAddExt ext= new ProjectServiceMaterialsAddExt(controller);
        
        system.assert(ext != null);        
        system.assert(ext.materials.size() == 0);        
        
        Material__c mat = mts[0];
        
        projectservicematerial__C pscObj = new projectservicematerial__C();
        pscObj.ProjectService__c = projServs[0].Id;
        pscObj.Material__c = mat.Id;
        //pscObj.MaterialName__c = mat.Name;
        pscObj.Quantity__c = 1;
        pscObj.MaterialDescription__c = mat.Description__c;
        //pscObj.Kit__c=mat.Kit__c;
        //pscObj.CostPerUnit__c=mat.EstimatedCostPerUnit__c;
        
        ext.psm = pscObj;
        ext.AddMaterial();
        
        //system.assert(ext.materials.size() == 0);
        
        //ApexPages.currentPage().getParameters().put('psmParamDEL', ext.materials[0].Id); 
        
        //ext.DeleteMaterials();
        //system.assert(ext.materials.size() == 0);
               
        
    }    
}