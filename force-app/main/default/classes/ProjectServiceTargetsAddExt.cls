public with sharing class ProjectServiceTargetsAddExt {
    public ApexPages.StandardController controller;
    public ID psID {get;set;}
    public ID projectid {get;set;}
    public Project__c project {get;set;}
    public service__c ServiceObj{get;set;}
    public ProjectService__c ps{get;set;}
    public projectserviceTarget__c psc {get;set;}
    public List<SelectOption> AvlTypes{get;set;}
    public string SelectedType{get;set;}
    public list<projectserviceTarget__C> PrimaryPSC{get;set;}
    public list<projectserviceTarget__C> BackupPSC{get;set;}
    public list<projectserviceTarget__C> HaloPSC{get;set;}
    public list<projectserviceTarget__C> SuppPSC{get;set;}
    public list<projectserviceTarget__C> FeatPSC{get;set;}
    public integer QtyParam{get;set;}
    public list<ProdAttribute> prodAttr{get;set;}
    public list<string> tempHeader{get;set;}
    public Boolean showDelete{get;set;}
    public Boolean showProductButtons {get;private set;}
    public List<SelectOption> AvailAccnts{get;set;}    
    public string SelectedAccnt{get;set;}   
    public string showPriceForAddItemsCSS {get;set;}
    public String MultipleTgts{get;set;}
    
    public String csvFileBody {get;set;}
    public list<errorClass> lstErr{get;set;}
    public list<errorClass> lstSucc{get;set;}
        
    private void addMessage(ApexPages.Severity severity, String message){
        //if (Apexpages.getMessages().size() == 0){
            Apexpages.addMessage(new ApexPages.Message(severity, message));
        //}
    }     

    public List<SelectOption> getItems() {
        List<SelectOption> options = new List<SelectOption>();
        options.add(new SelectOption('Stock ID','Stock ID'));
        options.add(new SelectOption('UPC','UPC'));
        return options;
    }
    public string TargetOption{get;set;}  


    public Map<String,Boolean> editableMap {get;set;}

    public ProjectServiceTargetsAddExt(ApexPages.StandardController controller) {
        TargetOption = 'Stock ID';
        prodAttr= new list<ProdAttribute>();
        psID = ApexPages.CurrentPage().getParameters().get('id');   //'a0Hj0000002sPDp'; 'a0Hj00000037Dt5';
        ps = [SELECT Id, Name, Project__c,    Service__c, TargetType__c, Status__c, OneHubRetailerId__c,Variant__c  FROM ProjectService__c where id =:psID ];
        psc= new projectserviceTarget__c();
        AvlTypes= new List<SelectOption>();
        AvlTypes.add(new SelectOption('Primary','Primary'));
        /*AvlTypes.add(new SelectOption('Supplemental','Supplemental'));
        AvlTypes.add(new SelectOption('Featured','Featured'));
        AvlTypes.add(new SelectOption('BackUp','BackUp'));
        AvlTypes.add(new SelectOption('Halo','Halo'));*/
        LoadProducts();
        project = [Select Id, Name, Status__c, ProjectCancelLeadTime__c, FulfillmentLeadTime__c, Project__c.StartDate__c, Retailer__r.TargetAcquiredDefault__c, ProjectOrigin__c,retailer__c,retailer__r.name, ProjectRetailerONEHUBID__c from Project__c where Id =: ps.Project__c];
        showPriceForAddItemsCSS = (project.Retailer__r.TargetAcquiredDefault__c != 'Donated') ? '' : 'cm-hide';

        Set<String> editableFields = new Set<String>{'Project__c.RL_Targets'};
        editableMap = UIConfig.isEditale(project.Status__c, editableFields);
        showProductButtons = editableMap.get('Project__c.RL_Targets') && Schema.sObjectType.ProjectServiceTarget__c.isUpdateable() && Schema.sObjectType.Project__c.isUpdateable();

        psc.TargetAcquired__c = project.Retailer__r.TargetAcquiredDefault__c;

        AvailAccnts= new List<SelectOption>();                
        for(projectaccount__c pa : [select account__c,account__r.name from projectaccount__c where project__c=: project.id  ORDER BY IsPrimary__c DESC NULLS FIRST])
        {
            if(pa.account__c!=null){
                AvailAccnts.add(new SelectOption(pa.account__c,pa.account__r.name));            
            }    
        }
        lstErr= new list<errorClass>();
        lstSucc=new list<errorClass>(); 
    }

    public PageReference AddProduct(){
        //SaveAllChanges();
        if(psc.Target__c ==null){
            return null;
        }

        if(SelectedType != 'Primary')
        {        
            if (PrimaryPSC.size() == 0)
            {
                addMessage(ApexPages.Severity.ERROR, 'Please add a primary target before adding a Backup/Halo target.');
                return null;
            }        
        }
        if (CheckifAlreadyExists(psc.Target__c)){
            addMessage(ApexPages.Severity.ERROR, 'This target has already been added. Please check and try again.');
            return null;
        }
        
        try
        {
            Target__c col = [Select Id, Name,TargetName__c, Description__c, BrandInfo__c, UPC__c, DepartmentNumber__c, StockCode__c,ShelfName__c from Target__c where Id = :psc.Target__c LIMIT 1];
            projectserviceTarget__C pscObj = new projectserviceTarget__C();
            pscObj.ProjectService__c = psID;
            pscObj.Target__c = psc.Target__c;
            pscObj.Type__c = SelectedType;
            pscObj.Quantity__c = psc.Quantity__c;
            pscObj.Price__c = showPriceForAddItemsCSS != 'cm-hide' ? psc.Price__c : 0;
            pscObj.IsDonated__c = false;
            pscObj.account__c = SelectedAccnt;
            pscObj.YieldPerUnit__C = [Select PackageSizeQty__c from Target__c Where Id =: psc.Target__c LIMIT 1].PackageSizeQty__c;
            pscObj.Customdesc__c = col.ShelfName__c;
            
            pscObj.TargetAcquired__c = (SelectedType=='Featured'|| SelectedType=='Halo') ? '':  psc.TargetAcquired__c;
            insert pscObj;
    
        }
        catch(DmlException e)
        {
            addMessage(ApexPages.Severity.ERROR, e.getMessage());
            return null;
        }
        
        LoadProducts();
        
        
        psc= new projectserviceTarget__c();
        psc.TargetAcquired__c = project.Retailer__r.TargetAcquiredDefault__c;
        SelectedType = 'Primary';
        addMessage(ApexPages.Severity.CONFIRM, 'Target(s) added successfully.');
        return null;
        
    }

    public PageReference SaveAllChanges()
    {
        try
        {
            system.debug(' inside  SaveAllChanges()');
            for(ProdAttribute pa : prodAttr)
            {
                update pa.psc;
            }
            update BackupPSC;
            update HaloPSC;
            update SuppPSC;
            update FeatPSC;
            
            Set<id> psids = new Set<id>();
            psids.add(psID);
            AppUtil.updateProjectService(psids);

        }
        catch(DmlException e)
        {
            addMessage(ApexPages.Severity.ERROR, e.getMessage());
            return null;
        }
        //this redirecting causes project service page to be refreshed each time when the Uint is update and "save" button is clicked. 
        addMessage(ApexPages.Severity.CONFIRM, 'Target(s) saved successfully.'); 
        /*PageReference psPage = new ApexPages.StandardController(ps).view();
        psPage.setRedirect(true);
        psPage.GetParameters().Put('message', 'Target(s) saved successfully.');
        return psPage;*/ 
        return null;
    }

    public PageReference DeleteProducts()
    {
        string pscParamVal = ApexPages.currentpage().getParameters().get('pscParamDEL');
        string Oper =   ApexPages.currentpage().getParameters().get('Oper') ;
        if(Oper=='Primary')
        {
        
            if (PrimaryPSC.size() == 1 && (BackupPSC.size() > 0 || HaloPSC.size() > 0 || SuppPSC.size() > 0 || FeatPSC.size() > 0 ))
            {
                addMessage(ApexPages.Severity.ERROR, 'Please remove all the Backup/Halo targets before removing the only primary target.');
                return null;
            }
        
            for (ProjectServiceTarget__c c : PrimaryPSC) {
                if (pscParamVal == c.Id) {
                    delete c;
                    break;
                }
            }
        }
        else if(Oper=='Backup')
        {
            for (ProjectServiceTarget__c c : BackupPSC) {
                if (pscParamVal == c.Id) {
                    delete c;
                    break;
                }
            }
        }
        else if(Oper=='Supplemental')
        {
            for (ProjectServiceTarget__c c : SuppPSC) {
                if (pscParamVal == c.Id) {
                    delete c;
                    break;
                }
            }
        }
        else if(Oper=='Featured')
        {
            for (ProjectServiceTarget__c c : FeatPSC) {
                if (pscParamVal == c.Id) {
                    delete c;
                    break;
                }
            }
        }        
        
        else
        {
            for (ProjectServiceTarget__c c : HaloPSC) {
                if (pscParamVal == c.Id) {
                    delete c;
                    break;
                }
            }
        }
        LoadProducts();
        addMessage(ApexPages.Severity.CONFIRM, 'Target(s) deleted successfully.');
        /*PageReference psPage = new ApexPages.StandardController(ps).view();
        psPage.setRedirect(true);
        psPage.GetParameters().Put('message', 'Target(s) deleted successfully.');*/
        return null;
    }

    public class ProdAttribute{
        public projectserviceTarget__C psc{get; set;}
    }

    public void LoadProducts(){
        PrimaryPSC= [SELECT Id, ProjectService__c,CustomDesc__c, Target__c, Price__c, Type__c, Quantity__c,YieldPerUnit__c, IsDonated__c,Target__r.Name,Target__r.TargetName__c,Target__r.PackageSizeQty__c,Target__r.PackageSizeUnits__c,Target__r.CategoryInfo__c,Target__r.UPC__c,Target__r.StockCode__c,Target__r.DepartmentNumber__c, Target__r.DepartmentName__c, CeatedByExternalSource__c,account__c, TargetAcquired__c FROM ProjectServiceTarget__c where Type__c='Primary' and ProjectService__c=:psid ];
        BackupPSC = [SELECT Id, ProjectService__c,CustomDesc__c, Target__c, Price__c, Type__c, Quantity__c,YieldPerUnit__c, IsDonated__c,Target__r.Name,Target__r.TargetName__c,Target__r.PackageSizeQty__c,Target__r.PackageSizeUnits__c,Target__r.CategoryInfo__c,Target__r.UPC__c,Target__r.StockCode__c,Target__r.DepartmentNumber__c, Target__r.DepartmentName__c, CeatedByExternalSource__c,account__c, TargetAcquired__c FROM ProjectServiceTarget__c where Type__c='BackUp' and ProjectService__c=:psid ];
        HaloPSC   = [SELECT Id, ProjectService__c,CustomDesc__c, Target__c, Price__c, Type__c, Quantity__c,YieldPerUnit__c, IsDonated__c,Target__r.Name,Target__r.TargetName__c,Target__r.PackageSizeQty__c,Target__r.PackageSizeUnits__c,Target__r.CategoryInfo__c,Target__r.UPC__c,Target__r.StockCode__c,Target__r.DepartmentNumber__c, Target__r.DepartmentName__c, CeatedByExternalSource__c,account__c, TargetAcquired__c FROM ProjectServiceTarget__c where Type__c='Halo' and ProjectService__c=:psid ];

        SuppPSC = [SELECT Id, ProjectService__c,CustomDesc__c, Target__c, Price__c, Type__c, Quantity__c,YieldPerUnit__c, IsDonated__c,Target__r.Name,Target__r.TargetName__c,Target__r.PackageSizeQty__c,Target__r.PackageSizeUnits__c,Target__r.CategoryInfo__c,Target__r.UPC__c,Target__r.StockCode__c,Target__r.DepartmentNumber__c, Target__r.DepartmentName__c, CeatedByExternalSource__c,account__c, TargetAcquired__c FROM ProjectServiceTarget__c where Type__c='Supplemental' and ProjectService__c=:psid ];
        FeatPSC = [SELECT Id, ProjectService__c,CustomDesc__c, Target__c, Price__c, Type__c, Quantity__c,YieldPerUnit__c, IsDonated__c,Target__r.Name,Target__r.TargetName__c,Target__r.PackageSizeQty__c,Target__r.PackageSizeUnits__c,Target__r.CategoryInfo__c,Target__r.UPC__c,Target__r.StockCode__c,Target__r.DepartmentNumber__c, Target__r.DepartmentName__c, CeatedByExternalSource__c,account__c, TargetAcquired__c FROM ProjectServiceTarget__c where Type__c='Featured' and ProjectService__c=:psid ];        
        prodAttr= new list<ProdAttribute>();
        ProdAttribute PA = new ProdAttribute();
        for(projectserviceTarget__C psc: PrimaryPSC)
        {
            PA = new ProdAttribute();
            PA.psc = psc;
            prodAttr.add(PA);
        }
    }

    private Boolean CheckifAlreadyExists(Id col)
    {
        for (ProjectServiceTarget__c psc : PrimaryPSC){
            if (psc.Target__c == col){
                return true;
            }
        }
        for (ProjectServiceTarget__c psc : BackupPSC){
            if (psc.Target__c == col){
                return true;
            }
        }
        for (ProjectServiceTarget__c psc : HaloPSC){
            if (psc.Target__c == col){
                return true;
            }
        }
        for (ProjectServiceTarget__c psc : SuppPSC){
            if (psc.Target__c == col){
                return true;
            }
        }
        for (ProjectServiceTarget__c psc : FeatPSC){
            if (psc.Target__c == col){
                return true;
            }
        }       
        
        return false;
    }

    private Boolean IsDeleteSucceeded(Database.DeleteResult[] results) {
        for(Database.DeleteResult result: results) {
            if (!result.isSuccess()) {
                return false;
            }
        }
        return true;
    }
    
    public PageReference BulkAddProduct()
    {
        try{
            
            system.debug('~~~~'+MultipleTgts.length());
            if(MultipleTgts.length()==0){
                addMessage(ApexPages.Severity.ERROR, 'Please provide Stock ID/UPC.');
                return null;
            }
            
            set<string> SuccLoc = new set<string>();                    
            list<ProjectServiceTarget__c> CollList = new list<ProjectServiceTarget__c>();        
            lstErr= new list<errorClass>();
            lstSucc=new list<errorClass>();        
    
            //read data
            system.debug('~~~~read data');
            Set<String> UserTgtSet = new Set<String>();        
            List<String> resultLst = new List<String>();        
            for(string s : MultipleTgts.split('\n'))
            {
                UserTgtSet.add(s.trim());
            }
            resultLst.addAll(UserTgtSet);
            system.debug('~~~~UserTgtSet'+UserTgtSet);
            
                    
            //check availability
            system.debug('~~~~check avail');
            set<string> AvlTgtSet = new set<string>();
            list<Target__c> AvlTgtsList;
            list<string> invalidTgts= new list<string>();
            
            //get total count of rows returned
            integer RowsCount=0;
            if(TargetOption=='UPC')
                RowsCount = [SELECT count()  FROM Target__c where  status__c='Active' and  UPC__c IN :UserTgtSet limit 49000];
            else
                RowsCount = [SELECT count()  FROM Target__c where status__c='Active' and  StockCode__c IN :UserTgtSet limit 49000];          
            
            if(RowsCount> UserTgtSet.size()){
                addMessage(ApexPages.Severity.ERROR, 'Multiple Targets found for the same '+TargetOption+'. Please filter your data.');
                return null;    
            }
            
            
            if(TargetOption=='UPC')
                AvlTgtsList = [SELECT Id, Name,TargetName__c, Description__c, BrandInfo__c, UPC__c, DepartmentNumber__c, StockCode__c,ShelfName__c,PackageSizeQty__c  FROM Target__c where  status__c='Active' and  UPC__c IN :UserTgtSet];
            else
                AvlTgtsList = [SELECT Id, Name,TargetName__c, Description__c, BrandInfo__c, UPC__c, DepartmentNumber__c, StockCode__c,ShelfName__c,PackageSizeQty__c  FROM Target__c where status__c='Active' and  StockCode__c IN :UserTgtSet];
            
            system.debug('~~~~ AvlTgtsList '+AvlTgtsList.size());
            
           
            
            
            
            
            for(Target__c l:AvlTgtsList)
            { 
                if(TargetOption=='UPC')
                    AvlTgtSet.add(l.upc__c);
                else
                    AvlTgtSet.add(l.StockCode__c);
                
                System.debug('  AvlLocs   l.StockCode__c ' + l.StockCode__c + '     ' + l.UPC__c );
            }  
            
            if(AvlTgtSet!=null && AvlTgtSet.size()>0)
            {
                for(string s : resultLst)
                {
                   if(!AvlTgtSet.contains(s)){
                       invalidTgts.add(s);
                   }
                }
            }
            else
            {
                system.debug(' AvlTgtsMap is null ');
                invalidTgts= resultLst;                
            }
            
            
            system.debug(' invalid target '+String.join(invalidTgts, ','));
            system.debug('~~~~~~'+invalidTgts.size()+'~~~~~~'+resultLst.size());
            if(invalidTgts.size() == resultLst.size())
            {
                lstErr.add( new ErrorClass( String.join(invalidTgts, ',') ,'Invalid Target.',''));               
            }
              
            
            system.debug(' target search begins ');
            list<ProjectServiceTarget__c> ExistingProjTgtList;
    
            if(TargetOption=='UPC')
                ExistingProjTgtList = new list<ProjectServiceTarget__c>([SELECT target__c,target__r.StockCode__c,target__r.ShelfName__c,Target__r.PackageSizeQty__c,target__r.upc__c FROM ProjectServiceTarget__c where ProjectService__c = : psID  AND target__r.upc__c IN :AvlTgtSet]);
            else
                ExistingProjTgtList = new list<ProjectServiceTarget__c>([SELECT target__c,target__r.StockCode__c,target__r.ShelfName__c,Target__r.PackageSizeQty__c,target__r.upc__c FROM ProjectServiceTarget__c where ProjectService__c = : psID  AND target__r.StockCode__c IN :AvlTgtSet]);
    
           
            set<string> ExistingProjTgtsSet = new set<string>();
            
            for(ProjectServiceTarget__c plt : ExistingProjTgtList)
            {
                if(TargetOption=='UPC')
                    ExistingProjTgtsSet.add(plt.target__r.upc__c);
                else
                    ExistingProjTgtsSet.add(plt.target__r.StockCode__c);                    
                
                System.debug('     ExistingProjLocs     ' + plt.target__r.StockCode__c);
            }
            
            
            projectserviceTarget__C pscObj;
            for(target__c newTarget: AvlTgtsList )
            {
               if(!(TargetOption=='UPC'? ExistingProjTgtsSet.contains(newTarget.upc__c) : ExistingProjTgtsSet.contains(newTarget.StockCode__c))){
                    pscObj = new projectserviceTarget__C();
                    pscObj.ProjectService__c = psID;
                    pscObj.Target__c = newTarget.id;
                    pscObj.Type__c = 'Primary';
                    pscObj.IsDonated__c = false;
                    pscObj.Customdesc__c = newTarget.ShelfName__c;
                    pscObj.Price__c = 0;
                    pscObj.YieldPerUnit__C = newTarget.PackageSizeQty__c;
                    
                    CollList.add(pscObj);       
                    
                    if(TargetOption=='UPC')
                        SuccLoc.add(newTarget.upc__c);
                    else
                        SuccLoc.add(newTarget.StockCode__c);                    
               }
            }  
            system.debug('~~~~CollList'+CollList);
            insert CollList;
            
            string tempMsg;
            tempMsg =  (TargetOption=='UPC'? ' UPC(s) '  : ' Stock ID(s)');
            
            if(SuccLoc.size() >0 ){            
                lstSucc.add( new ErrorClass(String.join((new list<string>(SuccLoc)), ','),'Target(s) successfully added to the project',''));
                addMessage(ApexPages.Severity.CONFIRM, tempMsg+' successfully added :  ' + String.join((new list<string>(SuccLoc)), ','));
            }
            
            if(ExistingProjTgtsSet.size() >0 ){
                lstErr.add( new ErrorClass( String.join((new list<string>(ExistingProjTgtsSet)), ',') ,'Target(s) already added to the project.',''));
                addMessage(ApexPages.Severity.error, tempMsg+ ' already added to the project :  '+ String.join((new list<string>(ExistingProjTgtsSet)), ','));
            }
            
            if(invalidTgts.size() >0 ) {
                lstErr.add( new ErrorClass( String.join(invalidTgts, ',') ,'Invalid Target(s)',''));
                addMessage(ApexPages.Severity.error, 'Invalid '+tempMsg+' :  ' + String.join(invalidTgts, ','));
            }
            
            
            LoadProducts();
            
            
            
            
        }
        catch(DmlException e)
        {
            addMessage(ApexPages.Severity.ERROR, e.getMessage());
            return null;
        }  
            
        
        return null;       
    }
    
    public class ErrorClass{
       public string ENumber {get;set;}
       public string EReason {get;set;}
       public string EName{get;set;}
       public ErrorClass()
       {
       }
       public ErrorClass(string loc, string rsn, string obj)
       {
           ENumber = loc;EReason= rsn;EName = obj;
       }
    }
    
    public class result{
        public target__c NewLoc{get;set;} 
        public string id{get;set;} 
        public string name{get;set;} 
        public string city{get;set;}  public string status{get;set;} 
        public result(target__c loc, string val){
            newLoc=loc;
            status=val;
        }
        public result(){}
    }
    
}