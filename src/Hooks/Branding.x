//
//  Branding.x
//  NeoFreeBird
//

#import "BHTHookHelpers.h"

// MARK: Restore Twitter terminology, controlled by "restore_twitter_names"
// Two layers, both driven by locale files in the tweak bundle:
//   1. RenameOverrides.strings — Twitter localization key -> exact replacement,
//      a missing key falls through to the generic replacement
//   2. RenameWords.strings — generic word replacements ("X" -> "Twitter",
//      "Post" -> "Tweet", etc.) applied to localized and server-side strings
// Both are strictly per-language: a language without its own copy of a file gets no
// renaming from that layer, rather than English rules applied to non-English text.

static NSDictionary<NSString *, NSString *> *BHTRenameTable(NSString *name) {
    NSBundle *bundle = [BHTBundle sharedBundle].mainBundle;
    NSString *appLanguage = [[NSBundle mainBundle] preferredLocalizations].firstObject ?: @"en";
    NSString *localization = [NSBundle preferredLocalizationsFromArray:bundle.localizations
                                                        forPreferences:@[appLanguage]].firstObject;

    // preferredLocalizationsFromArray: silently returns the development region (en)
    // when nothing matches, so reject a locale that disagrees with the app language:
    // unsupported languages then skip renaming instead of getting English rules.
    NSString *appCode = [appLanguage componentsSeparatedByString:@"-"].firstObject;
    NSString *lprojCode = [[localization stringByReplacingOccurrencesOfString:@"_" withString:@"-"]
                              componentsSeparatedByString:@"-"].firstObject;
    if (![appCode isEqualToString:lprojCode]) {
        return @{};
    }

    NSString *path = [bundle pathForResource:name ofType:@"strings" inDirectory:nil forLocalization:localization];
    NSString *contents = path ? [NSString stringWithContentsOfFile:path encoding:NSUTF8StringEncoding error:nil] : nil;
    NSDictionary *table = [contents propertyListFromStringsFileFormat];
    return [table isKindOfClass:[NSDictionary class]] ? table : @{};
}

static NSDictionary<NSString *, NSString *> *BHTRenameKeyOverrides(void) {
    static NSDictionary *overrides = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ overrides = BHTRenameTable(@"RenameOverrides"); });
    return overrides;
}

static NSDictionary<NSString *, NSString *> *BHTwitterWordMap(void) {
    static NSDictionary *map = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ map = BHTRenameTable(@"RenameWords"); });
    return map;
}

// Builds a case-insensitive \b(word|word…)\b from every map key, longest word first
// so inflections win over their stems ("reposts" before "repost"). Matching is always
// case-insensitive; per-match resolution (see BHRenameEdits) enforces exact case for
// keys that carry an uppercase letter, so lowercase "x" never becomes "Twitter".
static NSRegularExpression *BHTRenameRegex(void) {
    NSMutableArray<NSString *> *words = [NSMutableArray array];
    for (NSString *word in BHTwitterWordMap()) {
        [words addObject:[NSRegularExpression escapedPatternForString:word]];
    }
    if (words.count == 0) {
        return nil;
    }

    [words sortUsingComparator:^NSComparisonResult(NSString *a, NSString *b) {
        if (a.length > b.length) return NSOrderedAscending;
        if (a.length < b.length) return NSOrderedDescending;
        return [a compare:b];
    }];
    NSString *pattern = [NSString stringWithFormat:@"\\b(%@)\\b", [words componentsJoinedByString:@"|"]];
    return [NSRegularExpression regularExpressionWithPattern:pattern
                                                     options:NSRegularExpressionCaseInsensitive
                                                       error:nil];
}

// Applies the capitalisation style of `token` (all-caps or leading-capital) to `base`.
static NSString *BHMatchCapitalisation(NSString *token, NSString *base) {
    if (token.length == 0 || base.length == 0) {
        return base;
    }

    NSString *lower = token.lowercaseString;
    if (token.length > 1 && [token isEqualToString:token.uppercaseString] && ![token isEqualToString:lower]) {
        return base.uppercaseString;
    }

    unichar first = [token characterAtIndex:0];
    if ([[NSCharacterSet uppercaseLetterCharacterSet] characterIsMember:first]) {
        return [base stringByReplacingCharactersInRange:NSMakeRange(0, 1)
                                             withString:[base substringToIndex:1].uppercaseString];
    }
    return base;
}

// Returns the edits (@"range" -> NSValue, @"repl" -> NSString) to apply to `input`, in
// ascending order — the single regex pass yields non-overlapping left-to-right matches,
// so callers apply them back-to-front and no edit invalidates a later range.
// Returns nil when there is nothing to change.
static NSArray<NSDictionary *> *BHRenameEdits(NSString *input) {
    if (input.length == 0) {
        return nil;
    }

    static NSRegularExpression *regex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ regex = BHTRenameRegex(); });
    if (!regex) {
        return nil;
    }

    NSDictionary *wordMap = BHTwitterWordMap();
    NSRange full = NSMakeRange(0, input.length);
    NSMutableArray<NSDictionary *> *edits = [NSMutableArray array];

    for (NSTextCheckingResult *match in [regex matchesInString:input options:0 range:full]) {
        NSString *token = [input substringWithRange:match.range];
        // Exact key wins (uppercase-bearing keys like "X" replace verbatim); otherwise
        // fall back to the lowercase key and copy the token's capitalisation. A lowercase
        // occurrence of an uppercase-only key resolves to neither and is left alone.
        NSString *repl = wordMap[token];
        if (!repl) {
            NSString *base = wordMap[token.lowercaseString];
            repl = base ? BHMatchCapitalisation(token, base) : nil;
        }
        if (repl) {
            [edits addObject:@{@"range": [NSValue valueWithRange:match.range], @"repl": repl}];
        }
    }

    return edits.count > 0 ? edits : nil;
}

static NSString *BHRestoreTwitterTerminology(NSString *input) {
    // Memoise: labels re-set the same handful of strings over and over.
    static NSCache<NSString *, NSString *> *cache = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{ cache = [NSCache new]; });

    NSString *cached = [cache objectForKey:input];
    if (cached) {
        return cached;
    }

    NSArray<NSDictionary *> *edits = BHRenameEdits(input);
    NSString *output = input;
    if (edits) {
        NSMutableString *result = [input mutableCopy];
        for (NSDictionary *edit in edits.reverseObjectEnumerator) {
            [result replaceCharactersInRange:[edit[@"range"] rangeValue] withString:edit[@"repl"]];
        }
        output = [result copy];
    }

    [cache setObject:output forKey:input];
    return output;
}

static NSAttributedString *BHRestoreTwitterAttributed(NSAttributedString *input) {
    NSArray<NSDictionary *> *edits = BHRenameEdits(input.string);
    if (!edits) {
        return input;
    }

    NSMutableAttributedString *result = [input mutableCopy];
    for (NSDictionary *edit in edits.reverseObjectEnumerator) {
        NSRange range = [edit[@"range"] rangeValue];
        NSDictionary *attrs = [result attributesAtIndex:range.location effectiveRange:NULL];
        NSAttributedString *piece = [[NSAttributedString alloc] initWithString:edit[@"repl"] attributes:attrs];
        [result replaceCharactersInRange:range withAttributedString:piece];
    }
    return result;
}

// MARK: Rename localized strings, controlled by "restore_twitter_names"
// Every UI string routes through this Foundation method in 12.3, so the rename
// applies broadly. Skip our own bundle so the tweak's strings aren't reprocessed.
%hook NSBundle
- (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName {
    NSString *result = %orig;
    if (![BHTSettings boolForKey:@"restore_twitter_names"] || self == [BHTBundle sharedBundle].mainBundle) {
        return result;
    }

    NSString *override = key ? BHTRenameKeyOverrides()[key] : nil;
    if (override) {
        return override;
    }
    return result.length > 0 ? BHRestoreTwitterTerminology(result) : result;
}
%end

// MARK: Rename server-composed text + colour restored source labels
// TFNAttributedTextView renders interface chrome and server-composed URT text
// (notification headers, footers, timestamps, counts…) that carries no localization
// key, so the NSBundle hook can't reach it. Tweet bodies also flow through here:
// TTAStatusBodyAttributedTextView is a TFNAttributedTextView subclass that doesn't
// override setTextModel:, so the rename is skipped for it to avoid mangling a user's
// own words ("Post", "Tweet", …) inside their tweet.
%hook TFNAttributedTextView
- (void)setTextModel:(TFNAttributedTextModel *)model {
    if (!model || !model.attributedString) {
        %orig(model);
        return;
    }

    NSString *currentText = model.attributedString.string;
    NSMutableAttributedString *newString = nil;
    BOOL textChanged = NO;

    // --- Tweet source label colouring ---
    if ([BHTSettings boolForKey:@"restore_tweet_labels"] && tweetSources.count > 0) {
        NSString *unavailable = [[BHTBundle sharedBundle] localizedStringForKey:@"SOURCE_UNAVAILABLE"];
        for (NSString *sourceText in tweetSources.allValues) {
            if (sourceText.length > 0 &&
                ![sourceText isEqualToString:unavailable] &&
                [currentText containsString:sourceText]) {

                NSRange sourceRange = [currentText rangeOfString:sourceText];
                if (sourceRange.location != NSNotFound) {
                    UIColor *existingColor = [model.attributedString attribute:NSForegroundColorAttributeName
                                                                       atIndex:sourceRange.location
                                                                effectiveRange:NULL];
                    UIColor *accentColor = BHTCurrentAccentColor();

                    if (!existingColor || ![existingColor isEqual:accentColor]) {
                        if (!newString) {
                            newString = [[NSMutableAttributedString alloc] initWithAttributedString:model.attributedString];
                        }
                        // Add only the colour attribute, don't overwrite the run.
                        [newString addAttribute:NSForegroundColorAttributeName
                                          value:accentColor
                                          range:sourceRange];
                    }
                }
                break; // Only colour the first matching source.
            }
        }
    }

    // --- Restore Twitter terminology (never on tweet bodies) ---
    if ([BHTSettings boolForKey:@"restore_twitter_names"] &&
        ![self isKindOfClass:%c(TTAStatusBodyAttributedTextView)]) {
        NSAttributedString *source = newString ?: model.attributedString;
        NSAttributedString *renamed = BHRestoreTwitterAttributed(source);
        if (renamed != source) {
            newString = [renamed mutableCopy];
            textChanged = YES;
        }
    }

    if (!newString) {
        %orig(model);
        return;
    }

    if (textChanged) {
        // Text length changed, so rebuild the model to refresh length-derived state.
        TFNAttributedTextModel *newModel =
            [[%c(TFNAttributedTextModel) alloc] initWithAttributedString:newString];
        %orig(newModel);
    } else if ([model respondsToSelector:@selector(setAttributedString:)]) {
        // Attributes only: keep the model to preserve its layout metadata.
        [model setAttributedString:newString];
        %orig(model);
    } else {
        TFNAttributedTextModel *newModel =
            [[%c(TFNAttributedTextModel) alloc] initWithAttributedString:newString];
        %orig(newModel);
    }
}
%end

// MARK: Label the "new posts" refresh pill, controlled by "refresh_pill_label"
// TUIUpdateIndicator rebuilds its pill on every presentation and hardcodes blank text
// on the facepile variant (no feature flag gates it); it used to say "posted". The
// tweak ships that label in the app's terminology and routes it through the rename
// pipeline, so "restore_twitter_names" converts it per-language like any app string.
static NSString *BHPillLabelText(void) {
    NSString *label = [[BHTBundle sharedBundle] localizedStringForKey:@"REFRESH_PILL_TEXT"];
    if ([BHTSettings boolForKey:@"restore_twitter_names"]) {
        label = BHRestoreTwitterTerminology(label);
    }
    return label;
}

%hook TUIUpdateIndicator

- (void)_recreatePillControlForContentNotification:(id)notification hideOnScroll:(BOOL)hideOnScroll {
    %orig;

    if (![BHTSettings boolForKey:@"refresh_pill_label"]) {
        return;
    }

    TFNPillControl *pill = self.pillControl;
    NSString *current = [pill.text stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]];
    if (current.length > 0) {
        return;
    }

    NSString *label = BHPillLabelText();
    if (label) {
        pill.text = label;
    }
}

%end
