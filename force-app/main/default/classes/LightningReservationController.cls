public with sharing class LightningReservationController 
{
    
    @AuraEnabled
    public static List<ReservationRequestWrapper>  getLocationsApex(Id reservationId, Integer maxCount , string requestedDate, string advancedFilters, string reservationData) {
        try
        {
            Date reqDate = DateUtil.ToDate(requestedDate);
            if (reservationData.trim().length() > 0)
            {
                system.debug('RL: ' + reservationData);
                List<ReservationRequestWrapper> reservationLocations = (List<ReservationRequestWrapper>) JSON.deserialize(reservationData,List<ReservationRequestWrapper>.class);
                return ReservationHelper.GetAvailableLocationsByList(reservationId, reservationLocations, advancedFilters);
            }
            else
            {
	            return ReservationHelper.GetAvailableLocationsByNumber(reservationId, Integer.valueof(maxCount), reqDate, advancedFilters);
            }
                
        }
        catch(Exception ex)
        {
            throw new System.AuraHandledException(ex.getMessage());
        }
    }     
    
    @AuraEnabled
    public static Map<String, List<ReservationRequestWrapper>>  getAlternateReservationOptions(string reservationId, string locationId, string requestedDate, string advancedFilters) {
        try
        {
            Date reqDate = DateUtil.ToDate(requestedDate);
            return ReservationHelper.getAlternateReservationOptions(reservationId, locationId, reqDate, advancedFilters);
        }
        catch(Exception ex)
        {
            throw new System.AuraHandledException(ex.getMessage());
        }
    }     
    
    @AuraEnabled
    public static List<ReservationRequestWrapper>  getReservationLocations(Id reservationId) {
        
        try
        {
            return ReservationHelper.GetReservationLocations(reservationId);
        }
        catch(Exception ex)
        {
            throw new System.AuraHandledException(ex.getMessage());
        }
    }     
    
    
    @AuraEnabled
    public static Integer  getTotalLocationsApex(Id retailerAccountId) {
        
        try
        {
            Integer locationCount = [Select count() FROM Location__c WHERE RetailerAccount__c = :retailerAccountId];
            return locationCount;
        }
        catch(Exception ex)
        {
            throw new System.AuraHandledException(ex.getMessage());
        }
    }     
    
    @AuraEnabled
    public static String getNamespaceApex() {
        return CONSTANTS.CURRENTNAMESPACEPREFIX;
    }    
    
    
    @AuraEnabled
    public static void  reserveLocationsApex(Id reservationId, string reservationData) {
        
        try
        {
            system.debug('RL: ' + reservationData);
            List<ReservationRequestWrapper> reservationLocations = (List<ReservationRequestWrapper>) JSON.deserialize(reservationData,List<ReservationRequestWrapper>.class);
            ReservationHelper.ReserveLocations(reservationId, reservationLocations);
        }
        catch(Exception ex)
        {
            throw new System.AuraHandledException(ex.getMessage());
        }
    }     
    
    @AuraEnabled
    public static void  unreserveLocationsApex(Id reservationId, string reservationData) {
        
        try
        {
            
            system.debug('RL: ' + reservationData);
            List<ReservationRequestWrapper> reservationLocations = (List<ReservationRequestWrapper>) JSON.deserialize(reservationData,List<ReservationRequestWrapper>.class);
            system.debug(reservationLocations);
            ReservationHelper.UnReserveLocations(reservationId, reservationLocations);
        }
        catch(Exception ex)
        {
            throw new System.AuraHandledException(ex.getMessage());
        }
    }
    
    @AuraEnabled
    public static string getReservationReportUrl(string reservationId)
    {
        string ReservationUrl = string.valueOf(AppUtil.ExportReservationReportUrl.replace('{ReservationId}',reservationId));
        return ReservationUrl;
        
    }
    
    @AuraEnabled
    public static string GetReservation(Id reservationId) {
        
        try
        {
            string rw = ReservationHelper.GetReservationDetail(reservationId);
            return rw;
        }
        catch(Exception ex)
        {
            throw new System.AuraHandledException(ex.getMessage());
        }
    } 
    @AuraEnabled
    public static List<String> GetReservationCancelReasons()
    {        
        List<String> options = new List<String>();        
        Schema.DescribeFieldResult fieldResult = Reservation__c.CancelReason__c.getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        options.add('--SELECT--');
        for(Schema.PicklistEntry f : ple)
        {
            options.add(f.getLabel());
        }
        return options;
    }
    
    @AuraEnabled
    public static string  cancelReservationApex(Id reservationId, string cancelReason, string cancelComments) {
        ResponseWrapper rw = ResponseWrapper.getInstance(CONSTANTS.RESPONSE_STATE_SUCCESS, 'Cancel request has been successfully queued.', null);
        try
        {
            List<Reservation__c> reservations = [Select Id, Name, RequestStatus__c, RequestPending__c, DateRequestSubmitted__c FROM Reservation__c 
                                                 WHERE Id = :reservationId];
            if (!reservations.isEmpty())
            {
                ReservationHelper.CancelReservation(reservationId, cancelReason, cancelComments);               
            }
        }
        catch(Exception ex)
        {
            rw.State = CONSTANTS.RESPONSE_STATE_ERROR;
            rw.Message = 'Unable to cancel the reservation : ' + reservationId + ', ' + ex.getMessage();
        }
        return JSON.serialize(rw);  
    }     
    
    //Unused method that needs to be deprecated
    @AuraEnabled
    public static List<ReservationRequestWrapper>  getLocationsByListApex(Id reservationId, string reservationData) {
        
        try
        {
            system.debug('RL: ' + reservationData);
            List<ReservationRequestWrapper> reservationLocations = (List<ReservationRequestWrapper>) JSON.deserialize(reservationData,List<ReservationRequestWrapper>.class);
            return ReservationHelper.GetAvailableLocationsByList(reservationId, reservationLocations);
            
        }
        catch(Exception ex)
        {
            throw new System.AuraHandledException(ex.getMessage());
        }
    }     
    
    
    
}