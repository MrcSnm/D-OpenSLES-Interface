module android.asset_manager_jni;
import android.asset_manager;

import arsd.jni;

extern(C):

/**
 * Given a Dalvik AssetManager object, obtain the corresponding native AAssetManager
 * object.  Note that the caller is responsible for obtaining and holding a VM reference
 * to the jobject to prevent its being garbage collected while the native object is
 * in use.
 */
AAssetManager* AAssetManager_fromJava(JNIEnv* env, jobject assetManager);
