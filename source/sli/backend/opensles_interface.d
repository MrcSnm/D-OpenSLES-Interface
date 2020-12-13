module sli.backend.opensles_interface;
import bindbc.OpenSLES.types;
import sli.backend.opensles_utils;
import bindbc.OpenSLES.android;
import std.algorithm.searching:count;
import core.sys.posix.pthread;
import arsd.jni;
import android.log;

import sli.slioutputmix;
import sli.sliaudioplayer;
import sli.sliformats;
import sli.slilocators;

/**
*   Std.array.join crashes on Android
*/
string join(T)(T[] array, string separator)
{
    string ret;
    bool isFirst = false;
    import std.conv:to;
    foreach (key; array)
    {
        if(!isFirst)
            ret~=separator;
        else
            isFirst = true;
        ret~= to!string(key);
    }
    return ret;
}




/**
*   This file is meant to provide a higher level interface OpenAL-alike
* as there is little information about how to use, I'm trying to bring to D this interface following
* the steps from the audioprogramming blog, as it is currently private, I'm bringing it what I could find.
*/


struct BufferQueuePlayer
{
    SLObjectItf playerObject;
    SLPlayItf playerPlay;
    SLAndroidSimpleBufferQueueItf playerBufferQueue;
    SLEffectSendItf playerEffectSend;
    SLMuteSoloItf playerMuteSolo;
    SLVolumeItf playerVolume;
    SLmilliHertz playerSampleRate = 0;
    /**
    * device native buffer size is another factor to minimize audio latency, not used in this
    * sample: we only play one giant buffer here
    */
    int   playerBufferSize = 0;
    short* resampleBuf = null;
}

struct SLClip
{
    void* samples; //Raw sample
    uint numSamples; //How many samples it has
    uint samplesPerSec; //Samples in Hz
}


/**
* Engine interface
*/
static SLObjectItf engineObject = null;
static SLEngineItf engine;

static SLIOutputMix outputMix;
static SLIAudioPlayer gAudioPlayer;
static short[8000] sawtoothBuffer;

static void loadSawtooth()
{
    for(uint i =0; i < 8000; ++i)
        sawtoothBuffer[i] = cast(short)(40_000 - ((i%100) * 220));       
}

static BufferQueuePlayer bq;

/**
*   Initializes the engine and output mixer
*/
string sliCreateOutputContext()
{
    string[] errorMessages = [];
    SLresult res = slCreateEngine(&engineObject,0,null,0,null,null);
    if(slError(res))
        errorMessages~= slGetError("Could not create engine");

    //Initialize|Realize the engine
    res = (*engineObject).Realize(engineObject, SL_BOOLEAN_FALSE);
    if(slError(res))
        errorMessages~= slGetError("Could not realize|initialize engine");
    

    //Get the interface for being able to create child objects from the engine
    res = (*engineObject).GetInterface(engineObject, SL_IID_ENGINE, &engine);
    if(slError(res))
        errorMessages~= slGetError("Could not get an interface for creating objects");

    
    __android_log_print(android_LogPriority.ANDROID_LOG_ERROR, "SLES", "Initialized engine");
    SLIOutputMix.initializeForAndroid(outputMix, engine);
    loadSawtooth();

    sliPlayAudio();

    return errorMessages.join("\n");
}


void sliPlayAudio()
{
    version(Android)
    {
        SLDataLocator_AndroidSimpleBufferQueue locator;
        locator.locatorType = SL_DATALOCATOR_ANDROIDSIMPLEBUFFERQUEUE;
        locator.numBuffers = 1;
    }
    else
    {
        SLDataLocator_Address locator;
        locator.locatorType = SL_DATALOCATOR_ADDRESS;
        locator.pAddress = sawtoothBuffer.ptr;
        locator.length = 8000*2;
    }
    SLIDataSource_URI uriSrc = SLIDataSource_URI.createDataSource("assets/HopeToYou.wav");
    
    //Okay
    SLDataFormat_PCM format;
    format.formatType = SL_DATAFORMAT_PCM;
    format.numChannels = 1;
    format.samplesPerSec =  SL_SAMPLINGRATE_8;
    format.bitsPerSample = SL_PCMSAMPLEFORMAT_FIXED_16;
    format.containerSize = SL_PCMSAMPLEFORMAT_FIXED_16;
    format.channelMask = SL_SPEAKER_FRONT_CENTER;
    format.endianness = SL_BYTEORDER_LITTLEENDIAN;

    SLDataSink decodedContainer;
    decodedContainer.pLocator = &locator; //Throws at the android buffer queue
    decodedContainer.pFormat = &format;
    
    //Okay
    SLDataSource src;
    src.pLocator = &locator;
    src.pFormat = &format;
    

    //Okay
    SLDataLocator_OutputMix locatorMix;
    locatorMix.locatorType = SL_DATALOCATOR_OUTPUTMIX;
    locatorMix.outputMix = outputMix.outputMixObj;

    __android_log_print(android_LogPriority.ANDROID_LOG_ERROR, "SLES", "Created locators");
    //Okay
    SLDataSink destination;
    destination.pLocator = &locatorMix;
    destination.pFormat = null;

     SLIAudioPlayer.initializeForAndroid(gAudioPlayer, engine, src, destination);
    __android_log_print(android_LogPriority.ANDROID_LOG_ERROR, "SLES", "Okay here");

    __android_log_print(android_LogPriority.ANDROID_LOG_ERROR, "SLES", "Playing sound");
     SLIAudioPlayer.play(gAudioPlayer, sawtoothBuffer.ptr, 8000); 
}


// pointer and size of the next player buffer to enqueue, and number of remaining buffers
static short *nextBuffer;
static uint nextSize;
static int nextCount;
// this callback handler is called every time a buffer finishes playing
extern(C)void bqPlayerCallback(SLAndroidSimpleBufferQueueItf bq, void *context)
{
    // for streaming playback, replace this test by logic to find and fill the next buffer
    if (--nextCount > 0 && null != nextBuffer && 0 != nextSize) {
        SLresult result;
        // enqueue another buffer
        result = (*bq).Enqueue(bq, nextBuffer, nextSize);
        // the most likely other result is SL_RESULT_BUFFER_INSUFFICIENT,
        // which for this code example would indicate a programming error
        // if (SL_RESULT_SUCCESS != result) {
        //     pthread_mutex_unlock(&audioEngineLock);
        // }
    } 
    // else {
    //     releaseResampleBuf();
    //     pthread_mutex_unlock(&audioEngineLock);
    // }
}
