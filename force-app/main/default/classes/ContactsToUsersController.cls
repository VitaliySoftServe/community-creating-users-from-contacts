public with sharing class ContactsToUsersController {
    public static final String GMT_04 = 'America/New_York';
    public static final String GMT_05 = 'America/Chicago';
    public static final String GMT_06 = 'America/El_Salvador';
    public static final String GMT_07 = 'America/Los_Angeles';
    public static final String GMT_08 = 'America/Anchorage';
    public static final String USER_PROFILE_NAME = 'Chatter Free User';

    private static List<User> allExistingUsers;
    private static Set<String> allExistingUserAliases;
    private static Set<String> allExistingUserNames;
    private static Set<String> allExistingUserEmails;
    private static Id userProfileId;

    @AuraEnabled
    public static String checkContacts(List<String> states) {
        createInitialData();
        List<Contact> contacts = getContacts(states);
        List<Contact> usersToBeCreated = new List<Contact>();
        List<Contact> alreadyAssociatedContacts = new List<Contact>();
        List<Contact> contactsWithoutEmail = new List<Contact>();
        List<Contact> contactsWithAlreadyExistingEmail = new List<Contact>();
        for (Contact contact : contacts) {
            if (contact.Email != null) {
                //if (!contact.Users.isEmpty()) {
                if (
                    !allExistingUserNames.contains(
                        createUsername(contact.Email)
                    )
                ) {
                    if (!allExistingUserEmails.contains(contact.Email)) {
                        usersToBeCreated.add(contact);
                    } else {
                        contactsWithAlreadyExistingEmail.add(contact);
                    }
                } else {
                    alreadyAssociatedContacts.add(contact);
                }
            } else {
                contactsWithoutEmail.add(contact);
            }
        }
        String result = checkUsersToBeCreated(usersToBeCreated);
        result += checkUserExist(
            alreadyAssociatedContacts,
            contactsWithoutEmail,
            contactsWithAlreadyExistingEmail
        );
        return result;
    }

    @AuraEnabled
    public static String createNewUsersFromContactsByStates(
        List<String> states
    ) {
        createInitialData();

        List<Contact> contacts = getContacts(states);
        List<User> usersToCreate = new List<User>();
        List<Contact> alreadyAssociatedContacts = new List<Contact>();
        List<Contact> contactsWithoutEmail = new List<Contact>();
        List<Contact> contactsWithAlreadyExistingEmail = new List<Contact>();
        for (Contact contact : contacts) {
            if (contact.Email != null) {
                //if (!contact.Users.isEmpty()) {
                if (
                    !allExistingUserNames.contains(
                        createUsername(contact.Email)
                    )
                ) {
                    if (!allExistingUserEmails.contains(contact.Email)) {
                        usersToCreate.add(
                            new User(
                                FirstName = contact.FirstName,
                                LastName = contact.LastName,
                                ProfileId = userProfileId,
                                //ContactId = contact.Id,
                                Email = contact.Email,
                                Phone = contact.Phone,
                                Street = contact.MailingStreet,
                                City = contact.MailingCity,
                                PostalCode = contact.MailingPostalCode,
                                State = contact.MailingState,
                                Country = contact.MailingCountry,
                                Alias = createAlias(
                                    contact.FirstName,
                                    contact.LastName
                                ),
                                Username = createUsername(contact.Email),
                                TimeZoneSidKey = findTimeZone(
                                    contact.MailingState
                                ),
                                EmailEncodingKey = 'UTF-8',
                                LanguageLocaleKey = 'en_US',
                                LocaleSidKey = 'en_US'
                            )
                        );
                    } else {
                        contactsWithAlreadyExistingEmail.add(contact);
                    }
                } else {
                    alreadyAssociatedContacts.add(contact);
                }
            } else {
                contactsWithoutEmail.add(contact);
            }
        }
        String result = createUsers(usersToCreate);
        result += checkUserExist(
            alreadyAssociatedContacts,
            contactsWithoutEmail,
            contactsWithAlreadyExistingEmail
        );
        return result;
    }

    private static String checkUsersToBeCreated(
        List<Contact> usersToBeCreated
    ) {
        String result;
        if (!usersToBeCreated.isEmpty()) {
            String state = '';
            result =
                '<h4><span style="color:#004487">Users to be created (' +
                usersToBeCreated.size() +
                '):</span></h4>';
            for (Contact contact : usersToBeCreated) {
                String firstName = contact.FirstName != null
                    ? contact.FirstName
                    : '';
                if (state != contact.MailingState) {
                    if (state != '') {
                        result += '<br>';
                    }
                    state = contact.MailingState;
                    result += '<b>' + getFullStateName(state) + ':</b><br>';
                }
                result += firstName + ' ' + contact.LastName + '<br>';
            }
        } else {
            result = '<h4><span style="color:#004487">Users to be created:</span></h4>';
            result += 'No <b>new</b> users will be created<br>';
        }
        return result;
    }

    private static void createInitialData() {
        userProfileId = [
            SELECT Id, Name
            FROM Profile
            WHERE Name = :USER_PROFILE_NAME
        ]
        .Id;
        allExistingUsers = [
            SELECT Alias, UserName, Email
            FROM User
            WHERE ProfileId = :userProfileId
        ];
        allExistingUserAliases = new Set<String>();
        allExistingUserNames = new Set<String>();
        allExistingUserEmails = new Set<String>();
        for (User user : allExistingUsers) {
            allExistingUserAliases.add(user.Alias);
            allExistingUserNames.add(user.Username);
            allExistingUserEmails.add(user.Email);
        }
    }

    private static List<Contact> getContacts(List<String> states) {
        return [
            SELECT
                Id,
                (SELECT Id FROM Users),
                FirstName,
                LastName,
                Email,
                Phone,
                MailingStreet,
                MailingCity,
                MailingPostalCode,
                MailingState,
                MailingCountry
            FROM Contact
            WHERE MailingState IN :states
            ORDER BY MailingState
        ];
    }

    private static String createUsers(List<User> usersToCreate) {
        Integer userCounter = -1;
        String state = '';
        String result;
        if (!usersToCreate.isEmpty()) {
            Database.SaveResult[] srList = Database.insert(
                usersToCreate,
                false
            );
            Integer quantityOfSuccessfullyCreatedUsers = 0;
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    quantityOfSuccessfullyCreatedUsers++;
                }
            }
            String quantity = '';
            if (quantityOfSuccessfullyCreatedUsers > 0) {
                quantity = '(' + quantityOfSuccessfullyCreatedUsers + ')';
            }
            result =
                '<h4><span style="color:#004487">Creating users ' +
                quantity +
                ':</span></h4>';
            for (Database.SaveResult sr : srList) {
                userCounter++;
                if (state != usersToCreate[userCounter].State) {
                    if (state != '') {
                        result += '<br>';
                    }
                    state = usersToCreate[userCounter].State;
                    result += '<b>' + getFullStateName(state) + ':</b><br>';
                }
                String firstName = usersToCreate[userCounter].FirstName != null
                    ? usersToCreate[userCounter].FirstName
                    : '';
                if (sr.isSuccess()) {
                    result +=
                        'New User <b>' +
                        firstName +
                        ' ' +
                        usersToCreate[userCounter].LastName +
                        '</b> was successfully created<br>';
                } else {
                    result +=
                        '<span style="color:red">The following error has occurred while creating user <b>' +
                        firstName +
                        ' ' +
                        usersToCreate[userCounter].LastName +
                        ':</b></span><br>';
                    for (Database.Error err : sr.getErrors()) {
                        result +=
                            err.getStatusCode() +
                            ': ' +
                            err.getMessage() +
                            '<br>';
                        result +=
                            'Account fields that affected this error: ' +
                            err.getFields() +
                            '<br>';
                    }
                }
            }
        } else {
            result = '<h4><span style="color:#004487">Creating users:</span></h4>';
            result += 'No <b>new</b> users were created<br>';
        }
        return result;
    }

    private static String createAlias(String FirstName, String LastName) {
        String lName = lastName.length() >= 4
            ? LastName.toLowerCase().substring(0, 4)
            : LastName.toLowerCase();
        String fName = String.isBlank(FirstName)
            ? ''
            : FirstName.toLowerCase().substring(0, 1);
        String alias = fName + lName;
        if (allExistingUserAliases.contains(alias)) {
            Set<Integer> sameAliasesDigitsSet = new Set<Integer>();
            for (String a : allExistingUserAliases) {
                if (a.contains(alias) && a.remove(alias).trim().isNumeric()) {
                    sameAliasesDigitsSet.add(
                        Integer.valueOf(a.remove(alias).trim())
                    );
                }
            }
            List<Integer> sameAliasesDigitsList = new List<Integer>(
                sameAliasesDigitsSet
            );
            sameAliasesDigitsList.sort();
            for (Integer i = 1; i <= sameAliasesDigitsList.size() + 1; i++) {
                if (sameAliasesDigitsList.contains(i)) {
                    continue;
                } else {
                    alias += String.valueOf(i);
                    break;
                }
            }
        }
        allExistingUserAliases.add(alias);
        return alias;
    }

    private static String createUsername(String email) {
        String baseURL = URL.getSalesForceBaseUrl().getHost();
        String sandboxName = baseURL.substringBefore('.');
        Boolean isTestSandBox = sandboxName.containsIgnoreCase('--');
        if (isTestSandBox) {
            sandboxName = sandboxName.replace('--', '.');
        }
        return email + '.' + sandboxName;
    }

    private static String findTimeZone(String state) {
        state = state.toUpperCase();
        switch on state {
            when 'CT',
                'CONNECTICUT',
                'DC',
                'WASHINGTON, D.C.',
                'DISTRICT OF COLUMBIA',
                'DE',
                'DELAWARE',
                'FL',
                'FLORIDA',
                'GA',
                'GEORGIA',
                'IN',
                'INDIANA',
                'KY',
                'KENTUCKY',
                'MA',
                'MASSACHUSETTS',
                'MD',
                'MARYLAND',
                'ME',
                'MAINE',
                'MI',
                'MICHIGAN',
                'NC',
                'NORTH CAROLINA',
                'NEW HAMPSHIRE',
                'NJ',
                'NEW JERSEY',
                'NH',
                'NY',
                'NEW YORK',
                'OH',
                'OHIO',
                'PA',
                'PENNSYLVANIA',
                'RI',
                'RHODE ISLAND',
                'SC',
                'SOUTH CAROLINA',
                'VA',
                'VIRGINIA',
                'VERMONT',
                'VT',
                'WV',
                'WEST VIRGINIA' {
                return GMT_04;
            }
            when 'AL',
                'ALABAMA',
                'AR',
                'ARKANSAS',
                'IL',
                'ILLINOIS',
                'IA',
                'IOWA',
                'KS',
                'KANZAS',
                'LA',
                'LOUISIANA',
                'MN',
                'MINNESOTA',
                'MS',
                'MISSISSIPPI',
                'MO',
                'MISSOURI',
                'NE',
                'NEBRASKA',
                'ND',
                'NORTH DAKOTA',
                'OK',
                'OKLAHOMA',
                'SD',
                'SOUTH DAKOTA',
                'TN',
                'TENNESSEE',
                'TX',
                'TEXAS',
                'WI',
                'WISCONSIN' {
                return GMT_05;
            }
            when 'AZ',
                'ARIZONA',
                'CO',
                'COLORADO',
                'ID',
                'IDAHO',
                'MT',
                'MONTANA',
                'NM',
                'NEW MEXICO',
                'UT',
                'UTAH',
                'WY',
                'WYOMING' {
                return GMT_06;
            }
            when 'CA',
                'CALIFORNIA',
                'NV',
                'NEVADA',
                'OR',
                'OREGON',
                'WA',
                'WASHINGTON' {
                return GMT_07;
            }
            when 'AK', 'ALASKA' {
                return GMT_08;
            }
            when else {
                return GMT_04;
            }
        }
    }

    private static String getFullStateName(String state) {
        Map<String, String> states = new Map<String, String>{
            'AL' => 'Alabama (AL)',
            'AK' => 'Alaska (AK)',
            'AZ' => 'Arizona (AZ)',
            'AR' => 'Arkansas (AR)',
            'CA' => 'California (CA)',
            'CO' => 'Colorado (CO)',
            'CT' => 'Connecticut (CT)',
            'DE' => 'Delaware (DE)',
            'DC' => 'District of Columbia (DC)',
            'GA' => 'Florida (GA)',
            'FL' => 'Georgia (FL)',
            'ID' => 'Idaho (ID)',
            'IL' => 'Illinois (IL)',
            'IN' => 'Indiana (IN)',
            'IA' => 'Iowa (IA)',
            'KS' => 'Kansas (KS)',
            'KY' => 'Kentucky (KY)',
            'LA' => 'Louisiana (LA)',
            'ME' => 'Maine (ME)',
            'MD' => 'Maryland (MD)',
            'MA' => 'Massachusetts (MA)',
            'MI' => 'Michigan (MI)',
            'MN' => 'Minnesota (MN)',
            'MS' => 'Mississippi (MS)',
            'MO' => 'Missouri (MO)',
            'MT' => 'Montana (MT)',
            'NE' => 'Nebraska (NE)',
            'NV' => 'Nevada (NV)',
            'NH' => 'New Hampshire (NH)',
            'NJ' => 'New Jersey (NJ)',
            'NY' => 'New York (NY)',
            'NC' => 'North Carolina (NC)',
            'ND' => 'North Dakota (ND)',
            'OH' => 'Ohio (OH)',
            'OK' => 'Oklahoma (OK)',
            'OR' => 'Oregon (OR)',
            'PA' => 'Pennsylvania (PA)',
            'RI' => 'Rhode Island (RI)',
            'SC' => 'South Carolina (SC)',
            'SD' => 'South Dakota (SD)',
            'TN' => 'Tennessee (TN)',
            'TX' => 'Texas (TX)',
            'UT' => 'Utah (UT)',
            'VT' => 'Vermont (VT)',
            'VA' => 'Virginia (VA)',
            'WA' => 'Washington (WA)',
            'WV' => 'West Virginia (WV)',
            'WI' => 'Wisconsin (WI)',
            'WY' => 'Wyoming (WY)'
        };
        return states.get(state);
    }

    private static String checkUserExist(
        List<Contact> alreadyAssociatedContacts,
        List<Contact> contactsWithoutEmail,
        List<Contact> contactsWithAlreadyExistingEmail
    ) {
        String resultCheckContacts = checkAlreadyAssociatedContacts(
            alreadyAssociatedContacts
        );
        resultCheckContacts += checkContactsWithoutEmail(contactsWithoutEmail);
        resultCheckContacts += checkContactsWithAlreadyExistingEmail(
            contactsWithAlreadyExistingEmail
        );
        return resultCheckContacts == ''
            ? 'There are no contacts in selected states'
            : resultCheckContacts;
    }

    private static String checkAlreadyAssociatedContacts(
        List<Contact> alreadyAssociatedContacts
    ) {
        String result;
        if (!alreadyAssociatedContacts.isEmpty()) {
            Map<String, Integer> usersQuantityByStates = new Map<String, Integer>();
            for (Contact contact : alreadyAssociatedContacts) {
                if (!usersQuantityByStates.containsKey(contact.MailingState)) {
                    usersQuantityByStates.put(contact.MailingState, 1);
                } else {
                    Integer temp = usersQuantityByStates.get(
                        contact.MailingState
                    );
                    temp++;
                    usersQuantityByStates.put(contact.MailingState, temp);
                }
            }
            result =
                '<br><h4><span style="color:#004487">Following users in selected states are already exist and associated with Contacts (' +
                alreadyAssociatedContacts.size() +
                '):</span></h4>';
            String state = '';
            //Integer counter=0;
            for (Contact contact : alreadyAssociatedContacts) {
                String firstName = contact.FirstName != null
                    ? contact.FirstName
                    : '';
                if (state != contact.MailingState) {
                    if (state != '') {
                        result += '<br>';
                    }
                    state = contact.MailingState;
                    result +=
                        '<b>' +
                        getFullStateName(state) +
                        '</b> - [' +
                        usersQuantityByStates.get(state) +
                        ']<b>:</b><br>';
                }
                result += firstName + ' ' + contact.LastName + '<br>';
            }
        }
        return result != null ? result : '';
    }

    private static String checkContactsWithoutEmail(
        List<Contact> contactsWithoutEmail
    ) {
        String result;
        if (!contactsWithoutEmail.isEmpty()) {
            result =
                '<br><h4><span style="color:red">Following users in selected states could not be created due to lack of email (' +
                contactsWithoutEmail.size() +
                '):</span></h4>';
            for (Contact contact : contactsWithoutEmail) {
                String firstName = contact.FirstName != null
                    ? contact.FirstName
                    : '';
                result += firstName + ' ' + contact.LastName + '<br>';
            }
        }
        return result != null ? result : '';
    }

    private static String checkContactsWithAlreadyExistingEmail(
        List<Contact> contactsWithAlreadyExistingEmail
    ) {
        System.debug(contactsWithAlreadyExistingEmail);
        String result;
        if (!contactsWithAlreadyExistingEmail.isEmpty()) {
            result =
                '<br><h4><span style="color:red">Following contacts already have their email associated with created user (' +
                contactsWithAlreadyExistingEmail.size() +
                '):</span></h4>';
            for (Contact contact : contactsWithAlreadyExistingEmail) {
                String firstName = contact.FirstName != null
                    ? contact.FirstName
                    : '';
                result += firstName + ' ' + contact.LastName + '<br>';
            }
        }
        return result != null ? result : '';
    }
}
