//
//     Generated by class-dump 3.5 (64 bit) (Debug version compiled Jun  9 2015 22:53:21).
//
//     class-dump is Copyright (C) 1997-1998, 2000-2001, 2004-2014 by Steve Nygard.
//

@interface IMAccount (AliasAdditions)
- (id)loginName;
- (id)phoneNumberAlias;
- (id)allAliases;
- (long long)numberOfActiveAliases;
- (BOOL)isAliasActivated:(id)arg1;
- (double)timeIntervalSinceEmailWasSentForAlias:(id)arg1;
- (void)removeCreationMarker:(id)arg1;
- (void)setCreationMarker:(id)arg1;
@end
