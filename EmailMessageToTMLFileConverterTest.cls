/*
*   Class EmailMessageToHTMLFileConverterTest
*   Description:    Test Class of EmailMessageToHTMLFileConverter.
					built for version 1.1
*   Where it is used: to validate EmailMessageToHTMLFileConverter Apex Class
*   Created By: Mateus Franco @ 15-02-2020
*   Change Log:
*   Date        Developer       Version     Description
*   15-02-2020  Mateus Franco   1.0         Created.
*
*/

@isTest
public class EmailMessageToHTMLFileConverterTest {
	@testSetup
    static void setup() {
        String toEmail = 'receiver@test.com';
        String fromEmail = 'sender@test.com';
        
        Case firstCase = createCase();       
		createAttachments('Case_Att_',firstCase.Id,1);
        EmailMessage firstMessage = createEmailMessage('Email Message 1',fromEmail,toEmail,firstCase.Id);
        createAttachments('EmailMessage_1_Attachment_',firstMessage.Id,2);
        EmailMessage secondMessage = createEmailMessage('Email Message 2',fromEmail,toEmail,firstCase.Id);
        createAttachments('EmailMessage_2_Attachment_',secondMessage.Id,2);
        
        // Scenario for Negative Test (check if it is archiving only requested messages)
        Case secondCase = createCase(); 
        EmailMessage thirdMessage = createEmailMessage('Email Message 3',fromEmail,toEmail,secondCase.Id);
        createAttachments('EmailMessage_3_Attachment_',thirdMessage.Id,2);
        
    }
    
    public static Case createCase() {
        Case c = new Case();
        insert c;
        return c;
    }
    
    public static void createAttachments(String fileName, String parentId, Integer quant) {
        List<Attachment> atts = new List<Attachment>();
        for(Integer i = 0; i < quant; i++) {
        	Attachment newAtt = new Attachment();
            newAtt.Name = String.valueOf(fileName+String.valueOf(i)+'.txt');
        	newAtt.Body = Blob.valueOf('Test file body content '+String.valueOf(i));
        	newAtt.ParentId = parentId;
            atts.add(newAtt);
        }
        insert atts;
    }
    
    public static EmailMessage createEmailMessage(String subject,String fromEmail,String toEmail,String parentId) {
        EmailMessage newEmailMessage = new EmailMessage();
        newEmailMessage.Subject = subject;
        newEmailMessage.TextBody = subject+' body content';
        newEmailMessage.HtmlBody = '<div> '+subject+ 'HTML body content </div>';
        newEmailMessage.FromAddress = fromEmail;
        newEmailMessage.ToAddress = toEmail;
        newEmailMessage.ParentId = parentId;
        insert newEmailMessage;
        return newEmailMessage;
    }
    
    
    @isTest
    static void emailArchivingPositiveTest(){
        Test.startTest();
        List<Case> cases = new List<Case>();
        List<Attachment> atts = new List<Attachment>();
        cases = [Select Id FROM Case ORDER BY CaseNumber ASC];
     	List<EmailMessage> emailMessages = [Select Id FROM EmailMessage WHERE ParentId =: cases[0].Id];
        
        for(EmailMessage emailMessage : emailMessages) {
            List<String> message = new List<String>();
            message.add(emailMessage.Id);
            EmailMessageToHTMLFileConverter converter = new EmailMessageToHTMLFileConverter(message);
        }
        List<Attachment> firstCaseAtts = [SELECT Id FROM Attachment WHERE ParentId =: cases[0].Id];
        List<Attachment> secondCaseAtts = [SELECT Id FROM Attachment WHERE ParentId =: cases[1].Id];
    
        System.assert(firstCaseAtts.size() == 7);	// Sum of all attachments on First Case
        System.assert(secondCaseAtts.size() == 0); //	Not converted
        Test.stopTest();
    }
}
