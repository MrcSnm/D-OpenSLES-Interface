module sli.backend.opensles_decode;
import sli.backend.opensles_utils:allocate, free;
import std.string:toStringz;


//Needs to link with libandroid
import arsd.jni;
import bindbc.OpenSLES;
import android.asset_manager;
import android.asset_manager_jni;


__gshared AAssetManager* mgr;

struct SLIDataSource_Android
{
    SLDataLocator_AndroidFD* androidFDLocator;
    SLDataFormat_MIME* mimeFormat;
    SLDataSource source;

    static SLIDataSource_Android createDataSource(SLint32 fileDescriptorId, SLAint64 offset, SLAint64 length)
    {
        SLIDataSource_Android ret;
        with(ret)
        {
            androidFDLocator = allocate!SLDataLocator_AndroidFD;
            *androidFDLocator = SLDataLocator_AndroidFD(SL_DATALOCATOR_ANDROIDFD, fileDescriptorId, offset, length);
            mimeFormat = allocate!SLDataFormat_MIME;
            *mimeFormat = SLDataFormat_MIME(SL_DATAFORMAT_MIME, null, SL_CONTAINERTYPE_UNSPECIFIED);
            source = SLDataSource(androidFDLocator, mimeFormat);
        }
        return ret;
    }

    static void freeDataSource(ref SLIDataSource_Android dataSource)
    {
        with(dataSource)
        {
            free(androidFDLocator);
            free(mimeFormat);
        }
    }
   
}



bool sliStartDecoder(JNIEnv* env, void* managerFromJava)
{
    mgr = AAssetManager_fromJava(env, managerFromJava);
    openAudio("HopeToYou.wav");
    return mgr != null;
}

bool openAudio(string fileName)
{
    AAsset* asset =  AAssetManager_open(mgr, fileName.toStringz, AASSET_MODE.AASSET_MODE_UNKNOWN);
    import android.helper.log;
    import std.conv:to;

    if(asset == null)
    {
        LOGE("OPENSLES Decode", (to!string("Didn't work").toStringz));
        return false;
    }

    version(X86){off_t  start, length;}
    else        {off64_t start, length;}

    int fileDescriptor = AAsset_openFileDescriptor(asset, &start, &length); //Get data
    AAsset_close(asset);

    //Test

    SLIDataSource_Android ds = SLIDataSource_Android.createDataSource(fileDescriptor, start, length);

    return true;
}