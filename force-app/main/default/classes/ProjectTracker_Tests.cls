@IsTest
private class ProjectTracker_Tests {
   
    @testSetup
    static void setupTestData() {
        // Activate a Pricebook
        Pricebook2 standardPb = new Pricebook2(Name = 'Standard Pricebook', IsActive = true);
        insert standardPb;
    
        // 2. Create Product
        Product2 prod = new Product2(Name = 'Test Product', IsActive = true);
        insert prod;
    
        // Create a Standard Price Book Entry (Required)
        Id standardPricebookId = Test.getStandardPricebookId();
        
        PricebookEntry standardPbe = new PricebookEntry(
            Pricebook2Id = standardPricebookId,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert standardPbe;
    
        // 5. PricebookEntry in custom Pricebook
        PricebookEntry pbe = new PricebookEntry(
            Pricebook2Id = standardPb.Id,
            Product2Id = prod.Id,
            UnitPrice = 100,
            IsActive = true
        );
        insert pbe;
    
        // 6. Create Opportunity
        Opportunity opp = new Opportunity(
            Name = 'Test Opportunity',
            StageName = 'Prospecting',
            CloseDate = Date.today().addDays(30)
        );
        insert opp;
    
        // 7. Create OpportunityLineItem
        OpportunityLineItem oli = new OpportunityLineItem(
            OpportunityId = opp.Id,
            Quantity = 1,
            UnitPrice = 100,
            PricebookEntryId = pbe.Id
        );
        insert oli;
    
        // 8. Create Task
        Task t = new Task(
            Subject = 'Initial Task',
            Status = 'Not Started',
            ActivityDate = Date.today().addDays(5),
            WhatId = opp.Id,
            Opportunity_Product__c = oli.Id,
            Is_Internal_Task__c = true
        );
        insert t;
    }


    @isTest
    static void testGetTasksForOpportunity() {
        Opportunity opp = [SELECT Id FROM Opportunity LIMIT 1];

        Test.startTest();
        ProjectTaskController.TaskViewDTO dto = ProjectTaskController.getTasksForOpportunity(opp.Id);
        Test.stopTest();

        System.assertNotEquals(null, dto, 'DTO should not be null');
        System.assert(dto.rows.size() > 0, 'There should be at least one task row');
        System.assertNotEquals(null, dto.progress, 'Progress DTO should not be null');
    }

    @isTest
    static void testUpdateTasks() {
        Task existingTask = [SELECT Id, Status FROM Task LIMIT 1];
        existingTask.Status = 'Completed';

        Test.startTest();
        List<ProjectTaskController.TaskRowDTO> updatedRows =
            ProjectTaskController.updateTasks(new List<Task>{ existingTask });
        Test.stopTest();

        System.assertEquals(1, updatedRows.size(), 'One task row should be returned');
        System.assertEquals('Completed', updatedRows[0].status, 'Task status should be updated');
    }
}