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

    // preferredLocalizationsFromArray: if there's no match, it silently
    // returns the development region (en) instead, and rejects that so unsupported
    // languages skip renaming rather than getting English rules
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

// Builds \b(word|word…)\b from the map keys of one sensitivity class, longest word
// first so inflections win over their stems ("reposts" before "repost").
static NSRegularExpression *BHTRenameRegex(BOOL caseSensitive) {
    NSMutableArray<NSString *> *words = [NSMutableArray array];
    for (NSString *word in BHTwitterWordMap()) {
        BOOL hasUpper = [word rangeOfCharacterFromSet:[NSCharacterSet uppercaseLetterCharacterSet]].location != NSNotFound;
        if (hasUpper == caseSensitive) {
            [words addObject:[NSRegularExpression escapedPatternForString:word]];
        }
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
                                                     options:(caseSensitive ? 0 : NSRegularExpressionCaseInsensitive)
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

// Returns the ordered list of edits (@"range" -> NSValue, @"repl" -> NSString) to apply
// to `input`, sorted last-match-first so applying them never invalidates a later range.
// Returns nil when there is nothing to change.
static NSArray<NSDictionary *> *BHRenameEdits(NSString *input) {
    if (input.length == 0) {
        return nil;
    }

    static NSRegularExpression *insensitiveRegex = nil;
    static NSRegularExpression *sensitiveRegex = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        insensitiveRegex = BHTRenameRegex(NO);
        sensitiveRegex = BHTRenameRegex(YES);
    });

    NSDictionary *wordMap = BHTwitterWordMap();
    NSRange full = NSMakeRange(0, input.length);
    NSMutableArray<NSDictionary *> *edits = [NSMutableArray array];

    for (NSTextCheckingResult *match in [sensitiveRegex matchesInString:input options:0 range:full]) {
        NSString *repl = wordMap[[input substringWithRange:match.range]];
        if (repl) {
            [edits addObject:@{@"range": [NSValue valueWithRange:match.range], @"repl": repl}];
        }
    }

    for (NSTextCheckingResult *match in [insensitiveRegex matchesInString:input options:0 range:full]) {
        NSString *token = [input substringWithRange:match.range];
        NSString *base = wordMap[token.lowercaseString];
        if (base) {
            [edits addObject:@{@"range": [NSValue valueWithRange:match.range],
                               @"repl": BHMatchCapitalisation(token, base)}];
        }
    }

    if (edits.count == 0) {
        return nil;
    }

    [edits sortUsingComparator:^NSComparisonResult(NSDictionary *a, NSDictionary *b) {
        NSUInteger la = [a[@"range"] rangeValue].location;
        NSUInteger lb = [b[@"range"] rangeValue].location;
        if (la > lb) return NSOrderedAscending;
        if (la < lb) return NSOrderedDescending;
        return NSOrderedSame;
    }];
    return edits;
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
        for (NSDictionary *edit in edits) {
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
    for (NSDictionary *edit in edits) {
        NSRange range = [edit[@"range"] rangeValue];
        NSDictionary *attrs = [result attributesAtIndex:range.location effectiveRange:NULL];
        NSAttributedString *piece = [[NSAttributedString alloc] initWithString:edit[@"repl"] attributes:attrs];
        [result replaceCharactersInRange:range withAttributedString:piece];
    }
    return result;
}

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

%hook TFNAttributedTextView
- (void)setTextModel:(TFNAttributedTextModel *)model {
    if (!model || !model.attributedString) {
        %orig(model);
        return;
    }

    NSString *currentText = model.attributedString.string;
    NSMutableAttributedString *newString = nil;
    BOOL modified = NO;
    BOOL textChanged = NO;

    // --- Tweet source label coloring ---
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
                        // Add only the color attribute, do not overwrite the run
                        [newString addAttribute:NSForegroundColorAttributeName
                                          value:accentColor
                                          range:sourceRange];
                        modified = YES;
                        // attributes only, textChanged stays NO
                    }
                }
                break; // Only color the first matching source
            }
        }
    }

    // --- Restore Twitter terminology ---
    // TFNAttributedTextView renders interface chrome (notification headers, footers,
    // timestamps, counts…). Tweet bodies use T1StatusBodyTextView /
    // TTAStatusBodySelectableContentTextView, so they never reach this hook and are
    // left untouched. The rewrite is driven by the shared word-boundary transform, so
    // it changes the actual rendered text rather than a hardcoded list of phrases.
    if ([BHTSettings boolForKey:@"restore_twitter_names"]) {
        NSAttributedString *source = newString ?: model.attributedString;
        NSAttributedString *renamed = BHRestoreTwitterAttributed(source);
        if (renamed != source) {
            newString = [renamed mutableCopy];
            modified = YES;
            textChanged = YES;
        }
    }

    // --- Apply modifications if needed ---
    if (modified && newString) {
        if (textChanged) {
            // Text changed, use a new model so length-related state is rebuilt
            TFNAttributedTextModel *newModel =
                [[%c(TFNAttributedTextModel) alloc] initWithAttributedString:newString];
            %orig(newModel);
        } else if ([model respondsToSelector:@selector(setAttributedString:)]) {
            // Attributes only, keep model to preserve layout metadata
            [model setAttributedString:newString];
            %orig(model);
        } else {
            TFNAttributedTextModel *newModel =
                [[%c(TFNAttributedTextModel) alloc] initWithAttributedString:newString];
            %orig(newModel);
        }
    } else {
        %orig(model);
    }
}
%end

// Helper for the refresh pill setting
static BOOL BHPillLabelOverrideEnabled(void) {
    return [BHTSettings boolForKey:@"refresh_pill_label"];
}

// Only the "new posts/Tweets" refresh pill should be relabelled. TFNPillControl
// is used for other pills too ("Back to top", counts, …); the old code forced
// every pill's text to "Tweeted" and corrupted their reads. Gate on the pill's
// own text mentioning posts/tweets.
static BOOL BHPillTextIsNewContent(id text) {
    if (![text isKindOfClass:[NSString class]]) return NO;
    NSString *s = [(NSString *)text lowercaseString];
    return [s containsString:@"post"] || [s containsString:@"tweet"];
}

// MARK: Change Pill text, controlled by "refresh_pill_label"
%hook TFNPillControl

- (id)text {
    id origText = %orig;
    if (!BHPillLabelOverrideEnabled() || !BHPillTextIsNewContent(origText)) {
        // Setting off, or not the new-content pill: keep original behavior
        return origText;
    }

    NSString *localizedText = [[BHTBundle sharedBundle] localizedStringForKey:@"REFRESH_PILL_TEXT"];
    NSString *fallback = @"Tweeted";
    return localizedText ?: fallback;
}

- (void)setText:(id)arg1 {
    if (!BHPillLabelOverrideEnabled() || !BHPillTextIsNewContent(arg1)) {
        // Setting off, or not the new-content pill: pass through original argument
        return %orig(arg1);
    }

    NSString *localizedText = [[BHTBundle sharedBundle] localizedStringForKey:@"REFRESH_PILL_TEXT"];
    NSString *fallback = arg1 ?: @"Tweeted";
    %orig(localizedText ?: fallback);
}

%end
