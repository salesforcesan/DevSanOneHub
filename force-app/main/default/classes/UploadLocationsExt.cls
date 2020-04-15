global with sharing class UploadLocationsExt {

    public ApexPages.StandardController controller;
    public Project__c proj {get;set;}
    public String projectName {get;set;}
    public String csvFileBody{get;set;}
    public list<errorClass> lstErr{get;set;}
    public list<errorClass> lstSucc{get;set;}
    public string csvAsString{get;set;}
    public boolean isGridVisible{get;set;}
    public String projectId {get;set;} 
    public boolean displayGrid{get;set;}
    public Project__c TmpProj{get;set;}
    public ProjectLocation__c TmpProjLoc{get;set;}
    public location__c TempLoc{get;set;}
    public list<location__c> TempLocList{get;set;}
    public string City{get;set;}
    public string Region{get;set;}
    public string RoadShowNo{get;set;}
    public string soqlQuery{get;set;}
    public boolean ShowServices{get;set;}
    public string VendorName{get;set;}
    public string ClubName{get;set;}
    public boolean initialLoad{get;set;}
    public string OwnerName{get;set;}
    public list<result> FullResult{get;set;}
    public string SuccessMsg{get;set;}
    public String AvlTags{get;set;}
    public String RetailerCode {get;set;}
    
    public String getNAMESPACE() {
        return CONSTANTS.CURRENTNAMESPACEPREFIX;
    }

    public UploadLocationsExt(ApexPages.StandardController controller) {
        lstErr= new list<errorClass>();
        lstSucc=new list<errorClass>();
                
        TmpProjLoc = new projectlocation__c();
        TempLoc = new location__C();
        TempLocList = new list<location__c>();   
        displayGrid = false;
        ProjectID = ApexPages.currentPage().getParameters().get('projectid');
        TmpProj = [select id,name from project__c where id=:projectid];
        SuccessMsg = '';
        
        project__c proj = [select id,name,retailer__c, ProjectRetailerONEHUBID__c from project__c where id=:projectId];
        retailer__c retl = [select id,name from retailer__c where id=:proj.retailer__c];
        RetailerCode = proj.ProjectRetailerONEHUBID__c;
        projectName = proj.name;
        set<string> AvlTagsSet = new set<string>();
        string locationQry = ' SELECT ItemId,Name,Type FROM Location__Tag where itemid  in (SELECT id FROM Location__c where Retailer__c = \'' + retl.id + '\')';
        system.debug(' ~~~~~ locationQry' +locationQry);
        list<location__tag> listTag = database.query(locationQry);
        for(location__tag td : listTag)
        {
            AvlTagsSet.add(td.Name);
        }
        AvlTags =  String.join((new list<string>(AvlTagsSet)), ','); 
        
        FullResult = new list<result>();
    }

    public class ErrorClass{
       public string locationNumber {get;set;}
       public string reason {get;set;}
       public string LocName{get;set;}
       public ErrorClass()
       {
       }
       public ErrorClass(string loc, string rsn, string obj)
       {
           locationNumber = loc;reason= rsn;LocName = obj;
       }
    }
   
   

    global class result{
        public location__c NewLoc{get;set;} 
        public string id{get;set;} 
        public string name{get;set;} 
        public string city{get;set;}  public string status{get;set;} 
        public result(location__c loc, string val){
            newLoc=loc;
            status=val;
        }
        public result(){}
    }

    
    
    public void importCSVFile()
    {  
        ProjectLocation__c pl ;
        String retURL;
        string csvAsString;
        String[] csvFileLines;
        string[] csvRecordData;    
        string TestRecordData;
        List<ProjectLocation__c> CollList = New List<ProjectLocation__c>(); 
        List<ProjectLocation__c> CollList2;
        List<Location__c> failedColl;
        List<ProjectLocation__c> AlreadyExists;
        ProjectLocation__c ProjectLocationObj ;
        Location__c LocationObj ;
        boolean isGridVisible;
        id temp;    
        String Query ;  
        set<string> SuccLoc = new set<string>();  
            
        try
        {
            List<ProjectLocation__c>  returnedList  = New List<ProjectLocation__c>(); 
           
            csvFileLines = csvFileBody.split('\n');
                
            Set<String> myset = new Set<String>();
            List<String> result = new List<String>();
            for(string s : csvFileLines)
            {
                myset.add(s.trim());
            }
            result.addAll(myset);
            
            String Projid = ApexPages.currentPage().getParameters().get('projectid');
            proj = [select retailer__c,retailer__r.name, ProjectRetailerONEHUBID__c from project__c where id=:Projid limit 1];
            system.debug('proj retailer      '+ proj.retailer__r.name + '______' +  proj.retailer__c);
            if(result.size() == 0 )
            {
                ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,'Empty file/data. Please check and resubmit.');
                ApexPages.addMessage(errorMessage);           
                return;
            }
            
            location__c loc = new location__C();
            CollList = New List<ProjectLocation__c>(); 
            AlreadyExists= New List<ProjectLocation__c>(); 
            failedColl = New List<Location__c>(); 
            lstErr= new list<errorClass>();
            lstSucc=new list<errorClass>();
            
            list<string> invalidLoc= new list<string>();
            list<string> newLoc= new list<string>();
            
            system.debug(' search begins ');
            system.debug(' result '+String.join(result, ','));
            system.debug(' myset '+myset );
            
            set<string> AvlLocs = new set<string>();
            list<location__c> AvlLocsMap = [SELECT LocationNumber__c,name FROM Location__c where Type__c = 'Location' AND retailer__c =: proj.retailer__c and isactive__c=true and  LocationNumber__c IN :myset];
            for(location__c l:AvlLocsMap )
            { 
                AvlLocs.add(l.LocationNumber__c);
                System.debug('  AvlLocs   l.LocationNumber__c     ' + l.LocationNumber__c);
            }            
             
            if(AvlLocsMap!=null && AvlLocsMap.size()>0)
            {
                for(string s : result)
                {
                   if(!AvlLocs.contains(s)){
                       invalidLoc.add(s);
                   }
                }
            }
            else
            {
                system.debug(' AvlLocsMap is null ');
                invalidLoc = result;                
            }
            system.debug(' invalid loc '+String.join(invalidLoc, ','));
            
            if(invalidLoc.size() == result.size())
            {
                lstErr.add( new ErrorClass( String.join(invalidLoc, ',') ,'Invalid Location number.',''));
                return;
            }
            
            
            system.debug(' ProjectLocation search begins ');
            list<ProjectLocation__c> ExistingProjLocsMap = new list<ProjectLocation__c>([SELECT Location__r.LocationNumber__c FROM ProjectLocation__c where Project__c = : Proj.id   AND Status__c != 'Canceled' AND Location__r.LocationNumber__c IN :AvlLocs]);
            set<string> ExistingProjLocs = new set<string>();
            for(projectlocation__c plt : ExistingProjLocsMap)
            {
                ExistingProjLocs.add(plt.Location__r.LocationNumber__c);
                System.debug('     ExistingProjLocs     ' + plt.Location__r.LocationNumber__c);
            }
            
            Project__c p = [SELECT Id,Status__c FROM Project__c WHERE Id =:projectID];
            
            for(location__c newlocation:AvlLocsMap)
            {
               if(!ExistingProjLocs.contains(newlocation.locationnumber__c)){
                    ProjectLocationObj= new ProjectLocation__c();
                    ProjectLocationObj.Location__c =newlocation.ID;
                    ProjectLocationObj.Project__c =Projid ;
                    if(p.Status__c != CONSTANTS.PROJECT_STATUS_PLANNING){
                        ProjectLocationObj.IsNewLocation__c = true ;
                    }
                    CollList.add(ProjectLocationObj);
                    SuccLoc.add(newlocation.locationnumber__c);
               }
            }  
            insert CollList;
            
                       
            if(SuccLoc.size() >0 ){
                
                lstSucc.add( new ErrorClass(String.join((new list<string>(SuccLoc)), ','),'Location successfully added to the project',''));
            }
            
            if(ExistingProjLocs.size() >0 ){
                lstErr.add( new ErrorClass( String.join((new list<string>(ExistingProjLocs)), ',') ,'Location already added to the project.',''));
            }
            
            if(invalidLoc.size() >0 ) {
                lstErr.add( new ErrorClass( String.join(invalidLoc, ',') ,'Invalid Location number.',''));
            }
      

       }
       catch (System.DmlException e) {
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,e.getDMLMessage(0));
            ApexPages.addMessage(errorMessage);
       }
       catch (System.NullPointerException e) {
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,'Invalid file/data. Please check and resubmit.');
            ApexPages.addMessage(errorMessage);
       }        
       catch (Exception e)
       {           
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,'Invalid file with errors.');            
            // ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,e.getMessage()+ e.getTypeName());           
            ApexPages.addMessage(errorMessage);
       }          
    }
    
    
    @RemoteAction
    global static list<location__c> getProj(string tag,string state,string city,string postalcode, boolean IncludeProjLoc,string projectId, string Location) 
    {  
        project__c proj = [select id,retailer__c from project__c where id=:projectId];
        retailer__c retl = [select id,name from retailer__c where id=:proj.retailer__c];
        system.debug('retailer name  ' + retl.name);
        string LocationQry = 'Select name,Address__c,state__c,city__c,PostalCodeName__c,locationnumber__c from location__c where type__c=\'Location\' and isactive__c=true and  retailer__c =  \'' + retl.id+'\'  '; 
        Integer existingLocCount = [SELECT count() FROM ProjectLocation__c WHERE Project__c = :projectId AND Status__c != 'Canceled'];
        boolean isFilterExist = false;
        if(Location!=null && Location!='')
        {   
            isFilterExist =true;         
            LocationQry+= ' and locationnumber__c = \'' + string.valueof(Location) +'\'  '; 
        }
        
        if(state!='--NONE--' && state!=null)
        {   
            isFilterExist =true;         
            LocationQry+= ' and State__c = \'' + string.valueof(state) +'\'  '; 
        }     
        if(city!='' && city!=null)
        {   
            isFilterExist =true;         
            LocationQry+= ' and city__c like \'%' + string.valueof(city) +'%\'  '; 
        }  
         if(postalcode!='' && postalcode!=null)
        {   
            isFilterExist =true;         
            LocationQry+= ' and postalcodename__c like \'%' + string.valueof(postalcode) +'%\'  '; 
        }    
         system.debug('LocationQry  ' + LocationQry );
        
        if(!IncludeProjLoc){
            Set<string> locSet = new Set<string>();
            //string loc = ' select id from projectlocation__c where project__c=: \' ' + projectId + ' \' ' ;         
            string loc = ' select location__c from projectlocation__c where project__c=: projectId AND Status__c != \'Canceled\'' ;         
            system.debug('__#### loc __'+loc+'-----');  
            //list<AggregateResult> tagList =  Database.query(soqlQry);
            
            for(projectlocation__c ploc : Database.query(loc)){
                locSet.add((string)ploc.location__c);
            }
                        
            LocationQry+= ' and id not in :locSet ';    
        }

        system.debug('__#### tag__'+tag +'-----'); 
        if(tag!='')
        {
            isFilterExist=true;
            Set<string> subjectSet = new Set<string>();
            Set<string> SelectedTag = new Set<string>();     
            for(string item : tag.split(','))
            {
               SelectedTag.add(item);           
            }
            
            string soqlQry = ' SELECT ItemId,count(name) FROM Location__Tag where name in: SelectedTag group by itemid having count(name) = ' + SelectedTag.size()  ;         
            system.debug('__#### soqlQry __'+soqlQry+'-----');  
            list<AggregateResult> tagList =  Database.query(soqlQry);
            
            for(AggregateResult t : tagList){
                subjectSet.add((string)t.get('itemid'));
            }
            
            system.debug('__#### subjectSet __'+subjectSet+'-----'); 
            LocationQry+= ' and id in :subjectSet  ';
        }
        LocationQry+= '  order by name ';
        system.debug('__#### loc qry __'+LocationQry+'-----');  
        
        if(!isFilterExist){
            LocationQry+= '  limit 0 ';    
        }
        else{
            LocationQry+= '  limit ' + (9500 - existingLocCount);    
        }
       
        return Database.query(LocationQry);
        
    }
    
    @RemoteAction
    global static string Import(string allLocID,string projectID)
    {
        string msg = '';
        try{
            system.debug('inside import');
            list<ProjectLocation__c> ExistingProjLocsMap = new list<ProjectLocation__c>([SELECT Location__r.LocationNumber__c FROM ProjectLocation__c where Project__c = : ProjectID AND Status__c != 'Canceled']);
            Project__c p = [SELECT Id,Status__c FROM Project__c WHERE Id =:projectID];
            set<string> ExistingProjLocs = new set<string>();
            for(projectlocation__c plt : ExistingProjLocsMap)
            {
                ExistingProjLocs.add(plt.Location__r.LocationNumber__c);                
            }
            
            set<string> AllProjLocs = new set<string>();
            for(string item : allLocID.split(','))
            {
               AllProjLocs.add(item);           
            }
            
            result res = new result();
            list<result> lstresult = new list<result>();
            
            ProjectLocation__c ProjectLocationObj;
            list<ProjectLocation__c> CollList = new list<ProjectLocation__c>(); 
            
            list<location__c> locList = [select id,locationnumber__c,name,city__c from location__c where id in: AllProjLocs LIMIT 9500];
            
            for(location__c row: locList )
            {
                    res = new result();
                    res.id = row.id;
                    res.city = row.city__c;
                    res.name = row.name;
                    
               if(!ExistingProjLocs.contains(row.locationnumber__c)){
                    ProjectLocationObj= new ProjectLocation__c();
                    ProjectLocationObj.Location__c =row.id;
                    ProjectLocationObj.Project__c =ProjectID ;
                    if(p.Status__c != CONSTANTS.PROJECT_STATUS_PLANNING){
                        ProjectLocationObj.IsNewLocation__c = true ;
                    }
                    CollList.add(ProjectLocationObj);
                    res.status='Success';
               }
               else{
                    res.status='Location already exist';
               }
               lstresult.add(res);
            }  
            
            if(CollList.size()>0)
            {
                Database.SaveResult[] obj = database.insert(CollList);
                
                //Comment Versioning Code
                //AppUtil.UpdateProjectVersion(ProjectID);
                
                return CollList.size() + ' location(s) added to project';
            }
            else{
                return 'Location(s) already exist in the project';
            }
            
        }
        catch(exception ex){
                return string.valueof(ex);
            //return 'Error during Import. Contact Admin';
        }

    }
}