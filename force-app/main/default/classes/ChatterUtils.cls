public with sharing class ChatterUtils {
   
   public static void simpleTextPost(Id parentId, string body) 
   { 
        FeedItem post = new FeedItem();
        post.ParentId = parentId; //eg. Opportunity id, custom object id..
        post.Body = body;
        insert post;
   }
    
   public static void simpleTextPostWithMention(Id subjectId, string body, string mentionId)
   {
       
        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
        ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();

       	textSegmentInput.text = body;
        messageBodyInput.messageSegments.add(textSegmentInput);
        
        mentionSegmentInput.id = mentionId;
        messageBodyInput.messageSegments.add(mentionSegmentInput);
        
        
        feedItemInput.body = messageBodyInput;
        feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
        feedItemInput.subjectId = subjectId;
       	ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);
   }

}