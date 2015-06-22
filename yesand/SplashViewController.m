//
//  SplashViewController.m
//  yesand
//
//  Created by Joseph DiVittorio on 6/21/15.
//  Copyright (c) 2015 Meduse. All rights reserved.
//

#import "SplashViewController.h"

@interface SplashViewController ()
@property NSMutableArray *availableUsers;
@property NSUInteger indexOfCurrentUser;
@property (weak, nonatomic) IBOutlet UILabel *currentUserLabel;
@property (weak, nonatomic) IBOutlet UILabel *otherUserLabel;
@property NSString *currentUserEmail;
@end

@implementation SplashViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.availableUsers = [NSMutableArray new];
    Firebase *ref = [[Firebase alloc] initWithUrl: @"https://yesand.firebaseio.com"];
    NSString *currentUserString = [NSString stringWithFormat:@"https://yesand.firebaseio.com/users/%@", ref.authData.uid];
    Firebase *currentUserRef = [[Firebase alloc] initWithUrl:currentUserString];
    [currentUserRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        self.currentUserLabel.text = snapshot.value[@"email"];
        self.currentUserEmail = snapshot.value[@"email"];
    }];
    Firebase *usersRef = [[Firebase alloc] initWithUrl:@"https://yesand.firebaseio.com/users"];

    // Retrieve new posts as they are added to firebase
    [usersRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        NSMutableArray *usersArray = [NSMutableArray new];
        for (FDataSnapshot *user in snapshot.children) {
            if (![user.value[@"email"] isEqualToString:self.currentUserEmail]) {
                if ([user.value[@"isPair"] isEqualToNumber:@0] && [user.value[@"isAvailable"] isEqualToNumber:@1]) {
                    [usersArray addObject:user.value];
                }
            }
        }
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"updateAt" ascending:YES];
        NSArray *arrayOfDescriptors = [NSArray arrayWithObject:sortDescriptor];

        [usersArray sortUsingDescriptors: arrayOfDescriptors];
        self.availableUsers = usersArray;
//        if (self.availableUsers.count != 0) {
            [self pairUsers];
//        }
        NSLog(@"------- AVAILABLE %@", self.availableUsers);
    }];
}

-(void)pairUsers {
    if (self.availableUsers.firstObject[@"email"] != nil) {
        NSArray *pairedUsers = @[self.currentUserEmail, self.availableUsers.firstObject[@"email"]];
        self.otherUserLabel.text = self.availableUsers.firstObject[@"email"];
        NSDictionary *userDic = @{@"isPair": @1
                                  };
        Firebase *usersRef = [[Firebase alloc] initWithUrl: @"https://yesand.firebaseio.com/users"];
        Firebase *user = [usersRef childByAppendingPath:usersRef.authData.uid];
        [user updateChildValues:userDic];
        NSLog(@"pairedUsers: %@", pairedUsers);
    } else {
        NSArray *pairedUsers = @[self.currentUserEmail, @"not paired"];
        self.otherUserLabel.text = @"not paired";
        NSDictionary *userDic = @{@"isPair": @0
                                  };
        Firebase *usersRef = [[Firebase alloc] initWithUrl: @"https://yesand.firebaseio.com/users"];
        Firebase *user = [usersRef childByAppendingPath:usersRef.authData.uid];
        [user updateChildValues:userDic];
    }
}

-(void)viewWillDisappear:(BOOL)animated {
    Firebase *usersRef = [[Firebase alloc] initWithUrl: @"https://yesand.firebaseio.com/users"];
    Firebase *user = [usersRef childByAppendingPath:usersRef.authData.uid];
    NSDictionary *userDic = @{@"isAvailable": @0,
                              @"isPair": @0
                              };
    [user updateChildValues: userDic];
}

@end
