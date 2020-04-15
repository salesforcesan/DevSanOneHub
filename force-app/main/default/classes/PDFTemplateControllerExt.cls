public with sharing class PDFTemplateControllerExt {
    private Boolean isEnglish;
    public String EVENT_OVERVIEW_KEY{get;set;}
    public String SPECIAL_INSTRUCTION_KEY{get;set;}
    public String projectServiceId  {get;private set;}
    public String jobId  {get;private set;}

    public String psId  {get;private set;}
    public Job__c job  {get;private set;}
    public ProjectService__c projectService {get;private set;}
    public String clientLogoImg {get;private set;}
    public String eventExecutionDates {get;private set;}
    public String barcodeImg {get;private set;}
    public String serviceImageId {get;private set;}
    public List<SurveyWrapper> surveyQuestions {get;private set;}
    public String previewMessage {get;private set;}
    public List<ProjectServiceTarget__c> PrjTargetItems{get;set;}
    public List<ProjectServiceTarget__c> primaryItems{get;set;}
    public List<ProjectServiceTarget__c> backupItems {get;set;}
    public List<ProjectServiceTarget__c> haloItems {get;set;}
    
    public List<ProjectServiceTarget__c> SuppItems {get;set;}
    public List<ProjectServiceTarget__c> FeatItems {get;set;}
    public string eqTools{get;set;}
    public LocaleManager locale {get; private set;}
    
    public Decimal primaryTotal {get;set;}
    public Decimal backupTotal {get;set;}
    public Decimal haloTotal {get;set;}
    public Decimal SalesTax {get;set;}
    public String productImageId {get;private set;}
    public List<ProjectServiceAttribute__c> primaryItemsAttributeValues{get;set;}
    public List<ProjectServiceAttribute__c> backupItemsAttributeValues {get;set;}
    public List<ProjectServiceAttribute__c> haloItemsAttributeValues {get;set;}
    public Map<string, List<itemvalue>> primaryAttributes{get; set;}
    public Map<string, List<itemvalue>> backupAttributes{get; set;}
    public Map<string, List<itemvalue>> haloAttributes{get; set;}
    public Map<string, attributevalue> nrAttributes{get; set;}
    public Map<integer, string> nrAttributesOrdered{get; set;}

    public List<attributevalue> NonRepeatAttributes {get;set;}
    public String EventOverview {get;set;}
    public String SpecialInstruction {get;set;}
    public String ServiceObjective {get;set;}
    public List<ProjectServiceMaterial__c> materialsKits {get;set;}
    public String LogoURL{get;set;}
    public String logoheight {get;set;}
    public list<string> AllItems{get;set;}
    public integer AllItemsCount{get;set;}
    public integer AllItemsRowCount{get;set;}
    public String ShippingPreference{get;set;}
    public String UseType{get;set;}
    public Boolean DisplayShipping  
    {
        get 
        { 
            return (AllItemsCount>0 && ShippingPreference!=null && ShippingPreference!='' && ShippingPreference.toLowerCase()!='none');
        }
    }
        
    public list<string> AllItems1{get;set;}
    public list<string> AllItems2{get;set;}
    public list<string> AllItems3{get;set;}
      
    public list<Wrapper> utensilList{get;set;}
    public list<ServiceException__c> exceptionList{get;set;}    
    
    public string ToolImageFolder{get;set;}    
            
    public class itemvalue{
        public string item {get; set;}
        public string value {get; set;}
        public itemvalue(string itm, string val)
        {
            item = itm;
            value = val;
        }
    }

   
    public class AttributeValue{
        public String Name {get;set;}
        public String NameForLang {get;set;}

        public string Value {get; set;}
        public string AttributeType {get; set;}
        public string AttachmentName {get; set;}
        public string AttachmentId {get; set;}
        public String ImageFlag {get;set;}
        public Boolean showSectionOne {
            get {
               String source = 'Event Overview|Supporting Attachment 1|Supporting Attachment 2|Supporting Attachment 3|Supporting Attachment 4|Supporting Attachment 5|Special Instructions';

                return String.isNotEmpty(this.Value) && source.indexOf(this.Name) == -1; 
            }
        }
        public Boolean showSectionTwo {
            get {
               String source = 'Event Overview|Special Instructions|Cart-Event Set Up|Talking Points|Event Instructions';

                return String.isNotEmpty(this.Value) && source.indexOf(this.Name) == -1; 
            }
        }

        public Boolean isAttachment {
            get {
                return AttachmentAnalyzer.isFile(AttachmentId, AttributeType);
            }
        }

        public Boolean isImage {
            get {
                return AttachmentAnalyzer.isImage(AttachmentId, AttachmentName, AttributeType);
            }
        }
        
        public AttributeValue(){}

        public AttributeValue(string val, string type, string atname, string atid)
        {
            Value = val;
            AttributeType = type;
            AttachmentName = atname;
            AttachmentId = atid;
        }

         public AttributeValue(string val, string type, string atname, string atid, string imageFlag)
        {
            Value = val;
            AttributeType = type;
            AttachmentName = atname;
            AttachmentId = atid;
            this.ImageFlag = imageFlag;
        }
    }    
   
    public PDFTemplateControllerExt(ApexPages.StandardController controller) {
        initData();
    }

    private void initLocale(ProjectService__c pService) {
        if (pService != null && pService.VariantLanguage__c == 'French')  {
                this.locale = LocaleManager.newInstance(LocaleManager.FRENCH_CODE);
                isEnglish = false;
            } else {
                isEnglish = true;
                this.locale = LocaleManager.newInstance(); 
            }
    }
   
    public Boolean initData(){
        EVENT_OVERVIEW_KEY='Service Objective';
        SPECIAL_INSTRUCTION_KEY='Service Instruction';
        Map<String,String> query = ApexPages.currentPage().getParameters();
        this.jobId = String.valueOf(query.get('jobId'));
        this.psId = String.valueOf(query.get('psId'));
        
         ToolImageFolder = '';
        List<ImageFolder__c> toolImageFolders = [SELECT FolderName__c FROM ImageFolder__c where name='ToolImages' limit 1];
        if(toolImageFolders.size() > 0 && toolImageFolders[0].FolderName__c != ''){
            ToolImageFolder = toolImageFolders[0].FolderName__c;
        }

        if(string.isempty(jobId)){
            this.job = new Job__c();
            projectServiceId = this.psId;
            this.projectService = [SELECT project__r.OperationsTitle__c,ServiceObjective__c ,Name,status__c,TargetType__c,Project__c,project__r.name, project__r.ProjectNumber__c, PurchaseAmount__c, ServiceName__c, Service__c, SalesTax__c, VariantLanguage__c, ShippingPreference__c, NumberOfMaterials__c FROM ProjectService__c WHERE Id =: projectServiceId AND IsDeleted = false];
            
            Project__c p = [SELECT Name,StartDate__c,Retailer__r.LogoURL__C,Retailer__r.Name, EndDate__c, Retailer__r.LogoHeight__c FROM Project__c WHERE Id =: this.projectService.Project__c AND IsDeleted = false];
            LogoURL = p.Retailer__r.LogoURL__c;
            logoheight = '60';
            if(p.Retailer__r.LogoHeight__c != null){
                logoheight =  String.valueOf(p.Retailer__r.LogoHeight__c);
            }
            this.eventExecutionDates = p.StartDate__c.format() + ' - ' + p.EndDate__c.format();
            //insert job;
            previewMessage = 'This is a preview';
        }
        else{
            this.job = [SELECT Project__r.Retailer__r.LogoURL__c,  Jobcanceledreason__c,JobEndDate__c,Id,LocationNumber__c,Location__c,Name,ProjectEndDate__c,ProjectLocation__c,ProjectName__c,ProjectService__c,ProjectStartDate__c,Project__c,/*ServiceName__c,Service__c,*/JobStartDate__c,jobstatus__c FROM Job__c WHERE Id =: jobId AND IsDeleted = false];
            LogoURL = job.PRoject__r.Retailer__r.LogoURL__c;
            projectServiceId = job.ProjectService__c;
            this.projectService = [SELECT Name,PurchaseAmount__c, status__c,TargetType__c,  VariantLanguage__c, Service__c,ShippingPreference__c, NumberOfMaterials__c FROM ProjectService__c WHERE Id =: projectServiceId AND IsDeleted = false];
            this.eventExecutionDates = job.ProjectStartDate__c.format() + ' - ' + job.ProjectEndDate__c.format();
        }
        
        ShippingPreference = this.projectService.ShippingPreference__c == 'Ship to Worker'?'Home':'Store';
        
        eqTools = [SELECT Value__c FROM AppSettings__mdt WHERE DeveloperName = 'Equimenttypetool' limit 1].Value__c;
        initLocale(this.projectService);
        PrjTargetItems = [SELECT Id, ProjectService__c,customdesc__c, Target__c, Price__c, Type__c, Quantity__c,YieldPerUnit__c, IsDonated__c,Target__r.Name,Target__r.TargetName__c,Target__r.PackageSizeQty__c,Target__r.PackageSizeUnits__c,Target__r.CategoryInfo__c,Target__r.UPC__c,Target__r.StockCode__c,Target__r.DepartmentNumber__c,Target__r.DepartmentName__c,TargetAcquired__c  FROM ProjectServiceTarget__c  where ProjectService__c=:projectServiceId  and Type__c !='Analytics' order by Type__c asc];     
        primaryItems = [SELECT Id, ProjectService__c,customdesc__c, Target__c, Price__c, Type__c, Quantity__c,YieldPerUnit__c, IsDonated__c,Target__r.Name,Target__r.TargetName__c,Target__r.PackageSizeQty__c,Target__r.PackageSizeUnits__c,Target__r.CategoryInfo__c,Target__r.UPC__c,Target__r.StockCode__c,Target__r.DepartmentNumber__c,Target__r.DepartmentName__c,TargetAcquired__c  FROM ProjectServiceTarget__c  where ProjectService__c=:projectServiceId order by name limit 20];     
        backupItems = [SELECT Id, ProjectService__c,customdesc__c, Target__c, Price__c, Type__c, Quantity__c,YieldPerUnit__c, IsDonated__c,Target__r.Name,Target__r.TargetName__c,Target__r.PackageSizeQty__c,Target__r.PackageSizeUnits__c,Target__r.CategoryInfo__c,Target__r.UPC__c,Target__r.StockCode__c,Target__r.DepartmentNumber__c,Target__r.DepartmentName__c, TargetAcquired__c FROM ProjectServiceTarget__c where ProjectService__c=:projectServiceId order by name limit 20];      
        haloItems   = [SELECT Id, ProjectService__c, customdesc__c,Target__c, Price__c, Type__c, Quantity__c,YieldPerUnit__c, IsDonated__c,Target__r.Name,Target__r.TargetName__c,Target__r.PackageSizeQty__c,Target__r.PackageSizeUnits__c,Target__r.CategoryInfo__c,Target__r.UPC__c,Target__r.StockCode__c,Target__r.DepartmentNumber__c,Target__r.DepartmentName__c, TargetAcquired__c FROM ProjectServiceTarget__c where ProjectService__c=:projectServiceId order by name limit 20];
         
        SuppItems = [SELECT Id, ProjectService__c, Target__c,customdesc__c, Price__c, Type__c, Quantity__c,YieldPerUnit__c, IsDonated__c,Target__r.Name,Target__r.TargetName__c,Target__r.PackageSizeQty__c,Target__r.PackageSizeUnits__c,Target__r.CategoryInfo__c,Target__r.UPC__c,Target__r.StockCode__c,Target__r.DepartmentNumber__c,Target__r.DepartmentName__c, TargetAcquired__c FROM ProjectServiceTarget__c where Type__c='Supplemental' and ProjectService__c=:projectServiceId];       
        FeatItems = [SELECT Id, ProjectService__c, Target__c, customdesc__c,Price__c, Type__c, Quantity__c,YieldPerUnit__c, IsDonated__c,Target__r.Name,Target__r.TargetName__c,Target__r.PackageSizeQty__c,Target__r.PackageSizeUnits__c,Target__r.CategoryInfo__c,Target__r.UPC__c,Target__r.StockCode__c,Target__r.DepartmentNumber__c,Target__r.DepartmentName__c, TargetAcquired__c FROM ProjectServiceTarget__c where Type__c='Featured' and ProjectService__c=:projectServiceId];       

        initProjectServiceMaterials();
        initNOnRepeatAttributes();
        
        Set<Id> primaryIds = new Set<Id>();
        for(ProjectServiceTarget__c  s : primaryItems ){
            primaryIds.add(s.Id);
        }
        
        Set<Id> backupIds = new Set<Id>();
        for(ProjectServiceTarget__c  s : backupItems ){
            backupIds.add(s.Id);
        }

        Set<Id> haloIds = new Set<Id>();
        for(ProjectServiceTarget__c  s : haloItems   ){
            haloIds.add(s.Id);
        }
        
        
        
        
        system.debug('Ordered Size: ' + nrAttributesOrdered.size());
        system.debug('UnOrdered Size: ' + nrAttributes.size());
                
        this.surveyQuestions = getSurveyQuestions();
        primaryTotal = 0;
        backupTotal = 0;
        haloTotal = 0;
        if(primaryItems.size() > 0 ){
            List<Attachment> attachments = [SELECT Id FROM Attachment WHERE ParentID = :primaryItems[0].Target__c ORDER BY LastModifiedDate DESC LIMIT 1];
            if(attachments.size()>0){
                this.productImageId = attachments[0].Id;
            }
            
        }
        for(ProjectServiceTarget__c item:primaryItems){
            if (item.IsDonated__c == true || item.Price__c == null || item.Quantity__c == null) 
                continue;
            primaryTotal += (item.Price__c * item.Quantity__c);
        }
        
        for(ProjectServiceTarget__c item:backupItems){
            if (item.IsDonated__c == true || item.Price__c == null || item.Quantity__c == null) 
                continue;
            backupTotal += (item.Price__c * item.Quantity__c);
        }
        
        for(ProjectServiceTarget__c item:haloItems){
            if (item.IsDonated__c == true || item.Price__c == null || item.Quantity__c == null) 
                continue;
            haloTotal += (item.Price__c * item.Quantity__c);
        }
        initUtensilList();
        
        
        exceptionList = new List<ServiceException__c>();        
        String field;
        
        for (ServiceException__c EC : [SELECT Id, Name, Exception__r.Exceptioncode__c, Exception__r.ExceptionCodeDesc__c, service__r.name from ServiceException__c where service__c =: this.projectservice.service__c])
        {                                                                                                                                                     
        exceptionList.add(EC);
        }
        
        return true;
            
    }

    private void initNOnRepeatAttributes() {
        List<ProjectServiceAttribute__c> psNonRepeatAttributeValues = [Select Id, Name, AttributeType__c, AttributeTitle__c,   ProjectService__c, AttributeValue__c,   AttributeOrder__c  from ProjectServiceAttribute__c where ProjectService__c=:projectServiceId AND AttributeTitle__c !='Job Manual' AND ServiceAttribute__r.ExcludeFromJobManual__c= false Order By AttributeOrder__c] ;
         

        nrAttributes = new Map<string, attributevalue>();
        nrAttributesOrdered = new Map<integer, string>();
        Map<String, AttributeValue> result = new Map<String, attributevalue>();

        for(ProjectServiceAttribute__c  psca : psNonRepeatAttributeValues){
            if (!result.containsKey(psca.AttributeTitle__c)) {
                AttributeValue attrV = genAttribute(psca);
                if (attrV.isAttachment) {
                    if (String.isNotBlank(attrV.AttachmentId)) {
                        result.put(psca.AttributeTitle__c, attrV);
                    }
                } else {
                    result.put(psca.AttributeTitle__c, attrV);
                }
            }    
            
            /*    
        
            if (nrAttributesOrdered.ContainsKey(Integer.ValueOf(psca.AttributeOrder__c)) == false)
            {
                nrAttributesOrdered.put(Integer.Valueof(psca.AttributeOrder__c), psca.AttributeTitle__c);
                //system.debug('inside nrAttributesOrdered ' + psca.AttributeTitle__c + '__'+ psca.AttributeOrder__c);
            }

            if (nrAttributes.containsKey(psca.AttributeTitle__c) == false)             
            {
                attributevalue av = GetAttributeValue(psca.AttributeTitle__c,psNonRepeatAttributeValues);
                //system.debug('inside nrAttributes ' + psca.AttributeTitle__c + '__'+ av.value);
                nrAttributes.put(psca.AttributeTitle__c, av);
            }
            */
        }
        if (result.containsKey(EVENT_OVERVIEW_KEY)) {
            this.EventOverview = result.get(EVENT_OVERVIEW_KEY).Value; 
        }
        if (result.containsKey(SPECIAL_INSTRUCTION_KEY)) {
            this.SpecialInstruction = result.get(SPECIAL_INSTRUCTION_KEY).Value;
        }
        system.debug('~~~result.values()'+result.values());
        this.NonRepeatAttributes = result.values();
    }

    private AttributeValue genAttribute(ProjectServiceAttribute__c psAttribute) {
        AttributeValue attr = new attributevalue();
        attr.Name = psAttribute.AttributeTitle__c;
        //attr.NameForLang =  psAttribute.Attribute__r.EngName__c ;
        attr.AttributeType = psAttribute.AttributeType__c;
        attr.Value = psAttribute.AttributeValue__c != null ? psAttribute.AttributeValue__c : '';

        if ((attr.AttributeType == 'Photo' || attr.AttributeType == 'File' ) && attr.Value != '' ) {
            String[] arr = attr.Value.split('=');
            attr.ImageFlag = arr.size() == 2 ? arr[1] : '0';
            String attrId = arr[0];
            String[] attachments = getAttachment(attrId);
            attr.AttachmentName = attachments[0];
            attr.AttachmentId = attachments[1];

        }

        return attr;
    }

    private String[] getAttachment(String id) {
        list<Attachment> at = [Select Id, Name from Attachment where Id =:id];
        if (at != null && at.size()>0)
        {
            return new List<String> {
              at[0].Name,
              String.ValueOf(at[0].Id)   
            };
        }
        return new List<String>{
            '',
            ''
        };
    }

     private attributevalue GetAttributeValue(string attributename, List<ProjectServiceAttribute__c>pscas )
    {
        string atname = '';
        string atid = '';
        string atValue = '';
        
        system.debug('attributename     :' + attributename);
        for (ProjectServiceAttribute__c psca : pscas)
        {
            
          
            system.debug('psca.AttributeTitle__c     :' + psca.AttributeTitle__c  + '___'+ psca.AttributeValue__c);
            
            if (psca.AttributeValue__c == null)
            {
                atValue = '';
            }
            else
            {
                atValue = psca.AttributeValue__c.trim();
            }
            
            
            if (psca.AttributeTitle__c == attributename) 
            {
                if ((psca.AttributeType__c == 'Photo' || psca.AttributeType__c == 'File' ) && atValue != '' )
                {
                    list<Attachment> at = [Select Id, Name from Attachment where Id =: psca.AttributeValue__c ];
                    if (at != null && at.size()>0)
                    {
                        atname = at[0].Name;
                        atid = String.ValueOf(at[0].Id);
                    }
                    else{
                        atname = '';
                        atid = String.ValueOf(psca.AttributeValue__c);
                    }
                }
                
            
                return new attributevalue(atValue , psca.AttributeType__c, atname, atid);
            }
        
        }
        return null;
    }

    private void initProjectServiceMaterials() {
        materialsKits= new List<ProjectServiceMaterial__c>();    
        List<ProjectServiceMaterial__c> materialsAlaCarte;    
        String field;

        materialsKits = [SELECT Id, MaterialDescription__c, MaterialName__c,  Quantity__c, ShipTo__c, UseType__c,material__r.ExternalId__c from ProjectServiceMaterial__c where ProjectService__c = :projectServiceId order by name /*limit 5*/];
        
        materialsAlaCarte = [SELECT Quantity__c, Material__r.name from ProjectServiceMaterial__c where ProjectService__c = :projectServiceId AND Kit__c = false];

        /*AllItems = new list<string>();
        if (materialsKits != null && materialsKits.size() > 0)
        {
            field = 'Description__c' ;
            for(ProjectServiceMaterial__c psm : materialsKits ){
                if (psm.Material__r.get(field) != null && String.valueOf(psm.Material__r.get(field)) != '')
                {
                    for(string s: String.valueOf(psm.Material__r.get(field)).split('<br>'))
                        AllItems.add(s);
                }    
            }
        }
        
        if (materialsAlaCarte != null && materialsAlaCarte.size() > 0)
        {
            field =  'Name' ;
            for(ProjectServiceMaterial__c psm : materialsAlaCarte){

                AllItems.add(psm.Quantity__c+ ' ' + String.valueOf(psm.Material__r.get(field)));
            }
        }
        
        AllItemsCount=AllItems.size();
        //AllItemsRowCount = (AllItems.size() + math.mod(AllItems.size(),3))/3 ;
        AllItemsRowCount = Math.ceil(AllItems.size()/3.0).intValue();

        AllItems1 = new list<string>();
        AllItems2 = new list<string>();
        AllItems3 = new list<string>(); 
        system.debug('AllItemsRowCount: '+AllItemsRowCount );               
        system.debug('AllItems.size(): '+AllItems.size());               
        for(integer i=0;i<AllItemsRowCount;i++){
            if(i<AllItems.size())
            AllItems1.add(AllItems[i]);    
        }
        for(integer i=AllItemsRowCount;i<AllItemsRowCount*2;i++){
            if(i<AllItems.size()&& i!=AllItems.size()-1)
              AllItems2.add(AllItems[i]);    
             else if(i==AllItems.size()-1)
              AllItems3.add(AllItems[i]); 
        }
        
        for(integer i=AllItemsRowCount*2;i<AllItems.size();i++){
            if(i<AllItems.size())
            AllItems3.add(AllItems[i]);    
        }*/
        
    }

    private void initUtensilList() {
        utensilList = new list<Wrapper>();
  
            for(projectserviceEquipment__c  pse : [SELECT Id,equipment__r.Name,equipment__r.Description__c FROM projectserviceEquipment__c WHERE equipment__r.EquipmentType__c=:eqTools and projectservice__c =: projectServiceId ])
            {
                utensilList.add(new Wrapper(pse.equipment__r.name.toLowerCase().replace(' ','') + '.png',pse.equipment__r.Description__c));            
            }    

    }    
    
   
    
    
    private List<SurveyWrapper> getSurveyQuestions(){
        List<SurveyWrapper> sqList = new List<SurveyWrapper>();
        List<ProjectServiceQuestion__c> qstns;
        List<ProjectServiceTarget__c> targets;
        SurveyWrapper sw;


        qstns = [SELECT Id,QuestionText__c,question__c, Question__r.ItemQuestion__c,ServiceQuestion__c, 
                 ProjectService__r.PopulateTargetQuestions__c FROM ProjectServiceQuestion__c WHERE 
                 ProjectService__c =: projectServiceId AND IsDeleted = false and Active__c =true order by QuestionNumber__c ];
        
        
        targets = [SELECT Id, Name, TargetUPC__c, Target__c, ProjectService__c, TargetName__c, 
                   TargetStockCode__c, YieldPerUnit__c, Target__r.PackageSizeQty__c,Target__r.PackageSizeUnits__c 
                   FROM ProjectServiceTarget__c where ProjectService__c =: projectServiceId];
        
       // Set<String> questionIds = new Set<String>();
        //for (ProjectServiceQuestion__c qstn: qstns)
        //{
          //  questionIds.add(qstn.question__c);
       // }
       Set<String> psquestionIds = new Set<String>();
        for (ProjectServiceQuestion__c psqstn: qstns)
        {
            psquestionIds.add(psqstn.Id);
        }
        
        
        //List<QuestionDefinedResponse__c> drs = [select id,DefinedResponseOrder__c,DefinedResponseText__c, Question__c 
                                              ///  from questionDefinedResponse__c where question__c IN :questionIds AND Question__r.Active__c = true
                                              //  order by DefinedResponseOrder__c ];
        List<ProjectServiceQuestionDefinedResponse__c>lstPsqdr = [select Id, DefinedResponseOrder__c,DefinedResponseText__c, ProjectServiceQuestion__c 
                                                from ProjectServiceQuestionDefinedResponse__c where ProjectServiceQuestion__c IN :psquestionIds AND Active__c = true
                                               order by DefinedResponseOrder__c ];
        Map<String, List<ProjectServiceQuestionDefinedResponse__c>> psqndrsMap = new Map<String, List<ProjectServiceQuestionDefinedResponse__c>>();
      
      //  Map<String, List<QuestionDefinedResponse__c>> qndrsMap = new Map<String, List<QuestionDefinedResponse__c>>();
      //  
       /* for (QuestionDefinedResponse__c dr: drs)
        {
           	List<QuestionDefinedResponse__c> listdrs = qndrsMap.get(dr.Question__c);
           	if (listdrs == null || listdrs.isEmpty())
           	{
            	listdrs = new List<QuestionDefinedResponse__c>();
           	}
            listdrs.add(dr);
                
			qndrsMap.put(dr.Question__c, listdrs);
        }*/
          for (ProjectServiceQuestionDefinedResponse__c psqdr: lstPsqdr)
        {
             List<ProjectServiceQuestionDefinedResponse__c> listpsqdrs;
              if(psqndrsMap.containsKey(psqdr.ProjectServiceQuestion__c))
            {
                listpsqdrs = psqndrsMap.get(psqdr.ProjectServiceQuestion__c);
        
            }
            else
            {
                listpsqdrs = new  List<ProjectServiceQuestionDefinedResponse__c>();
            }
            listpsqdrs.add(psqdr);
           
           if(listpsqdrs.size() >0)
           {
                if(psqndrsMap.containsKey(psqdr.ProjectServiceQuestion__c))
                {
                    psqndrsMap.put(psqdr.ProjectServiceQuestion__c,listpsqdrs);
                }
               else
               {
                 psqndrsMap.put(psqdr.ProjectServiceQuestion__c, listpsqdrs);
               }
           }
 			
        }
        
        
        integer serviceQtn = 1;
        
        for(ProjectServiceQuestion__c qstn:qstns){
            
            
            if((qstn.ProjectService__r.PopulateTargetQuestions__c && qstn.Question__r.ItemQuestion__c) || qstn.QuestionText__c == Constants.QUESTIONTYPE_TARGET_GROUP)
            {
                integer targetQtn = 1;                                        
                for(ProjectServiceTarget__c target:targets)
                {   
                    //{Stock ID - item desc (UPC)}
                    
                    sw = new SurveyWrapper(string.valueof(serviceQtn) + '.' + string.valueof(targetQtn));
                    //Product Name - 20 oz (Stock ID: {1} | UPC: {2})
                    String title = target.TargetStockCode__c + ' - ' + target.TargetName__c;
                    
                    //sw.Question = qstn.QuestionText__c.replace('{title}',target.TargetName__c + ' - ' + target.YieldPerUnit__c);
                    if(target.TargetUPC__c !=null && target.TargetUPC__c!='')
                    {  
                        title += ' (' + target.TargetUPC__c + ')'; 
                    }
                    sw.Question = qstn.QuestionText__c.replace('{title}',title).replace('{item}',title);
                    //sw.Question = qstn.QuestionText__c.replace('{item}',title);
                    sqList.add(sw);
                    targetQtn +=1;
                }
            }
            else if(!qstn.Question__r.ItemQuestion__c)
            {
                sw = new SurveyWrapper(string.valueof(serviceQtn));
                sw.Question = qstn.QuestionText__c;
                sw.DefinedResponse = '';
                
                List<ProjectServiceQuestionDefinedResponse__c> qndrs = psqndrsMap.get(qstn.Id);
                if (qndrs!= null && !qndrs.isEmpty())
                {
                    for (ProjectServiceQuestionDefinedResponse__c dr : psqndrsMap.get(qstn.Id)) {
                        sw.DefinedResponse += dr.DefinedResponseOrder__c + '. ' +dr.DefinedResponseText__c + '<br/>';     
                    }
                }
                sqList.add(sw);
            }
            serviceQtn +=1;
        } 
        return sqList;

        


    }  

    private Map<ID,String> getVariantQuestions(String projectServiceId, string variantId) {
        Map<ID,String> variantQuestions = new Map<ID,String>();
        for(QuestionVariant__c v: [SELECT Question__c, QuestionText__c FROM QuestionVariant__c WHERE Variant__c=:variantId AND Question__c IN (SELECT question__c FROM ProjectServiceQuestion__c WHERE ProjectService__c =: projectServiceId AND IsDeleted = false)]){
                variantQuestions.put(v.question__c, v.QuestionText__c);
        }
        return variantQuestions;
    }
    
    private String genLangError(String message) {
        if (this.locale.LanguageCode == LocaleManager.FRENCH_CODE) {
            return 'La question suivante ne se traduit pas: ' + message;
        }
        return message;
    }
   
    public class SurveyWrapper{
        public String Question {get;set;}
        public String DefinedResponse {get;set;}
        public String QuestionNo{get;set;}
        
        public SurveyWrapper(String QNo)
        {
            this.QuestionNo=QNo;
        }
        public SurveyWrapper()
        {
        }

    }

    public class Wrapper{
        public String Key{get;set;}
        public String Val{get;set;}
        public wrapper(string param1,string param2)
        {
            Key = param1;
            Val = param2;
        }
    }  
  
  
    

}