public class QueryUtil {
    
    public static string FetchQuery(string ObjectName) 
    { 
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        system.debug(' ~~ObjectName~~ ' + ObjectName);
        system.debug(' ~~~~CONSTANTS.CURRENTNAMESPACEPREFIX~~~ ' + CONSTANTS.CURRENTNAMESPACEPREFIX);
        string commaStr = '';
        
        Map <String, Schema.SObjectField> fieldMap = schemaMap.get(CONSTANTS.CURRENTNAMESPACEPREFIX + ObjectName).getDescribe().fields.getMap();
        for(Schema.SObjectField sfield : fieldMap.Values())
        {
            schema.describefieldresult dfield = sfield.getDescribe();
            system.debug(CONSTANTS.CURRENTNAMESPACEPREFIX + ObjectName+'______' + dfield.getname() + '_____' + dfield.getLabel());
            commaStr+= dfield.getname()+',';
        }
        string qry = ' Select ';
        if(ObjectName=='ProjectService__c')
        {
        	qry = ' Select service__r.AllowDistribution__c,Project__r.ProjectType__r.AllowMultidays__c,service__r.IsNumberOfWorkersRequired__c, ';      
        }
        
        /*if(ObjectName=='ProjectAttribute__c')
        {
        	qry = ' Select ProjectTypeAttribute__r.IsRequired__c, ';      
        } */       
                      
        qry = qry + commaStr.removeend(',') + ' from ' + ObjectName ;      
        
        /*
        string paramVal='';
        if(params!=null){
            paramVal = ' where '
            for (String val : params.keySet()){
            	paramVal+= val+'='+params.get(val);	    
            }    
        }
        */
        system.debug(' ~~qry~~ ' + qry);
        return qry;
    }
}