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

@interface MockTransportSessionLoginTests : MockTransportSessionTests

@end

@implementation MockTransportSessionLoginTests

- (void)testThatLoginSucceedsAndSetsTheCookieWithEmail
{
    // given
    
    __block MockUser *selfUser;
    NSString *email = @"doo@example.com";
    NSString *password = @"Bar481516";
    
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Food"];
        selfUser.email = email;
        selfUser.password = password;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    self.sut.cookieStorage = [OCMockObject mockForClass:[ZMPersistentCookieStorage class]];
    [[(id) self.sut.cookieStorage expect] setAuthenticationCookieData:OCMOCK_ANY];
    
    // when
    NSString *path = @"/login";
    ZMTransportResponse *response = [self responseForPayload:@{
                                                               @"email": email,
                                                               @"password": password
                                                               } path:path method:ZMMethodPOST];
    
    // then
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 200);
    [self verifyMockLater:self.cookieStorage];
    
}

- (void)testThatLoginSucceedsAndSetsTheCookieWithPhoneNumberAfterRequestingALoginCode
{
    // given
    
    __block MockUser *selfUser;
    NSString *phone = @"+49000000";
    
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Food"];
        selfUser.phone = phone;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    self.sut.cookieStorage = [OCMockObject mockForClass:[ZMPersistentCookieStorage class]];
    [[(id) self.sut.cookieStorage expect] setAuthenticationCookieData:OCMOCK_ANY];
    
    // when
    [self responseForPayload:@{@"phone":phone} path:@"/login/send" method:ZMMethodPOST];
    
    // and when
    ZMTransportResponse *response = [self responseForPayload:@{
                                                               @"phone": phone,
                                                               @"code": self.sut.phoneVerificationCodeForLogin
                                                               } path:@"/login" method:ZMMethodPOST];
    
    // then
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 200);
    [self verifyMockLater:self.cookieStorage];
    
}

- (void)testThatPhoneLoginFailsIfTheLoginCodeIsWrong
{
    // given
    
    __block MockUser *selfUser;
    NSString *phone = @"+49000000";
    
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Food"];
        selfUser.phone = phone;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    self.sut.cookieStorage = [OCMockObject mockForClass:[ZMPersistentCookieStorage class]];
    [[(id) self.sut.cookieStorage reject] setAuthenticationCookieData:OCMOCK_ANY];
    
    // when
    [self responseForPayload:@{@"phone":phone} path:@"/login/send" method:ZMMethodPOST];
    
    // and when
    ZMTransportResponse *response = [self responseForPayload:@{
                                                               @"phone": phone,
                                                               @"code": self.sut.invalidPhoneVerificationCode
                                                               } path:@"/login" method:ZMMethodPOST];
    
    // then
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 404);
    [self verifyMockLater:self.cookieStorage];
    
}

- (void)testThatPhoneLoginFailsIfThereIsNoUserWithSuchPhone
{
    // given
    
    __block MockUser *selfUser;
    NSString *phone = @"+49000000";
    
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Food"];
        selfUser.phone = @"+491231231231231123";
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    self.sut.cookieStorage = [OCMockObject mockForClass:[ZMPersistentCookieStorage class]];
    [[(id) self.sut.cookieStorage reject] setAuthenticationCookieData:OCMOCK_ANY];
    
    // when
    [self responseForPayload:@{@"phone":phone} path:@"/login/send" method:ZMMethodPOST];
    
    // and when
    ZMTransportResponse *response = [self responseForPayload:@{
                                                               @"phone": phone,
                                                               @"code": self.sut.phoneVerificationCodeForLogin
                                                               } path:@"/login" method:ZMMethodPOST];
    
    // then
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 404);
    [self verifyMockLater:self.cookieStorage];
    
}

- (void)testThatRequestingThePhoneLoginCodeSucceedsIfThereIsAUserWithSuchPhone
{
    // given
    
    __block MockUser *selfUser;
    NSString *phone = @"+49000000";
    
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Food"];
        selfUser.phone = phone;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
     // when
    ZMTransportResponse *response = [self responseForPayload:@{@"phone":phone} path:@"/login/send" method:ZMMethodPOST];
    
    // then
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 200);
}


- (void)testThatRequestingThePhoneLoginCodeFailsIfThereIsNoUserWithSuchPhone
{
    // given
    
    __block MockUser *selfUser;
    NSString *phone = @"+49000000";
    
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Food"];
        selfUser.phone = @"4324324";
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    // when
    ZMTransportResponse *response = [self responseForPayload:@{@"phone":phone} path:@"/login/send" method:ZMMethodPOST];
    
    // then
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 404);
}

- (void)testThatPhoneLoginFailsIfNoVerificationCodeWasRequested
{
    // given
    
    __block MockUser *selfUser;
    NSString *phone = @"+49000000";
    
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"Food"];
        selfUser.phone = phone;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    
    self.sut.cookieStorage = [OCMockObject mockForClass:[ZMPersistentCookieStorage class]];
    [[(id) self.sut.cookieStorage reject] setAuthenticationCookieData:OCMOCK_ANY];
    
    // when
    ZMTransportResponse *response = [self responseForPayload:@{
                                                               @"phone": phone,
                                                               @"code": self.sut.phoneVerificationCodeForLogin
                                                               } path:@"/login" method:ZMMethodPOST];
    
    // then
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 404);
    [self verifyMockLater:self.cookieStorage];
    
}


- (void)testThatItReturns403PendingActivationIfTheUserIsPendingEmailValidation
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
    NSString *path = @"/login";
    ZMTransportResponse *response = [self responseForPayload:@{
                                                               @"email": email,
                                                               @"password": password
                                                               } path:path method:ZMMethodPOST];
    
    // then
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 403);
    XCTAssertEqualObjects([response payloadLabel], @"pending-activation");
}

- (void)testThatLoginFailsAndDoesNotSetTheCookie
{
    // given
    
    __block MockUser *selfUser;
    NSString *email = @"doo@example.com";
    NSString *password = @"Bar481516";
    
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"good"];
        selfUser.email = email;
        selfUser.password = password;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    [[(id) self.cookieStorage reject] setAuthenticationCookieData:OCMOCK_ANY];
    
    // when
    NSString *path = @"/login";
    ZMTransportResponse *response = [self responseForPayload:@{
                                                               @"email": email,
                                                               @"password": @"invalid"
                                                               } path:path method:ZMMethodPOST];
    
    // then
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 403);
    XCTAssertEqualObjects(response.payload[@"label"], @"invalid-credentials");
    [self verifyMockLater:self.cookieStorage];
}



- (void)testThatLoginFailsForWrongEmailAndDoesNotSetTheCookie
{
    // given
    
    __block MockUser *selfUser;
    NSString *email = @"doo@example.com";
    NSString *password = @"Bar481516";
    
    [self.sut performRemoteChanges:^(MockTransportSession<MockTransportSessionObjectCreation> *session) {
        selfUser = [session insertSelfUserWithName:@"good"];
        selfUser.email = email;
        selfUser.password = password;
    }];
    WaitForAllGroupsToBeEmpty(0.5);
    [[(id) self.cookieStorage reject] setAuthenticationCookieData:OCMOCK_ANY];
    
    
    // when
    NSString *path = @"/login";
    ZMTransportResponse *response = [self responseForPayload:@{
                                                               @"email": @"invalid@example.com",
                                                               @"password": password
                                                               } path:path method:ZMMethodPOST];
    
    // then
    XCTAssertNotNil(response);
    XCTAssertEqual(response.HTTPStatus, 403);
    XCTAssertEqualObjects(response.payload[@"label"], @"invalid-credentials");
    [self verifyMockLater:self.cookieStorage];
    
    
}

@end
