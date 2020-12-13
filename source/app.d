import std.stdio;
import sli.backend.opensles_interface;
import android.asset_manager;
import sli.backend.opensles_decode:sliStartDecoder;
import bindbc.OpenSLES;
import arsd.jni;

extern(C):
void Java_com_hipreme_zenambience_MainActivity_AudioEngineEntryPoint(JNIEnv* env, jclass clazz, jobject assetManager)
{
	import core.runtime:rt_init;
	rt_init();
	sliCreateOutputContext();
	sliStartDecoder(env,  assetManager);
}