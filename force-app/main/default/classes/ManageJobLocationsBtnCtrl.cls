public with sharing class ManageJobLocationsBtnCtrl {

    private final Id projectId;


    public ManageJobLocationsBtnCtrl(ApexPages.StandardSetController stdController) {
        projectId = ApexPages.currentPage().getParameters().get('id');
    }


    public pagereference navigateToManageJobLocations(){
        pagereference p = Page.ManageJobsLocations;
        p.getParameters().put('projectid',projectId);
        p.getParameters().put('Obj','ProjLoc');
        return p;
    }

     public pagereference navigateToJobLocations(){
        pagereference p = Page.ManageJobsLocations;
        p.getParameters().put('projectid',projectId);
        p.getParameters().put('Obj','Job');
        return p;
    }


    public pagereference navigateToUploadLocations(){
        pagereference p = Page.UploadLocations;
        p.getParameters().put('projectid',projectId);
        return p;
    }

    public pagereference navigateToJobManagement(){
        pagereference p = Page.JobManagement;
        p.getParameters().put('id',projectId);
        return p;
    }
   

    private class ManageJobLocationsBtnCtrlException extends Exception {}

}