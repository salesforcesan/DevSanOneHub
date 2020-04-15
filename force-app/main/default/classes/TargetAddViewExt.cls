public with sharing class TargetAddViewExt {
    public Blob csvFileBody{get;set;}
    public string csvAsString{get;set;}
    public String[] csvFileLines{get;set;}
    public string[] csvRecordData{get;set;}    
    public List<Target__c> CollList{get;set;}
    public List<Target__c> failedColl{get;set;}
    public Target__c TargetObj{get;set;}    
    public boolean isGridVisible{get;set;}
    public string docID{get;set;}
    
    public TargetAddViewExt(ApexPages.StandardController controller) {
        csvFileLines = new String[]{};
        CollList = New List<Target__c>(); 
        failedColl = New List<Target__c>(); 
        isGridVisible=false;
        TargetObj = new Target__c();
        docID = [select id from document where developername='Upload_Item_template' limit 1].id;
    }
    public void importCSVFile(){  
        try
        {
           location__c loc = new location__C();
           CollList = New List<Target__c>(); 
           failedColl = New List<Target__c>();           
           List<Target__c>  returnedList  = New List<Target__c>(); 
           
           system.debug('~~~~  b44 ~~~~');
           
           csvAsString = csvFileBody.toString();
           //csvAsString = EncodingUtil.base64Encode(csvAsString);
           
           system.debug('~~~~  csvFileLines ~~~~'+ csvFileLines);
           
           csvFileLines = csvAsString.split('\n');  

           string t ;

           system.debug('~~~~  csvRecordData ~~~~' + csvFileLines);
                  
                            
           for(Integer i=1;i<csvFileLines.size();i++)
           {
           
               csvRecordData = csvFileLines[i].split(',');
               system.debug('~~~~  csvRecordData ~~~~' + csvRecordData);
               /*
               returnedList = [select id from Target__c where Target__c.StockCode__c =: csvRecordData[1]];
               if(returnedList.size()>0)
               {
                   TargetObj = new Target__c();
                   TargetObj.Name = csvRecordData[0];
                   TargetObj.StockCode__c = csvRecordData[1];
                   TargetObj.UPC__c = csvRecordData[2];                     
                   TargetObj.Description__c = 'Target already exist in the system.';
                   failedColl.add(TargetObj);
               }
               else
               {     
                   try{                 
                      TargetObj = new Target__c();
                      TargetObj.Name = csvRecordData[0];
                      TargetObj.StockCode__c = csvRecordData[1];  
                      TargetObj.UPC__c = csvRecordData[2] ;                   
                      TargetObj.AccountInfo__c= csvRecordData[3];
                      TargetObj.BrandInfo__c= csvRecordData[4];
                      TargetObj.CategoryInfo__c= csvRecordData[5];
                      TargetObj.TargetType__c= csvRecordData[6];
                      TargetObj.DescriptionName__c= csvRecordData[7];
                      TargetObj.PackageSizeQty__C= Decimal.valueOf(csvRecordData[8]);
                      TargetObj.PackageSizeUnits__c = csvRecordData[9];
                      TargetObj.department__c = csvRecordData[10];
                      insert TargetObj;  //inserting every object and not the whole list to catch exceptions at object level
                      CollList.add(TargetObj);
                     
                  }
                  catch(exception ex){
                        TargetObj = new Target__c();
                        TargetObj.Name = csvRecordData[0];
                        TargetObj.StockCode__c = csvRecordData[1];
                        TargetObj.UPC__c = csvRecordData[2];                        
                        TargetObj.Description__c = ex.getdmlMessage(0);
                        failedColl.add(TargetObj);
                  } 
             }      
                  */
                  system.debug('~~~~  csvRecordData ~~~~' + csvRecordData);
                  
                  try{                 
                      TargetObj = new Target__c();
                      TargetObj.Name = csvRecordData[0];
                      TargetObj.StockCode__c = csvRecordData[1];  
                      TargetObj.UPC__c = csvRecordData[2] ;                   
                      TargetObj.AccountInfo__c= csvRecordData[3];
                      TargetObj.BrandInfo__c= csvRecordData[4];
                      TargetObj.CategoryInfo__c= csvRecordData[5];
                      TargetObj.TargetType__c= csvRecordData[6];
                      TargetObj.Description__c= csvRecordData[7];
                      TargetObj.PackageSizeQty__C= Decimal.valueOf(csvRecordData[8]);
                      TargetObj.PackageSizeUnits__c = csvRecordData[9];
                      TargetObj.DepartmentName__c = csvRecordData[10];
                      insert TargetObj;  //inserting every object and not the whole list to catch exceptions at object level
                      CollList.add(TargetObj);
                     
                  }
                  catch(exception ex){
                        TargetObj = new Target__c();
                        TargetObj.Name = csvRecordData[0];
                        TargetObj.StockCode__c = csvRecordData[1];
                        TargetObj.UPC__c = csvRecordData[2];                        
                        TargetObj.Description__c = ex.getdmlMessage(0);
                        failedColl.add(TargetObj);
                  }
               
          }
          
         //  insert CollList;
          isGridVisible=true;                      
        
        
       }
       catch (System.DmlException e) {
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,e.getDMLMessage(0));
            ApexPages.addMessage(errorMessage);
        }
       catch (Exception e)
       {
            //ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,'Invalid file with errors.');
            ApexPages.Message errorMessage = new ApexPages.Message(ApexPages.severity.ERROR,e.getMessage());            
            ApexPages.addMessage(errorMessage);
       }          
   }
}