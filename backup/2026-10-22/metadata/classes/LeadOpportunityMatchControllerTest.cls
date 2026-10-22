@IsTest
private class LeadOpportunityMatchControllerTest {
    @TestSetup
    static void setup() {
        Account acc = newAccount('Zzyx Test Holdings');
        Account other = newAccount('Unrelated Test Account');
        insert new List<Account>{ acc, other };
        insert new Contact(LastName = 'Buyer', Email = 'buyer@zzyx-other.example', AccountId = other.Id);
        String openStage = [SELECT ApiName FROM OpportunityStage WHERE IsActive = true AND IsClosed = false ORDER BY SortOrder LIMIT 1].ApiName;
        String wonStage = [SELECT ApiName FROM OpportunityStage WHERE IsActive = true AND IsWon = true LIMIT 1].ApiName;
        insert new List<Opportunity>{
            newOpportunity('Open Opp', acc.Id, openStage, Date.today().addDays(30)),
            newOpportunity('Won Opp', acc.Id, wonStage, Date.today()),
            newOpportunity('Email Opp', other.Id, openStage, Date.today().addDays(10))
        };
    }

    private static Account newAccount(String name) {
        return new Account(Name = name, Business_Partner_Role__c = 'Prospect', Business_Segments__c = 'Aerospace');
    }

    private static Opportunity newOpportunity(String name, Id accountId, String stage, Date closeDate) {
        return new Opportunity(
            Name = name,
            AccountId = accountId,
            StageName = stage,
            CloseDate = closeDate,
            Competitors__c = firstActiveValue(Opportunity.Competitors__c)
        );
    }

    // Picklist values change in this org, so pick a valid one at runtime
    private static String firstActiveValue(Schema.SObjectField field) {
        for (Schema.PicklistEntry pe : field.getDescribe().getPicklistValues()) {
            if (pe.isActive()) {
                return pe.getValue();
            }
        }
        return null;
    }

    private static Id newLead(String company, String email) {
        Lead l = new Lead(
            LastName = 'Tester',
            Company = company,
            Email = email,
            Business_Partner_Role__c = 'Prospect',
            Business_Segments__c = 'Aerospace'
        );
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        Database.insert(l, dml);
        return l.Id;
    }

    @IsTest
    static void returnsOnlyOpenOpportunitiesForSameCompany() {
        Id leadId = newLead('Zzyx Test Holdings', null);
        Test.startTest();
        List<LeadOpportunityMatchController.OpportunityMatch> result = LeadOpportunityMatchController.getOpenOpportunities(leadId);
        Test.stopTest();
        Assert.areEqual(1, result.size(), 'Only the open opportunity should match');
        Assert.areEqual('Open Opp', result[0].name);
        Assert.areEqual('Zzyx Test Holdings', result[0].accountName);
    }

    @IsTest
    static void matchesViaContactEmail() {
        Id leadId = newLead('Some New Company', 'buyer@zzyx-other.example');
        List<LeadOpportunityMatchController.OpportunityMatch> result = LeadOpportunityMatchController.getOpenOpportunities(leadId);
        Assert.areEqual(1, result.size());
        Assert.areEqual('Email Opp', result[0].name);
    }

    @IsTest
    static void returnsNothingWithoutMatch() {
        Id leadId = newLead('Qwvx Nonexistent Ltd', null);
        Assert.areEqual(0, LeadOpportunityMatchController.getOpenOpportunities(leadId).size());
    }

    @IsTest
    static void returnsNothingForConvertedLead() {
        Id leadId = newLead('Zzyx Test Holdings', null);
        Database.LeadConvert lc = new Database.LeadConvert();
        lc.setLeadId(leadId);
        lc.setDoNotCreateOpportunity(true);
        lc.setConvertedStatus([SELECT ApiName FROM LeadStatus WHERE IsConverted = true LIMIT 1].ApiName);
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.allowSave = true;
        Database.convertLead(lc, dml);
        Assert.areEqual(0, LeadOpportunityMatchController.getOpenOpportunities(leadId).size());
    }
}