//
//  ChatViewController.m
//  yesand
//
//  Created by Husein Kareem on 6/20/15.
//  Copyright (c) 2015 Meduse. All rights reserved.
//

#import "ChatViewController.h"
#import "RatingViewController.h"
#import "HomeViewController.h"

@interface ChatViewController () <UITableViewDelegate, UITableViewDataSource, UITextFieldDelegate, UIScrollViewDelegate>
@property (weak, nonatomic) IBOutlet UIView *userSetupview;
@property (weak, nonatomic) IBOutlet UITableView *tableView;
@property (weak, nonatomic) IBOutlet UITextField *messageTextField;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textFieldBottomLayout;
@property (weak, nonatomic) IBOutlet UILabel *currentUserLabel;
@property (weak, nonatomic) IBOutlet UILabel *otherUserLabel;
@property (weak, nonatomic) IBOutlet UILabel *currentUserCharacter;
@property (weak, nonatomic) IBOutlet UIView *splashView;
@property (weak, nonatomic) IBOutlet UILabel *otherUserCharacter;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *cancelBarButton;
@property (weak, nonatomic) IBOutlet UIBarButtonItem *endSceneBarButton;
@property (weak, nonatomic) IBOutlet UILabel *topicLabel;
@property (weak, nonatomic) IBOutlet UIImageView *currentUserImageView;
@property (weak, nonatomic) IBOutlet UIImageView *otherUserImageView;
@property double keyboardHeight;
@property NSMutableArray *localMessages;
@property NSMutableArray *cloudMessages;
@property Firebase *conversationsRef;
@property Firebase *convoRef;
@property Firebase *rootRef;
@property NSArray *currentUserMessages;
@property NSArray *otherUserMessages;
@property Firebase *sceneConvo;
@property BOOL ifCalled;
@property NSMutableArray *availableUsers;
@property NSString *currentUserCharacterTwo;
@property Firebase *ref;
@property NSString *currentUserCharacterOne;
@property Firebase *usersRef;
@property NSString *currentUserTopic;
@property NSInteger indexOfCurrentUser;
@property NSDictionary *otherUser;
@property BOOL isSplashHidden;
@property NSString *otherAuthuid;
@property NSDictionary *topic;
@property NSTimer *timer;
@property int countdown;
@property (weak, nonatomic) IBOutlet UIImageView *typingImageView;
@property (weak, nonatomic) IBOutlet UILabel *countdownLabel;
@end

@implementation ChatViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    self.userSetupview.layer.cornerRadius = 5;
    self.countdownLabel.layer.cornerRadius = 5;
    self.topicLabel.layer.cornerRadius = 5;
    self.topicLabel.clipsToBounds = YES;
    self.countdownLabel.clipsToBounds = YES;
    self.tabBarController.tabBar.hidden = YES;
    self.typingImageView.hidden = YES;

    self.navigationController.navigationBar.barTintColor = [UIColor colorWithRed:255/255.0 green:40/255.0 blue:40/255.0 alpha:1.0];
    self.navigationController.navigationBar.tintColor = [UIColor colorWithRed:255/255.0 green:255/255.0 blue:255/255.0 alpha:1.0];
    NSDictionary *attrDict = @{
                               NSFontAttributeName : [UIFont fontWithName:@"AppleGothic" size:21.0],
                               NSForegroundColorAttributeName : [UIColor whiteColor]
                               };
    self.navigationController.navigationBar.titleTextAttributes = attrDict;

    //--------------------------------chat view stuff

    self.localMessages = [NSMutableArray new];
    self.conversationsRef = [[Firebase alloc] initWithUrl:@"https://yesand.firebaseio.com/conversations"];
    NSNotificationCenter *center = [NSNotificationCenter defaultCenter];
    [center addObserver:self selector:@selector(keyboardOnScreen:) name:UIKeyboardWillShowNotification object:nil];
    self.cloudMessages = [NSMutableArray new];

    //---------------------------------endsHere

    self.tableView.separatorColor = [UIColor clearColor];
    self.tableView.rowHeight = UITableViewAutomaticDimension;
}

//----------------------------------------splashscreenstuff

#pragma mark - TOPIC GENERATION
-(void)viewDidAppear:(BOOL)animated {
    self.splashView.alpha = 1.0;
    self.isSplashHidden = NO;
    self.endSceneBarButton.enabled = NO;
    self.tabBarController.tabBar.hidden = YES;
    self.cancelBarButton.enabled = YES;
    self.cancelBarButton.title = @"Cancel";
    self.endSceneBarButton.title = @"";
    self.countdown = 10;
    [self retrieveNewTopic];
}
// Step 1
-(void)retrieveNewTopic {
    NSURL *url = [NSURL URLWithString:@"https://api.myjson.com/bins/1pt90"];
    NSURLRequest *request = [NSURLRequest requestWithURL:url];

    [NSURLConnection sendAsynchronousRequest:request
                                       queue:[NSOperationQueue mainQueue]
                           completionHandler:^(NSURLResponse *response, NSData *data, NSError *connectionError) {

                               NSArray *topics = [NSJSONSerialization JSONObjectWithData:data options:NSJSONReadingAllowFragments error:&connectionError];
                               self.topic = topics[arc4random_uniform((int)topics.count)];
                               [self saveNewTopic];
                           }];
}
// Step 2
-(void)saveNewTopic {
    Firebase *usersRef = [[Firebase alloc] initWithUrl: @"https://yesand.firebaseio.com/users"];
    Firebase *user = [usersRef childByAppendingPath:usersRef.authData.uid];
    NSDictionary *userDic = @{@"isAvailable": @1,
                              @"character one": [self.topic objectForKey:@"character one"],
                              @"character two": [self.topic objectForKey:@"character two"],
                              @"topic name": [self.topic objectForKey:@"name"],
                              @"updateAt": kFirebaseServerValueTimestamp
                              };
    [user updateChildValues:userDic];
    [self findNewUsers];
}
// Step 3
-(void)findNewUsers {
    //----------------------------------splashviewstuff
    self.ifCalled = NO;
    self.availableUsers = [NSMutableArray new];
    self.ref = [[Firebase alloc] initWithUrl: @"https://yesand.firebaseio.com"];
    NSString *currentUserString = [NSString stringWithFormat:@"https://yesand.firebaseio.com/users/%@", self.ref.authData.uid];
    Firebase *currentUserRef = [[Firebase alloc] initWithUrl:currentUserString];
    [currentUserRef observeSingleEventOfType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        self.currentUsername = snapshot.value[@"username"];
        self.currentUserLabel.text = snapshot.value[@"username"];
        self.currentUserTopic = snapshot.value[@"topic name"];
        self.currentUserCharacterOne = snapshot.value[@"character one"];
        self.currentUserCharacterTwo = snapshot.value[@"character two"];
    }];
    self.usersRef = [[Firebase alloc] initWithUrl:@"https://yesand.firebaseio.com/users"];

    // Retrieve new posts as they are added to firebase
    [self.usersRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        NSMutableArray *usersArray = [NSMutableArray new];
        for (FDataSnapshot *user in snapshot.children) {
            if ([user.value[@"isAvailable"] isEqualToNumber:@1]) {
                [usersArray addObject:user.value];
            }
        }
        NSSortDescriptor *sortDescriptor = [NSSortDescriptor sortDescriptorWithKey:@"updateAt" ascending:YES];
        NSArray *arrayOfDescriptors = [NSArray arrayWithObject:sortDescriptor];

        [usersArray sortUsingDescriptors: arrayOfDescriptors];
        self.availableUsers = usersArray;
        [self pairUsers];
        NSLog(@"------- AVAILABLE %@", self.availableUsers);
    }];
}

// Step 4
#pragma mark - Pair Users
-(void)pairUsers {
    NSLog(@"---- PAIR USERS");
    for (NSDictionary *data in self.availableUsers) {
        if ([self.currentUsername isEqualToString:[data objectForKey:@"username"]]) {
            self.indexOfCurrentUser = [self.availableUsers indexOfObject:data];
        }
    }

    if (self.indexOfCurrentUser % 2 == 0) {
        if (self.indexOfCurrentUser + 1 < self.availableUsers.count) {
            self.otherUser = self.availableUsers[self.indexOfCurrentUser + 1];
            self.otherUsername = [self.otherUser objectForKey:@"username"];
            self.otherUserLabel.text = [self.otherUser objectForKey:@"username"];
            self.otherAuthuid = [self.otherUser objectForKey:@"authuid"];
            self.currentUserCharacter.text = self.currentUserCharacterOne;
            self.otherUserCharacter.text = self.currentUserCharacterTwo;
            self.topicLabel.text = [NSString stringWithFormat:@"Topic: %@", self.currentUserTopic];
            self.isEven = YES;
            [self.otherUserImageView.layer removeAllAnimations];
            self.otherUserImageView.image = [UIImage imageNamed:@"profilepic2.png"];
            if (!self.ifCalled) {
                [self performSelector:@selector(splashViewDisappear) withObject:nil afterDelay:10.0];
                self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                         target:self
                                                       selector:@selector(countDown)
                                                       userInfo:nil
                                                        repeats:YES];
                self.ifCalled = YES;
            }
        } else {
            self.otherUserLabel.text = @"Finding";
            self.currentUserCharacter.text = @"Character";
            self.otherUserCharacter.text = @"Character";
            self.topicLabel.text = @"Prompt will show when next performer arrives...";
            self.ifCalled = NO;
            self.otherUserImageView.image = [UIImage imageNamed:@"MaskIndicator.png"];
            [self rotateSecondImageView];
            [NSObject cancelPreviousPerformRequestsWithTarget:self selector:@selector(splashViewDisappear) object:nil];
            [self.timer invalidate];
            self.countdownLabel.text = @"Your scene will start shortly...";
            self.countdown = 10;
        }
    } else {
        self.otherUser = self.availableUsers[self.indexOfCurrentUser - 1];
        self.otherUsername = [self.otherUser objectForKey:@"username"];
        self.otherAuthuid = [self.otherUser objectForKey:@"authuid"];
        self.otherUserLabel.text = [self.otherUser objectForKey:@"username"];
        self.currentUserCharacter.text = [self.otherUser objectForKey:@"character two"];
        self.otherUserCharacter.text = [self.otherUser objectForKey:@"character one"];
        self.topicLabel.text = [NSString stringWithFormat:@"Topic: %@", [self.otherUser objectForKey:@"topic name"]];
        self.isEven = NO;
        if (!self.ifCalled) {
            [self performSelector:@selector(splashViewDisappear) withObject:nil afterDelay:10.0];
            self.timer = [NSTimer scheduledTimerWithTimeInterval:1
                                                          target:self
                                                        selector:@selector(countDown)
                                                        userInfo:nil
                                                         repeats:YES];
            self.ifCalled = YES;
        }
        [self.otherUserImageView.layer removeAllAnimations];
        self.otherUserImageView.image = [UIImage imageNamed:@"profilepic2.png"];
    }
}

-(void)countDown {
    if (self.countdown == 0) {
        [self.timer invalidate];
    }
    self.countdown--;
    self.countdownLabel.text = [NSString stringWithFormat:@"Scene starts in %i", self.countdown];
}

-(void)splashViewDisappear {
    self.splashView.alpha = 0.0;
    self.isSplashHidden = YES;
    self.endSceneBarButton.title = @"End Scene";
    self.endSceneBarButton.enabled = YES;
    self.cancelBarButton.title = @"";
    self.cancelBarButton.enabled = NO;
    [self.usersRef removeAllObservers];
    [self queryConversation];
    Firebase *otherUserRef = [[Firebase alloc] initWithUrl: [NSString stringWithFormat:@"https://yesand.firebaseio.com/users/%@",self.otherAuthuid]];
    [otherUserRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
        if ([snapshot.value[@"isAvailable"] isEqualToNumber:@0]) {
            UIAlertController* alert = [UIAlertController alertControllerWithTitle:[NSString stringWithFormat:@"%@ left the scene", self.otherUsername] message:nil preferredStyle:UIAlertControllerStyleAlert];
            UIAlertAction *continueAction = [UIAlertAction actionWithTitle:@"Continue" style:UIAlertActionStyleCancel handler:^(UIAlertAction *action) {
                [self performSegueWithIdentifier:@"SplashChatToRatings" sender:self];
            }];
            [alert addAction:continueAction];
            [self presentViewController:alert animated:YES completion:nil];
            [otherUserRef removeAllObservers];
        }
    }];
}
//------------------------------------------ends here

#pragma mark - Query Conversation

-(void)queryConversation {
    if (self.isEven) {
        //setting up scene model for even only
        Firebase *scenesConvo = [[Firebase alloc] initWithUrl:@"https://yesand.firebaseio.com/scenes"];
        NSDictionary *sceneDic = @{
                                   @"topicName": self.currentUserTopic,
                                   @"characterOne": self.currentUserCharacterOne,
                                   @"characterTwo": self.currentUserCharacterTwo,
                                   @"userOne": self.ref.authData.uid,
                                   @"userTwo": self.otherAuthuid,
                                   @"isLive": @1,
                                   @"messages": @[@"test"]
                                   };
        self.sceneConvo = [scenesConvo childByAutoId];
        [self.sceneConvo setValue:sceneDic];
        //setting up conversation model and query
        if (self.currentUsername != nil) {
            NSLog(@"----------------%@", self.currentUsername);
            self.convoRef = [self.conversationsRef childByAppendingPath: self.currentUsername];

            [self.convoRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
                if (![snapshot.value isEqual:[NSNull null]]) {
                    self.currentUserMessages = snapshot.value[@"messages"];
                    self.cloudMessages = [NSMutableArray new];
                    [self.cloudMessages addObjectsFromArray:self.currentUserMessages];
                    NSDictionary *sceneMessages = @{
                                                    @"messages": self.cloudMessages
                                                    };
                    [self.sceneConvo updateChildValues:sceneMessages];
                    [self.tableView reloadData];
                    if (self.cloudMessages.count > 5) {
                        NSIndexPath* ipath = [NSIndexPath indexPathForRow: self.cloudMessages.count-1 inSection: 0];
                        [self.tableView scrollToRowAtIndexPath: ipath atScrollPosition: UITableViewScrollPositionTop animated: YES];
                    }
                    if ([snapshot.value[self.otherUserCharacter.text] isEqualToNumber:@1]) {
                        self.typingImageView.hidden = NO;
                    } else {
                        self.typingImageView.hidden = YES;
                    }
                }
            } withCancelBlock:^(NSError *error) {
            }];
        }
    } else {
        //setting up conversation model and query
        if (self.otherUsername != nil) {
            NSLog(@"----------------%@", self.otherUsername);
            self.convoRef = [self.conversationsRef childByAppendingPath: self.otherUsername];

            [self.convoRef observeEventType:FEventTypeValue withBlock:^(FDataSnapshot *snapshot) {
                if (![snapshot.value isEqual:[NSNull null]]) {
                    self.otherUserMessages = snapshot.value[@"messages"];
                    self.cloudMessages = [NSMutableArray new];
                    [self.cloudMessages addObjectsFromArray:self.otherUserMessages];
                    [self.tableView reloadData];
                    if (self.cloudMessages.count > 5) {
                        NSIndexPath* ipath = [NSIndexPath indexPathForRow: self.cloudMessages.count-1 inSection: 0];
                        [self.tableView scrollToRowAtIndexPath: ipath atScrollPosition: UITableViewScrollPositionBottom animated: YES];
                    }
                    if ([snapshot.value[self.otherUserCharacter.text] isEqualToNumber:@1]) {
                        self.typingImageView.hidden = NO;
                    } else {
                        self.typingImageView.hidden = YES;
                    }
                }
            } withCancelBlock:^(NSError *error) {
            }];
        }
    }
}



#pragma mark - Sending Message
- (IBAction)onSendButtonTapped:(id)sender {
    [self.cloudMessages addObject:[NSString stringWithFormat:@"%@: %@", self.currentUserCharacter.text, self.messageTextField.text]];
    NSDictionary *conversation = @{
                                   @"messages": self.cloudMessages
                                   };
    [self.convoRef updateChildValues:conversation];
    [self.messageTextField resignFirstResponder];
    self.textFieldBottomLayout.constant = 0;
    self.messageTextField.text = @"";
}

-(void)makeNotAvailable {
    Firebase *usersRef = [[Firebase alloc] initWithUrl: @"https://yesand.firebaseio.com/users"];
    NSDictionary *userDic = @{@"isAvailable": @0
                            };
    if (usersRef.authData.uid != nil) {
        NSLog(@"----------------%@", usersRef.authData.uid);
        Firebase *user = [usersRef childByAppendingPath:usersRef.authData.uid];
        [user updateChildValues: userDic];
    }

    if (self.isSplashHidden) {
        if (self.otherAuthuid != nil) {
            NSLog(@"----------------%@", self.otherAuthuid);
            Firebase *usersRef = [[Firebase alloc] initWithUrl: @"https://yesand.firebaseio.com/users"];
            Firebase *otherUser = [usersRef childByAppendingPath:self.otherAuthuid];
            [otherUser updateChildValues:userDic];
        }
    }

}

#pragma mark - Keyboard Animation

-(void)keyboardOnScreen:(NSNotification *)notification
{
    NSDictionary *info  = notification.userInfo;
    NSValue      *value = info[UIKeyboardFrameEndUserInfoKey];

    CGRect rawFrame      = [value CGRectValue];
    CGRect keyboardFrame = [self.view convertRect:rawFrame fromView:nil];

    self.textFieldBottomLayout.constant = keyboardFrame.size.height; //- 50;
}


- (void)scrollViewWillBeginDragging:(UIScrollView *)scrollView
{
    [self.messageTextField resignFirstResponder];
    self.textFieldBottomLayout.constant = 0;
}

#pragma mark - Segues

- (IBAction)onCancelTapped:(UIBarButtonItem *)sender {
    NSLog(@"cancel");
    [self performSegueWithIdentifier:@"ChatToHome" sender:sender];
}
- (IBAction)onEndSceneTapped:(UIBarButtonItem *)sender {
    [self performSegueWithIdentifier:@"SplashChatToRatings" sender:sender];
}

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    if ([segue.identifier isEqualToString:@"SplashChatToRatings"]) {
        RatingViewController *ratingVC = segue.destinationViewController;
        ratingVC.otherAuthuid = self.otherAuthuid;
    }
}

-(IBAction)unwindToChatFromRating:(UIStoryboardSegue *)segue {
    self.localMessages = [NSMutableArray new];
    self.conversationsRef = [[Firebase alloc] initWithUrl:@"https://yesand.firebaseio.com/conversations"];
    self.cloudMessages = [NSMutableArray new];
    [self.tableView reloadData];

    NSLog(@"unwindToChat");
}

#pragma mark - Table View

-(NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
    return self.cloudMessages.count;
}

-(UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    if ([self.cloudMessages[indexPath.row] hasPrefix:[NSString stringWithFormat:@"%@", self.currentUserCharacter.text]]) {
        SendTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"SendMessageID"];
        cell.sendMessageLabel.text = self.cloudMessages[indexPath.row];
        return cell;
    } else {
        ReceiveTableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:@"ReceiveMessageID"];
        cell.receiveMessageLabel.text = self.cloudMessages[indexPath.row];
        return cell;
    }
}

-(CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    NSString *msg = self.cloudMessages[indexPath.row];
    CGSize sizeOfString = [self testSizeOfString:msg];
    return sizeOfString.height + 20;
}

-(CGSize)testSizeOfString:(NSString *)labelText {
    UILabel *gettingSizeLabel = [[UILabel alloc] init];
    gettingSizeLabel.font = [UIFont fontWithName:@"Helvetica Neue" size:14];
    gettingSizeLabel.text = labelText;
    gettingSizeLabel.numberOfLines = 0;
    gettingSizeLabel.lineBreakMode = NSLineBreakByWordWrapping;
    CGSize maximumLabelSize = CGSizeMake(190, 9999);

    CGSize expectSize = [gettingSizeLabel sizeThatFits:maximumLabelSize];
    return expectSize;
}

#pragma mark - Disappearing

-(void)viewWillDisappear:(BOOL)animated {
    [self makeNotAvailable];
    if (self.isSplashHidden) {
        if (self.isEven) {
            NSDictionary *sceneMessages = @{
                                            @"isLive": @0
                                            };
            [self.sceneConvo updateChildValues:sceneMessages];
        }
        Firebase *currentConvo = [self.conversationsRef childByAppendingPath: self.currentUsername];
        Firebase *otherConvo = [self.conversationsRef childByAppendingPath: self.otherUsername];
        [currentConvo removeValue];
        [otherConvo removeValue];
        [self.usersRef removeAllObservers];
        [self.convoRef removeAllObservers];
    }
}

#pragma mark - Animation with image

- (void)rotateSecondImageView {
    CABasicAnimation *rotation;
    rotation = [CABasicAnimation animationWithKeyPath:@"transform.rotation"];
    rotation.fromValue = [NSNumber numberWithFloat:0];
    rotation.toValue = [NSNumber numberWithFloat:(2 * M_PI)];
    rotation.duration = 2.0f; // Speed
    rotation.repeatCount = HUGE_VALF; // Repeat forever until remove animation
    [self.otherUserImageView.layer removeAllAnimations];
    [self.otherUserImageView.layer addAnimation:rotation forKey:@"Spin"];
}

#pragma mark - Typing indicator

-(void)textFieldDidBeginEditing:(UITextField *)textField {
    NSDictionary *conversation = @{
                                   self.currentUserCharacter.text: @1
                                   };
    [self.convoRef updateChildValues:conversation];
}

-(void)textFieldDidEndEditing:(UITextField *)textField {
    NSDictionary *conversation = @{
                                   self.currentUserCharacter.text: @0
                                   };
    [self.convoRef updateChildValues:conversation];
}

//  To remove animation
// [self.imageview.layer removeAllAnimations]

@end
