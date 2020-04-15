public class ReservationLocationsExportController {
    public List<Map<String,Object>> Locations {get;set;}
    
    public ReservationLocationsExportController() {
        try{
            String recordId = ApexPages.currentPage().getParameters().get('id');
            
            List<ReservationLocation__c> locations = this.getLocations(recordId);
			if(!locations.isEmpty()){ this.Locations = this.mapLocations(locations); }
            
        } catch(Exception ex){
            system.debug(ex.getStackTraceString());
        }
        
    }
    
    List<Map<String,Object>> mapLocations(List<ReservationLocation__c> locations){
        List<Map<String,Object>> results = new List<Map<String,Object>>();
        for(ReservationLocation__c res: locations) {
            
            results.add(
                new Map<String,Object> {
                    'LocationNumber' => normalizeValue(res.LocationNumber__c),
                        'Address' => normalizeValue(res.Address__c),
                        'ReservationName' => normalizeValue(res.Reservation__r.Name),
                        'NumberOfReservedLocations' => string.valueOf(normalizeValue(string.valueOf(res.Reservation__r.NumberofReservedLocations__c))),
                        'PrimaryOpportunity' => normalizeValue(res.Reservation__r.PrimaryOpportunity__r.Name),
                        'City' => normalizeValue(res.City__c),
                        'State' => normalizeValue(res.State__c),
                        'Status' => normalizeValue(res.Status__c),
                        'Id' => normalizeValue(res.Id),
                        'ReservedDate' =>  normalizeValue(res.ReservedDate__c)
                        });
        }
        
        return results;
    }
    
    Object normalizeValue(Object val){
        return val != null ? val : '';
    }
    public List<ReservationLocation__c> getLocations(string id) {
        try{
            
            String recordId = apexpages.currentpage().getparameters().get('id');
            List<ReservationLocation__c> results =[SELECT Id, Name, Reservation__c, Status__c, State__c, City__c, 
                                                   LocationNumber__c, Address__c, Reservation__r.Name, 
                                                   Reservation__r.NumberofReservedLocations__c, 
                                                   Reservation__r.PrimaryOpportunity__r.Name, ReservedDate__c
                                                   FROM ReservationLocation__c 
                                                   WHERE Reservation__c =: id
                                                   AND Status__c =: CONSTANTS.RESERVATION_STATUS_RESERVED]; 
            
            system.debug(results);
            return results;
            
        } catch(Exception ex){
            system.debug(ex.getStackTraceString());
        }
        return null;
    }
}