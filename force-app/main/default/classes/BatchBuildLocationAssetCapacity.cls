Global class BatchBuildLocationAssetCapacity implements Database.Batchable<Object> {
    
    Map<id,List<AggregateResult>> resultsMap =new Map<id,List<AggregateResult>>();
    Map<id,List<Asset>> locationAssetsMap = new Map<id,List<Asset>>();
    
    Date startDate = date.today();    
    Date endDate = startDate.addMonths(6);
    Integer daysBetween = startDate.daysBetween(endDate); 
    
    public BatchBuildLocationAssetCapacity()
    {   
        // Get list of Asset per location
        locationAssetsMap = LocationAssetCapacityHelper.GetLocationAsset(startDate,endDate);        
    }
    
    public List<Object> start(Database.BatchableContext context) {
        List<Object> entityList = new List<Object>();
    
        for (String locationId : locationAssetsMap.keySet()){
            entityList.add(locationId);
        }
        
        return entityList;           
    }
    
    public void execute(Database.BatchableContext context, List<Object> scope) {        

        //List<Id> locationIds = new List<Id>(new Map<Id, Object>(scope).keySet());
        
        List<Id> locationIds = new List<Id>();
        
		for (Object locationId : scope){
            locationIds.add(String.valueOf(locationId));
        }
        
        Map<ID, List<LocationAssetCapacity__c>> locationAssetCapacityMap = LocationAssetCapacityHelper.GetLocationAssetCapacity(locationIds,startDate,endDate);
        //Map<ID,List<ReservationLocation__c>> reservationLocationsMap = GetReservationLocation(locationIds);
        
        List<LocationAssetCapacity__c> newLocationAssetCapacityList = new List<LocationAssetCapacity__c>();
        
        for(Id locationId : locationIds){
            
            // To process each day between dates
            for (Integer i=0; i <= daysBetween;i++) {
                
                Date processDate = startDate.addDays(i);
                
                List<LocationAssetCapacity__c> LocationAssetCapacityList = locationAssetCapacityMap.get(locationId);
                //List<ReservationLocation__c> reservationLocationList = reservationLocationsMap.get(locationId);
                
                boolean locationAssetCapacityRecordAvailable = false;
                
                if (LocationAssetCapacityList != null && LocationAssetCapacityList.size() > 0)
                {
                    for	(LocationAssetCapacity__c locationAssetCapacity:LocationAssetCapacityList){
                        
                        //If a record is already there in location asset capacity skip for loop
                        if (locationAssetCapacity.Date__c == processDate){
                            locationAssetCapacityRecordAvailable = true;   
                            break;
                        }               
                        
                        //Since LocationAssetCapacityList is ordered by Date__c once Date__c is greater then proccess date skip the for loop
                        if (locationAssetCapacity.Date__c > processDate){ break;}
                    }
                } 
                
                
                //If no record available in Location Asset Capacity make a count entry 
                if (!locationAssetCapacityRecordAvailable){
                    
                    List<Asset> locationAssetList = locationAssetsMap.get(locationId);
                    
                    Map<String,List<Asset>> countByAssetTypeMap = new Map<String,List<Asset>>();                    
                    
                    for (Asset asset:locationAssetList){
                        
                        if (asset.InstallDate <= processDate && asset.UsageEndDate >= processDate)
                        {
                            if( countByAssetTypeMap.ContainsKey(asset.AssetType__c) ){
                                countByAssetTypeMap.get(asset.AssetType__c).add(asset);
                            }
                            else{
                                countByAssetTypeMap.put(asset.AssetType__c,new List<Asset>{asset});
                            }  
                        }
                    }
                    
                    for (String assetType : countByAssetTypeMap.keySet()){
                        
                        List<Asset> assetListForCount = countByAssetTypeMap.get(assetType);
                        LocationAssetCapacity__c newLocationAssetCapacity = new LocationAssetCapacity__c();
                        newLocationAssetCapacity.Location__c = locationId;
                        newLocationAssetCapacity.Date__c = processDate;
                        newLocationAssetCapacity.AssetType__c = assetType;
                        newLocationAssetCapacity.AssetCapacity__c = assetListForCount.size();
                        newLocationAssetCapacity.AvailableCapacity__c = assetListForCount.size();
                        newLocationAssetCapacityList.add(newLocationAssetCapacity);
                    }                    
                }                
            }
        }
        
        if (newLocationAssetCapacityList.size() > 0)
        {
            insert newLocationAssetCapacityList;
        }

    }
    
    public void finish(Database.BatchableContext BC) {                    
        system.debug('Build Location Asset Capacity Batch Finished');
    }
    
    
    public void AggregateLocationAsset(){
        
        List<AggregateResult> results = [SELECT Location__c, AssetType__c,InstallDate, UsageEndDate, COUNT(Id) FROM Asset 
                                         WHERE InstallDate <= :startDate and UsageEndDate >= :endDate 
                                         GROUP BY Location__c,AssetType__c,InstallDate, UsageEndDate];
        
        for (AggregateResult ar : results)  {
            string id = String.valueOf(ar.get('Location__c'));
            List<AggregateResult> result;
            
            if( resultsMap.ContainsKey(id) ){
                result = resultsMap.get(id);
                result.add(ar);
                resultsMap.put(id,result);
            }
            else{
                result = new List<AggregateResult>();
                result.add(ar);
                resultsMap.put(id,result);
            }           
        }
    }
}