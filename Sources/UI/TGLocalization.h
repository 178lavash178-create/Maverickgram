#import <Foundation/Foundation.h>

NSString *TGLanguageCode(void);
void TGSetLanguageCode(NSString *code);
NSString *TGLoc(NSString *key);

// Presentation only; model type summaries remain stable routing identifiers.
NSString *TGLocalizedChatTypeSummary(NSString *summary);
