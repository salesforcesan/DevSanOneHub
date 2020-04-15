public interface IImportRequestService {
    void init(String parentId, String attachmentName, String jobName);
    String getId();
    String getAttachmentName();
    String getJobName();
    String getImportTitles();
    Integer getChunkSize();
    void canImport();
    void afterImport();
}