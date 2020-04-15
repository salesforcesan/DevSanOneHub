global without sharing class ReservationHelper {
    
	global static List<ReservationRequestWrapper> GetAvailableLocationsByList(string reservationId, List<ReservationRequestWrapper> rwlist, string advancedFilters)
    {

        List<String> assetsRequiredList = new List<String>();
        Set<String> locationdates = new Set<String>();
        Map<String, Date> locationdateMap = new Map<String, Date>();
        Set<String> locationnumbers = new Set<String>();
        Set<String> locationnumbersfromlocation = new Set<String>();
        Map<String,Location__c> locationMap = new Map<String,Location__c>();
        Map<String,Date> locationnumberDateMap = new Map<String,Date>();
        
        
        List<ReservationRequestWrapper> ret = new List<ReservationRequestWrapper>();
        
		string accountId = '';        
        
        List<Reservation__c> reservations = [Select Id, Name, Status__c, Service__c, Service__r.AssetsRequired__c, RetailerAccount__c FROM Reservation__c 
                                           		WHERE Id = :reservationId LIMIT 1];
        if (!reservations.isEmpty())
        {

            if (reservations[0].Service__c == null)
            {
                throw new CustomException('Please select a valid service.');
            }
            
            if (reservations[0].Service__r.AssetsRequired__c != null && !String.isEmpty(reservations[0].Service__r.AssetsRequired__c))
            {
            	assetsRequiredList = reservations[0].Service__r.AssetsRequired__c.Split(';');    
            }
            accountId = reservations[0].RetailerAccount__c;
        }
        
        for (ReservationRequestWrapper rw : rwlist)
        {
            locationnumbers.add(rw.LocationNumber);
            locationnumberDateMap.put(rw.LocationNumber, DateUtil.ToDate(rw.ReservationDate));
            
        }
        
		List<String> topics = new List<String>();
        Map<String, List<String>> taMap = new Map<String, List<String>>();        
        Map<String,String> tmap = new Map<String,String>();        
        if (!String.isEmpty(advancedFilters))
        {
            topics = advancedFilters.split(';');
            tmap = getTopics(topics);
            taMap = getLocationTopicAssignments(topics);
            
        }
			
        
        
        
        
        List<ReservationLocation__c> reservationLocations = [Select Id, Name, Status__c, Location__c from ReservationLocation__c WHERE Reservation__c = :reservationId  AND Status__c = :CONSTANTS.RESERVATIONLOCATION_STATUS_RESERVED];
        Map<String, ReservationLocation__c> rlMap = new Map<String, ReservationLocation__c>();
        
        for (ReservationLocation__c rl: reservationLocations)
        {
            rlMap.put(rl.Location__c, rl);
            
        }
        
        List<Location__c> locations = [SELECT Id, Name, LocationNumber__c, City__c,
                                       Address__c, State__c, GeoLocation__Latitude__s, GeoLocation__Longitude__s
                                       FROM Location__c WHERE IsActive__c = true AND RetailerAccount__c = :accountId 
                                       AND LocationNumber__c IN :locationnumbers];
        for (Location__c location : locations)
        {
        	locationdates.add(location.Id + String.valueof(locationnumberDateMap.get(location.LocationNumber__c)));
            locationdateMap.put(location.Id, locationnumberDateMap.get(location.LocationNumber__c));
            locationnumbersfromlocation.add(location.LocationNumber__c);
            locationMap.put(location.Id, location);
        }
        
        //Check if locations exist. if not throw an error about missing location.
        for (string locationnumber: locationnumbers)
        {
            if (!locationnumbersfromlocation.contains(locationnumber))
            {
                ReservationRequestWrapper rw = new ReservationRequestWrapper();
                rw.LocationId = locationnumber;
                rw.LocationNumber = locationnumber;
                rw.ReservationErrorCode = 'LOCATION_NOT_FOUND';
                rw.ReservationErrorMessage = 'Location is either not active or not found. Please verify.';
                rw.IsOverridable = false;
                rw.IsResolvable = false;
                ret.add(rw);
            }
            
        }
        
		//Get all the asset capacities for locations that have been requested to be reserved        
        Map<String, Integer> ladCapacityMap = new Map<String, Integer>();
        List<LocationAssetCapacity__c> lacs = [Select Id, Name, AssetType__c, Location__c, Date__c, AvailableCapacity__c 
                                              FROM LocationAssetCapacity__c WHERE LocationDate__c in :locationdates
                                              AND AssetType__c IN :assetsRequiredList];
        for (LocationAssetCapacity__c lac : lacs)
        {
            ladCapacityMap.put(lac.Location__c + lac.AssetType__c + string.valueOf(lac.Date__c), Integer.valueof(lac.AvailableCapacity__c));
            
        }
        
        //Check the availability of assets and 
        Set<String> rldSuccess = new Set<String>();
        Set<String> rldFailure = new Set<String>();
        Integer successCount = 0;
        for (Location__c location : locations)
        {
            Boolean success = true;
            String failedassets = '';
            String availableCapacity = '';
            string missingtopics = '';
            
		    if ( rlMap.get(location.Id) != null && 
                rlMap.get(location.Id).Status__c == CONSTANTS.RESERVATIONLOCATION_STATUS_RESERVED)        
            {
                ReservationRequestWrapper rw = new ReservationRequestWrapper();
                rw.LocationId = location.Id;
                rw.LocationNumber = location.LocationNumber__c;
                rw.LocationAddress = location.Address__c;
                rw.ReservationDate = string.valueof(locationdateMap.get(location.Id));
                rw.ReservationErrorCode = 'LOCATION_ALREADY_RESERVED';
                rw.ReservationErrorMessage = 'Location has already been reserved.';
                rw.LocationLatitude = location.GeoLocation__Latitude__s;
                rw.LocationLongitude = location.GeoLocation__Longitude__s;
                rw.IsOverridable = false;
                rw.IsResolvable = false;
                ret.add(rw);
                continue;
                
            }
            //Check for topics
            if (!topics.isEmpty())
            {
                missingtopics = doesLocationSupportGivenTopics (location.Id, topics, taMap, tmap) ;
                if (!String.isEmpty(missingtopics))
                {
                    success = false;
                }

            }
            
            if (!success)
            {
                ReservationRequestWrapper rw = new ReservationRequestWrapper();
                rw.LocationId = location.Id;
                rw.LocationNumber = location.LocationNumber__c;
                rw.LocationAddress = location.Address__c;
                rw.ReservationDate = string.valueof(locationdateMap.get(location.Id));
                rw.ReservationErrorCode = 'MISSING_TOPICS';
                rw.ReservationErrorMessage = 'Following topics are missing - ' + missingtopics;
                rw.LocationLatitude = location.GeoLocation__Latitude__s;
                rw.LocationLongitude = location.GeoLocation__Longitude__s;
                rw.IsOverridable = true;
                rw.IsResolvable = true;
                ret.add(rw);
                continue;
            }
                
            
            for (String asset: assetsRequiredList)
            {
                string key = location.Id + asset + string.valueOf(locationdateMap.get(location.Id));

                string capacity = ladCapacityMap.get(key) == null ? '0' : string.valueof(ladCapacityMap.get(key));
                availableCapacity = availableCapacity + asset + ':' + capacity + '; ';
                
                if (ladCapacityMap.get(key) <= 0 || ladCapacityMap.get(key) == null)
                {
                    success = false;
                    failedassets = failedassets + asset + ':';
                }
            }

            ReservationRequestWrapper rw = new ReservationRequestWrapper();
            rw.LocationId = location.Id;
            rw.ReservationDate = string.valueof(locationdateMap.get(location.Id));
            rw.LocationNumber = location.LocationNumber__c;
            rw.LocationName = location.Name;
            rw.LocationLatitude = location.GeoLocation__Latitude__s;
            rw.LocationLongitude = location.GeoLocation__Longitude__s;
            rw.LocationCity = location.City__c;
            rw.LocationState = location.State__c;
            rw.LocationAddress = location.Address__c;
            rw.AvailableCapacity = availableCapacity;
            
            if (success)
            {
                rw.ReservationErrorCode = '';
                rw.ReservationErrorMessage = '';
            }
            else
            {
                rw.ReservationErrorCode = 'ASSET_INSUFF_CAPACITY';
                rw.ReservationErrorMessage = 'These assets are not available - ' + failedassets;
                rw.IsOverridable = true;
                rw.IsResolvable = true;
            }
            ret.add(rw);
        }

		List<ReservationRequestWrapper> srws = new List<ReservationRequestWrapper>();
        for (ReservationRequestWrapper srw : srws)
        {
            if (srw.ReservationErrorCode.Trim().length() == 0)
            {
                srws.add(srw);
            }
            
        }
        
        List<object> parameters = new List<Object>();
        parameters.addAll(srws);
        
        
        //Check if there are any Apex rules that need to be vaidated
        //
        if (!ret.isEmpty())
        	checkApexRules(ret, reservationId);
        
        return ret;


        
    }
    

	global static List<ReservationRequestWrapper> GetAvailableLocationsByNumber(string reservationId, Integer maxcount, Date requestedDate, string advancedFilters)
    {
        List<String> assetsRequiredList = new List<String>();
        Set<String> locationdates = new Set<String>();
        Set<String> locationids = new Set<String>();
        Map<String,Location__c> locationMap = new Map<String,Location__c>();
        system.debug('Ad Filters: ' + advancedFilters);
        Boolean IslimitLocations = maxcount > 0? true:false;
        
		List<String> topics = new List<String>();
        Map<String, List<String>> taMap = new Map<String, List<String>>();        
        Map<String,String> tmap = new Map<String,String>();
        if (!String.isEmpty(advancedFilters))
        {
	        topics = advancedFilters.split(';');
            tmap = getTopics(topics);
        	taMap = getLocationTopicAssignments(topics);    
        }
			
        
        
        
        List<ReservationRequestWrapper> ret = new List<ReservationRequestWrapper>();
		string accountId = '';        
        
        List<Reservation__c> reservations = [Select Id, Name, Status__c, Service__c, Service__r.AssetsRequired__c, RetailerAccount__c 
                                             FROM Reservation__c 
                                           	 WHERE Id = :reservationId LIMIT 1];
        
        if (!reservations.isEmpty())
        {
            if (reservations[0].Service__c == null)
            {
                throw new CustomException('Please select a valid service.');
            }
            
            if (reservations[0].Service__r.AssetsRequired__c != null && !String.isEmpty(reservations[0].Service__r.AssetsRequired__c))
            {
            	assetsRequiredList = reservations[0].Service__r.AssetsRequired__c.Split(';');    
            }
            
            accountId = reservations[0].RetailerAccount__c;
        }
        List<Location__c> locations = [SELECT Id, Name, LocationNumber__c, City__c,
                                       Address__c, State__c, GeoLocation__Latitude__s, GeoLocation__Longitude__s 
                                       FROM Location__c WHERE IsActive__c = true AND RetailerAccount__c = :accountId  AND Id NOT IN 
                                      (Select Location__c from ReservationLocation__c WHERE Reservation__c = :reservationId  AND Status__c = :CONSTANTS.RESERVATIONLOCATION_STATUS_RESERVED)];
        for (Location__c location : locations)
        {
         	locationdates.add(location.Id + string.valueOf(requestedDate));    
            locationids.add(location.Id);
            locationMap.put(location.Id, location);
        }
        
		//Get all the asset capacities for locations that have been requested to be reserved        
        Map<String, Integer> ladCapacityMap = new Map<String, Integer>();
        List<LocationAssetCapacity__c> lacs = [Select Id, Name, AssetType__c, Location__c, Date__c, AvailableCapacity__c 
                                              FROM LocationAssetCapacity__c WHERE LocationDate__c in :locationdates
                                              AND AssetType__c IN :assetsRequiredList];
        for (LocationAssetCapacity__c lac : lacs)
        {
            ladCapacityMap.put(lac.Location__c + lac.AssetType__c + string.valueOf(lac.Date__c), Integer.valueof(lac.AvailableCapacity__c));
            
        }
        
        //Check the availability of assets and 
        Set<String> rldSuccess = new Set<String>();
        Set<String> rldFailure = new Set<String>();
        Integer successCount = 0;
        for (Location__c location : locations)
        {
            Boolean success = true;
            String failedassets = '';
            String availableCapacity = '';
            String missingtopics = '';
            
            //Check for topics
            if (!topics.isEmpty())
            {
                missingtopics = doesLocationSupportGivenTopics (location.Id, topics, taMap, tmap) ;
                if (!String.isEmpty(missingtopics))
                {
                    success = false;
                }

            }
            
            if (!success)
            {
                ReservationRequestWrapper rw = new ReservationRequestWrapper();
                rw.LocationId = location.Id;
                rw.LocationNumber = location.LocationNumber__c;
                rw.LocationAddress = location.Address__c;
                rw.ReservationDate = string.valueof(requestedDate);
                rw.ReservationErrorCode = 'MISSING_TOPICS';
                rw.ReservationErrorMessage = 'Following topics are missing - ' + missingtopics;
                rw.LocationLatitude = location.GeoLocation__Latitude__s;
                rw.LocationLongitude = location.GeoLocation__Longitude__s;
                rw.IsOverridable = true;
                rw.IsResolvable = true;
                ret.add(rw);
                continue;
            }            
                
            for (String asset: assetsRequiredList)
            {
                string key = location.Id + asset + string.valueOf(requestedDate);
                string capacity = ladCapacityMap.get(key) == null ? '0' : string.valueof(ladCapacityMap.get(key));
                availableCapacity = availableCapacity + asset + ':' + capacity + '; ';
                
                if (ladCapacityMap.get(key) <= 0 || ladCapacityMap.get(key) == null)
                {
                    success = false;
                    failedassets = failedassets + asset + ':';
                }
            }

            ReservationRequestWrapper rw = new ReservationRequestWrapper();
            rw.LocationId = location.Id;
            rw.ReservationDate = string.valueof(requestedDate);
            rw.LocationNumber = location.LocationNumber__c;
            rw.LocationName = location.Name;
            rw.LocationCity = location.City__c;
            rw.LocationState = location.State__c;
            rw.LocationAddress = location.Address__c;
            rw.ReservationErrorCode = '';
            rw.ReservationErrorMessage = '';
            rw.LocationLatitude = location.GeoLocation__Latitude__s;
            rw.LocationLongitude = location.GeoLocation__Longitude__s;
            rw.AvailableCapacity = availableCapacity;
            
            if (success)
            {
                rw.ReservationErrorCode = '';
                rw.ReservationErrorMessage = '';
                successCount += 1;
            }
            else
            {
                rw.ReservationErrorCode = 'ASSET_INSUFF_CAPACITY';
                rw.ReservationErrorMessage = 'These assets are not available - ' + failedassets;
                rw.IsOverridable = true;
                rw.IsResolvable = true;
                    
            }
            ret.add(rw);

            
            if (IslimitLocations && successCount >= maxcount)
            {
                //return only the successful list
                
                List<ReservationRequestWrapper> filteredlist = new List<ReservationRequestWrapper>();
                
                for (ReservationRequestWrapper fw : ret)
                {
                    if (fw.ReservationErrorCode.Trim().Length() == 0)
                    {
                        filteredlist.add(fw);
                    }
                    
                }
                if (!filteredlist.isEmpty())
                    checkApexRules(filteredlist, reservationId);
                
                return filteredlist;
            }
        }
        
        //Check if there are any Apex rules that need to be vaidated
        checkApexRules(ret, reservationId);
        
      	return ret;
    }
    
    global static Map<String, List<ReservationRequestWrapper>> GetAlternateReservationOptions(string reservationId, string locationId, Date requestedDate, string advancedFilters)
    {
        List<ReservationRequestWrapper> lrw; 
        List<ReservationRequestWrapper> allrrws = new List<ReservationRequestWrapper>(); 
        
        Map<String, List<ReservationRequestWrapper>> ret = new Map<String, List<ReservationRequestWrapper>>();
        Set<Date> alternatedates = new Set<Date>();
        List<String> assetsRequiredList = new List<String>();
		List<String> topics = new List<String>();
        Map<String, List<String>> taMap = new Map<String, List<String>>();        
        Location__c altLocation;
		string accountId = ''; 
        Integer pastOptionDays = -3;
        Integer futureOptionDays = 3;
        
		Map<String,String> tmap = new Map<String,String>();    
        
        // Get reservation settings from custom setting		
        ReservationSettings__c reservationSetting = ReservationSettings__c.getInstance();       
        
        pastOptionDays = reservationSetting.PastOptionDays__c == null?-3:-(Integer.valueof(reservationSetting.PastOptionDays__c));
        futureOptionDays = reservationSetting.futureOptionDays__c == null?3:Integer.valueof(reservationSetting.FutureOptionDays__c);
        
        
        if (!String.isEmpty(advancedFilters))
        {
            topics = advancedFilters.split(';');         
            tmap = getTopics(topics);
            taMap = getLocationTopicAssignments(topics);
        }
        system.debug('tamap: ' + taMap);
        
        List<Location__c> locs = [Select Id, GeoLocation__Latitude__s, GeoLocation__Longitude__s FROM Location__c WHERE Id = :locationId LIMIT 1];
        if (!locs.isEmpty())
        {
            altLocation = locs[0];
            
        }
        

        List<Reservation__c> reservations = [Select Id, Name, Status__c, Service__r.AssetsRequired__c, RetailerAccount__c FROM Reservation__c 
                                           		WHERE Id = :reservationId LIMIT 1];
        if (!reservations.isEmpty())
        {
            if (reservations[0].Service__r.AssetsRequired__c != null && !String.isEmpty(reservations[0].Service__r.AssetsRequired__c))
            {
            	assetsRequiredList = reservations[0].Service__r.AssetsRequired__c.Split(';');    
            }
            accountId = reservations[0].RetailerAccount__c;
        }

        
        
        for (Integer i=pastOptionDays; i<=futureOptionDays; i++)
        {
            //Make sure no past days are included
            if (requestedDate.addDays(i) > Date.today())
            	alternatedates.add(requestedDate.addDays(i));
        }
        
        Map<String, Integer> alternateladCapacityMap = new Map<String, Integer>();
        List<LocationAssetCapacity__c> alternatelacs = [Select Id, Name, AssetType__c, Location__c, Date__c, AvailableCapacity__c 
                                                        FROM LocationAssetCapacity__c WHERE Date__c in :alternatedates
                                                        AND AssetType__c IN :assetsRequiredList];
        for (LocationAssetCapacity__c alternatelac : alternatelacs)
        {
            alternateladCapacityMap.put(alternatelac.Location__c + alternatelac.AssetType__c + string.valueOf(alternatelac.Date__c), Integer.valueof(alternatelac.AvailableCapacity__c));
            
        }
        
        
        List<Location__c> locations = [SELECT Id, Name, LocationNumber__c, City__c,
                                       Address__c, State__c, GeoLocation__Latitude__s, GeoLocation__Longitude__s,
                                       DISTANCE(GeoLocation__c, GEOLOCATION(:altLocation.GeoLocation__Latitude__s,:altLocation.GeoLocation__Longitude__s), 'mi') dist
                                       FROM Location__c WHERE RetailerAccount__c = :accountId AND IsActive__c = true 
                                       AND Id NOT IN 
                                      (Select Location__c from ReservationLocation__c WHERE Reservation__c = :reservationId AND Status__c = :CONSTANTS.RESERVATIONLOCATION_STATUS_RESERVED)
                                      ORDER BY DISTANCE(GeoLocation__c, GEOLOCATION(:altLocation.GeoLocation__Latitude__s,:altLocation.GeoLocation__Longitude__s), 'mi')];
        for (Date alternatedate : alternatedates)
        {
            Integer successCount = 0;
            string strdate = string.valueOf(alternatedate);
            
            ret.put(strdate, new List<ReservationRequestWrapper>());
            
            lrw = new List<ReservationRequestWrapper>();
            
            for (Location__c location : locations)
            {
                
                Boolean success = true;
                String failedassets = '';
                String availableCapacity = '';
                String missingtopics = '';
                
                //Exclude the alternate location / date from the returned set.
                if (alternatedate == requestedDate && location.Id == altLocation.Id)
                    continue;
                
                //Check for topics
                missingtopics = doesLocationSupportGivenTopics (location.Id, topics, taMap, tmap) ;
                if (!String.isEmpty(missingtopics))
                {
                    success = false;
                }
                
                if (!success)
                {
                    continue;
                }
                    
                
                    
                for (String asset: assetsRequiredList)
                {
                    string key = location.Id + asset + string.valueof(alternatedate);
                    system.debug('key: ' + key);
                    string capacity = alternateladCapacityMap.get(key) == null ? '0' : string.valueof(alternateladCapacityMap.get(key));
                    availableCapacity = availableCapacity + asset + ':' + capacity + '; ';
                    
                    if (alternateladCapacityMap.get(key) <= 0 || alternateladCapacityMap.get(key) == null)
                    {
                        success = false;
                        failedassets = failedassets + asset + ':';
                    }
                }
    
                if (success)
                {
                    system.debug('sucess');
                    ReservationRequestWrapper rw = new ReservationRequestWrapper();
                    rw.LocationId = location.Id;
                    rw.ReservationDate = string.valueof(requestedDate);
                    rw.LocationNumber = location.LocationNumber__c;
                    rw.LocationName = location.Name;
                    rw.LocationLatitude = location.GeoLocation__Latitude__s;
                    rw.LocationLongitude = location.GeoLocation__Longitude__s;
                    rw.LocationCity = location.City__c;
                    rw.LocationState = location.State__c;
                    rw.LocationAddress = location.Address__c;
                    rw.ReservationErrorCode = '';
                    rw.ReservationErrorMessage = '';
                    rw.AvailableCapacity = availableCapacity;
                    rw.ReservationErrorCode = '';
                    rw.ReservationErrorMessage = '';
                    rw.Proximity = location.get('dist') == null? '':string.valueOf(location.get('dist'));
                    
                    List<ReservationRequestWrapper> trw;
                    if (ret.get(strdate) != null)
                    {
                        trw = ret.get(strdate);
                    }
                    else
                    {
                        trw = new List<ReservationRequestWrapper>();
                    }
                    trw.add(rw);
                    ret.put(strdate, trw);
                    successCount += 1;
                    
                    if (successCount >= 10)
                    {
                        break;
                    }
                    
                }
                else
                {
                    system.debug('not success');
                }
            }
            
            allrrws.addAll(lrw);
        }
        system.debug('alllist'+allrrws);
        
        //Check if there are any Apex rules that need to be vaidated
        checkApexRules(allrrws, reservationId);

        return ret;
        
    }    
    
    global static void ReserveLocations(string reservationId, List<ReservationRequestWrapper> rrws)    	
    {
        
        system.debug('rrws::' + rrws);
            
        Set<String> locationDates = new Set<String>();
		List<String> assetsRequiredList = new List<String>();
        List<ReservationLocation__c> rls = new List<ReservationLocation__c>();
        
        for (ReservationRequestWrapper rrw: rrws)
        {
            locationdates.add(rrw.LocationId + rrw.ReservationDate);
        }
        
      	List<Reservation__c> reservations = [Select Id, Name, Status__c, Service__r.AssetsRequired__c, Owner.Email 
                                             FROM Reservation__c WHERE Id = :reservationId LIMIT 1 FOR UPDATE]; 

        if (!reservations.isEmpty() && !String.isEmpty(reservations[0].Service__r.AssetsRequired__c))
        {
            assetsRequiredList = reservations[0].Service__r.AssetsRequired__c.Split(';');
        }
        
		//Get all the asset capacities for locations that have been requested to be reserved        
        Map<String, Integer> ladCapacityMap = new Map<String, Integer>();
        List<LocationAssetCapacity__c> lacs = [Select Id, Name, AssetType__c, Location__c, Date__c, AvailableCapacity__c 
                                              FROM LocationAssetCapacity__c WHERE LocationDate__c in :locationdates
                                              AND AssetType__c IN :assetsRequiredList FOR UPDATE];
        for (LocationAssetCapacity__c lac : lacs)
        {
            ladCapacityMap.put(lac.Location__c + lac.AssetType__c + string.valueOf(lac.Date__c), Integer.valueof(lac.AvailableCapacity__c));
            
        }
        
        
        //Check the availability of assets and 
        Set<String> rldSuccess = new Set<String>();
        Set<String> rldFailure = new Set<String>();
        String failureMessage = '';

        for (ReservationRequestWrapper rrw: rrws)
        {
            Boolean success = true;
            String failedasset = '';
            ReservationLocation__c rl = new ReservationLocation__c();
            rl.Reservation__c = reservationId;
            rl.Location__c = rrw.LocationId;
            rl.ReservedDate__c = DateUtil.ToDate(rrw.ReservationDate);
            
            for (String asset: assetsRequiredList)
            {
                if (ladCapacityMap.get(rrw.LocationId + asset + string.valueOf(rrw.ReservationDate)) <= 0)
                {
                    if (rrw.CapacityOverride)
                    {
                        rl.CapacityOverride__c = true;
                        
                    }
                    else
                    {
                        success = false;
                        failedasset = asset;
                        
                    }
                }
            }

            if (success)
            {
                rldSuccess.add(rrw.LocationId + String.valueOf(rrw.ReservationDate));
                rl.Status__c = CONSTANTS.RESERVATIONLOCATION_STATUS_RESERVED;
            }
            else
            {
                rldFailure.add(rrw.LocationId + String.valueOf(rrw.ReservationDate));
                rl.Status__c = CONSTANTS.RESERVATIONLOCATION_STATUS_FAILED;
                rl.ErrorCode__c = 'INSUFF_ASSET';
                rl.ErrorMessage__c = failedasset + ': No capacity available. ';
                failureMessage = failureMessage + ' ' + rrw.LocationNumber + ':' + rrw.ReservationDate + ':' + rl.ErrorMessage__c + '<br>';
            }
            rls.add(rl);
            
        }
        
        //Decrement the number of assets for successful reservations
        for (LocationAssetCapacity__c lac : lacs)
        {
            if (rldSuccess.contains(lac.Location__c + string.valueOf(lac.Date__c)))
            {
                lac.AvailableCapacity__c = lac.AvailableCapacity__c - 1;
            }
        }
        
        insert rls;
        update lacs;
        
        if (!rldSuccess.isEmpty())
        	AddProjectLocations(rls);
        
    }
    
	global static void UnReserveLocations(string reservationId, List<ReservationRequestWrapper> rrws)    	
    {
        
        List<String> reservationlocationids = new List<String>();

        if (rrws.isEmpty())
        {
            return;
        }

        
        List<Reservation__c> reservations = [Select Id, Name, Status__c, Service__r.AssetsRequired__c FROM Reservation__c 
                                           		WHERE Id = :reservationId LIMIT 1];

        for (ReservationRequestWrapper rrw : rrws)
        {
            reservationlocationids.add(rrw.LocationId);
            
        }
        
		List<String> assetsRequiredList = new List<String>();

        if (!reservations.isEmpty() && !String.isEmpty(reservations[0].Service__r.AssetsRequired__c))
        {
            assetsRequiredList = reservations[0].Service__r.AssetsRequired__c.Split(';');
        }
        
        AdjustLocationAssetCapacityForCanceledLocations(reservationlocationids, assetsRequiredList);
        UpdateReservationLocationsStatus(reservationlocationids, CONSTANTS.RESERVATION_STATUS_CANCELED);
        
        if (!reservationlocationids.isEmpty())
        	CancelProjectLocations(reservationlocationids,'','');

    }
    
    public static void AdjustLocationAssetCapacityForCanceledLocations(List<String> reservationlocationids, List<String> assetsRequiredList)
    {
        Set<String> locationdates = new Set<String>();
        
        //Get all the reservation locations that have been requested to be cancelled
        List<ReservationLocation__c> rls =  [Select Id, Location__c, Status__c, ReservedDate__c FROM ReservationLocation__c 
                                                     WHERE Id IN :reservationlocationids];
        
        for (ReservationLocation__c rl : rls)
        {
            locationdates.add(rl.Location__c + String.valueof(rl.ReservedDate__c));
        }
        
		//Get all the asset capacities for locations that have been requested to be reserved        
        Map<String, Integer> ladCapacityMap = new Map<String, Integer>();
        List<LocationAssetCapacity__c> lacs = [Select Id, Name, AssetType__c, Location__c, Date__c, AvailableCapacity__c 
                                              FROM LocationAssetCapacity__c WHERE LocationDate__c in :locationdates
                                              AND AssetType__c IN :assetsRequiredList FOR UPDATE];
        for (LocationAssetCapacity__c lac : lacs)
        {
            lac.AvailableCapacity__c = lac.AvailableCapacity__c + 1;
        }
        
        update lacs;
        
    }

	global static void CancelReservation(string reservationId, string cancelReason, string cancelReasonComments)    	
    {
        
		List<String> assetsRequiredList = new List<String>();
        List<String> rlids = new List<String>();
                        
        List<Reservation__c> reservations = [Select Id, Name, Status__c, CancelReason__c, CancelReasonComment__c,
                                             Service__r.AssetsRequired__c 
                                             FROM Reservation__c 
                                             WHERE Id = :reservationId FOR UPDATE];

        if (!reservations.isEmpty() && !String.isEmpty(reservations[0].Service__r.AssetsRequired__c))
        {
            assetsRequiredList = reservations[0].Service__r.AssetsRequired__c.Split(';');
        }
        
        
        List<ReservationLocation__c> reservationlocations = [Select Id  
                                             FROM ReservationLocation__c 
                                             WHERE Reservation__c = :reservationId FOR UPDATE];
        for (ReservationLocation__c rl : reservationlocations )
        {
            rlids.add(rl.Id);
        }
        
        
        if (!reservations.isEmpty())
        {
            reservations[0].Status__c = CONSTANTS.RESERVATION_STATUS_CANCELED;
            reservations[0].CancelReason__c = cancelReason;
            reservations[0].CancelReasonComment__c = cancelReasonComments;
        }
        
        
        UpdateReservationLocationsStatus(reservationId, CONSTANTS.RESERVATIONLOCATION_STATUS_CANCELED);        
        AdjustLocationAssetCapacityForCanceledLocations(rlids, assetsRequiredList);
        
		//OH2-1141: Wes stated when canceling a reservation, canceling the project is one step to far. Commenting out cancel project code, and changing to delete project location.
        //CancelProject(reservationId, cancelReason, cancelReasonComments);
        List<ReservationRequestWrapper> rrws = new List<ReservationRequestWrapper>();
            
        if (!rlids.isEmpty())
            CancelProjectLocations(rlids,'','');
        
       update reservations;
        
    }
    
	global static void ExpireReservation(string reservationId)    	
    {
        
		List<String> assetsRequiredList = new List<String>();
        List<String> rlids = new List<String>();
        
        List<Reservation__c> reservations = [Select Id, Name, Status__c, Service__r.AssetsRequired__c 
                                             FROM Reservation__c 
                                             WHERE Id = :reservationId FOR UPDATE];

        if (!reservations.isEmpty() && !String.isEmpty(reservations[0].Service__r.AssetsRequired__c))
        {
            assetsRequiredList = reservations[0].Service__r.AssetsRequired__c.Split(';');
        }
        
        
        List<ReservationLocation__c> reservationlocations = [Select Id  
                                             FROM ReservationLocation__c 
                                             WHERE Reservation__c = :reservationId FOR UPDATE];
        for (ReservationLocation__c rl : reservationlocations )
        {
            rlids.add(rl.Id);
        }
        
        
        if (!reservations.isEmpty())
        {
            reservations[0].Status__c = CONSTANTS.RESERVATION_STATUS_EXPIRED;
        }
        
        
        AdjustLocationAssetCapacityForCanceledLocations(rlids, assetsRequiredList);
        UpdateReservationLocationsStatus(reservationId, CONSTANTS.RESERVATIONLOCATION_STATUS_EXPIRED);        
		update reservations;
        
    }

    
	global static List<ReservationRequestWrapper> GetReservationLocations(string reservationId)
    {
        
        List<ReservationRequestWrapper> ret = new List<ReservationRequestWrapper>();
        
		string accountId = '';        
        
        List<ReservationLocation__c> reservationLocations = [Select Id, Name, Status__c, Address__c, City__c, State__c,
                                                             ErrorCode__c, ErrorMessage__c, LocationNumber__c,
                                                             Location__r.Name, ReservedDate__c
                                                             FROM ReservationLocation__c 
                                                             WHERE Reservation__c = :reservationId AND 
                                                             Status__c = :CONSTANTS.RESERVATIONLOCATION_STATUS_RESERVED];
        if (reservationLocations.isEmpty())
			return null;

		for (ReservationLocation__c rl: reservationLocations)
        {
            ReservationRequestWrapper rw = new ReservationRequestWrapper();
            rw.LocationId = rl.Id;
            rw.ReservationDate = string.valueof(rl.ReservedDate__c);
            rw.LocationNumber = rl.LocationNumber__c;
            rw.LocationName = rl.location__r.Name;
            rw.LocationCity = rl.City__c;
            rw.LocationState = rl.State__c;
            rw.LocationAddress = rl.Address__c;
            rw.Status = rl.Status__c;
            rw.ReservationErrorMessage = rl.ErrorMessage__c;
            rw.ReservationErrorCode = rl.ErrorCode__c;
            ret.add(rw);
        }
        
        return ret;
        
    }
    
    global static String GetReservationDetail(string reservationId)
    {
        
        String returnString= '';
        
        List<Reservation__c> reservations = [Select Id, Name, Status__c, CancelReason__c, CancelReasonComment__c, ExpirationDate__c,
                                             RequestedDate__c, RequestedLocations__c, Service__c
                                             FROM Reservation__c
                                             WHERE Id = :reservationId AND Status__c NOT IN 
                                             (:CONSTANTS.RESERVATIONLOCATION_STATUS_CANCELED)  Limit 1];
        if (reservations.isEmpty())
        {
            returnString = null;
			
        }
           
        if(reservations.size()>0)
        {
        	Reservation__c reservation = reservations[0];
           	ReservationWrapper rwr = new ReservationWrapper();
          	rwr.Id = reservation.Id;
           	rwr.Name = reservation.Name;
           	rwr.CancelReason = string.valueOf(reservation.CancelReason__c);
           	rwr.CancelReasonComment = string.valueOf(reservation.CancelReasonComment__c);
           	rwr.Status = reservation.Status__c;
            rwr.RequestedDate = string.valueof(reservation.RequestedDate__c);
            rwr.RequestedLocationCount = reservation.RequestedLocations__c == null ? 0 : integer.valueof(reservation.RequestedLocations__c);
            rwr.RequestedService = reservation.Service__c;
            
            returnString = JSON.serialize(rwr);
           
        }
        return  returnString;
        
    }
    
    private static void GetReservation(string reservationId, List<String> accounts, List<String> assetsRequiredList)
    {
        
        List<Reservation__c> reservations = [Select Id, Name, Status__c, Service__r.AssetsRequired__c, RetailerAccount__c FROM Reservation__c 
                                           		WHERE Id = :reservationId LIMIT 1];
        if (!reservations.isEmpty())
        {
            assetsRequiredList = reservations[0].Service__r.AssetsRequired__c.Split(';');
            accounts = new List<String>{reservations[0].RetailerAccount__c};
        }
    }    
    
    private static void UpdateReservationLocationsStatus(string reservationId, string status)
    {
        
        List<ReservationLocation__c> rls =  [Select Id, Location__c, Status__c FROM ReservationLocation__c 
                                                     WHERE Reservation__c = :reservationId FOR UPDATE];
        for (ReservationLocation__c rl: rls)
        {
            rl.Status__c = status;
        }

        update rls;        
        
    }
    
    private static void UpdateReservationLocationsStatus(List<String> reservationlocationids, string status )
    {
        
        List<ReservationLocation__c> rls =  [Select Id, Location__c, Status__c FROM ReservationLocation__c 
                                                     WHERE Id IN :reservationlocationids FOR UPDATE];
        for (ReservationLocation__c rl: rls)
        {
            rl.Status__c = status;
        }

        update rls;        
        
    }
    
    private static void CancelProjectLocations(List<String> reservationlocationids, string cancelreason, string cancelcomments)
    {
        cancelreason = string.isEmpty(cancelreason)?'Other':cancelreason;
        cancelcomments = string.isEmpty(cancelcomments)?'Canceled from Reservation':cancelcomments;
        string reslocnumbers = '';
        
		Set<String> locids = new Set<String>();
        List<ReservationLocation__c> rls = [SELECT Id, Name, Reservation__c, Reservation__r.Name, Location__c, Location__r.LocationNumber__c from ReservationLocation__c WHERE Id IN :reservationlocationids];
        for (ReservationLocation__c rl : rls)
        {
            locids.add(rl.Location__c);
            reslocnumbers = reslocnumbers + rl.Location__r.LocationNumber__c + ';';
            
        }
        
        List<ProjectLocation__c> pls = new List<ProjectLocation__c>();
        List<Project__c> projects = [Select Id, ProjectType__c, ProjectType__r.Name, OwnerId, Status__c from Project__c WHERE Reservation__c =: rls[0].Reservation__c LIMIT 1];
        if (projects.isEmpty())
            return;
        Project__c project = projects[0];
        
        Id[] plids = new Id[]{};
        List<ProjectLocation__c> plocs = [SELECT Id, name from ProjectLocation__c where Project__c = :project.Id AND Location__c IN :locIds];
        for (ProjectLocation__c ploc:plocs)
        {
            plids.add(ploc.Id);
        }

        if (plids.size() == 0) return;
        
        if (project.Status__c == CONSTANTS.PROJECT_STATUS_PLANNING)
        {
            ProjectLocationActionsHelper.DeleteProjectLocations(plids);
            ChatterUtils.simpleTextPostWithMention(project.Id, ' The following location(s) have been deleted from reservation: ' + reslocnumbers, project.OwnerId );
        }
        else
        {
        	ProjectLocationActionsHelper.CancelProjectLocation(plids, cancelReason, cancelcomments);   
            ChatterUtils.simpleTextPostWithMention(project.Id, ' The following location(s) have been canceled from reservation: ' + reslocnumbers, project.OwnerId );
        }
        
    }    
    
    private static void CancelProject(string reservationid, string cancelreason, string cancelcomments)
    {
        cancelreason = string.isEmpty(cancelreason)?'Other':cancelreason;
        cancelcomments = string.isEmpty(cancelcomments)?'Canceled from Reservation':cancelcomments;
        
        List<Project__c> projects = [SELECT Id, Name, OwnerId, OperationsTitle__c, Status__c from Project__c WHERE Reservation__c = :reservationid LIMIT 1];
        
		if (projects.size() == 0)
            return;

        Project__c project = projects[0];
        
        String projectId = projects[0].Id;
        String projectStatus = projects[0].Status__c;
        
        if (projectId.trim().length() == 0)
            return;
        
        
		
        if (projectStatus == CONSTANTS.PROJECT_STATUS_PLANNING)
        {
            ProjectActionsHelper.DeleteProject(projectId);
        }
        else
        {
        	ProjectActionsHelper.CancelProject(projectId, cancelReason, cancelComments);    
			ChatterUtils.simpleTextPostWithMention(project.Id, ' Project has been canceled from reservation. ', Project.OwnerId);                        
        }
    }    
    
    
    private static void AddProjectLocations(List<ReservationLocation__c> rls)
    {
        
        List<ProjectLocation__c> pls = new List<ProjectLocation__c>();
        List<Project__c> projects = [Select Id, ProjectType__c, ProjectType__r.Name from Project__c WHERE Reservation__c =: rls[0].Reservation__c LIMIT 1];
        if (projects.isEmpty())
            return;
        Project__c project = projects[0];
        
        
        for (ReservationLocation__c rl : rls)
        {
            if (rl.Status__c == CONSTANTS.RESERVATIONLOCATION_STATUS_RESERVED)
            {
            	ProjectLocation__c pl = new ProjectLocation__c();
                pl.Project__c = project.Id;
                pl.Location__c = rl.Location__c;
                pl.ReservationLocation__c = rl.Id;
                pl.LocationScheduledDate__c = rl.ReservedDate__c;
                pls.add(pl);
            }
        }
        
        if (!pls.isEmpty())
            insert pls;
        
        
            
        SchedulingStrategy schedulingStrategyObject = SchedulingStrategyFactory.getSchedulingStrategy(project.ProjectType__r.Name);
        ApexJobTracker__c ajt = new   ApexJobTracker__c();
        ajt.Object__c = 'Project';
        ajt.Operation__c = 'Create Jobs';
        ajt.Project__c = project.Id;
        ajt.Status__c = 'In Progress';
        ajt.StartDateTime__c = DateTime.Now();
        ajt.Id1__c = String.ValueOf(project.Id);
        insert ajt;
        
        ProjectScheduler batch = new ProjectScheduler(project);
        String batchId = Database.ExecuteBatch(batch, 100);
        
        ProjectActionsHelper.LockProject(project, 'Create Jobs', batchId);
        TriggerUtil.skipProjectTrigger = true;
        update project; 

    }
    
    public static void notifyUserByEmail(String messageBody, Reservation__c reservation)
    {
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();       
        
        string link = System.URL.getSalesforceBaseUrl().toExternalForm() + '/' + reservation.Id;
        messageBody = messageBody + '<br><br><a href=' + link + '>Click here to directly access the reservation.</a>';
        
        try
        {
            String[] toAddresses = new String[] {reservation.Owner.Email};                
            String messageSubject = 'Reservation Request Failure: ' + reservation.Name;
            EmailHelper.SendEmail(toAddresses,messageSubject,messageBody);
        }
        catch(Exception ex){
            system.debug('ERROR: Failed to send reservation failure email. Details: ' + ex.getMessage());
        }
        
    }
    
    public static void notifyReservationExpiration()
    {
        
        // Get reservation settings from custom setting		
        ReservationSettings__c reservationSetting = ReservationSettings__c.getInstance();       
        
        Date startDate = Date.today();
        Date endDate = Date.today().addDays(integer.ValueOf(reservationSetting.PriorNotificationDays__c));
        
        List<Reservation__c> expiringReservations = [SELECT Id, Status__c, PendingExpirationNotified__c, ExpirationDate__c,OwnerId FROM Reservation__c WHERE Status__c =: CONSTANTS.RESERVATION_STATUS_DRAFT
                                                     AND PendingExpirationNotified__c = False 
                                                     AND ExpirationDate__c >=:startDate and ExpirationDate__c <=:endDate];
        
        List<Task> tasks = new List<Task>();
        for (Reservation__c reservation : expiringReservations)
        {
            Task task = new Task();
            task.WhatId = reservation.id;
            task.OwnerId = reservation.OwnerId;
            task.WhoId = reservation.OwnerId;
            task.Subject = reservationSetting.Subject__c;
            task.priority= reservationSetting.Priority__c;
            task.status = reservationSetting.Status__c;
            task.description = reservationSetting.Description__c;
            tasks.add(task);
            
            reservation.PendingExpirationNotified__c = true;
        }
        
        insert tasks;
        update expiringReservations;
        
    }
    
    private static Map<String, List<String>> getLocationTopicAssignments(List<String> topics)
    {
		Map<String, List<String>> taMap = new Map<String, List<String>>();        
        string entityType = CONSTANTS.CURRENTNAMESPACEPREFIX + 'Location';
        
        List<TopicAssignment> tas = [SELECT Id, Topic.Name, EntityId, EntityKeyPrefix, EntityType FROM TopicAssignment
                                     WHERE TopicId IN :topics and EntityType = :entityType];
        
        system.debug('tas: ' + tas);
        for (TopicAssignment ta: tas)
        {
            
            if (taMap.get(ta.EntityId) == null)
            {
                taMap.put(ta.EntityId, new List<String> {ta.Topic.Id});
            }
            else
            {
                
                List<String> extopics = taMap.get(ta.EntityId);
                extopics.add(ta.Topic.Id);
                taMap.put(ta.EntityId, extopics);
            }
        }

        return taMap;
        
    }
    
    private static Map<String, String> getTopics(List<String> topics)
    {
		Map<String, String> tMap = new Map<String, String>();        
        string entityType = CONSTANTS.CURRENTNAMESPACEPREFIX + 'Location';
        
        List<Topic> topicList = [SELECT Id, Name FROM Topic WHERE Id IN :topics];
        
        for (Topic topic : topicList)
        {
            tMap.put(topic.Id, topic.Name);
        }
        
        return tMap;
        
    }

	private static List<ReservationRequestWrapper> checkApexRules(List<ReservationRequestWrapper> rrws, string reservationId)
    {
        Map<String, ReservationRequestWrapper> maprw = new Map<String, ReservationRequestWrapper>();
        string delimiterJoin = '|';
        string delimiterSplit = '\\|';
        
        for (ReservationRequestWrapper rrw : rrws)
        {
            maprw.put(rrw.LocationId, rrw);
        }
        
        ReservationWrapper reswrapper = new ReservationWrapper();
        reswrapper.Id = reservationId;
        
        
        //Check for custom validation rules here
        List<Apexrule__c> apexRules = [SELECT Id, Name, Classname__c, ErrorMessage__c, HardStop__c, Overridable__c 
                                       FROM ApexRule__c where Type__c = :CONSTANTS.APEX_RULE_TYPE_RESERVATION AND IsActive__c = True ];

        if (!apexRules.isEmpty())
        {
            for (Apexrule__c apexrule : apexRules)
            {
                string apexrulemessage = apexrule.ErrorMessage__c != null?apexrule.ErrorMessage__c:'';
                
                List<object> objList = new List<object>();
                objList.add(reswrapper);
				for (ReservationRequestWrapper rrwp :rrws)
                {
                    ReservationRequestWrapper obj = new ReservationRequestWrapper();
                    
                    obj.LocationId = rrwp.LocationId;
                    obj.LocationNumber = rrwp.LocationNumber;
                    obj.LocationLatitude = rrwp.LocationLatitude;
                    obj.LocationLongitude = rrwp.LocationLongitude;
                    obj.LocationName = rrwp.LocationName;
                    obj.LocationCity = rrwp.LocationCity;
                    obj.LocationState = rrwp.LocationState;
                    obj.LocationAddress = rrwp.LocationAddress;
                    obj.LocationZip = rrwp.LocationZip;
                    obj.ReservationDate = rrwp.ReservationDate;
                    obj.ReservationErrorCode = rrwp.ReservationErrorCode;
                    obj.Status = rrwp.Status;
                    obj.AvailableCapacity = rrwp.AvailableCapacity;
                    obj.Proximity = rrwp.Proximity;
                    obj.CapacityOverride = rrwp.CapacityOverride;
                    obj.IsResolvable = rrwp.IsResolvable;
                    obj.IsOverridable = rrwp.IsOverridable;
                    obj.ReservationErrorMessage = '';
                    obj.ReservationWarningMessage = '';
                    objList.add(obj);
                }
                
                system.debug(objList);
                string classname = string.valueOf(apexrule.Classname__c); 
                IExternalClassInterface eci = (IExternalClassInterface) Type.forName(classname).newInstance();
				List<object> retRules = eci.execute(objList);
                system.debug('retrules: ' + retRules);
                for (object obj : retRules)
                {
                    if (obj instanceof ReservationRequestWrapper)
                    {
                        ReservationRequestWrapper rw = (ReservationRequestWrapper) obj;
                        
                        //If no error is returned then continue
                        if (rw.ReservationErrorMessage.trim().length() == 0)
                            continue;
                        
                        string errormessage = apexrulemessage.trim().length() > 0? apexrulemessage.trim() : rw.ReservationErrorMessage;
                        system.debug(rw.LocationNumber + ':' + errormessage);                        
                        ReservationRequestWrapper rwparameter = maprw.get(rw.LocationId);
                        
                        string currentdelimiter = rwparameter.ReservationErrorMessage.trim().length() > 0 ? delimiterJoin : '';

                        if (apexrule.HardStop__c)
                        {
                        	rwparameter.ReservationErrorMessage = rwparameter.ReservationErrorMessage + currentdelimiter + errormessage;    
                            rwparameter.ReservationErrorCode = rwparameter.ReservationErrorMessage;
                        }
                        else
                        {
                            rwparameter.ReservationWarningMessage = rwparameter.ReservationWarningMessage + currentdelimiter + errormessage;
                        }
                    }
                }
            }
        }
        
		for (ReservationRequestWrapper rrw : rrws )
        {
         	if (rrw.ReservationErrorMessage.trim().length() > 0)
            {
                rrw.ReservationErrorMessageList = rrw.ReservationErrorMessage.split(delimiterSplit);
                rrw.NumberofErrorMessages = rrw.ReservationErrorMessageList.size();
            }
            if (rrw.ReservationWarningMessage.trim().length() > 0)
            {
                rrw.ReservationWarningMessageList = rrw.ReservationWarningMessage.split(delimiterSplit);
                rrw.NumberofWarningMessages = rrw.ReservationWarningMessageList.size();
                
            }

            
            
        }
        
        return rrws;
    }    
    
    private static String doesLocationSupportGivenTopics(string locationid, List<String> topics, Map<String, List<String>> taMap, Map<String, String> tmap)
    {
        string missingTopics = '';
        
        for (string topic : topics)
        {
            if (taMap.get(locationid) == null || 
                (taMap.get(locationid) != null &&
                 !taMap.get(locationid).contains(topic))
               )
            {
                missingTopics = missingTopics + tmap.get(topic) + ':';
            }            
        }
        return missingTopics;
    }    
    
    global static void AutoApprovePendingApprovalReservations()    	
    {
        
 		// Get reservation settings from custom setting		
        ReservationSettings__c reservationSetting = ReservationSettings__c.getInstance();       
        
        
        Date dateToFilter = Date.today().addDays(integer.ValueOf( '-' + string.ValueOf(reservationSetting.AutoApproveInterval__c)));        
        
        List<ProcessInstance> piList = [SELECT Id, TargetObject.Name, TargetObjectId, Status, SubmittedById, CompletedDate, CreatedDate FROM ProcessInstance 
                                         where TargetObjectId in (select id from Reservation__c where Status__c = 'Pending Approval') 
                                         and CreatedDate <=: dateToFilter];
        Set<Id> reservationIds = new Set<Id>();
        
        Set<Id> processTargetIds = new Set<Id>();
        
        for(ProcessInstance obj: piList){
            processTargetIds.add(obj.TargetObjectId);
        }
        
		//Getting Work Item Id
        List<ProcessInstanceWorkitem> pItemList = [Select Id, ProcessInstance.TargetObjectId from ProcessInstanceWorkitem 
        											Where ProcessInstance.TargetObjectId In :processTargetIds];
        
        //for(ProcessInstance obj: piList){
        for(ProcessInstanceWorkitem obj: pItemList){

            reservationIds.add(obj.ProcessInstance.TargetObjectId);
            ProcessInstanceWorkitem pItem = pItemList[0];
            Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
            req.setComments('Auto Approved');
            
            //Approve or Reject Record
            req.setAction('Approve');            
            
            req.setWorkitemId(pItem.Id);
            
            // Submit the request for approval
            Approval.ProcessResult result = Approval.process(req);                  
        }

        List<Reservation__c> reservationList  = [SELECT id, IsAutoApproved__c from Reservation__c where id in: reservationIds];

        for(Reservation__c objReservation: reservationList){
            objReservation.IsAutoApproved__c = True;
        }
        
        update reservationList;
    }  
    
    //DEPRECATED METHODS
    
	//Not used anymore. Needs to be deprecated
    global static void ProcessRLPendingReservations(string reservationId)    	
    {
    }   
    
    //Not used anymore. Needs to be deprecated
	global static void ProcessRLPendingCancellations(string reservationId)    	
    {
    }       
    
    //Not used anymore. Needs to be deprecated
	global static void CancelReservation(string reservationId)    	
    {
        CancelReservation(reservationId, '','');
    }
    
    //Not used. Needs to be deprecated
    global static ReservationWrapper GetReservationDetails(string reservationId)
    {
        return null;
    }    

    //Not used. Needs to be deprecated
	global static List<ReservationRequestWrapper> GetAvailableLocationsByNumber(string reservationId, Integer maxcount, Date requestedDate)
    {
		return GetAvailableLocationsByNumber(reservationId, maxcount, requestedDate, '');
    }

    //Not used. Needs to be deprecated
	global static List<ReservationRequestWrapper> GetAvailableLocationsByList(string reservationId, List<ReservationRequestWrapper> rwlist)
    {
        return GetAvailableLocationsByList(reservationId, rwlist, '');
        
    }
    


    
    
    
  
    
    
}