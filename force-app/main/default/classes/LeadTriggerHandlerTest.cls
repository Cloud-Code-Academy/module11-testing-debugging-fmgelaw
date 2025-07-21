@isTest
public with sharing class LeadTriggerHandlerTest {
    @testSetup
    static void setupData() {
        // Create a common Account for the Contact
        Account acct = new Account(Name = 'Test Account');
        insert acct;

        // Create a Contact that matches lead email
        Contact c = new Contact(
            FirstName = 'Match',
            LastName = 'Contact',
            Email = 'match@example.com',
            AccountId = acct.Id
        );
        insert c;
    }
    @isTest
    static void testhandleTitleNormalization_VicePresident() {
        Lead l1 = new Lead(LastName='Laa', Company='A', Title='vp');
        Lead l2 = new Lead(LastName='Baa', Company='B', Title='vice president of sales');
        Lead l3 = new Lead(LastName='Caa', Company='C', Title='v.p. of sales');
        
        List<Lead> leads = new List<Lead>{ l1, l2, l3 };
       // LeadTriggerHandler.handleTitleNormalization(leads);
        insert leads;

        List<Lead> insertedLeads = [SELECT Id, Title FROM Lead WHERE Id IN :leads];
        for (Lead l : insertedLeads) {
            Assert.areEqual('Vice President', l.Title, 'Actual Title is different than Vice President');
        }
    }
    @isTest
    static void testhandleTitleNormalization_Manager() {
        Lead l1 = new Lead(LastName='Laa', Company='A', Title='head of department');
        Lead l2 = new Lead(LastName='Baa', Company='B', Title='manager');
        Lead l3 = new Lead(LastName='Caa', Company='C', Title='sales mgr');
        
        List<Lead> leads = new List<Lead>{ l1, l2, l3 };
        //LeadTriggerHandler.handleTitleNormalization(leads);
        insert leads;

        List<Lead> insertedLeads = [SELECT Id, Title FROM Lead WHERE Id IN :leads];
        for (Lead l : insertedLeads) {
            Assert.areEqual('Manager', l.Title, 'Actual Title is different than Manager');
        }
    }
    @isTest
    static void testhandleTitleNormalization_Executive() {
        Lead l1 = new Lead(LastName='Laa', Company='A', Title='chief');
        Lead l2 = new Lead(LastName='Baa', Company='B', Title='executive director');
        Lead l3 = new Lead(LastName='Caa', Company='C', Title='head');
        
        List<Lead> leads = new List<Lead>{ l1, l2, l3};
        //LeadTriggerHandler.handleTitleNormalization(leads);
        
        insert leads;

        List<Lead> insertedLeads = [SELECT Id, Title FROM Lead WHERE Id IN :leads];
        for (Lead l : insertedLeads) {
           Assert.areEqual('Executive', l.Title, 'Actual Title is different than Executive');
        }
    }
    @isTest
    static void testhandleTitleNormalization_Assistant() {
        Lead l1 = new Lead(LastName='Laa', Company='A', Title='assistant officer');
        Lead l2 = new Lead(LastName='Baa', Company='B', Title='deputy director');
        Lead l3 = new Lead(LastName='Caa', Company='C', Title='jr');
        
        List<Lead> leads = new List<Lead>{ l1, l2, l3};
        //LeadTriggerHandler.handleTitleNormalization(leads);
        List<Lead> insertedLeads = [SELECT Id, Title FROM Lead WHERE Id IN :leads];
        for (Lead l : insertedLeads) {
           Assert.areEqual('Assistant', l.Title, 'Actual Title is different than assistant');
        }
    }
    @isTest
    static void testhandleTitleNormalization_titleupdate() {
        Lead l = new Lead(LastName='Laa', Company='A', Title='ceo');

        insert l;

        l.Title = 'jr';

        update l;

        List<Lead> updatedLeads = [SELECT Id, Title FROM Lead WHERE Id = :l.Id LIMIT 1];
        Lead updatedLead;
        if (!updatedLeads.isEmpty()) {
            updatedLead = updatedLeads[0];
        }
        
        Assert.areEqual('Assistant', updatedLead.Title, 'Actual Title is different than assistant');
        
    }
    //negative test 
    @isTest
    static void testhandleTitleNormalization_negative() {
        Lead l1 = new Lead(LastName='Laa', Company='A', Title='ceo');
        Lead l2 = new Lead(LastName='Baa', Company='B', Title='sales director');
        Lead l3 = new Lead(LastName='Caa', Company='C', Title='sr');
        
        List<Lead> leads = new List<Lead>{ l1, l2, l3};
        LeadTriggerHandler.handleTitleNormalization(leads);
        
        for (Lead l : leads) {
            Assert.areNotEqual('Assistant', l.Title, 'Title is Assistant when it shouldn\'t be');
            Assert.areNotEqual('Executive', l.Title, 'Title is Executive when it shouldn\'t be');
            Assert.areNotEqual('Manager', l.Title, 'Title is Manager when it shouldn\'t be');
            Assert.areNotEqual('Vice President', l.Title, 'Title is Vice President when it shouldn\'t be');
        }
    }
    @isTest
    static void testHandleAutoLeadScoring() {
        // Create test leads with various combinations
        Lead lead1 = new Lead(
            FirstName = 'John',
            LastName = 'Doe',
            Title='ceo',
            Company = 'Example Inc',
            LeadSource = 'Website',
            Email = 'john.doe@example.com',
            Phone = null,
            Industry = 'Finance'
        ); // score 13 (10 + 3)

        Lead lead2 = new Lead(
            FirstName = 'Jane',
            LastName = 'Smith',
            Title='ceo',
            Company = 'Other Corp',
            LeadSource = 'Website',
            Email = 'john.doe@example.com',
            Phone = '1234567890',
            Industry = 'Finance'
        ); // Score 18 (10 + 3 + 5)

        Lead lead3 = new Lead(
            FirstName = 'Jane',
            LastName = 'Smith',
            Title='ceo',
            Company = 'Other Corp',
            LeadSource = 'Website',
            Email = null,
            Phone = '1234567890',
            Industry = 'Finance'
        ); // Score 15 (10 + 5)

        Lead lead4 = new Lead(
            FirstName = 'Mike',
            LastName = 'Lee',
            Title='ceo',
            Company = 'TechCorp',
            LeadSource = 'Website',
            Email = null,
            Phone = null,
            Industry = 'Technology'
        ); // score 18 (10 + 10)
        //negative
       Lead lead5 = new Lead(
            FirstName = 'Mike',
            LastName = 'Lee',
            Title='ceo',
            Company = 'TechCorp',
            LeadSource = 'Website',
            Email = null,
            Phone = null,
            Industry = 'Finance'
        ); // score (10)
        
        List<Lead> leadsList = new List<Lead>{lead1, lead2, lead3, lead4, lead5};
        Test.startTest();
        LeadTriggerHandler.handleAutoLeadScoring(leadsList);
        Test.stopTest();

        // Validate scores
        System.assertEquals(13, leadsList[0].Lead_Score__c, 'Lead 1 should score 13');
        System.assertEquals(18, leadsList[1].Lead_Score__c, 'Lead 2 should score 0');
        System.assertEquals(15, leadsList[2].Lead_Score__c, 'Lead 3 should score 15');
        System.assertEquals(18, leadsList[3].Lead_Score__c, 'Lead 3 should score 18');
        System.assertEquals(10, leadsList[4].Lead_Score__c, 'Lead 3 should score 10');
    }
    @isTest
    static void testLeadInsertedWithMatchingContact() {

        Lead l = new Lead(
            FirstName = 'Auto',
            LastName = 'Convert',
            Company = 'Test Co',
            title = 'ceo',
            Email = 'match@example.com' // Matches setup Contact
        );
        Test.startTest();
        insert l;
        Test.stopTest();

        // Refresh lead from DB to check converted
        Lead convertedLead = [SELECT Id, IsConverted, ConvertedContactId FROM Lead WHERE Id = :l.Id LIMIT 1];
        System.assertEquals(true, convertedLead.IsConverted, 'Lead should have been auto-converted');
        System.assertNotEquals(null, convertedLead.ConvertedContactId, 'Lead should be linked to a Contact');
    }
    @isTest
    static void testLeadInsertedWithNoMatchingContact() {
        Lead l = new Lead(
            FirstName = 'No',
            LastName = 'Match',
            Company = 'Test Co',
            title = 'ceo',
            Email = 'nomatch@example.com'
        );
        Test.startTest();
        insert l;
        Test.stopTest();

        Lead y = [SELECT Id, IsConverted FROM Lead WHERE Id = :l.Id];
        System.assertEquals(false, y.IsConverted, 'Lead should not be converted');
    }
    @isTest
    static void testLeadEmailUpdatedToMatchContact() {
        // Insert with non-matching email
        Lead l = new Lead(
            FirstName = 'Updater',
            LastName = 'Lead',
            Company = 'Test Co',
            title = 'ceo',
            Email = 'somethingelse@example.com'
        );
        insert l;

        // Simulate email update
        Lead updated = new Lead(
            Id = l.Id,
            Email = 'match@example.com'
        );

        Map<Id, Lead> oldMap = new Map<Id, Lead>{ l.Id => l };
        Test.startTest();
        update updated; // Assumes logic is in trigger on update
        Test.stopTest();

        updated = [SELECT Id, IsConverted, ConvertedContactId FROM Lead WHERE Id = :l.Id];
        System.assertEquals(true, updated.IsConverted, 'Lead should have been converted after email update');
        System.assertNotEquals(null, updated.ConvertedContactId, 'Lead should be linked to a Contact');
    }
}