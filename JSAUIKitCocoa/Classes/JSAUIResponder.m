//
//  JSAUIResponder.m
//  JSAUIKitCocoa
//
//  Created by Neal on 2018/11/20.
//  Copyright © 2018年 JSAppSugar. All rights reserved.
//

#import "JSAUIResponder.h"
#import <JSA4Cocoa/JSAppSugar.h>
#import <objc/message.h>

static const char ASSOCIATEDOBJECT_KEY_JSA_OBSERVER;

#pragma mark - JSAUIActionEvent
@interface JSAUIActionEvent ()

@property (nonatomic, copy) NSString * name;
@property (nonatomic, weak) id object;
@property (nonatomic, strong) NSDictionary * userInfo;

@end

@implementation JSAUIActionEvent

+ (instancetype)eventWithName:(NSString *)name {
    return [[JSAUIActionEvent alloc] initWithName:name Object:nil UserInfo:nil];
}

+ (instancetype)eventWithName:(NSString *)name Object:(id)object {
    return [[JSAUIActionEvent alloc] initWithName:name Object:object UserInfo:nil];
}

+ (instancetype)eventWithName:(NSString *)name Object:(id)object UserInfo:(NSDictionary *)userInfo {
    return [[JSAUIActionEvent alloc] initWithName:name Object:object UserInfo:userInfo];
}

- (instancetype)initWithName:(NSString *)name Object:(id)object UserInfo:(NSDictionary *)userInfo {
    self = [super init];
    if (self) {
        self.name = name;
        self.object = object;
        self.userInfo = userInfo;
    }
    return self;
}

@end

#pragma mark - UIActionEventHandleResult
@interface JSAUIActionEventHandleResult ()

@property (nonatomic, assign) BOOL shouldContinueDispatch;

@end

@implementation JSAUIActionEventHandleResult

+ (instancetype)resultWithContinueDispatch:(BOOL)shouldContinueDispatch
{
    JSAUIActionEventHandleResult * result = [[[self class] alloc] init];
    result.shouldContinueDispatch = shouldContinueDispatch;
    return result;
}

@end

#pragma mark - UIResponder(JSAppSugar)
@implementation UIResponder (JSAppSugar)

-(void) dispatchJSAUIActionEvent:(JSAUIActionEvent *)actionEvent Selector:(SEL)sel{
    if ([self respondsToSelector:sel]) {
        JSAUIActionEventHandleResult * result = ((id(*)(id, SEL,JSAUIActionEvent*))objc_msgSend)(self, sel, actionEvent);
        if (result == nil ||
            ![result isKindOfClass:[JSAUIActionEventHandleResult class]] ||
            result.shouldContinueDispatch == NO) {
            return;
        }
    }
    id<JSAObject> jsaObject = [self getJSAUIActionEventObserver];
    if(jsaObject && [jsaObject hasMethod:actionEvent.name]){
        id object = actionEvent.object==nil?[NSNull null]:actionEvent.object;
        id userInfo = actionEvent.userInfo==nil?[NSNull null]:actionEvent.userInfo;
        id v = [jsaObject invokeMethod:actionEvent.name Arguments:@[object,userInfo]];
        if(v == nil || ![v boolValue]){
            return;
        }
    }
    UIResponder * next = [self nextResponder];
    if (next) {
        [next dispatchJSAUIActionEvent:actionEvent];
    }
}

- (void)dispatchJSAUIActionEvent:(JSAUIActionEvent *)actionEvent {
    NSString * name = [[[actionEvent.name substringToIndex:1] uppercaseString] stringByAppendingString:[actionEvent.name substringFromIndex:1]];
    NSString * actionSelectorName = [NSString stringWithFormat:@"handle%@WithActionEvent:", name];
    SEL sel = NSSelectorFromString(actionSelectorName);
    [self dispatchJSAUIActionEvent:actionEvent Selector:sel];
}

- (void)dispatchJSAUIActionEventWithName:(NSString *)name Object:(id)object UserInfo:(NSDictionary *)userInfo{
    JSAUIActionEvent* event = [JSAUIActionEvent eventWithName:name Object:object UserInfo:userInfo];
    [self dispatchJSAUIActionEvent:event];
}

-(id<JSAObject>)getJSAUIActionEventObserver{
    id<JSAWeakObject> weakObj = objc_getAssociatedObject(self, &ASSOCIATEDOBJECT_KEY_JSA_OBSERVER);
    return [weakObj value];
}

-(void)setJSAUIActionEventObserver:(id<JSAObject>) observer{
    id<JSAWeakObject> weakObj = [observer weakObject];
    objc_setAssociatedObject(self, &ASSOCIATEDOBJECT_KEY_JSA_OBSERVER, weakObj, OBJC_ASSOCIATION_RETAIN_NONATOMIC);
}

@end
