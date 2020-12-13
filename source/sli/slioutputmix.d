module sli.slioutputmix;
import bindbc.OpenSLES;
import sli.backend.opensles_utils;

struct SLIOutputMix
{
    SLEnvironmentalReverbItf environmentReverb;
    SLPresetReverbItf presetReverb;
    SLBassBoostItf bassBoost;
    SLEqualizerItf equalizer;
    SLVirtualizerItf virtualizer;
    SLObjectItf outputMixObj;


    static bool initializeForAndroid(ref SLIOutputMix output, ref SLEngineItf e)
    {
        //All those interfaces are supported on Android, so, require it
        const(SLInterfaceID)* ids = 
        [
            SL_IID_ENVIRONMENTALREVERB,
            SL_IID_PRESETREVERB,
            SL_IID_BASSBOOST,
            SL_IID_EQUALIZER,
            SL_IID_VIRTUALIZER
        ].ptr;
        const(SLboolean)* req = 
        [
            SL_BOOLEAN_TRUE,
            SL_BOOLEAN_TRUE,
            SL_BOOLEAN_TRUE,
            SL_BOOLEAN_TRUE,
            SL_BOOLEAN_TRUE //5
        ].ptr;

        string[] err;
        SLresult r;
        with(output)
        {
            r = (*e).CreateOutputMix(e, &outputMixObj, 5, ids, req);
            if(slError(r))
                err~= slGetError("Could not create output mix");
            //Do it assyncly
            r = (*outputMixObj).Realize(outputMixObj, SL_BOOLEAN_FALSE);
            if(slError(r))
                err~= slGetError("Could not initialize output mix");

            
            if(slError((*outputMixObj).GetInterface(outputMixObj, SL_IID_ENVIRONMENTALREVERB, &environmentReverb)))
            {
                err~=slGetError("Could not get the ENVIRONMENTALREVERB interface");
                environmentReverb = null;
            }
            if(slError((*outputMixObj).GetInterface(outputMixObj, SL_IID_PRESETREVERB, &presetReverb)))
            {
                err~=slGetError("Could not get the PRESETREVERB interface");
                presetReverb = null;
            }
            if(slError((*outputMixObj).GetInterface(outputMixObj, SL_IID_BASSBOOST, &bassBoost)))
            {
                err~=slGetError("Could not get the BASSBOOST interface");
                bassBoost = null;
            }
            if(slError((*outputMixObj).GetInterface(outputMixObj, SL_IID_EQUALIZER, &equalizer)))
            {
                err~=slGetError("Could not get the EQUALIZER interface");
                equalizer = null;
            }
            if(slError((*outputMixObj).GetInterface(outputMixObj, SL_IID_VIRTUALIZER, &virtualizer)))
            {
                err~=slGetError("Could not get the VIRTUALIZER interface");
                virtualizer = null;
            }
        }
        return r==SL_RESULT_SUCCESS && err.length==0;
    }
}
