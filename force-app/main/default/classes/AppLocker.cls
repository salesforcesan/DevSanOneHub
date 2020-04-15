public with sharing class AppLocker {
	private String objectType;
	private String objectId;
	private String token;
	private String requestorId;
	private Boolean locked;

	private AppLocker(String objType, String objId, String requestorId, String appToken) {
		this.objectId = objId;
		this.objectType = objType;
		this.token = appToken;
		this.locked = false;
		this.requestorId = requestorId;
	}

	public String getToken() {
		return this.token;
	}

	public Boolean isLocked() {
		return this.locked;
	}

	public AppLocker setRequestor(String requestor) {
		this.requestorId = requestor;
		return this;
	}

	public static AppLocker newInstance(String objType, String objId, String requestor) {
		return new AppLocker(objType, objId, requestor, Uuid.newInstance().getValue());
	}

	public static AppLocker newInstance(String objType, String objId, String requestor, String appToken) {
		return new AppLocker(objType, objId, requestor, appToken);
	}

	public void lock() {
		String oId = objectId, oType = objectType;
		try {
			AppLocker__c locker = getLocker(oId, oType);
			locker.StartTime__c = Datetime.now();
			locker.RequestorId__c = this.requestorId;
			locker.Token__c = this.token;
			DBX.doUpdate(locker);
			this.locked = true;
		} catch(QueryException tenSecondEx){
			throw new AppLockException('Faild to lock resource (' + oType + ':' + oId + ') ' + tenSecondEx.getMessage());
		} catch(DmlException failedToLock){
			throw new AppLockException('Failed to lock resource (' + oType + ':' + oId + ') ' + failedToLock.getMessage());
		}
	}

	public void release() {
		String oId = this.objectId, oType = this.objectType;
		try {
			List<AppLocker__c> lockers = tryToGetLockers(oId, oType);
			if (lockers.isEmpty()) { return; }
			AppLocker__c locker = lockers.get(0);
			locker.Token__c = '';
			locker.StartTime__c = null;
			locker.RequestorId__c = '';
			DBX.doUpdate(locker);
			this.locked = false;
		} catch(QueryException tenSecondEx){
			throw new AppLockException('Faild to unlock resource (' + oType + ':' + oId + ') ' + tenSecondEx.getMessage());
		} catch(DmlException failedToLock){
			throw new AppLockException('Failed to unlock resource (' + oType + ':' + oId + ') ' + failedToLock.getMessage());
		}
	}

	AppLocker__c getLocker(String oId, String oType) {
		List<AppLocker__c> lockers = tryToGetLockers(oId, oType);
		if (lockers.isEmpty()) {
			tryToCreateLocker(oId, oType);
			lockers = tryToGetLockers(oId, oType);
			if (lockers.isEmpty()) {
				throw new AppLockException(
				  StringBuilder.newInstance()
				  .append('Failed to create and get locker type:')
				  .append(oType)
				  .append(' id:')
				  .append(oId)
				  .build());
			}
		}

		ensureLockOwner(lockers.get(0));
		return lockers.get(0);
	}

	void ensureLockOwner(AppLocker__c locker) {
		if (String.isNotBlank(locker.Token__c) && this.token != locker.Token__c) {
			throw new AppLockException(
			  StringBuilder.newInstance()
			  .append('Token not match.')
			  .appendIfNotNull('locked requestor:', locker.RequestorId__c)
			  .append('current requestor:')
			  .append(this.requestorId)
			  .build()
			);
		}
	}

	List<AppLocker__c> tryToGetLockers(String oId, String oType) {
		return [
		         SELECT
		         Id,
		         StartTime__c,
		         Token__c,
		         RequestorId__c
		         FROM AppLocker__c
		         WHERE ObjectType__c = :oType
		                               AND ObjectId__c = :oId
		                                   FOR UPDATE];
	}

	void tryToCreateLocker(String oId, String oType) {
		AppLocker__c locker = new AppLocker__c(
		  ObjectType__c = oType,
		  ObjectId__c = oId,
		  Token__c = this.token,
		  RequestorId__c = this.requestorId
		);
		DBX.doInsert(locker);
	}
}