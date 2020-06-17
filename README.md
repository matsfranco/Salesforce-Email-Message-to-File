# Salesforce Email Message to File

Apex class to convert Email Message record into an HTML Attachment.
Designed to be called by Process Builder or Trigger from EmailMessage.
The Email Message data is used to build and HTML file keeping the original content in CSV format. This file is attached to the original parent record.
All attachments of the email message are cloned and assigned to the same parent record.

This class was developed to save Salesforce record storage.

