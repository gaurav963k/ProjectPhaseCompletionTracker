public without sharing class ProjectTrackerService {

    public class ProgressDTO {
        @AuraEnabled public Decimal numerator;
        @AuraEnabled public Decimal denominator;
        @AuraEnabled public Decimal percent;
        @AuraEnabled public Boolean stamped;
        @AuraEnabled public Datetime stampDate;
    }

    public static Set<Id> parentOppsFromOliIds(Set<Id> oliIds){
        if (oliIds == null || oliIds.isEmpty()) return new Set<Id>();
        Set<Id> oppIds = new Set<Id>();
        for (OpportunityLineItem oli : [
            SELECT Id, OpportunityId FROM OpportunityLineItem WHERE Id IN :oliIds
        ]) {
            oppIds.add(oli.OpportunityId);
        }
        return oppIds;
    }
    
    public static void recomputeForOpportunityLineItem(Set<Id> oppIds, String reason, Set<Id> oliIds, String taskAction){
        if (oppIds == null || oppIds.isEmpty()) return;
        
        // Get all OLIs for these Opportunities
        if(taskAction=='Insert'){
            List<OpportunityLineItem> olis = [
                SELECT Id, OpportunityId,PricebookEntry.Name
                FROM OpportunityLineItem
                WHERE Id IN :oliIds
            ];
            
            List<Task> listTask = NEW List<Task>();
            FOR(OpportunityLineItem oli:olis){
                Task t = new Task(
                    Subject = oli.PricebookEntry.Name,
                    whatId = oli.OpportunityId,
                    Is_Internal_Task__c = false,
                    Opportunity_Product__c = oli.Id,
                    Status = 'Not Started',
                    ActivityDate = Date.today().addDays(10)
                );
                listTask.add(t);            
            }
            insert listTask;
        }
        
        recomputeFor(oppIds,reason,oliIds);
    }

    public static void recomputeFor(Set<Id> oppIds, String reason, Set<Id> oliIds){
        if (oppIds == null || oppIds.isEmpty()) return;
		// MAP OF opportunity Id, Opportunity
        Map<Id, Opportunity> oppMap = new Map<Id, Opportunity>([
            SELECT Id, Project_Type__c,
                   Project_80_Complete__c, Project_80_Complete_Date__c,
                   Project_Completion_History__c
            FROM Opportunity
            WHERE Id IN :oppIds
        ]);
        
        //Calculate pct map based on Opportunity Id
		Map<Id, List<Decimal>> oppIdToPctMap = new Map<Id, List<Decimal>>();

        AggregateResult[] groupedResults = [
            SELECT OpportunityId oppId,
                   SUM(Completed_Phase_Value__c) num,
                   SUM(Total_Phase_Value__c) den
            FROM OpportunityLineItem
            WHERE OpportunityId IN :oppIds
            GROUP BY OpportunityId
        ];
        
        for (AggregateResult ar : groupedResults) {
            Decimal num = (Decimal) ar.get('num');
            Decimal den = (Decimal) ar.get('den');
        	
            // Handle null values
            num = (num == null) ? 0 : num;
            den = (den == null) ? 0 : den;
        
            Decimal pct = (den == 0) ? 0 : (num / den * 100);
            oppIdToPctMap.put(
                (Id) ar.get('oppId'),
                new List<Decimal>{ pct.setScale(2), num, den }
            );
        }

		
        // Update the Opportunities
        List<Opportunity> updatesOpportunities = new List<Opportunity>();
        Datetime nowTs = Datetime.now();

        for (Id oppId : oppIds) {
            Opportunity opp = oppMap.get(oppId);
            if (opp == null) continue;
            if (opp.Project_Type__c != 'New Project') continue;

            Decimal pct = oppIdToPctMap.get(oppId)[0];
            decimal num = oppIdToPctMap.get(oppId)[1];
			decimal den = oppIdToPctMap.get(oppId)[2];
            
            String line = String.format(
                '[{0}] Reason={1}; Num={2}; Den={3}; %={4}%',
                new List<Object>{ nowTs.format(), reason, num, den, pct }
            );

            Boolean shouldStamp = (pct >= 80 && opp.Project_80_Complete__c == false);

            Opportunity upd = new Opportunity(
                Id = opp.Id,
                Project_Completion_History__c = ProjectTrackerUtil.appendLine(
                    opp.Project_Completion_History__c, line
                )
            );

            if (shouldStamp) {
                upd.Project_80_Complete__c = true;
                upd.Project_80_Complete_Date__c = nowTs;
                upd.Project_Completion_History__c = ProjectTrackerUtil.appendLine(
                    upd.Project_Completion_History__c,
                    '[STAMP] 80% threshold reached. Date=' + nowTs.format()
                );
            }
            updatesOpportunities.add(upd);
        }

        if (!updatesOpportunities.isEmpty()) update updatesOpportunities;
    }

    // Helper used by LWC to get the current progress quickly
    public static ProgressDTO getProgress(Id oppId){
        ProgressDTO dto = new ProgressDTO();
        Opportunity opp = [
            SELECT Id, Project_80_Complete__c, Project_80_Complete_Date__c, Project_Type__c
            FROM Opportunity
            WHERE Id = :oppId
            LIMIT 1
        ];
        Decimal num = 0, den = 0;
        for (OpportunityLineItem oli : [
            SELECT Total_Phase_Value__c, Completed_Phase_Value__c
            FROM OpportunityLineItem
            WHERE OpportunityId = :oppId
        ]) {
            num += (oli.Completed_Phase_Value__c == null ? 0 : oli.Completed_Phase_Value__c);
            den += (oli.Total_Phase_Value__c == null ? 0 : oli.Total_Phase_Value__c);
        }
        dto.numerator = num;
        dto.denominator = den;
        dto.percent = (den == 0) ? 0 : (num / den * 100).setScale(2);
        dto.stamped = opp.Project_80_Complete__c;
        dto.stampDate = opp.Project_80_Complete_Date__c;
        return dto;
    }
}