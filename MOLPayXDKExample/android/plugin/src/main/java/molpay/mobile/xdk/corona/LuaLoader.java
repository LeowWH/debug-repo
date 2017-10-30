package molpay.mobile.xdk.corona;

import android.content.Intent;
import android.util.Log;

import com.ansca.corona.CoronaActivity;
import com.ansca.corona.CoronaEnvironment;
import com.ansca.corona.CoronaLua;
import com.ansca.corona.CoronaRuntime;
import com.ansca.corona.CoronaRuntimeListener;
import com.ansca.corona.CoronaRuntimeTask;
import com.naef.jnlua.JavaFunction;
import com.naef.jnlua.LuaState;
import com.naef.jnlua.LuaType;
import com.naef.jnlua.NamedJavaFunction;

import java.util.ArrayList;
import java.util.HashMap;
import com.molpay.molpayxdk.MOLPayActivity;


@SuppressWarnings("WeakerAccess")
public class LuaLoader implements JavaFunction, CoronaRuntimeListener {
	public static int fListener;
	public static int requestCode;
	public static final String EVENT_NAME = "MOLPayEvent";

	@SuppressWarnings("unused")
	public LuaLoader() {
		fListener = CoronaLua.REFNIL;
		CoronaEnvironment.addRuntimeListener(this);
	}
	@Override
	public int invoke(LuaState L) {
		NamedJavaFunction[] luaFunctions = new NamedJavaFunction[] {
			new startMolpay()
		};
		String libName = L.toString( 1 );
		L.register(libName, luaFunctions);

		// Returning 1 indicates that the Lua require() function will return the above Lua library.
		return 1;
	}
	@Override
	public void onLoaded(CoronaRuntime runtime) {}
	@Override
	public void onStarted(CoronaRuntime runtime) {}
	@Override
	public void onSuspended(CoronaRuntime runtime) {}
	@Override
	public void onResumed(CoronaRuntime runtime) {}
	@Override
	public void onExiting(CoronaRuntime runtime) {
		CoronaLua.deleteRef( runtime.getLuaState(), fListener );
		fListener = CoronaLua.REFNIL;
	}

	public int startMolpay(LuaState L){

		if ( CoronaLua.isListener( L, 2, EVENT_NAME ) ) {
			fListener = CoronaLua.newRef( L, 2 );
		}
		HashMap<String, Object> paymentDetails = new HashMap<>();

		L.checkType(1, com.naef.jnlua.LuaType.TABLE);
		for (L.pushNil(); L.next(1); L.pop(1)) {
			String keyName = "";
			keyName = L.toString(-2);
			if(keyName == ""){
				continue;
			}

			LuaType luaType = L.type(-1);
			String valueString = "";
			switch (luaType) {
				case STRING:
					valueString = L.toString(-1);
					paymentDetails.put(keyName, valueString);
					break;
				case BOOLEAN:
					Boolean val = L.toBoolean(-1);
							paymentDetails.put(keyName, val);
				break;
				case TABLE:
					ArrayList<String> ar = new ArrayList<String>();
					int N = L.length(-1);
					for (int i = 1; i <= N; ++i)
					{
						L.rawGet(-1, i); // array# at stack top
						{
							ar.add(L.toString(-1));
						}
						L.pop(1); // pop array#
					}
					paymentDetails.put(keyName, ar);
					break;
			}
		}

		paymentDetails.put("is_submodule", true);
		paymentDetails.put("module_id", "molpay-mobile-xdk-corona-android");
		paymentDetails.put("wrapper_version", "0");
		requestCode = CoronaEnvironment.getCoronaActivity().registerActivityResultHandler(new MOLPayCoronaHandler());
		Intent intent = new Intent(CoronaEnvironment.getCoronaActivity(), MOLPayActivity.class);
		intent.putExtra(MOLPayActivity.MOLPayPaymentDetails,paymentDetails);
		CoronaEnvironment.getCoronaActivity().startActivityForResult(intent, requestCode);

		return 0;
	}

	private class startMolpay implements NamedJavaFunction{
		@Override
		public String getName() {return "startMolpay";}

		@Override
		public int invoke(LuaState L){return  startMolpay(L);}

	}
}

class MOLPayCoronaHandler implements CoronaActivity.OnActivityResultHandler {
	public MOLPayCoronaHandler() {}

	@Override
	public void onHandleActivityResult(CoronaActivity activity, int requestCode, int resultCode, final Intent data)
	{
		if (requestCode == LuaLoader.requestCode){
			Log.d(MOLPayActivity.MOLPAY, "MOLPay result = "+data.getStringExtra(MOLPayActivity.MOLPayTransactionResult));
			activity.unregisterActivityResultHandler(this);

			CoronaEnvironment.getCoronaActivity().getRuntimeTaskDispatcher().send( new CoronaRuntimeTask() {
				@Override
				public void executeUsing(CoronaRuntime runtime) {
					LuaState L = runtime.getLuaState();

					CoronaLua.newEvent( L, LuaLoader.EVENT_NAME );
					L.pushString(data.getStringExtra(MOLPayActivity.MOLPayTransactionResult));
					L.setField(-2, "results");

					try {
						CoronaLua.dispatchEvent( L, LuaLoader.fListener, 0 );
					} catch (Exception ignored) {
					}
				}
			} );
		}
	}
}
