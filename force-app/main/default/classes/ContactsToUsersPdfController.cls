public with sharing class ContactsToUsersPdfController {
    public String text { get; set; }
    public String Name { get; set; }
    public String todayDate { get; set; }
    public ContactsToUsersPdfController() {
        text = System.currentPageReference().getParameters().get('text');
        todayDate = String.valueOf(DateTime.now()).replace('_', ':');
        Name = 'Creating Users Report - ' + todayDate;
    }
}
