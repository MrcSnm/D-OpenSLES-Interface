module sli.slilocators;
import bindbc.OpenSLES;
import sli.backend.opensles_utils;
import arsd.jni;
import core.stdc.stdio;
import core.stdc.stdlib:free;

ubyte* nullString(string str)
{
    return cast(ubyte*)(str~'\0').ptr;
}

/**
*   This function must probably receive the resourceID from Android
*/
SLDataLocator_AndroidFD sliGetAndroidFileLocator(SLuint32 resourceID)
{
    SLDataLocator_AndroidFD loc;
    loc.locatorType = SL_DATALOCATOR_ANDROIDFD;
    loc.length = SL_DATALOCATOR_ANDROIDFD_USE_FILE_SIZE;
    loc.offset = 0;
    loc.fd = resourceID;
    return loc;
}

struct SLIMime
{
    SLchar* mimeType;
    ///SL_CONTAINERTYPE enumerators
    SLuint32 containerType;
}


SLIMime fileNameToAudioMimeType(string fileName)
{
    import std.string:lastIndexOf;
    ulong ind = fileName.lastIndexOf('.');
    if(ind == -1)
        slGetError(fileName~" does not contain any extension!");

    string ext = fileName[ind+1..$];
    string mime;

    SLIMime ret;

    switch(ext)
    {
        case "mp3":
            mime = "mpeg";
            ret.containerType = SL_CONTAINERTYPE_MP3;
            break;
        case "ogg":
            mime = "ogg";
            ret.containerType = SL_CONTAINERTYPE_OGG;
            break;
        case "wav":
            mime = "x-wav";
            ret.containerType = SL_CONTAINERTYPE_WAV;
            break;
        ///Android does not supports MIDI. MIDI is present only as documentation
        case "midi":
            mime = "sp-midi";
            ret.containerType = SL_CONTAINERTYPE_SMF;
            break;
        default:
            mime = "basic";
            ret.containerType = SL_CONTAINERTYPE_UNSPECIFIED;
    }
    ret.mimeType = nullString("audio/"~mime);
    return ret;
}

SLDataSource sliGetFileSource(string fileName, SLDataLocator_URI* locator, SLDataFormat_MIME* format)
{
    SLIMime sliMime = fileNameToAudioMimeType(fileName);

    // Use file:// for indetifying how to acquire resource, another '/' is needed because it starts on root
    (*locator) = SLDataLocator_URI(SL_DATALOCATOR_URI, nullString("file:///"~fileName));
    (*format) = SLDataFormat_MIME(SL_DATAFORMAT_MIME, sliMime.mimeType, sliMime.containerType);

    return SLDataSource(locator, format);
}

struct SLIDataSource_URI
{
    SLDataLocator_URI* uriLocator;
    SLDataFormat_MIME* mimeFormat;
    SLDataSource source;
    bool isPopulated;

    static SLIDataSource_URI createDataSource(string fileName)
    {
        SLIDataSource_URI ret;
        ret.uriLocator = allocate!SLDataLocator_URI;
        ret.mimeFormat = allocate!SLDataFormat_MIME;
        ret.isPopulated = true;
        ret.source = sliGetFileSource(fileName, ret.uriLocator, ret.mimeFormat);
        return ret;
    }
    static void setFile(string fileName)
    {
        // ret.uri
    }

    static void destroyDataSource(ref SLIDataSource_URI dataSource)
    {
        if(dataSource.isPopulated)
        {
            free(dataSource.uriLocator);
            free(dataSource.mimeFormat);
        }
        dataSource.isPopulated = false;
    }
}
