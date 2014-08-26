//
//  SCKTextContainerView.m
//  SlackChatKit
//
//  Created by Ignacio Romero Z. on 8/16/14.
//  Copyright (c) 2014 Tiny Speck, Inc. All rights reserved.
//

#import "SCKTextContainerView.h"
#import "UIView+ChatKitAdditions.h"

NSString * const SCKInputAccessoryViewKeyboardFrameDidChangeNotification = @"com.slack.chatkit.SCKTextContainerView.frameDidChange";

@interface SCKInputAccessoryView : UIView
@end

@interface SCKTextContainerView () <UITextViewDelegate>

@property (nonatomic, copy) NSString *rightButtonTitle;

@property (nonatomic, strong) NSLayoutConstraint *leftButtonWC;
@property (nonatomic, strong) NSLayoutConstraint *leftButtonHC;
@property (nonatomic, strong) NSLayoutConstraint *leftMarginWC;
@property (nonatomic, strong) NSLayoutConstraint *bottomMarginWC;
@property (nonatomic, strong) NSLayoutConstraint *rightButtonWC;
@property (nonatomic, strong) NSLayoutConstraint *rightMarginWC;
@property (nonatomic, strong) NSLayoutConstraint *accessoryViewHC;

@end

@implementation SCKTextContainerView

#pragma mark - Initialization

- (id)init
{
    self = [super init];
    if (self) {
        [self configure];
    }
    return self;
}

- (void)configure
{
    self.translucent = NO;
    self.autoHideRightButton = YES;
    self.bounces = NO;
    self.editing = NO;
    
    [self addSubview:self.accessoryView];
    [self addSubview:self.leftButton];
    [self addSubview:self.rightButton];
    [self addSubview:self.textView];
    
    [self setupViewConstraints];
    
    [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(didChangeTextView:) name:UITextViewTextDidChangeNotification object:nil];
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:UITextViewTextDidChangeNotification object:nil];
    
    _leftButton = nil;
    _rightButton = nil;
    _textView = nil;
}

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    [super willMoveToSuperview:newSuperview];
    
    [self updateConstraintConstants];
    [self layoutIfNeeded];
}


#pragma mark - Getters

- (CGSize)intrinsicContentSize
{
    return CGSizeMake(CGRectGetWidth(self.superview.frame), kTextContainerViewHeight);
}

- (SCKTextView *)textView
{
    if (!_textView)
    {
        _textView = [[SCKTextView alloc] init];
        _textView.translatesAutoresizingMaskIntoConstraints = NO;
        _textView.font = [UIFont systemFontOfSize:15.0f];
        _textView.maxNumberOfLines = 6;
        _textView.autocorrectionType = UITextAutocorrectionTypeNo; // For debug purpose
        _textView.spellCheckingType = UITextSpellCheckingTypeNo; // For debug purpose
        _textView.keyboardType = UIKeyboardTypeTwitter;
        _textView.returnKeyType = UIReturnKeyDefault;
        _textView.enablesReturnKeyAutomatically = YES;
        _textView.scrollIndicatorInsets = UIEdgeInsetsMake(0, -1, 0, 1);
        _textView.accessibilityLabel = NSLocalizedString(@"Text Input", nil);
        _textView.inputAccessoryView = [SCKInputAccessoryView new];
        _textView.delegate = self;
        
        _textView.layer.cornerRadius = 5.0f;
        _textView.layer.borderWidth = 1.0f;
        _textView.layer.borderColor =  [UIColor colorWithRed:200.0f/255.0f green:200.0f/255.0f blue:205.0f/255.0f alpha:1.0f].CGColor;
    }
    return _textView;
}

- (UIButton *)leftButton
{
    if (!_leftButton)
    {
        _leftButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _leftButton.translatesAutoresizingMaskIntoConstraints = NO;
        _leftButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
    }
    return _leftButton;
}

- (UIButton *)rightButton
{
    if (!_rightButton)
    {
        _rightButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _rightButton.translatesAutoresizingMaskIntoConstraints = NO;
        _rightButton.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
        _rightButton.enabled = NO;
        
        [_rightButton setTitle:NSLocalizedString(@"Send", nil) forState:UIControlStateNormal];
        [_rightButton setAccessibilityLabel:NSLocalizedString(@"Send", nil)];
    }
    return _rightButton;
}

- (UIView *)accessoryView
{
    if (!_accessoryView)
    {
        _accessoryView = [UIView new];
        _accessoryView.translatesAutoresizingMaskIntoConstraints = NO;
        _accessoryView.backgroundColor = self.backgroundColor;
        _accessoryView.clipsToBounds = YES;
        
        _editorTitle = [UILabel new];
        _editorTitle.translatesAutoresizingMaskIntoConstraints = NO;
        _editorTitle.text = NSLocalizedString(@"Editing Message", nil);
        _editorTitle.accessibilityLabel = NSLocalizedString(@"Editing Message", nil);
        _editorTitle.textAlignment = NSTextAlignmentCenter;
        _editorTitle.backgroundColor = [UIColor clearColor];
        _editorTitle.font = [UIFont boldSystemFontOfSize:15.0];
        [_accessoryView addSubview:self.editorTitle];
        
        _editortLeftButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _editortLeftButton.translatesAutoresizingMaskIntoConstraints = NO;
        _editortLeftButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentLeft;
        _editortLeftButton.titleLabel.font = [UIFont systemFontOfSize:15.0];
        [_editortLeftButton setTitle:NSLocalizedString(@"Cancel", nil) forState:UIControlStateNormal];
        [_editortLeftButton setAccessibilityLabel:NSLocalizedString(@"Cancel", nil)];
        [_accessoryView addSubview:self.editortLeftButton];
        
        _editortRightButton = [UIButton buttonWithType:UIButtonTypeSystem];
        _editortRightButton.translatesAutoresizingMaskIntoConstraints = NO;
        _editortRightButton.contentHorizontalAlignment = UIControlContentHorizontalAlignmentRight;
        _editortRightButton.titleLabel.font = [UIFont boldSystemFontOfSize:15.0];
        _editortRightButton.enabled = NO;
        [_editortRightButton setTitle:NSLocalizedString(@"Save", nil) forState:UIControlStateNormal];
        [_editortLeftButton setAccessibilityLabel:NSLocalizedString(@"Save", nil)];
        [_accessoryView addSubview:self.editortRightButton];
        
        NSDictionary *views = @{@"label": self.editorTitle,
                                @"leftButton": self.editortLeftButton,
                                @"rightButton": self.editortRightButton,
                                };
        
        NSDictionary *metrics = @{@"hor" : @(kTextViewHorizontalPadding),
                                  @"ver" : @(kTextViewVerticalPadding),
                                  };
        
        [_accessoryView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(==hor)-[leftButton(60)]-(==hor)-[label(>=0)]-(==hor)-[rightButton(60)]-(==hor)-|" options:0 metrics:metrics views:views]];
        [_accessoryView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[leftButton]|" options:0 metrics:metrics views:views]];
        [_accessoryView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[rightButton]|" options:0 metrics:metrics views:views]];
        [_accessoryView addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|[label]|" options:0 metrics:metrics views:views]];
    }
    return _accessoryView;
}

- (CGFloat)minHeight
{
    return self.intrinsicContentSize.height;
}

- (CGFloat)maxHeight
{
    if (self.textView.maxNumberOfLines > 0) {
        CGFloat height = roundf(self.textView.font.lineHeight*self.textView.maxNumberOfLines);
        height += (kTextViewVerticalPadding*2.0);
        return height;
    }
    else {
        return [UIScreen mainScreen].bounds.size.height;
    }
}

- (CGFloat)rightBtnWidth
{
    NSString *title = [self.rightButton titleForState:UIControlStateNormal];
    CGSize rigthButtonSize = [title sizeWithAttributes:@{NSFontAttributeName: self.rightButton.titleLabel.font}];
    
    if (self.autoHideRightButton) {
        if (self.textView.text.length == 0) {
            return 0.0;
        }
    }
    return rigthButtonSize.width+kTextViewHorizontalPadding;
}

- (CGFloat)rightBtnMargin
{
    if (self.autoHideRightButton) {
        if (self.textView.text.length == 0) {
            return 0.0;
        }
    }
    
    return kTextViewHorizontalPadding;
}


#pragma mark - Setters

- (void)setBackgroundColor:(UIColor *)color
{
    self.barTintColor = color;
    self.textView.inputAccessoryView.backgroundColor = color;
    self.accessoryView.backgroundColor = color;
}

- (void)setAutoHideRightButton:(BOOL)hide
{
    if (self.autoHideRightButton != hide) {
        _autoHideRightButton = hide;
    }
    
    self.rightButtonWC.constant = [self rightBtnWidth];
    [self layoutIfNeeded];
}


#pragma mark - Text Editing

- (BOOL)canEditText:(NSString *)text
{
    if (self.isEditing && [self.textView.text isEqualToString:text]) {
        return NO;
    }

    return YES;
}

- (void)beginTextEditing
{
    if (self.isEditing) {
        return;
    }
    
    self.editing = YES;
    
    [self updateConstraintConstants];
}

- (void)endTextEdition
{
    if (!self.isEditing) {
        return;
    }
    
    self.editing = NO;
    
    [self updateConstraintConstants];
}


#pragma mark - UITextViewDelegate

- (BOOL)textViewShouldBeginEditing:(UITextView *)textView
{
    return YES;
}

- (BOOL)textViewShouldEndEditing:(UITextView *)textView
{
    return YES;
}

- (BOOL)textView:(UITextView *)textView shouldChangeTextInRange:(NSRange)range replacementText:(NSString *)text
{
    NSDictionary *userInfo = @{@"text": text, @"range": [NSValue valueWithRange:range]};
    [[NSNotificationCenter defaultCenter] postNotificationName:SCKTextViewTextWillChangeNotification object:self.textView userInfo:userInfo];
    
    return YES;
}

- (void)textViewDidChangeSelection:(UITextView *)textView
{
    NSDictionary *userInfo = @{@"range": [NSValue valueWithRange:textView.selectedRange]};
    [[NSNotificationCenter defaultCenter] postNotificationName:SCKTextViewSelectionDidChangeNotification object:self.textView userInfo:userInfo];
}

- (void)didChangeTextView:(NSNotification *)notification
{
    SCKTextView *textView = (SCKTextView *)notification.object;
    
    // If it's not the expected textView, return.
    if (![textView isEqual:self.textView]) {
        return;
    }
    
    if (self.autoHideRightButton && !self.isEditing)
    {
        CGFloat rightButtonNewWidth = [self rightBtnWidth];
        
        if (self.rightButtonWC.constant == rightButtonNewWidth) {
            return;
        }
        
        self.rightButtonWC.constant = rightButtonNewWidth;
        self.rightMarginWC.constant = [self rightBtnMargin];
        
        if (rightButtonNewWidth > 0) {
            [self.rightButton sizeToFit];
        }
        
        [self animateLayoutIfNeededWithBounce:self.bounces curve:UIViewAnimationOptionCurveEaseInOut animations:NULL];
    }
}


#pragma mark - View Auto-Layout

- (void)setupViewConstraints
{
    // Removes all constraints
    [self removeConstraints:self.constraints];

    UIImage *leftButtonImg = [self.leftButton imageForState:UIControlStateNormal];
    
    [self.rightButton sizeToFit];
    
    CGFloat leftVerMargin = (self.minHeight - leftButtonImg.size.height) / 2.0f;
    CGFloat rightVerMargin = (self.minHeight - CGRectGetHeight(self.rightButton.frame)) / 2.0f;

    NSDictionary *views = @{@"textView": self.textView,
                            @"leftButton": self.leftButton,
                            @"rightButton": self.rightButton,
                            @"accessoryView": self.accessoryView
                            };
    
    NSDictionary *metrics = @{@"hor" : @(kTextViewHorizontalPadding),
                              @"ver" : @(kTextViewVerticalPadding),
                              @"leftVerMargin" : @(leftVerMargin),
                              @"rightVerMargin" : @(rightVerMargin),
                              };
    
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|-(==hor)-[leftButton(0)]-(==hor)-[textView]-(==hor)-[rightButton(0)]-(==hor)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=0)-[leftButton(0)]-(0)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-(>=rightVerMargin)-[rightButton]-(==rightVerMargin)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"V:|-0-[accessoryView(0)]-(==ver)-[textView(==34@750)]-(==ver)-|" options:0 metrics:metrics views:views]];
    [self addConstraints:[NSLayoutConstraint constraintsWithVisualFormat:@"H:|[accessoryView]|" options:0 metrics:metrics views:views]];

    NSArray *heightConstraints = [self constraintsForAttribute:NSLayoutAttributeHeight];
    NSArray *widthConstraints = [self constraintsForAttribute:NSLayoutAttributeWidth];
    NSArray *bottomConstraints = [self constraintsForAttribute:NSLayoutAttributeBottom];

    self.accessoryViewHC = heightConstraints[1];

    self.leftButtonWC = widthConstraints[0];
    self.leftButtonHC = heightConstraints[0];
    self.leftMarginWC = [self constraintsForAttribute:NSLayoutAttributeLeading][0];
    self.bottomMarginWC = bottomConstraints[0];

    self.rightButtonWC = widthConstraints[1];
    self.rightMarginWC = [self constraintsForAttribute:NSLayoutAttributeTrailing][0];
}

- (void)updateConstraintConstants
{
    CGFloat null = 0.0;

    if (self.isEditing)
    {
        self.accessoryViewHC.constant = kEditingViewHeight;
        self.leftButtonWC.constant = null;
        self.leftButtonHC.constant = null;
        self.leftMarginWC.constant = null;
        self.bottomMarginWC.constant = null;
        self.rightButtonWC.constant = null;
        self.rightMarginWC.constant = null;
    }
    else
    {
        self.accessoryViewHC.constant = null;

        CGSize leftButtonSize = [self.leftButton imageForState:UIControlStateNormal].size;
        
        self.leftButtonWC.constant = roundf(leftButtonSize.width);
        self.leftButtonHC.constant = roundf(leftButtonSize.height);
        self.leftMarginWC.constant = (leftButtonSize.width > 0) ? kTextViewHorizontalPadding : null;
        self.bottomMarginWC.constant = roundf((self.minHeight - leftButtonSize.height) / 2.0f);
        
        self.rightButtonWC.constant = [self rightBtnWidth];
        self.rightMarginWC.constant = [self rightBtnMargin];
    }
}

@end

@implementation SCKInputAccessoryView

- (void)willMoveToSuperview:(UIView *)newSuperview
{
    if (self.superview) {
        [self.superview removeObserver:self forKeyPath:NSStringFromSelector(@selector(frame))];
    }
    
    [newSuperview addObserver:self forKeyPath:NSStringFromSelector(@selector(frame)) options:0 context:NULL];
    
    [super willMoveToSuperview:newSuperview];
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
    if ([object isEqual:self.superview] && [keyPath isEqualToString:NSStringFromSelector(@selector(frame))])
    {
        NSDictionary *userInfo = @{UIKeyboardFrameEndUserInfoKey:[NSValue valueWithCGRect:[object frame]]};
        [[NSNotificationCenter defaultCenter] postNotificationName:SCKInputAccessoryViewKeyboardFrameDidChangeNotification object:nil userInfo:userInfo];
    }
}

- (void)dealloc
{
    if (self.superview) {
        [self.superview removeObserver:self forKeyPath:NSStringFromSelector(@selector(frame))];
    }
}

@end
