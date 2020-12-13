module sli.sliformats;
import bindbc.OpenSLES;


/**
*   Stereo PCM, 44.1Khz, little endian
*/
SLDataFormat_PCM sliGetDefaultStereoPCMFormat()
{
    
    SLDataFormat_PCM pcm;
    pcm.formatType = SL_DATAFORMAT_PCM;
    pcm.numChannels = 2;
    pcm.samplesPerSec = SL_SAMPLINGRATE_44_1;
    pcm.bitsPerSample = SL_PCMSAMPLEFORMAT_FIXED_16;
    pcm.containerSize = SL_PCMSAMPLEFORMAT_FIXED_16;
    pcm.channelMask = SL_SPEAKER_FRONT_LEFT | SL_SPEAKER_FRONT_RIGHT;
    pcm.endianness = SL_BYTEORDER_LITTLEENDIAN;
    return pcm;
}
