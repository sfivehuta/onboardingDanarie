/**
 * Finds open opportunities that belong to the same company as a lead,
 * so users see possible duplicates before converting the lead.
 */
public with sharing class LeadOpportunityMatchController {
    private static final Integer MAX_RESULTS = 20;

    public class OpportunityMatch {
        @AuraEnabled public Id id;
        @AuraEnabled public String name;
        @AuraEnabled public String accountName;
        @AuraEnabled public String stageName;
        @AuraEnabled public Date closeDate;
        @AuraEnabled public Decimal amount;
        @AuraEnabled public String ownerName;
    }

    @AuraEnabled(cacheable=true)
    public static List<OpportunityMatch> getOpenOpportunities(Id leadId) {
        List<OpportunityMatch> matches = new List<OpportunityMatch>();
        List<Lead> leads = [
            SELECT Company, Email, Phone, Street, City, PostalCode, Website, IsConverted
            FROM Lead
            WHERE Id = :leadId
            WITH USER_MODE
        ];
        if (leads.isEmpty() || leads[0].IsConverted) {
            return matches;
        }
        Set<Id> accountIds = findMatchingAccountIds(leads[0]);
        if (accountIds.isEmpty()) {
            return matches;
        }
        for (Opportunity opp : [
            SELECT Name, Account.Name, StageName, CloseDate, Amount, Owner.Name
            FROM Opportunity
            WHERE AccountId IN :accountIds AND IsClosed = false
            WITH USER_MODE
            ORDER BY CloseDate ASC
            LIMIT :MAX_RESULTS
        ]) {
            OpportunityMatch m = new OpportunityMatch();
            m.id = opp.Id;
            m.name = opp.Name;
            m.accountName = opp.Account?.Name;
            m.stageName = opp.StageName;
            m.closeDate = opp.CloseDate;
            m.amount = opp.Amount;
            m.ownerName = opp.Owner?.Name;
            matches.add(m);
        }
        return matches;
    }

    // Accounts with the same name, accounts found by the active Account duplicate rules,
    // and accounts of contacts that share the lead's email.
    private static Set<Id> findMatchingAccountIds(Lead l) {
        Set<Id> accountIds = new Set<Id>();
        if (String.isNotBlank(l.Company)) {
            for (Account a : [SELECT Id FROM Account WHERE Name = :l.Company WITH USER_MODE LIMIT 50]) {
                accountIds.add(a.Id);
            }
            Account probe = new Account(
                Name = l.Company,
                Phone = l.Phone,
                Website = l.Website,
                BillingStreet = l.Street,
                BillingCity = l.City,
                BillingPostalCode = l.PostalCode
            );
            try {
                for (Datacloud.FindDuplicatesResult fdr : Datacloud.FindDuplicates.findDuplicates(new List<Account>{ probe })) {
                    for (Datacloud.DuplicateResult dr : fdr.getDuplicateResults()) {
                        for (Datacloud.MatchResult mr : dr.getMatchResults()) {
                            for (Datacloud.MatchRecord rec : mr.getMatchRecords()) {
                                accountIds.add(rec.getRecord().Id);
                            }
                        }
                    }
                }
            } catch (Exception e) {
                // No active Account duplicate rule: fall back to the exact name match above.
            }
        }
        if (String.isNotBlank(l.Email)) {
            for (Contact c : [
                SELECT AccountId FROM Contact
                WHERE Email = :l.Email AND AccountId != null
                WITH USER_MODE
                LIMIT 50
            ]) {
                accountIds.add(c.AccountId);
            }
        }
        return accountIds;
    }
}