/**
* ExampleRatingCalloutTest.cls
* Created By: Florian Hoehn
* Created On: January 18th, 2017
* Description: Test class for ExampleRatingCallout
**/
@isTest
private class ExampleRatingCalloutTest {
    private static String expectedResponseBodySuccess = '{"success":true,"errors":[],"accountId":"{0}","accountRating":"{1}"}';
    private static String expectedResponseBodyFailureNoErrorDefined = '{"success":false,"errors":[]}';
    private static String expectedResponseBodyFailure = '{"success":false,"errors":[{"errorCode":"{0}","message":"{1}"}]}';

    /**
    * @description setup test data for this class
    */
    @testSetup
    private static void setupTestData() {
        Account testAccount = new Account(
            Name = 'Test Account',
            Type = 'Test Type',
            AnnualRevenue = 500000
        );
        insert testAccount;

        Opportunity testOpportunity = new Opportunity(
            AccountId = testAccount.Id,
            Name = 'Test Opportunity',
            StageName = 'Test StageName',
            Amount = 100000,
            CloseDate = System.today() + 1
        );
        insert testOpportunity;
    }

    /**
    * @description tests making a successful callout
    */
    @isTest private static void it_should_DoACalloutWithReturnedRating() {
        Account expectedAccount = [SELECT Id, Name, Type, AnnualRevenue, Rating,
                                          (SELECT Id, Name, Amount, StageName FROM Opportunities)
                                     FROM Account
                                    LIMIT 1];
        String expectedRating = 'Test Account Rating';
        expectedResponseBodySuccess = expectedResponseBodySuccess.replace('{0}', expectedAccount.Id);
        expectedResponseBodySuccess = expectedResponseBodySuccess.replace('{1}', expectedRating);
        RestMock responseMock = new RestMock(
            200,
            'SUCCESS',
            expectedResponseBodySuccess,
            new Map<String, String> {'Content-Type' => 'application/json'}
        );
        Test.setMock(HttpCalloutMock.class, responseMock);

        Test.startTest();
            ExampleRatingCallout actualRestCallout = new ExampleRatingCallout(expectedAccount);
            actualRestCallout.sendAccountToRatingEngine();
        Test.stopTest();

        Account actualAccount = [SELECT Id, Rating FROM Account WHERE Id = :expectedAccount.Id];
        System.assertEquals(expectedRating, actualAccount.Rating);
        Rest_Log__c actuallog = [SELECT Id, Status__c FROM Rest_Log__c];
        System.assertNotEquals(null, actualLog.Id);
        System.assertEquals(RestLogBuilder.STATUS_SUCCESS, actualLog.Status__c);
    }

    /**
    * @description tests making a successful callout via the invoker (process builder)
    */
    @isTest private static void it_should_DoACalloutByInvokerWithReturnedRating() {
        Account expectedAccount = [SELECT Id, Name, Type, AnnualRevenue, Rating,
                                          (SELECT Id, Name, Amount, StageName FROM Opportunities)
                                     FROM Account
                                    LIMIT 1];
        String expectedRating = 'Test Account Rating';
        expectedResponseBodySuccess = expectedResponseBodySuccess.replace('{0}', expectedAccount.Id);
        expectedResponseBodySuccess = expectedResponseBodySuccess.replace('{1}', expectedRating);
        RestMock responseMock = new RestMock(
            200,
            RestLogBuilder.STATUS_SUCCESS,
            expectedResponseBodySuccess,
            new Map<String, String> {'Content-Type' => 'application/json'}
        );
        Test.setMock(HttpCalloutMock.class, responseMock);

        Test.startTest();
            ExampleRatingCallout.sendAccountsToRatingEngine(new List<Id> {expectedAccount.Id});
        Test.stopTest();

        Account actualAccount = [SELECT Id, Rating FROM Account WHERE Id = :expectedAccount.Id];
        System.assertEquals(expectedRating, actualAccount.Rating);
        Rest_Log__c actuallog = [SELECT Id, Status__c FROM Rest_Log__c];
        System.assertNotEquals(null, actualLog.Id);
        System.assertEquals(RestLogBuilder.STATUS_SUCCESS, actualLog.Status__c);
    }

    /**
    * @description tests making a failed callout
    */
    @isTest private static void it_should_DoACalloutWithErrorReturned() {
        Account expectedAccount = [SELECT Id, Name, Type, AnnualRevenue, Rating,
                                          (SELECT Id, Name, Amount, StageName FROM Opportunities)
                                     FROM Account
                                    LIMIT 1];
        String expectedErrorCode = 'Test Code';
        String expectedMessage = 'Test Message';
        expectedResponseBodyFailure = expectedResponseBodyFailure.replace('{0}', expectedErrorCode);
        expectedResponseBodyFailure = expectedResponseBodyFailure.replace('{1}', expectedMessage);
        RestMock responseMock = new RestMock(
            200,
            RestLogBuilder.STATUS_FAILURE,
            expectedResponseBodyFailure,
            new Map<String, String> {'Content-Type' => 'application/json'}
        );
        Test.setMock(HttpCalloutMock.class, responseMock);

        Test.startTest();
            ExampleRatingCallout actualRestCallout = new ExampleRatingCallout(expectedAccount);
            actualRestCallout.sendAccountToRatingEngine();
        Test.stopTest();

        Rest_Log__c actuallog = [SELECT Id, Status__c, Error_Code__c, Message__c FROM Rest_Log__c];
        System.assertNotEquals(null, actualLog.Id);
        System.assertEquals(expectedErrorCode, actualLog.Error_Code__c);
        System.assertEquals(expectedMessage, actualLog.Message__c);
        System.assertEquals(RestLogBuilder.STATUS_FAILURE, actualLog.Status__c);
    }

    /**
    * @description tests making a failed callout without error message being sent by endpoint
    */
    @isTest private static void it_should_DoACalloutWithStandardErrorReturned() {
        Account expectedAccount = [SELECT Id, Name, Type, AnnualRevenue, Rating,
                                          (SELECT Id, Name, Amount, StageName FROM Opportunities)
                                     FROM Account
                                    LIMIT 1];
        RestMock responseMock = new RestMock(
            200,
            RestLogBuilder.STATUS_FAILURE,
            expectedResponseBodyFailureNoErrorDefined,
            new Map<String, String> {'Content-Type' => 'application/json'}
        );
        Test.setMock(HttpCalloutMock.class, responseMock);

        Test.startTest();
            ExampleRatingCallout actualRestCallout = new ExampleRatingCallout(expectedAccount);
            actualRestCallout.sendAccountToRatingEngine();
        Test.stopTest();

        Rest_Log__c actuallog = [SELECT Id, Status__c, Error_Code__c, Message__c FROM Rest_Log__c];
        System.assertNotEquals(null, actualLog.Id);
        System.assertEquals(ExampleRatingCallout.EXCEPTION_TEXT, actualLog.Error_Code__c);
        System.assertEquals(ExampleRatingCallout.EXCEPTION_TEXT, actualLog.Message__c);
        System.assertEquals(RestLogBuilder.STATUS_FAILURE, actualLog.Status__c);
    }
}