@isTest
public class ProjectServiceTargetsAddExtTest {
    public static testMethod void genericTest(){ 
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, System.today().addDays(60), System.today().addDays(70));
        ProjectService__c ps  = [SELECT Id,Service__c FROM ProjectService__c LIMIT 1];
        ApexPages.currentPage().getParameters().put('Id', ps.Id);
        
        ApexPages.StandardController controller = new ApexPages.StandardController(new ProjectService__c());        
        ProjectServiceTargetsAddExt ctrl = new ProjectServiceTargetsAddExt(controller); 
        ctrl.projectid =  project.id;
        ctrl.QtyParam=0;
        ctrl.tempHeader = new string[]{};
        ctrl.ServiceObj = [select id from service__c limit 1];
        
        
        
        Target__c coll = new Target__c();
        coll.Name = 'CHEF SHAMY - Garlic Butter';
        coll.Targettype__c= 'Product';
        coll.DepartmentName__c = 'Dairy';
        coll.PackageSizeQty__c = 1;
        coll.PackageSizeUnits__c= 'oz';
        coll.StockCode__c = TestUtil.generateRandomString(8);
        coll.upc__c = TestUtil.generateRandomString(12);
        //coll.Type__c = 'Primary';
        insert coll;
        
        
        ProjectServiceTarget__c psc = new ProjectServiceTarget__c();
        psc.ProjectService__c = ps.Id;
        psc.Quantity__c = 0;
        psc.Price__c = 0;
        psc.YieldPerUnit__c = 0;
        psc.IsDonated__c = false;
        psc.Target__c = coll.Id;
        ctrl.psc = psc;
        ctrl.SelectedType = 'Primary';
        PageReference pageref = ctrl.AddProduct();
        
        
        List<Attribute__c> attributes = [Select Id, Name, AttributeType__c from Attribute__c LIMIT 5];
        
        ProjectServiceAttribute__c psca = new ProjectServiceAttribute__c();
        psca.Attribute__c = attributes[0].id;
        psca.AttributeValue__c   = '';
        
        psca.ProjectService__c =ps.id;
        psca.Service__c= ps.Service__c;
        insert psca;
        
        //system.assertEquals(pageref,null);
    } 
    
    public static testMethod void genericTest_Delete(){ 
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, System.today().addDays(60), System.today().addDays(70));
        ProjectService__c ps  = [SELECT Id,Service__c FROM ProjectService__c LIMIT 1];
        ApexPages.currentPage().getParameters().put('Id', ps.Id);
        
        ApexPages.StandardController controller = new ApexPages.StandardController(new ProjectService__c());        
        ProjectServiceTargetsAddExt ctrl = new ProjectServiceTargetsAddExt(controller); 
        ctrl.projectid =  project.id;
        ctrl.QtyParam=0;
        ctrl.tempHeader = new string[]{};
        ctrl.ServiceObj = [select id from service__c limit 1];
        /*
        
        
        Target__c coll = new Target__c();
        coll.Name = 'CHEF SHAMY - Garlic Butter';
        coll.Targettype__c= 'Product';
        coll.DepartmentName__c = 'Dairy';
        coll.PackageSizeQty__c = 1;
        coll.PackageSizeUnits__c= 'oz';
        coll.StockCode__c = TestUtil.generateRandomString(8);
        coll.upc__c = TestUtil.generateRandomString(12);
        //coll.Type__c = 'Primary';
        insert coll;
        
        
        ProjectServiceTarget__c psc = new ProjectServiceTarget__c();
        psc.ProjectService__c = ps.Id;
        psc.Quantity__c = 0;
        psc.Price__c = 0;
        psc.YieldPerUnit__c = 0;
        psc.IsDonated__c = false;
        psc.Target__c = coll.Id;
        psc.Type__c = 'Primary';
        insert psc;
        
        ctrl.psc = psc;
        ctrl.SelectedType = 'Primary';
        
        psc = new ProjectServiceTarget__c();
        psc.ProjectService__c = ps.Id;
        psc.Quantity__c = 0;
        psc.Price__c = 0;
        psc.YieldPerUnit__c = 0;
        psc.IsDonated__c = false;
        psc.Target__c = coll.Id;
        psc.Type__c = 'Backup';
        insert psc;
        
        psc = new ProjectServiceTarget__c();
        psc.ProjectService__c = ps.Id;
        psc.Quantity__c = 0;
        psc.Price__c = 0;
        psc.YieldPerUnit__c = 0;
        psc.IsDonated__c = false;
        psc.Target__c = coll.Id;
        psc.Type__c = 'Halo';
        insert psc;
        
        List<Attribute__c> attributes = [Select Id, Name, AttributeType__c from Attribute__c LIMIT 5];
        
        ProjectServiceAttribute__c psca = new ProjectServiceAttribute__c();
        psca.Attribute__c = attributes[0].id;
        psca.AttributeValue__c   = '';
        
        psca.ProjectService__c =ps.id;
        psca.Service__c= ps.Service__c;
        insert psca;
        
        
        Test.startTest();
       
        ApexPages.currentPage().getParameters().put('pscParamDEL', psc.Id);
        ApexPages.currentPage().getParameters().put('Oper', 'Primary');
        pagereference pageref = ctrl.SaveAllChanges();
        pageref = ctrl.DeleteProducts();

        

        ApexPages.currentPage().getParameters().put('pscParamDEL', psc.Id);
        ApexPages.currentPage().getParameters().put('Oper', 'Backup');
        pageref = ctrl.SaveAllChanges();        
        pageref = ctrl.DeleteProducts();

        ApexPages.currentPage().getParameters().put('pscParamDEL', psc.Id);
        ApexPages.currentPage().getParameters().put('Oper', 'Halo');
        pageref = ctrl.SaveAllChanges();        
        pageref = ctrl.DeleteProducts();
        Test.stopTest();
        */
        
    }
}