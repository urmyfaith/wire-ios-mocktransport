// 
// Wire
// Copyright (C) 2016 Wire Swiss GmbH
// 
// This program is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
// 
// This program is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
// 
// You should have received a copy of the GNU General Public License
// along with this program. If not, see http://www.gnu.org/licenses/.
// 


#import "MockTransportSessionTests.h"


@interface MockTransportSessionEmailPhoneVerificationTests : MockTransportSessionTests

@end

@implementation MockTransportSessionEmailPhoneVerificationTests


- (void)testThatItReturns400WhenRequestingTheVerificationEmailAndTheEmailAddressIsMissing
{
    // given
    
    __block MockUser *selfUser;
    NSString *email = @"doo@example.com";
    NSString *password = @"Bar481516";
    
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Food"];
        selfUser.email = email;
        selfUser.password = password;
        selfUser.isEmailValidated = NO;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    NSString *path = @"/activate/send";
    ZMTransportResponse *response = [self responseForPayload:@{} path:path method:ZMMethodPOST];
    
    // then
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 400);
}

- (void)testThatItReturns409WhenRequestingTheVerificationEmailAndTheEmailAddressBelongsToAnActivatedUser
{
    // given
    
    __block MockUser *selfUser;
    NSString *email = @"doo@example.com";
    NSString *password = @"Bar481516";
    
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Food"];
        selfUser.email = email;
        selfUser.password = password;
        selfUser.isEmailValidated = YES;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    NSString *path = @"/activate/send";
    ZMTransportResponse *response = [self responseForPayload:@{
                                                               @"email": email,
                                                               } path:path method:ZMMethodPOST];
    
    // then
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 409);
    XCTAssertEqualObjects([response payloadLabel], @"key-exists");
}

- (void)testThatItReturns200WhenRequestingTheVerificationEmailAndTheEmailAddressIsValidAndNotActivated
{
    // given
    
    __block MockUser *selfUser;
    NSString *email = @"doo@example.com";
    NSString *password = @"Bar481516";
    
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Food"];
        selfUser.email = email;
        selfUser.password = password;
        selfUser.isEmailValidated = NO;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    NSString *path = @"/activate/send";
    ZMTransportResponse *response = [self responseForPayload:@{
                                                               @"email": email,
                                                               } path:path method:ZMMethodPOST];
    
    // then
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 200);
}


- (void)testThatItCanRequestThePhoneNumberValidationCode
{
    // given
    NSDictionary *requestPayload = @{@"phone":@"+49123456789"};
    
    // when
    NSString *path = [NSString pathWithComponents:@[@"/", @"activate", @"send"]];
    ZMTransportResponse *response = [self responseForPayload:requestPayload path:path method:ZMMethodPOST];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 200);
}

- (void)testThatItReturnsDuplicatedPhoneWhenRequestingThePhoneNumberValidationCodeForAnExistingPhone
{
    // given
    NSString *phone = @"+49123456789";
    NSDictionary *requestPayload = @{@"phone":phone};
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        MockUser *user = [session insertUserWithName:@"foo"];
        user.phone = phone;
    }];
    
    // when
    NSString *path = [NSString pathWithComponents:@[@"/", @"activate", @"send"]];
    ZMTransportResponse *response = [self responseForPayload:requestPayload path:path method:ZMMethodPOST];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 409);
}

- (void)testThatItAcceptsTheDryRunOfAPhoneNumberValidationIfTheValidationCodeWasRequested
{
    // given
    NSString *phone = @"+4900000000";
    NSDictionary *codeRequestPayload = @{@"phone":phone};
    NSDictionary *validationPayload = @{@"phone":phone,@"code":self.sut.phoneVerificationCodeForRegistration,@"dryrun":@YES};
    NSString *codeRequestPath = [NSString pathWithComponents:@[@"/", @"activate", @"send"]];
    NSString *validationPath = [NSString pathWithComponents:@[@"/", @"activate"]];
    [self responseForPayload:codeRequestPayload path:codeRequestPath method:ZMMethodPOST];
    
    // when
    ZMTransportResponse *response = [self responseForPayload:validationPayload path:validationPath method:ZMMethodPOST];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertTrue([self.sut.phoneNumbersWaitingForVerificationForRegistration containsObject:phone]);

}

- (void)testThatItRejectsTheDryRunResultOfAPhoneNumberValidationIfTheValidationCodeWasNotRequested
{
    // given
    NSString *phone = @"+4900000000";
    NSDictionary *validationPayload = @{@"phone":phone,@"code":self.sut.phoneVerificationCodeForRegistration,@"dryrun":@YES};
    NSString *validationPath = [NSString pathWithComponents:@[@"/", @"activate"]];
    
    // when
    ZMTransportResponse *response = [self responseForPayload:validationPayload path:validationPath method:ZMMethodPOST];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 404);
}

- (void)testThatItRemovesAPhoneNumberFromTheListOfToValidateIfWithoutDryRun
{
    // given
    NSString *phone = @"+4900000000";
    NSDictionary *codeRequestPayload = @{@"phone":phone};
    NSDictionary *validationPayload = @{@"phone":phone,@"code":self.sut.phoneVerificationCodeForRegistration};
    NSString *codeRequestPath = [NSString pathWithComponents:@[@"/", @"activate", @"send"]];
    NSString *validationPath = [NSString pathWithComponents:@[@"/", @"activate"]];
    [self responseForPayload:codeRequestPayload path:codeRequestPath method:ZMMethodPOST];
    
    // when
    ZMTransportResponse *response = [self responseForPayload:validationPayload path:validationPath method:ZMMethodPOST];
    
    // then
    XCTAssertEqual(response.HTTPStatus, 200);
    XCTAssertFalse([self.sut.phoneNumbersWaitingForVerificationForRegistration containsObject:phone]);
}


@end
