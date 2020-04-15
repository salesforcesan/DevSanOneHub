public class AttachmentAnalyzer {
    private static String SUPPORTED_PHOTO_TYPE = ',jpg,jpeg,gif,png';

    public static Boolean isImage(String id, String name, String type) {
        if (String.isBlank(id) || type != 'Photo' || String.isBlank(name)) { return false; }

        String ext = (name.indexOf('.') != -1) ? (',' + name.right(name.length() - name.indexOf('.') - 1).toLowerCase()) : '';
        return (String.isNotBlank(ext) &&  
                SUPPORTED_PHOTO_TYPE.indexOf(ext) != -1) ? true : false;
            
     }
    public static Boolean isFile(String id, String type) {
        return ((type == 'Photo' || type == 'File') && String.isNotBlank(id)) ? true : false;
    }
}