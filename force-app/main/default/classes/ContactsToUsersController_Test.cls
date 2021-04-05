@isTest
public with sharing class ContactsToUsersController_Test {
	@TestSetup
	static void testSetup() {
		List<Contact> contacts = new List<Contact>{
			new Contact(FirstName = 'Testing', LastName = 'Test1', MailingState = 'TX', Email = 'test11111@gmail.com', Phone = '___SECRET!!!'),
			new Contact(LastName = 'Test2', MailingState = 'NY', Email = 'test222222@gmail.com', Phone = '___SECRET!!!'),
			new Contact(LastName = 'Test3', MailingState = 'TX', Email = 'test333333@gmail.com', Phone = '___SECRET!!!'),
			new Contact(FirstName = 'Hej', LastName = 'Test31', MailingState = 'TX', Email = 'test3111111@gmail.com', Phone = '___SECRET!!!'),
			new Contact(FirstName = 'Hejo', LastName = 'Test32', MailingState = 'NY', Email = 'test3222222@gmail.com', Phone = '___SECRET!!!'),
			new Contact(LastName = 'Test4', MailingState = 'TX'),
			new Contact(FirstName = 'NoEmail', LastName = 'Test41', MailingState = 'TX'),
			new Contact(FirstName = 'Li', LastName = 'Wo', MailingState = 'AZ', Email = 'test555555@gmail.com', Phone = '___SECRET!!!'),
			new Contact(FirstName = 'Hello', LastName = 'World', MailingState = 'CA', Email = 'test666666@gmail.com', Phone = '___SECRET!!!'),
			new Contact(FirstName = 'Jan', LastName = 'Kowalski', MailingState = 'TX', Email = 'test777777@gmail.com', Phone = '___SECRET!!!'),
			new Contact(FirstName = 'Alaska', LastName = 'Man', MailingState = 'AK', Email = 'test8888888@gmail.com', Phone = '___SECRET!!!'),
			new Contact(FirstName = 'Cowboy', LastName = 'Bob', MailingState = 'TX', Email = 'test999999@gmail.com', Phone = '___SECRET!!!')
		};
		insert contacts;
		Profile p = [SELECT Id FROM Profile WHERE Name = 'Chatter Free User'];
		populateUser(null, 'Test3', 'test3', 'test333333@gmail.com', p.Id);
		populateUser('Hej', 'Test31', 'test31', 'test3111111@gmail.com', p.Id);
		populateUser('Hejo', 'Test32', 'test32', 'test3222222@gmail.com', p.Id);
	}

	private static void populateUser(String firstName, String lastName, String alias, String email, Id profileId) {
		insert new User(
			FirstName = firstName,
			LastName = lastName,
			Alias = alias,
			ProfileId = profileId,
			Email = email,
			EmailEncodingKey = 'UTF-8',
			LanguageLocaleKey = 'en_US',
			LocaleSidKey = 'en_US',
			TimeZoneSidKey = 'America/Los_Angeles',
			Phone = '___SECRET!!!',
			Username = ContactsToUsersController.createUsername(email)
		);
	}

	@isTest
	static void testCheckContacts() {
		String s = ContactsToUsersController.checkContacts(new List<String>{ 'TX', 'NY', 'AZ', 'CA' });
		System.assert(s.contains('Users to be created'));
	}

	@isTest
	static void testCheckContactsNoNewUsers() {
		delete [SELECT Id FROM Contact];
		List<Contact> contacts = new List<Contact>{
			new Contact(LastName = 'Test3', MailingState = 'TX', Email = 'test333333@gmail.com', Phone = '___SECRET!!!'),
			new Contact(FirstName = 'Hej', LastName = 'Test31', MailingState = 'TX', Email = 'test3111111@gmail.com', Phone = '___SECRET!!!'),
			new Contact(FirstName = 'Hejo', LastName = 'Test32', MailingState = 'NY', Email = 'test3222222@gmail.com', Phone = '___SECRET!!!')
		};
		insert contacts;
		String result = ContactsToUsersController.checkContacts(new List<String>{ 'TX', 'NY', 'AZ', 'CA' });
		System.assert(result.contains('No <b>new</b> users will be created'));
		result = ContactsToUsersController.createNewUsersFromContactsByStates(new List<String>{ 'TX', 'NY', 'AZ', 'CA' });
		System.assert(result.contains('No <b>new</b> users were created<br>'));
	}

	@isTest
	static void testCreateNewUsersFromContactsByStates() {
		String s = ContactsToUsersController.createNewUsersFromContactsByStates(new List<String>{ 'TX', 'NY', 'AZ', 'CA', 'AK' });
		System.assert(s.contains('Creating users'));
		System.assertEquals(10, [SELECT Id FROM User WHERE Phone = '___SECRET!!!'].size());
	}

	@isTest
	static void testCreateNewUsersFromContactsByStatesNoContactsInState() {
		String s = ContactsToUsersController.createNewUsersFromContactsByStates(new List<String>{ 'PA' });
		System.assert(s.contains('There are no contacts in selected states'));
		Test.startTest();
		Test.stopTest();
	}
}
