
@interface FMLHandle : NSObject {
    NSString * _identifier;
}

@property (nonatomic, copy) NSString *identifier;

+ (id)handleWithIdentifier:(id)arg1;

- (id)comparisonIdentifier;
- (id)debugDescription;
- (id)description;
- (unsigned long long)hash;
- (id)identifier;
- (bool)isEqual:(id)arg1;
- (void)setIdentifier:(id)arg1;

@end
