public with sharing Class JobImageHandler {
    static final Integer JobImagsLimit;
    static{

        OrgCustomSettings__c setting = [SELECT BatchNumberofjobImages__c FROM OrgCustomSettings__c LIMIT 1];
        if (setting.BatchNumberofjobImages__c != null) {
            JobImagsLimit = Integer.valueOf(setting.BatchNumberofjobImages__c);
        } else
        {
            JobImagsLimit = 1000;
        }
    }

    @testVisible
    static boolean validateAttachment(Attachment att) {
        return att.bodylength > 4;
    }

    @testVisible
    static Set<Id> findIdsWithNotAttachmentOrBodyLengthEqualtoZero(Set<Id> attachments) {
        Set<Id> result = new Set<Id>(attachments);
        Set<Id> idsWithAttachment = new Set<Id>();

        for (Attachment att : [SELECT Id, BodyLength FROM Attachment
        WHERE Id IN :attachments]) {
            if (validateAttachment(att)) {
                idsWithAttachment.add(att.Id);
            }
        }

        if (idsWithAttachment.size() > 0) {
            result.removeAll(idsWithAttachment);
        }

        return result;
    }

    @testVisible
    static Set<Id> getPhotoAttachmentIds(List<jobImage__c> photos) {
        Set<Id> ids = new Set<Id>();
        for (jobImage__c r : photos) {
            ids.add(r.AttachmentId__c);
        }
        return ids;
    }

    @testVisible
    static List<jobImage__c> filterWithSideEffect(List<jobImage__c> images) {
        List<jobImage__c> validImages = new List<jobImage__c>();
        List<jobImage__c> imagesForUpdate = new List<jobImage__c>();
        jobImage__c r;

        Set<Id> invalidAttachments =
            findIdsWithNotAttachmentOrBodyLengthEqualtoZero(
                getPhotoAttachmentIds(images));

        for (jobImage__c image : images) {
            r = new jobImage__c(
                Id = image.Id,
                ProcessingPickupDateTime__c = DateTime.now()
            );
            if (String.isBlank(image.ImageContentType__c)) {
                r.IsErrored__c = true;
                r.ErrorMessage__c = 'Image Content Type Empty';
            } else if (!invalidAttachments.isEmpty()
                       && invalidAttachments.contains(image.AttachmentId__c)) {
                r.IsErrored__c = true;
                r.ErrorMessage__c =
                    'Attachment Either Empty Or Not Found: '
                    + String.valueOf(image.AttachmentId__c);
            } else {
                validImages.add(image);
            }
            imagesForUpdate.add(r);
        }
        update imagesForUpdate;
        return validImages;
    }

    public static  List<jobImage__c> getjobImages() {
        List<jobImage__c> images =
            [Select
             Id,
             name,
             ImageURL__c,
             ImageContentType__c,
             ImageName__c,
             ImageDescription__c,
             Job__c,
             AttachmentId__c,
             ProjectLocation__c,
             Project__c
             from jobImage__c
             where ReadyForProcessing__c = true AND IsErrored__c != true Limit:JobImagsLimit];

        if (images.isEmpty()) {return images;}
        return filterWithSideEffect(images);
    }



    public static void InvokeBatchjobImages(list<jobImage__c> lstjobImages) {
        if (lstjobImages.size() == 0) {
            return;
        }

        Id[] jobImageIds = new Id[] {};
        for (jobImage__c ji : lstjobImages) {
            jobImageIds.add(ji.Id);

        }
        BatchGeneratejobImageUrl bmimages = new BatchGeneratejobImageUrl(jobImageIds);
        Id batchJobId = Database.ExecuteBatch(bmimages, 1);

    }

    @testVisible
    static void errorOutjobImage(String imageId, String err) {
        jobImage__c target = new jobImage__c(
            Id = imageId,
            IsErrored__c = true,
            ErrorMessage__c = err
        );
        Database.SaveResult result = Database.update(target);
        if (!result.isSuccess()) {
            throw new CustomException(AppLogBatch.genSaveResultError(result));
        }
    }

    public static void DoGenerateNewjobImageURL(jobImage__c jobImage) {

        if (string.isBlank(jobImage.ImageContentType__c)) {
            errorOutjobImage(jobImage.Id, 'Attachment ContentType Required');
            return;
        }

        ImageServiceSettings__c imgSvc =
            ImageServiceSettings__c.getValues('ImageService');


        List<Attachment> attachments = [Select ID, ParentID, body, bodylength, Name from Attachment where Id = :jobImage.AttachmentId__c limit 1];

        if (attachments.isEmpty()) {
            errorOutjobImage(
                jobImage.Id,
                'Attachment Not Found: ' + String.valueOf(jobImage.AttachmentId__c));
            return;
        }

        if (!validateAttachment(attachments[0])) {
            errorOutjobImage(
                jobImage.Id,
                'Attachment Invalid (<4): ' + String.valueOf(jobImage.AttachmentId__c));
            return;
        }

        Attachment attachment = attachments[0];

        String ext = string.valueof(jobImage.ImageContentType__c).toLowerCase();
        string attext = '';
        if (ext.length() > 0) {
            Integer intIndex = ext.indexOf('/');

            if (intIndex > 0) {
                attext  = ext.substring(intIndex + 1, ext.length());
            } else {
                attext = ext;
            }
        }

        string JobcntType = AppUtil.getContentType(attext);


        String attachUrl = imgSvc.URL__c;
        String userName = imgSvc.UserName__c;
        String password = imgSvc.Password__c;
        Blob headerValue = Blob.valueOf(userName + ':' + password);
        String authorizationHeader = 'Basic ' + EncodingUtil.base64Encode(headerValue);

        // create new attachment URL
        HttpRequest req = new HttpRequest();
        req.setEndpoint(attachUrl);
        req.setMethod('POST');

        // set headers
        req.setHeader('Authorization', authorizationHeader);
        req.setHeader('Content-Type', JobcntType);
        req.setHeader('Accept', 'application/json');

        //set body

        req.setBodyAsBlob(attachment.body);

        //Send request
        HttpResponse res = new HttpResponse();
        String url = '';
        if (!Test.isRunningTest()) {
            Http http = new Http();
            res = http.send(req);
            url = res.getHeader('Location');
        } else {
            url = 'http://www.yahoo.com';
        }

        updateImageUrl(jobImage.Id, url);
        purgeAttachment(attachment.Id);
    }

    @testVisible
    static void purgeAttachment(String attId) {
        List<Attachment> a = [select id from attachment where id = :attId];
        if (a.size() > 0) {
            delete a;
        }
    }

    @testVisible
    static void updateImageUrl(String imageId, String url) {
        jobImage__c image = new jobImage__c(
            Id = imageId, ImageURL__c = url);

        if (String.isBlank(url)) {
            image.IsErrored__c = true;
            image.ErrorMessage__c = 'Image Service returns empty URL';
        }

        Database.SaveResult result = Database.update(image);
        if (!result.isSuccess()) {
            throw new CustomException(
                'Failed to update image URL: '
                + imageId
                + ' url: '
                + url
                + ' error: '
                + AppLogBatch.genSaveResultError(result));
        }
    }

}