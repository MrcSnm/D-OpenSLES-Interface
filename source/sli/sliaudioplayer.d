module sli.sliaudioplayer;
import std.algorithm:count;
import bindbc.OpenSLES;
import sli.backend.opensles_utils;
import android.log;

string getAndroidAudioPlayerInterfaces()
{
    string itfs = "SL_IID_VOLUME, SL_IID_EFFECTSEND, SL_IID_METADATAEXTRACTION";
    version(Android)
    {
        itfs~=", SL_IID_ANDROIDSIMPLEBUFFERQUEUE";
    }
    return itfs;
}
string getAndroidAudioPlayerRequirements()
{
    string req;
    bool isFirst = true;
    foreach (i; 0..getAndroidAudioPlayerInterfaces().count(",")+1)
    {
        if(isFirst)isFirst=!isFirst;
        else req~=",";
        req~= "SL_BOOLEAN_TRUE";
    }
    return req;
}



struct SLIAudioPlayer
{
    ///The Audio player
    SLObjectItf playerObj;
    ///Play/stop/pause the audio
    SLPlayItf player;
    ///Controls the volume
    SLVolumeItf playerVol;
    ///Ability to get and set the audio duration
    SLSeekItf playerSeek;
    ///@TODO
    SLEffectSendItf playerEffectSend;
    ///@TODO
    SLMetadataExtractionItf playerMetadata;

    version(Android){SLAndroidSimpleBufferQueueItf playerAndroidSimpleBufferQueue;}
    else  //Those lines will appear just as a documentation, right now, we don't have any implementation using it
    {
        ///@NO_SUPPORT
        SL3DSourceItf source3D;
        SL3DDopplerItf doppler3D;
        SL3DLocationItf location3D;
    }
    bool isPlaying, hasFinishedTrack;

    float volume;

    static void setVolume(ref SLIAudioPlayer audioPlayer, float gain)
    {
        with(audioPlayer)
        {
            (*playerVol).SetVolumeLevel(playerVol, cast(SLmillibel)(toAttenuation(gain)*100));
            volume = gain;
        }
    }

    static void destroyAudioPlayer(ref SLIAudioPlayer audioPlayer)
    {
        with(audioPlayer)
        {
            (*playerObj).Destroy(playerObj);
            playerObj = null;
            player = null;
            playerVol = null;
            playerSeek = null;
            playerEffectSend = null;
            version(Android){playerAndroidSimpleBufferQueue = null;}

        }
    }

    extern(C) static void checkClipEnd_Callback(SLPlayItf player, void* context, SLuint32 event)
    {
        if(event & SL_PLAYEVENT_HEADATEND)
        {
            SLIAudioPlayer p = *(cast(SLIAudioPlayer*)context);
            p.hasFinishedTrack = true;
        }
    }
    static void play(ref SLIAudioPlayer audioPlayer, void* samples, uint sampleSize)
    {
        with(audioPlayer)
        {
            version(Android){(*playerAndroidSimpleBufferQueue).Enqueue(playerAndroidSimpleBufferQueue, samples, sampleSize);}
            isPlaying = true;
            hasFinishedTrack = false;

            (*player).SetPlayState(player, SL_PLAYSTATE_PLAYING);
        }
    }
    static void stop(ref SLIAudioPlayer audioPlayer)
    {
        with(audioPlayer)
        {
            (*player).SetPlayState(player, SL_PLAYSTATE_STOPPED);
            version(Android){(*playerAndroidSimpleBufferQueue).Clear(playerAndroidSimpleBufferQueue);}
            isPlaying = false;
        }
    }

    static void checkFinishedPlaying(ref SLIAudioPlayer audioPlayer)
    {
        if(audioPlayer.isPlaying && audioPlayer.hasFinishedTrack)
        {
            SLIAudioPlayer.stop(audioPlayer);
        }
    }



    static bool initializeForAndroid(ref SLIAudioPlayer output, ref SLEngineItf engine, ref SLDataSource src, ref SLDataSink dest, bool autoRegisterCallback = true)
    {
        string[] errs;
        with(output)
        {
            mixin("const(SLInterfaceID)* ids = ["~getAndroidAudioPlayerInterfaces()~"].ptr;");
            mixin("const(SLboolean)* req = ["~getAndroidAudioPlayerRequirements()~"].ptr;");

            if(slError((*engine).CreateAudioPlayer(engine, &playerObj, &src, &dest,
            cast(uint)(getAndroidAudioPlayerInterfaces().count(",")+1), ids, req)))
                errs~= slGetError("Could not create AudioPlayer");
            if(slError((*playerObj).Realize(playerObj, SL_BOOLEAN_FALSE)))
                errs~= slGetError("Could not initialize AudioPlayer");

            __android_log_print(android_LogPriority.ANDROID_LOG_DEBUG, "SLES", "Created audio player");
            

            if(slError((*playerObj).GetInterface(playerObj, SL_IID_PLAY, &player)))
                errs~= slGetError("Could not get play interface for AudioPlayer");
            if(slError((*playerObj).GetInterface(playerObj, SL_IID_VOLUME, &playerVol)))
                errs~= slGetError("Could not get volume interface for AudioPlayer");
            
            // if(slError((*playerObj).GetInterface(playerObj, SL_IID_SEEK, &playerSeek)))
                // errs~= slGetError("Could not get Seek interface for AudioPlayer");
            if(slError((*playerObj).GetInterface(playerObj, SL_IID_EFFECTSEND, &playerEffectSend)))
                errs~= slGetError("Could not get EffectSend interface for AudioPlayer");
            if(slError((*playerObj).GetInterface(playerObj, SL_IID_METADATAEXTRACTION, &playerMetadata)))
                errs~= slGetError("Could not get MetadataExtraction interface for AudioPlayer");
            
            version(Android)
            {
                if(slError((*playerObj).GetInterface(playerObj, 
                SL_IID_ANDROIDSIMPLEBUFFERQUEUE, &playerAndroidSimpleBufferQueue)))
                    errs~= slGetError("Could not get AndroidSimpleBufferQueue for AudioPlayer");
            }
            __android_log_print(android_LogPriority.ANDROID_LOG_DEBUG, "SLES", "Got interfaces");

            if(autoRegisterCallback)
            {
                (*player).RegisterCallback(player, &SLIAudioPlayer.checkClipEnd_Callback, cast(void*)&output);
                (*player).SetCallbackEventsMask(player, SL_PLAYEVENT_HEADATEND);
            }
            return errs.length == 0;
        }
    }
}