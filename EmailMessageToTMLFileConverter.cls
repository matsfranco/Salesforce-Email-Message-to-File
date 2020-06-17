/*
*   Class EmailMessageToHTMLFileConverter
*   Description:    This class was developed to covert EmailMessage records into html file attachments.
                    Every EmailMessage attachment is cloned to replace the ParentId with the corresponding Case
                    record reference
*   Where it is used: on EmailMessage records. It is related to two Process Builders
*   Created By: Mateus Franco @ 17/01/2020
*   Change Log:
*   Date        Developer       Version     Description
*   20-01-2020  Mateus Franco   1.0         Created.
*
*/

public with sharing class EmailMessageToHTMLFileConverter {
    
    public static String version = 'v1.1';
    public static String format = '.html';
    
    public EmailMessageToHTMLFileConverter(List<String> messageIds) {
        convertEmailMessageToAttachment(messageIds);
    }

    // Create a new Attachment record with EmailMessage Content
    public static Attachment createEmailAsAttachment(EmailMessage email, String attachmentList) {
        Attachment newAtt = new Attachment();
        newAtt.Name = '[Archived] '+email.Subject+format;
        newAtt.Description = 'Archived from EmailMessage '+email.Id;
        String attBody =    '<html><p style="font-size:18px"><b>General Info</b><br/></p>'+
                            '<b>Source Case: </b>'+email.Parent.CaseNumber+'<br/>'+
                            '<b>Archived By: </b>'+UserInfo.getUserName()+'<br/>'+
                            '<b>Archive Date: </b>'+System.now()+'<br/>'+
                            '<b>Original Id: </b>'+email.Id+'<br/>'+  
                            '<b>Archiver Version: </b>'+version+'<br/>';
                            attBody += '<br/><p style="font-size:18px"><b>Message</b><br/></p>';
                            attBody += '<b>From: </b>'+email.FromName+' ('+email.FromAddress+')<br/>'+
                            '<b>MessageDate: </b>'+email.MessageDate+'<br/>'+
                            '<b>To: </b>'+email.ToAddress+'<br/>';
                            if(email.CcAddress != null) attBody += '<b>Cc: </b>'+email.CcAddress+'<br/>';
                            if(email.BccAddress != null) attBody += '<b>Bcc: </b>'+email.BccAddress+'<br/>';
                            attBody += '<b>Subject: </b>'+email.Subject+'<br/>';
                            attBody += email.HtmlBody+'<br/>';
                            attBody += '<br/>-----<br/>';
                            attBody += '<b>Attachment List: <b/>'+attachmentList+'<br/>';
                            attBody += '-----<br/>'+
                            '<p style="font-size:0px">'+'ActivityId,BccAddress,CcAddress,CreatedById,EmailTemplateId,FirstOpenedDate,FromAddress,FromName,Headers,Id,Incoming,IsBounced,IsClientManaged,IsExternallyVisible,IsTracked,LastOpenedDate,MessageDate,MessageIdentifier,ParentId,RelatedToId,ReplyToEmailMessageId,Status,Subject,TextBody,ThreadIdentifier,ToAddress<br/>'+
                            email.ActivityId+','+email.BccAddress+','+email.CcAddress+','+email.CreatedById+','+
                            email.EmailTemplateId+','+email.FirstOpenedDate+','+email.FromAddress+','+
                            email.FromName+','+email.Headers+','+email.HasAttachment+','+email.Id+','+
                            email.Incoming+','+email.IsBounced+','+email.IsClientManaged+','+
                            email.IsExternallyVisible+','+email.IsTracked+','+email.LastOpenedDate+','+
                            email.MessageDate+','+email.MessageIdentifier+','+email.ParentId+','+
                            email.Parent.CaseNumber+','+email.RelatedToId+','+email.ReplyToEmailMessageId+','+
                            email.Status+',"'+email.Subject+'","'+email.TextBody+'",'+email.ThreadIdentifier+','+
                            email.ToAddress+'<p/></html>';
        newAtt.Body = Blob.valueOf(attBody);
        newAtt.ParentId = email.ParentId;
        return newAtt;
    }
 
    // Create a new attachment by cloning original ones to change the ParentId reference
    public static Attachment cloneEmailAttachmentsToParent(Attachment att,String caseId) {
        Attachment newEmailAtt = new Attachment();
        newEmailAtt = att.clone(false,false);
        newEmailAtt.Description = 'Archived from Attachment '+att.Id+' related to EmailMessage '+att.ParentId;
        if(att.Description !=null) newEmailAtt.Description += '\n'+att.Description;
        newEmailAtt.ParentId = caseId;
        return newEmailAtt;
    }

    // Fetch Attachment List (Based on EmailMessage Id list)
    public static List<Attachment>  getEmailAttachments(String messageId) {
        List<Attachment>  emailAttachments =  [SELECT   Id,ParentId,Name,
                                                        Body,OwnerId,CreatedDate,
                                                        CreatedById,LastModifiedDate,
                                                        LastModifiedById,Description,
                                                        IsPartnerShared 
                                                        FROM Attachment 
                                                        WHERE ParentId =: messageId];
        return emailAttachments;
    }

    // Submit a list of attachments for cloning and ParentId reassignment
    public static List<Attachment> reasignParentIdsOfAttachments(List<Attachment> attachments, String newParentId) {
        List<Attachment> clonedAttachments = new List<Attachment>();
        for(Attachment att : attachments) {
            clonedAttachments.add(cloneEmailAttachmentsToParent(att,newParentId));
        }
        return clonedAttachments;
    }

    // Generate the HTML list to be used on file generated with email content
    public static String generateAttachmentLinks(List<Attachment> attachments) {
        String attachmentList = '<br/>'; 
        for(Attachment att : attachments) {
            attachmentList += '<a href="'+URL.getSalesforceBaseUrl().toExternalForm()+'/'+att.Id+'">'+att.Name+'</a><br/>';
        }
        return attachmentList;
    }

    // Main method that execute the transformation procedures
    // 1. Reassing Email Message attachments to have Case as Parent record by cloning
    // 2. Generate the HTML file for email message
    // 3. Generate the Attachment list with links
    // 4. Insert HTML file to replace the EmailMessage record
    // 5. Remove original EmailMessage and corresponding Attachments (Master-Detail)
    @InvocableMethod
    public static void convertEmailMessageToAttachment(List<String> messageIds) {
        String messageId = messageIds[0];
        Attachment emailAsArchive = new Attachment();
        List<Attachment> newAttachments = new List<Attachment>();
        List<Attachment> emailAttachments = new List<Attachment>();
        String newEmailAttachments;

        //  Step 1 to 3
        EmailMessage email = [SELECT    ActivityId,BccAddress,CcAddress,
                                        CreatedById,EmailTemplateId,FirstOpenedDate,
                                        FromAddress,FromName,Headers,HasAttachment,
                                        HtmlBody,Id,Incoming,IsBounced,
                                        IsClientManaged,IsExternallyVisible,
                                        IsTracked,LastOpenedDate,MessageDate,
                                        MessageIdentifier,ParentId,Parent.CaseNumber,RelatedToId,
                                        ReplyToEmailMessageId,Status,Subject,
                                        TextBody,ThreadIdentifier,ToAddress 
                                        FROM EmailMessage 
                                        WHERE Id =: messageId Limit 1]; // This record is unique (by Id)
        if(email.HasAttachment == True) {
            emailAttachments = getEmailAttachments(messageId);
            newAttachments = reasignParentIdsOfAttachments(emailAttachments,email.ParentId);
            insert newAttachments;
            newEmailAttachments = generateAttachmentLinks(newAttachments);
        }
        emailAsArchive = createEmailAsAttachment(email,newEmailAttachments);
        //  Step 4
        insert emailAsArchive;
        //  Step 5
        
        email.Email_Archiver_Log__c = 'Success! Archived By: '+UserInfo.getUserName()+' on '+System.now();
        email.Archiving_Status__c = 'Successfully Archived';

        update(email);
    }


}
