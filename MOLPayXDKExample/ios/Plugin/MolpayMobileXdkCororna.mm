//
//  PluginLibrary.mm
//  TemplateApp
//
//  Copyright (c) 2012 __MyCompanyName__. All rights reserved.
//

#import "MolpayMobileXdkCororna.h"

#include <CoronaRuntime.h>
#import <UIKit/UIKit.h>
#include "MOLPayViewController.h"
#import "MOLPayLib.h"

@interface MOLPay :NSObject
@end
@implementation MOLPay
-(NSMutableDictionary*)getTable:(lua_State *) L{
    NSMutableDictionary *returnObject = [[NSMutableDictionary alloc] init];
    luaL_checktype(L, 1, LUA_TTABLE);
    
    for (lua_pushnil(L); lua_next(L, 1); lua_pop(L, 1)) {
        NSString *keyName = NULL;
        keyName = [NSString stringWithFormat:@"%s", lua_tostring(L, -2)];
        if(keyName == NULL){
            continue;
        }
        int luaType = lua_type(L, -1);
        NSString *valueString = @"";
        if([keyName isEqual: @"mp_custom_css_url"]){
            valueString = [[NSBundle mainBundle] pathForResource:[NSString stringWithFormat:@"%s",lua_tostring(L, -1)] ofType:nil];
            [returnObject setObject:valueString forKey:keyName];
            continue;
        }
        switch (luaType) {
            case LUA_TSTRING:
                valueString = [NSString stringWithFormat:@"%s",lua_tostring(L, -1)];
                [returnObject setObject:valueString forKey:keyName];
                break;
            case LUA_TBOOLEAN:
                valueString = [NSString stringWithFormat:@"%d",lua_toboolean(L, -1)];
                NSNumber *bol;
                if([valueString  isEqual: @"1"]){
                    bol = [NSNumber numberWithBool:YES];
                }else{
                    bol =[NSNumber numberWithBool:NO];
                }
                
                [returnObject setObject:bol forKey:keyName];
                break;
            case LUA_TTABLE:
                size_t N = lua_objlen(L,-1);
                NSMutableArray *array = [[NSMutableArray alloc] init];
                for (int i = 1; i <= N; ++i)
                {
                    lua_rawgeti(L,-1, i); // array# at stack top
                    {
                        [array addObject:[NSString stringWithFormat:@"%s",lua_tostring(L, -1)]];
                    }
                    lua_pop(L, 1); // pop array#
                }
                [returnObject setObject:array forKey:keyName];
                break;
        }
    }
    
    [returnObject setObject:@"YES" forKey:@"is_submodule"];
    [returnObject setObject:@"molpay-mobile-xdk-corona-ios" forKey:@"module_id"];
    [returnObject setObject:@"0" forKey:@"wrapper_version"];
    
    return returnObject;
}
@end
// ----------------------------------------------------------------------------
class PluginLibrary
{
	public:
		typedef PluginLibrary Self;

	public:
		static const char kName[];
		static const char kEvent[];
        static CoronaLuaRef fListener;
	protected:
		PluginLibrary();

	public:
		CoronaLuaRef GetListener() const { return fListener; }

	public:
		static int Open( lua_State *L );

	protected:
		static int Finalizer( lua_State *L );

	public:
		static Self *ToLibrary( lua_State *L );

	public:
        static int startMolpay( lua_State *L);
    
};

// ----------------------------------------------------------------------------
const char PluginLibrary::kName[] = "molpay.mobile.xdk.corona";
const char PluginLibrary::kEvent[] = "MOLPayEvent";
CoronaLuaRef PluginLibrary::fListener;
PluginLibrary::PluginLibrary(){};

int
PluginLibrary::Open( lua_State *L )
{
	// Register __gc callback
	const char kMetatableName[] = __FILE__; // Globally unique string to prevent collision
	CoronaLuaInitializeGCMetatable( L, kMetatableName, Finalizer );

	// Functions in library
	const luaL_Reg kVTable[] =
	{
        { "startMolpay", startMolpay},

		{ NULL, NULL }
	};

	Self *library = new Self;
	CoronaLuaPushUserdata( L, library, kMetatableName );
    
    luaL_openlib( L, kName, kVTable, 1 ); // leave "library" on top of stack

	return 1;
}

int
PluginLibrary::Finalizer( lua_State *L )
{
	Self *library = (Self *)CoronaLuaToUserdata( L, 1 );

	CoronaLuaDeleteRef( L, library->GetListener() );

	delete library;

	return 0;
}

PluginLibrary *
PluginLibrary::ToLibrary( lua_State *L )
{
	// library is pushed as part of the closure
	Self *library = (Self *)CoronaLuaToUserdata( L, lua_upvalueindex( 1 ) );
	return library;
}

int
PluginLibrary::startMolpay( lua_State *L )
{
    MOLPay *obj=[[MOLPay alloc]init]; //Allocating the new object for the objective C   class we created
    
    NSMutableDictionary *paymentDetails = [obj getTable:L];
    
    MOLPayViewController *mpvc = [[MOLPayViewController alloc] init];
    
    CoronaLuaRef listener = CoronaLuaNewRef( L, 2 );
    
    fListener = listener;
    
    [mpvc.view setBackgroundColor:[UIColor whiteColor]];
    
    mpvc.PaymentDetails = paymentDetails;
    
    UINavigationController *nc = [[UINavigationController alloc] initWithRootViewController:mpvc];
    
    mpvc.didDismiss = ^(NSDictionary *data) {
        CoronaLuaNewEvent( L, kEvent );
        NSError * err;
        NSData * jsonData = [NSJSONSerialization dataWithJSONObject:data options:0 error:&err];
        NSString * myString = [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
        lua_pushstring( L, [myString UTF8String] );
        lua_setfield( L, -2, "results" );
        CoronaLuaDispatchEvent( L, fListener, 0 );
    };
    [[UIApplication sharedApplication].keyWindow.rootViewController presentViewController:nc animated:YES completion:nil];
    
    return 0;
}

// ----------------------------------------------------------------------------

CORONA_EXPORT int luaopen_molpay_mobile_xdk_corona( lua_State *L )
{
	return PluginLibrary::Open( L );
}
