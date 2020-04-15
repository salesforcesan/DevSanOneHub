public without sharing class ImportRequestQueueNotifierState {
	private static final Integer STATUS_COMPELETED = 1;
	private static final Integer STATUS_FAILED = 2;
	private static final Integer STATUS_PROCESSING = 3;
	private static final Integer STATUS_CANCELED = 4;
	private static final Integer STATUS_QUEUED = 5;

	private Integer SuccessCount;
	private Integer ErrorCount;
	private Integer TotalCount;
	private boolean EmailNotified;
	private Integer Status;
	private List<String> Errors;
	private Set<String> ErrorAttachments;


	private ImportRequestQueueNotifierState() {
		SuccessCount = 0;
		ErrorCount = 0;
		TotalCount = 0;	
		Status = 0;
		EmailNotified = false;
		Errors = new List<String>();
		ErrorAttachments = new Set<String>();
	}

	public static ImportRequestQueueNotifierState newInstance(){
		return new ImportRequestQueueNotifierState();
	}

	public void markCompleted(){
		Status = STATUS_COMPELETED;
	}

	public void markFailed() {
		Status = STATUS_FAILED;
	}

	public void markProcessing(){
		Status = STATUS_PROCESSING;
	}

	public void markCanceled(){
		Status = STATUS_CANCELED;
	}

	public void markQueued() {
		Status = STATUS_QUEUED;
	}

	public void markEmailNotified() {
		EmailNotified = true;
	}

	public Boolean shouldNotifyUser(){
		return Status == STATUS_COMPELETED || Status == STATUS_FAILED;
	}

	public Boolean getEmailNotified() {
		return EmailNotified;
	}

	public Boolean isSucceeded() {
		return STATUS == STATUS_COMPELETED || ErrorCount == 0;
	}

	public String getStatus() {
		if (Status == STATUS_PROCESSING) return 'Processing';
		if (Status == STATUS_COMPELETED) return 'Completed';
		if (Status == STATUS_FAILED) return 'Failed';
		if (Status == STATUS_CANCELED) return 'Canceled';
		return 'Queued';
	}

	public void plusSuccessCount(Integer count){
		SuccessCount += count;
	}

	public Integer getSuccessCount(){
		return SuccessCount;
	}

	public void plusErrorCount(Integer count){
		ErrorCount += count;
	}

	public Integer getErrorCount(){
		return ErrorCount;
	}

	public void plusTotalCount(Integer count){
		TotalCount += count;
	}

	public Integer getTotalCount(){
		return TotalCount;
	}

	public void addError(String errMsg){
		Errors.add(errMsg);
	}

	public void addErrorAttachment(String attachmentId){
		ErrorAttachments.add(attachmentId);
	}

	public List<String> getErrorAttachments() {
		return new List<String>(ErrorAttachments);
	}

	public Boolean hasError(){
		return !Errors.isEmpty();
	}

	public String getErrorString(){
		return String.join(Errors, ' ');
	}
}