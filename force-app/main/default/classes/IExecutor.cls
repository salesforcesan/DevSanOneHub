public interface IExecutor {
	DBResult doExecute(Object[] parameters);
	Object getFailedContent();
}