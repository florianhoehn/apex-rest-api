/**
* @author Florian Hoehn
* tests ExampleRatingCallout
**/
@isTest
private class ExampleRatingCalloutTest {
    private static String expectedResponseBodySuccess = '{"success":true,"errors":[],"accountId":"{0}","accountRating":"{1}"}';
    private static String expectedResponseBodyFailureNoErrorDefined = '{"success":false,"errors":[]}';
    private static String expectedResponseBodyFailure = '{"success":false,"errors":[{"errorCode":"{0}","message":"{1}"}]}';

    /**
    * setup test data for this class
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
    * tests making a successful callout
    */
    @isTest
    private static void doACalloutWithReturnedRating() {
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
        System.assertEquals(expectedRating, actualAccount.Rating, 'Account Rating does not match');
        Rest_Log__c actualLog = [SELECT Id, Status__c FROM Rest_Log__c];
        System.assertNotEquals(null, actualLog, 'Log is not set');
        System.assertEquals(RestLogBuilder.STATUS_SUCCESS, actualLog.Status__c, 'Log Status does not match');
    }

    /**
    * tests making a successful callout via the invoker (process builder)
    */
    @isTest
    private static void doACalloutByInvokerWithReturnedRating() {
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
        System.assertEquals(expectedRating, actualAccount.Rating, 'Account Rating doesnot match');
        Rest_Log__c actualLog = [SELECT Id, Status__c FROM Rest_Log__c];
        System.assertNotEquals(null, actualLog.Id, 'Log Id does match');
        System.assertEquals(RestLogBuilder.STATUS_SUCCESS, actualLog.Status__c, 'Log Status does not match');
    }

    /**
    * tests making a failed callout
    */
    @isTest
    private static void doACalloutWithErrorReturned() {
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

        Rest_Log__c actualLog = [SELECT Id, Status__c, Error_Code__c, Message__c FROM Rest_Log__c];
        System.assertNotEquals(null, actualLog.Id, 'Log Id does match');
        System.assertEquals(expectedErrorCode, actualLog.Error_Code__c, 'Log Error Code does not match');
        System.assertEquals(expectedMessage, actualLog.Message__c, 'Log Message does not match');
        System.assertEquals(RestLogBuilder.STATUS_FAILURE, actualLog.Status__c, 'Log Status does not match');
    }

    /**
    * tests making a failed callout without error message being sent by endpoint
    */
    @isTest
    private static void doACalloutWithStandardErrorReturned() {
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

        Rest_Log__c actualLog = [SELECT Id, Status__c, Error_Code__c, Message__c FROM Rest_Log__c];
        System.assertNotEquals(null, actualLog.Id, 'Log Id does match');
        System.assertEquals(ExampleRatingCallout.exceptionText, actualLog.Error_Code__c, 'Log Error Code does not match');
        System.assertEquals(ExampleRatingCallout.exceptionText, actualLog.Message__c, 'Log Message does not match');
        System.assertEquals(RestLogBuilder.STATUS_FAILURE, actualLog.Status__c, 'Log Status does not match');
    }
}