//
//  Ads.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

// MARK: hide ADS - New Implementation
%hook TFNItemsDataViewAdapterRegistry
- (id)dataViewAdapterForItem:(id)item {
    if ([BHTManager HidePromoted]) {
        //Old Ads
        if ([item isKindOfClass:objc_getClass("T1URTTimelineStatusItemViewModel")] && ((T1URTTimelineStatusItemViewModel *)item).isPromoted) {
            return nil;
        }
        //New Ads
        if ([item isKindOfClass:objc_getClass("TwitterURT.URTTimelineGoogleNativeAdViewModel")]) {
            return nil;
        }
    }
    return %orig;
}
%end

%hook TFNItemsDataViewController
- (id)tableViewCellForItem:(id)arg1 atIndexPath:(id)arg2 {
    UITableViewCell *_orig = %orig;
    id tweet = [self itemAtIndexPath:arg2];
    NSString *class_name = NSStringFromClass([tweet classForCoder]);



    if ([BHTManager HidePromoted] && [tweet respondsToSelector:@selector(isPromoted)] && [tweet performSelector:@selector(isPromoted)]) {
        [_orig setHidden:YES];
    }

    if ([self.adDisplayLocation isEqualToString:@"PROFILE_TWEETS"]) {
        if ([BHTManager hideWhoToFollow]) {
            if ([class_name isEqualToString:@"T1URTTimelineUserItemViewModel"] || [class_name isEqualToString:@"T1TwitterSwift.URTTimelineCarouselViewModel"] || [class_name isEqualToString:@"TwitterURT.URTModuleHeaderViewModel"] || [class_name isEqualToString:@"TwitterURT.URTModuleFooterViewModel"]) {
                [_orig setHidden:true];
            }
        }

        if ([BHTManager hideTopicsToFollow]) {
            if ([class_name isEqualToString:@"T1TwitterSwift.URTTimelineTopicCollectionViewModel"] || [class_name isEqualToString:@"TwitterURT.URTModuleHeaderViewModel"] || [class_name isEqualToString:@"TwitterURT.URTModuleFooterViewModel"] || [class_name isEqualToString:@"TwitterURT.URTTimelineCarouselViewModel"]) {
                [_orig setHidden:true];
            }
        }
    }

    if ([self.adDisplayLocation isEqualToString:@"OTHER"]) {
        if ([BHTManager HidePromoted] && ([class_name isEqualToString:@"TwitterURT.URTModuleHeaderViewModel"] || [class_name isEqualToString:@"TwitterURT.URTModuleFooterViewModel"] || [class_name isEqualToString:@"T1URTTimelineMessageItemViewModel"])) {
            [_orig setHidden:true];
        }

        if ([BHTManager HidePromoted] && [class_name isEqualToString:@"TwitterURT.URTTimelineEventSummaryViewModel"]) {
            // Hide all EventSummaryViewModel items, not just promoted ones
            [_orig setHidden:true];
        }
        if ([BHTManager HidePromoted] && [class_name isEqualToString:@"TwitterURT.URTTimelineTrendViewModel"]) {
            _TtC10TwitterURT25URTTimelineTrendViewModel *trendModel = tweet;
            if ([[trendModel.scribeItem allKeys] containsObject:@"promoted_id"]) {
                [_orig setHidden:true];
            }
        }
        if ([BHTManager hideTrendVideos] && ([class_name isEqualToString:@"TwitterURT.URTModuleHeaderViewModel"] || [class_name isEqualToString:@"T1TwitterSwift.URTTimelineCarouselViewModel"])) {
            [_orig setHidden:true];
        }
    }

    if ([self.adDisplayLocation isEqualToString:@"TIMELINE_HOME"]) {
        if ([tweet isKindOfClass:%c(T1URTTimelineStatusItemViewModel)]) {
            T1URTTimelineStatusItemViewModel *fullTweet = tweet;
            if ([BHTManager HideTopics]) {
                if ((fullTweet.banner != nil) && [fullTweet.banner isKindOfClass:%c(TFNTwitterURTTimelineStatusTopicBanner)]) {
                    [_orig setHidden:true];
                }
            }
        }

        if ([BHTManager HideTopics]) {
            if ([tweet isKindOfClass:%c(_TtC10TwitterURT26URTTimelinePromptViewModel)]) {
                [_orig setHidden:true];
            }
        }

        if ([BHTManager hideWhoToFollow]) {
            if ([class_name isEqualToString:@"T1URTTimelineUserItemViewModel"] || [class_name isEqualToString:@"T1TwitterSwift.URTTimelineCarouselViewModel"] || [class_name isEqualToString:@"TwitterURT.URTModuleHeaderViewModel"] || [class_name isEqualToString:@"TwitterURT.URTModuleFooterViewModel"]) {
                [_orig setHidden:true];
            }
        }

        if ([BHTManager hidePremiumOffer]) {
            if ([class_name isEqualToString:@"T1URTTimelineMessageItemViewModel"]) {
                [_orig setHidden:true];
            }
        }
    }



    return _orig;
}
- (double)tableView:(id)arg1 heightForRowAtIndexPath:(id)arg2 {
    id tweet = [self itemAtIndexPath:arg2];
    NSString *class_name = NSStringFromClass([tweet classForCoder]);

    if ([BHTManager HidePromoted] && [tweet respondsToSelector:@selector(isPromoted)] && [tweet performSelector:@selector(isPromoted)]) {
        return 0;
    }

    if ([self.adDisplayLocation isEqualToString:@"PROFILE_TWEETS"]) {
        if ([BHTManager hideWhoToFollow]) {
            if ([class_name isEqualToString:@"T1URTTimelineUserItemViewModel"] || [class_name isEqualToString:@"T1TwitterSwift.URTTimelineCarouselViewModel"] || [class_name isEqualToString:@"TwitterURT.URTModuleHeaderViewModel"] || [class_name isEqualToString:@"TwitterURT.URTModuleFooterViewModel"]) {
                return 0;
            }
        }
        if ([BHTManager hideTopicsToFollow]) {
            if ([class_name isEqualToString:@"T1TwitterSwift.URTTimelineTopicCollectionViewModel"] || [class_name isEqualToString:@"TwitterURT.URTModuleHeaderViewModel"] || [class_name isEqualToString:@"TwitterURT.URTModuleFooterViewModel"] || [class_name isEqualToString:@"TwitterURT.URTTimelineCarouselViewModel"]) {
                return 0;
            }
        }
    }

    if ([self.adDisplayLocation isEqualToString:@"OTHER"]) {
        if ([BHTManager HidePromoted] && ([class_name isEqualToString:@"TwitterURT.URTModuleHeaderViewModel"] || [class_name isEqualToString:@"TwitterURT.URTModuleFooterViewModel"] || [class_name isEqualToString:@"T1URTTimelineMessageItemViewModel"])) {
            return 0;
        }

        if ([BHTManager HidePromoted] && [class_name isEqualToString:@"TwitterURT.URTTimelineEventSummaryViewModel"]) {
            // Hide all EventSummaryViewModel items, not just promoted ones
            return 0;
        }
        if ([BHTManager HidePromoted] && [class_name isEqualToString:@"TwitterURT.URTTimelineTrendViewModel"]) {
            _TtC10TwitterURT25URTTimelineTrendViewModel *trendModel = tweet;
            if ([[trendModel.scribeItem allKeys] containsObject:@"promoted_id"]) {
                return 0;
            }
        }

        if ([BHTManager hideTrendVideos] && ([class_name isEqualToString:@"TwitterURT.URTModuleHeaderViewModel"] || [class_name isEqualToString:@"TwitterURT.URTModuleFooterViewModel"] || [class_name isEqualToString:@"T1TwitterSwift.URTTimelineCarouselViewModel"])) {
            return 0;
        }
    }

    if ([self.adDisplayLocation isEqualToString:@"TIMELINE_HOME"]) {
        if ([tweet isKindOfClass:%c(T1URTTimelineStatusItemViewModel)]) {
            T1URTTimelineStatusItemViewModel *fullTweet = tweet;

            if ([BHTManager HideTopics]) {
                if ((fullTweet.banner != nil) && [fullTweet.banner isKindOfClass:%c(TFNTwitterURTTimelineStatusTopicBanner)]) {
                    return 0;
                }
            }
        }

        if ([BHTManager HideTopics]) {
            if ([tweet isKindOfClass:%c(_TtC10TwitterURT26URTTimelinePromptViewModel)]) {
                return 0;
            }
        }

        if ([BHTManager hideWhoToFollow]) {
            if ([class_name isEqualToString:@"T1URTTimelineUserItemViewModel"] || [class_name isEqualToString:@"T1TwitterSwift.URTTimelineCarouselViewModel"] || [class_name isEqualToString:@"TwitterURT.URTModuleHeaderViewModel"] || [class_name isEqualToString:@"TwitterURT.URTModuleFooterViewModel"]) {
                return 0;
            }
        }

        if ([BHTManager hidePremiumOffer]) {
            if ([class_name isEqualToString:@"T1URTTimelineMessageItemViewModel"]) {
                return 0;
            }
        }
    }



    return %orig;
}

- (double)tableView:(id)arg1 heightForHeaderInSection:(long long)arg2 {
    if (self.sections && self.sections[arg2] && ((NSArray* )self.sections[arg2]).count && self.sections[arg2][0]) {
        NSString *sectionClassName = NSStringFromClass([self.sections[arg2][0] classForCoder]);
        if ([sectionClassName isEqualToString:@"TFNTwitterUser"]) {
            return 0;
        }
    }
    return %orig;
}
%end

%hook TFNTwitterStatus
- (_Bool)isCardHidden {
    return ([BHTManager HidePromoted] && [self isPromoted]) ? true : %orig;
}
%end
