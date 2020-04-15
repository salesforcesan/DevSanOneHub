public with sharing class LoggerFactory {
    public static ILogger createLogger(String application, Boolean useDatabase) {
        if (true == useDatabase) {
            return new DBLogger(application);
        }
        return new Logger(application);
    }
}