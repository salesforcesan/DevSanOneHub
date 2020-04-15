public class LocationAssetCapacityHelper {
    
    public static Map<ID, List<Asset>> GetLocationAsset(Date startDate,Date endDate)
    {
        Map<id,List<Asset>> locationAssetsMap = new Map<id,List<Asset>>();
        
        List<Asset> assetList = [SELECT Id, AssetType__c,InstallDate, UsageEndDate, Location__c FROM Asset
                                 WHERE InstallDate <= :endDate and UsageEndDate >= :startDate
                                 //AND Location__c='a0U21000000Lx3lEAC'
                                ]; 
        
        
        for (Asset asset : assetList)  {
            
            List<Asset> result;
            
            if( locationAssetsMap.ContainsKey(asset.Location__c) ){
                locationAssetsMap.get(asset.Location__c).add(asset);
            }
            else{
                locationAssetsMap.put(asset.Location__c,new List<Asset>{asset});
            }           
        }
        
        return locationAssetsMap;
    }
    
    
    public static Map<ID, List<LocationAssetCapacity__c>> GetLocationAssetCapacity(List<Id> locationId, Date startDate,Date endDate)
    {
        Map<id,List<LocationAssetCapacity__c>> assetCapacityMap = new Map<id,List<LocationAssetCapacity__c>>();
        
        List<LocationAssetCapacity__c> locationAssetCapacityList = [SELECT Location__c, Date__c, AssetType__c, AssetCapacity__c, AvailableCapacity__c, Id 
                                                                    FROM LocationAssetCapacity__c 
                                                                    WHERE Location__c In :locationId 
                                                                    AND Date__c >= :startDate and Date__c <= :endDate
                                                                    //AND Location__c='a0U21000000Lx3lEAC'
                                                                    ORDER BY Date__c]; 
        
        
        for (LocationAssetCapacity__c locationAssetCapacity : locationAssetCapacityList)  {
            
            if( assetCapacityMap.ContainsKey(locationAssetCapacity.Location__c) ){
                assetCapacityMap.get(locationAssetCapacity.Location__c).add(locationAssetCapacity);
            }
            else{
                assetCapacityMap.put(locationAssetCapacity.Location__c,new List<LocationAssetCapacity__c>{locationAssetCapacity});
            }
        }
        
        return assetCapacityMap;
    }
    
        public Map<ID, List<ReservationLocation__c>> GetReservationLocation(List<Id> locationId, Date startDate,Date endDate)
    {
        Map<id,List<ReservationLocation__c>> reservationLocationsMap =new Map<id,List<ReservationLocation__c>>();
        
        List<ReservationLocation__c> reservationLocationList = [SELECT  Id, ProjectLocation__c, Reservation__c, Status__c, Location__c, ErrorCode__c, ErrorMessage__c, ReservedDate__c, Location_Name__c, Address__c, City__c, State__c, LocationNumber__c 
                                                                FROM ReservationLocation__c
                                                                WHERE Location__c In :locationId
                                                                //AND Location__c='a0U21000000Lx3lEAC'
                                                                AND ReservedDate__c >= :startDate and ReservedDate__c <= :endDate];
        
        for (ReservationLocation__c reservationLocation : reservationLocationList)  {
            
            List<ReservationLocation__c> result;
            
            if( reservationLocationsMap.ContainsKey(reservationLocation.Location__c) ){
                result = reservationLocationsMap.get(reservationLocation.Location__c);
            }
            else{
                result = new List<ReservationLocation__c>();
            }           
            result.add(reservationLocation);
            reservationLocationsMap.put(reservationLocation.Location__c,result);
        }
        
        return reservationLocationsMap;
    }
    
}