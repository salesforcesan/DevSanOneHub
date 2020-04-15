public interface ILogger {
    void info(String msg);
    void debug(String msg);
    void warn(String msg);
    void error(String msg);
    void save();
}