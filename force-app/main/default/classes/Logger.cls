public virtual with sharing class Logger implements ILogger {
    public List<ErrorLog> logs {get; private set;}
    public String application {get;private set;}

    public Logger(String application) {
        this.logs = new List<ErrorLog>();
        this.application = application;
    }

    public void info(String msg) {
        logs.add(new ErrorLog(msg, ErrorLog.SEVERITY_INFO));
    }
    public void debug(String msg) {
        logs.add(new ErrorLog(msg, ErrorLog.SEVERITY_DEBUG));
    }
    public void warn(String msg) {
        logs.add(new ErrorLog(msg, ErrorLog.SEVERITY_WARN));
    }

    public void error(String msg) {
        logs.add(new ErrorLog(msg, ErrorLog.SEVERITY_ERROR));
    }

    public virtual void save() {
        if (logs.size() > 0) {
            System.debug('----<start of ' + application + '>----');
            for(ErrorLog log: logs) {
                System.debug(log.toString());
            }
            System.debug('----<end of ' + application + '>----');
            logs.clear();
        }
    }
}