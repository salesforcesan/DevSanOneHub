public with sharing class DBLogger extends Logger {
    private AppLogBatch appLog;

    public DBLogger(String application) {
     super(application);
    this.appLog = AppLogBatch.createInstance().newAppLog();
    }

    public override void save() {
        if (this.logs.size() == 0){return;}
       
        for(ErrorLog log: this.logs){
           this.appLog
                .newLog(this.application, AppLogBatch.LOG_LEVEL_ERROR)
                .setMessageDetail(log.Message, log.Message);
            if (log.Severity == ErrorLog.SEVERITY_ERROR){
                this.appLog.setError();     
            } else if (log.Severity == ErrorLog.SEVERITY_WARN){
                this.appLog.setWarning();
            } else if (log.Severity < 2) {
                this.appLog.setInfo();
            }
            this.appLog.addToBatch();
        }

        this.appLog.saveToDB();
        this.logs.clear();
    }
}