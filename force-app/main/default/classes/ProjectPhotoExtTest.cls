@isTest
public class ProjectPhotoExtTest {

    public static testMethod void testPhotos(){
        Project__c project = TestUtil.generateFullTestProject(ProjectType.MD, Date.today().addDays(10), Date.today().addDays(20));
        
        PageReference pageRef = Page.ProjectPhotos;
        pageRef.getParameters().put('Id', project.Id);
        
        Test.setCurrentPage(pageRef);
        try{
        ApexPages.StandardController sc = new ApexPages.standardController(project);
        ProjectPhotoExt ctrl = new ProjectPhotoExt(sc);
        //use new API to test
        list <string[]> testPhotos = ProjectPhotoExt.getPhotoURLs(project.id);
        } catch(Exception ex){}
    }
}