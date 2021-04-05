@isTest
public with sharing class ContactsToUsersPdfController_Test {
    
    @isTest
    static void testContactsToUsersGeneratePdfPage() {
        PageReference pageRef = Page.DownloadContactsToUsersPdfHelper;
        pageRef.getParameters().put('text', 'Hello World');
        Test.setCurrentPage(pageRef);
        ContactsToUsersPdfController userController = new ContactsToUsersPdfController();
        System.assertEquals('Hello World', userController.text);
    }

}
