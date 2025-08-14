public with sharing class ProjectTaskController {
    public class TaskRowDTO {
        @AuraEnabled public Id id;
        @AuraEnabled public String subject;
        @AuraEnabled public String status;
        @AuraEnabled public Date dueDate;
        @AuraEnabled public Decimal contributedValue;
        @AuraEnabled public Boolean isInternal;
        @AuraEnabled public String oliName;
        @AuraEnabled public Id oliId; // OLI Id
    }
    public class TaskViewDTO {
        @AuraEnabled public List<TaskRowDTO> rows;
        @AuraEnabled public ProjectTrackerService.ProgressDTO progress;
    }

    @AuraEnabled(cacheable=true)
    public static TaskViewDTO getTasksForOpportunity(Id opportunityId){
        TaskViewDTO dto = new TaskViewDTO();
        dto.rows = new List<TaskRowDTO>();

        // collect OLI ids for this opportunity
        Map<Id, String> oliIdToName = new Map<Id, String>();
        for (OpportunityLineItem oli : [
            SELECT Id, PricebookEntry.Name
            FROM OpportunityLineItem
            WHERE OpportunityId = :opportunityId
        ]) {
            oliIdToName.put(oli.Id, oli.PricebookEntry != null ? oli.PricebookEntry.Name : String.valueOf(oli.Id));
        }

        if (!oliIdToName.isEmpty()) {
            for (Task t : [
                SELECT Id, Subject, Status, ActivityDate, Contributed_Value__c, Is_Internal_Task__c, Opportunity_Product__c
                FROM Task
                WHERE Opportunity_Product__c IN :oliIdToName.keySet()
                ORDER BY CreatedDate DESC
                LIMIT 5000
            ]) {
                TaskRowDTO row = new TaskRowDTO();
                row.id = t.Id;
                row.subject = t.Subject;
                row.status = t.Status;
                row.dueDate = t.ActivityDate;
                row.contributedValue = t.Contributed_Value__c;
                row.isInternal = t.Is_Internal_Task__c;
                row.oliId= t.Opportunity_Product__c;
                row.oliName = oliIdToName.get(t.Opportunity_Product__c);
                dto.rows.add(row);
            }
        }

        dto.progress = ProjectTrackerService.getProgress(opportunityId);
        return dto;
    }

    @AuraEnabled
    public static List<TaskRowDTO> updateTasks(List<Task> tasks){
        if (tasks == null || tasks.isEmpty()) return new List<TaskRowDTO>();

        if(!tasks.isEmpty()){

            Boolean hasStatus = false;
            for (Task t : tasks) {
                if (String.isNotBlank(t.Status)) {
                    hasStatus = true;
                    break; // Found one, no need to keep checking
                }
            }
            if(hasStatus){
                update tasks;
            }else{
                SET<Id> oliIds = new SET<Id>();
                Decimal totalPhaseValue = 0;
                Decimal contributedValue = 0;
                SET<Id> taskIds = new SET<Id>();

                for(Task tk:tasks){
                    taskIds.add(tk.Id);
                    contributedValue += tk.Contributed_Value__c;
                }
                system.debug('Task Ids'+taskIds);
                for(Task tk:[SELECT Opportunity_Product__c, Contributed_Value__c from Task where Id IN :taskIds]){
                    oliIds.add(tk.Opportunity_Product__c);
                }
                system.debug('Opportunity Line Item Ids'+oliIds);
                // Sum phase values for related OLIs
                for (OpportunityLineItem oli : [
                    SELECT Total_Phase_Value__c 
                    FROM OpportunityLineItem 
                    WHERE Id IN :oliIds
                ]) {
                    totalPhaseValue += oli.Total_Phase_Value__c;
                }

                // Validation check
                if (contributedValue <= totalPhaseValue) {
                    update tasks;
                } else {
                    // Throw exception to be handled in LWC
                    throw new AuraHandledException(
                        'Total Contributed Value (' + contributedValue + 
                        ') cannot be greater than Total Phase Value (' + totalPhaseValue + ').'
                    );
                }
            }
        }
            
        
        // Return fresh rows for changed tasks
        Set<Id> ids = new Set<Id>();
        for (Task t : tasks) ids.add(t.Id);

        // Map OLI names for these tasks
        Map<Id, String> oliName = new Map<Id, String>();
        for (Task t : [SELECT Id, Opportunity_Product__c FROM Task WHERE Id IN :ids]) {
            if (t.Opportunity_Product__c != null) oliName.put(t.Id, fetchOliName(t.Opportunity_Product__c));
        }

        List<TaskRowDTO> result = new List<TaskRowDTO>();
        for (Task t : [
            SELECT Id, Subject, Status, ActivityDate, Contributed_Value__c, Is_Internal_Task__c, Opportunity_Product__c
            FROM Task
            WHERE Id IN :ids
        ]) {
            TaskRowDTO row = new TaskRowDTO();
            row.id = t.Id;
            row.subject = t.Subject;
            row.status = t.Status;
            row.dueDate = t.ActivityDate;
            row.contributedValue = t.Contributed_Value__c;
            row.isInternal = t.Is_Internal_Task__c;
            row.oliId = t.Opportunity_Product__c;
            row.oliName = (t.Opportunity_Product__c != null) ? fetchOliName(t.Opportunity_Product__c) : null;
            result.add(row);
        }
        return result;
    }

    private static String fetchOliName(Id oliId){
        OpportunityLineItem oli = [
            SELECT PricebookEntry.Name
            FROM OpportunityLineItem
            WHERE Id = :oliId
            LIMIT 1
        ];
        return (oli.PricebookEntry != null) ? oli.PricebookEntry.Name : String.valueOf(oliId);
    }
}