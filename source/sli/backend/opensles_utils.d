module sli.backend.opensles_utils;
import android.log;
import bindbc.OpenSLES.types;


bool slError(SLresult res)
{
    return res != SL_RESULT_SUCCESS;
}
float toAttenuation(float gain)
{
    import std.math:log10;
    return (gain < 0.01f) ? -96.0f : 20 * log10(gain);
}


T* allocate(T)(size_t quant = 1)
{
    import core.stdc.stdlib:malloc;
    return cast(T*)malloc(T.sizeof*quant);
}

void autoallocate(T)(ref T* pointer, size_t quant = 1)
{
    import core.stdc.stdlib:malloc;
    pointer = cast(T*)malloc(T.sizeof*quant);
}

void free(T)(ref T* pointer)
{
    static import core.stdc.stdlib;

    core.stdc.stdlib.free(cast(void*)pointer);
    pointer = null;
}

string slGetError(string msg, string func = __PRETTY_FUNCTION__, uint line = __LINE__)
{
    import std.conv:to;
    __android_log_print(android_LogPriority.ANDROID_LOG_ERROR, "OpenSL ES Error",
    (func~":"~to!string(line)~"\n\t"~msg).ptr);
    return "OpenSL ES Error:\n\t"~msg;
}


/**
*   Returns a comprehensive error message
*/
string slResultToString(SLresult res)
{
    switch (res)
    {
        case SL_RESULT_SUCCESS: return "Success";
        case SL_RESULT_BUFFER_INSUFFICIENT: return "Buffer insufficient";
        case SL_RESULT_CONTENT_CORRUPTED: return "Content corrupted";
        case SL_RESULT_CONTENT_NOT_FOUND: return "Content not found";
        case SL_RESULT_CONTENT_UNSUPPORTED: return "Content unsupported";
        case SL_RESULT_CONTROL_LOST: return "Control lost";
        case SL_RESULT_FEATURE_UNSUPPORTED: return "Feature unsupported";
        case SL_RESULT_INTERNAL_ERROR: return "Internal error";
        case SL_RESULT_IO_ERROR: return "IO error";
        case SL_RESULT_MEMORY_FAILURE: return "Memory failure";
        case SL_RESULT_OPERATION_ABORTED: return "Operation aborted";
        case SL_RESULT_PARAMETER_INVALID: return "Parameter invalid";
        case SL_RESULT_PERMISSION_DENIED: return "Permission denied";
        case SL_RESULT_PRECONDITIONS_VIOLATED: return "Preconditions violated";
        case SL_RESULT_RESOURCE_ERROR: return "Resource error";
        case SL_RESULT_RESOURCE_LOST: return "Resource lost";
        case SL_RESULT_UNKNOWN_ERROR: return "Unknown error";
        default: return "Undefined error";
    }
}