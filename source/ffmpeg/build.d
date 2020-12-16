/**
*   @author: Hipreme aka Marcelo Mancini (2020)
*   Module used for building ffmpeg for android, this build program was based on @donturner medium's article:
*   https://medium.com/@donturner/using-ffmpeg-for-faster-audio-decoding-967894e94e71
*
*   Usage of this file:
*   rdmd build.d androidVersion ffmpegPath (optional)buildTarget
*
*/
module ffmpeg.build;

import std;

string[] ndk_env_aliases =
[
    "ANDROID_NDK",
    "ANDROID_NDK_HOME",
    "NDK_HOME",
    "NDK_PATH",
    "NDK"
];


enum archs = 
[
    "x86" : "i686-linux-android",
    "x86_64" : "x86_64-linux-android",
    "arm-v7a" : "arm-linux-androideabi",
    "arm64-v8a" : "aarch64-linux-android"
];

enum archsFolders =
[
    "x86" : "x86",
    "x86_64" : "x86_64",
    "arm-v7a" : "armeabi-v7a",
    "arm64-v8a" : "arm64-v8a"
];

string[] formats = 
[
    "mp3",
    "ogg"
];

string[] configCommand =
[
    "target-os=android", //Android config
    "disable-programs", //No cli program
    "disable-doc", //Better size
    "disable-static", //Don't build static lib
    "disable-everything", //We will specify the modules that will get compiled
    "disable-all",
    "enable-shared", //Build only shared
    "enable-cross-compile",  //Android config
    "enable-small" //Better size than speed(important on android)
];

string getNDK()
{
    foreach(ndk; ndk_env_aliases)
    {
        try
        {
            if(environment[ndk])
                return environment[ndk];
        }
        catch(Exception e){}
    }
    return "";
}

string getToolchainPath(string ndkPath)
{
    string path = ndkPath~"/toolchains/llvm/prebuilt/";
    auto inputRange = dirEntries(path, SpanMode.shallow);

    if(inputRange.empty)
    {
        writeln("No os found at ", path);
        return "";
    }
    return inputRange.front~"/bin";
}

string buildConfigCommand(string architecture, string androidVersion, string toolchainPath, string outputPath)
{
    string command = "";
    ///Strips debug symbols
    string stripCommand = "";

    command~="--prefix="~outputPath~archsFolders[architecture]~" ";
    if(architecture == "arm64-v8a")
        command~="--arch=aarch64 ";
    else
        command~="--arch="~architecture~" ";

    string additionalOpts = "";
    string toolchainPrefix = "";
    switch(architecture)
    {
        case "x86":
            toolchainPrefix = "i686-linux-android";
            additionalOpts = "--disable-asm";
            break;
        case "x86_64":
            toolchainPrefix = "x86_64-linux-android";
            additionalOpts = "--disable-asm";
            break;
        case "arm-v7a":
            toolchainPrefix = "armv7a-linux-androideabi";
            stripCommand = "arm-linux-androideabi-strip";
            break;
        case "arm64-v8a":
            toolchainPrefix = "aarch64-linux-android";
            break;
        default:
            writeln("Architecture ", architecture, " not found");
            break;
    }
    if(stripCommand == "")
        stripCommand = toolchainPrefix~"-strip";


    command~="--cc="~toolchainPath~"/"~toolchainPrefix~androidVersion~"-clang ";
    command~="--strip="~toolchainPath~"/"~stripCommand~" ";



    foreach(cmd; configCommand)
    {
        command~="--"~cmd~" ";
    }
    foreach(fmt; formats)
    {
        if(fmt == "ogg")
            command~="--enable-decoder=vorbis ";
        else
            command~="--enable-decoder="~fmt~" ";
        command~="--enable-demuxer="~fmt~" ";
    }
    command~= additionalOpts~" ";
    return command.replaceAll(regex("\\\\"), "/"); //Returns a non windows only command
}


string outputPath = "build/android/ffmpeg/";

enum SUCCESS = 0;
enum ERROR = -1;

int err(string msg = "", int errCode = ERROR)
{
    if(msg != "")
        writeln(msg);
    return errCode;
}


version(Windows)
{
    string msys2InstallUrl = "https://repo.msys2.org/distrib/x86_64/msys2-x86_64-20201109.exe";

    string msys2Temp = "msys2temp";
    string msys2Installer = "msys2Installer.exe";

    string getShell()
    {
        //Use "" for reading as string literal
        string sh = environment["PROGRAMFILES"]~"/Git/bin/sh.exe";

        //Check if it has git shell, the most common
        if(exists(sh))
            return sh;
        else
            writeln("No Git shell was found at '"~sh~"'\nChecking for msys\n--\n");

        //Check for msys shell
        sh = "C:/msys64/usr/bin/bash.exe";
        if(exists(sh))
            return sh;
        else
        {
            writeln("No msys2 shell was found at "~sh~"', do you want to attemp to install a shell?");
            writeln("Press y to install it at %APPDATA%/"~msys2Temp~"/"~msys2Installer);
            string willContinue = readln();
            if(willContinue != "y\n")
                return "";
            if(downloadShell())
            {
                if(installShell())
                {
                    writeln("Cleaning up '%APPDATA%/"~msys2Temp~"/"~msys2Installer~"'...");
                    rmdirRecurse(environment["APPDATA"]~"/"~msys2Temp);
                    updateShell(sh);
                }
                return sh;
            }
        }

        return sh;
    }

    bool downloadShell()
    {
        auto ret = executeShell("where curl");
        Pid install = null;
        string downloadCommand = "";
        if(ret.status != 0)
            writeln("curl not found, trying wget...");
        else
        {
            downloadCommand = "curl "~msys2InstallUrl~" --output %APPDATA%/"~msys2Temp~"/"~msys2Installer;
            goto download;
        }
        ret = executeShell("where wget");
        if(ret.status != 0)
        {
            writeln("wget not found, please, download msys2 at :\n"~msys2InstallUrl);
            goto fail;
        }
        else
        {
            downloadCommand = "wget "~msys2InstallUrl~" --show-progress -O %APPDATA%/"~msys2Temp~"/"~msys2Installer;
            goto download;
        } 
            
        download:
            if(!exists(environment["APPDATA"]~"/"~msys2Temp~"/"~msys2Installer))
            {
                mkdirRecurse(environment["APPDATA"]~"/"~msys2Temp);
                writeln("Executing: '"~downloadCommand~"'...");
                install = spawnShell(downloadCommand);
                if(wait(install) != 0)
                    goto fail;
                else
                    writeln("Download concluded, starting msys2");
            }
            return true;

        fail:
            writeln("Msys2 download failed");
            return false;
    }

    bool installShell()
    {
        writeln("Write 'continue' and enter when you finish installing msys2\n");

        writeln(`Please, note that some may need to install mingw-w64-binutils, for that, open a
msys shell and type pacman -S mingw-w64-binutils, and it will work
`);
        //Too complex to handle it
        auto p  = spawnShell("start "~environment["APPDATA"]~"/"~msys2Temp~"/"~msys2Installer);
        stdout.flush;
        string str;
        while((str = readln()) != "continue\n"){}
        return exists("C:/msys64");
    }

    bool updateShell(string sh)
    {
        writeln("Updating shell with: \n\tpacman -Syuu\n\tpacman -S mingw-w64-binutils\n");
        return wait(spawnShell(sh~" yes | pacman -Syuu && yes | pacman -S mingw-w64-binutils")) == 0;
    }
}
else{string getShell(){return "";}}


void showUsage()
{
    writeln(`Usage for this build automation:

rdmd build.d androidVersion ffmpegPath (optional)buildTarget, e.g:
rdmd build.d 21 ../external/ffmpeg/ x86

Accepted values for buildTarget:
    x86
    x86_64
    arm-v7a
    arm64-v8a

The output path is the current working dir.`);
}

string androidVersion = "";
string ffmpegPath = "";
string makeOpts = "-j12";

version(Windows){string make = "mingw32-make ";}
else{string make = "make ";}
int main(string[] args)
{
    string buildTarget = "";
    if(args.length < 3)
    {
        showUsage();
        return SUCCESS;
    }
    else
    {
        androidVersion = args[1];
        ffmpegPath = args[2];
        if(args.length > 3)
        {
            buildTarget = args[3];
            string* test = buildTarget in archs;
            if(test is null)
            {
                writeln("Build target '"~buildTarget~"' is not valid.");
                showUsage();
                return ERROR;
            }
        }
        else
            writeln("Configuring build for all targets!This will take some time");

    }
    string sh = getShell();
    string shOpts = "";
    if(countUntil(sh, "Git") != -1)
        shOpts = " -c "; //This switch is needed for using git shell as execution only
    else
    {
        version(Windows)
        {
            shOpts = " -l -c ";
        }
    }
    auto ret = executeShell(make);
    //Includes mingw32-make err code(2) and make err code(1)
    if(ret.status < 0 || ret.status > 2 )
        return err(`No '`~make~`' command was found in system
If you believe that this message is a error, please contact the repository mantainer`);
    
    //Include shell for windows commands
    outputPath = getcwd()~"/"~outputPath;

    version(Windows)
    {
        string mingwStyle(Captures!string cap)
        {
            return cap.hit.toLower[0..1];
        }
        outputPath = "/"~outputPath.replace!(mingwStyle)(regex(".:"));
        chdir(ffmpegPath);
        ffmpegPath = getcwd().replaceAll(regex("\\\\"), "/")~"/";
        ffmpegPath = "/"~ffmpegPath.replace!(mingwStyle)(regex(".:"));
        ffmpegPath = "cd "~ffmpegPath~" && ./";
    }

    string ndk = getNDK();
    if(ndk=="")
        return err(format!`Could not get any of the available NDK's variable.
Please, define one of the following ndk variables:
%s`(ndk_env_aliases));
       else
        writeln("NDK Path: ", ndk);

    string toolchainPath = getToolchainPath(ndk);
    if(toolchainPath == "")
        return ERROR;
    

    // writeln(toolchainPath);
    version(Windows)
    {
        string shMake = sh~" -c \""~make;
    }
    else
    {
        string shMake = make;
    }
    if(buildTarget == "")
    {
        foreach(key, value; archs)
        {
            if(exists(outputPath~archsFolders[key]))
            {
                writeln("'"~key~"' already exists, skipping");
                continue;
            }
            writeln("Cleaning build "~shMake~" clean\"");
            wait(spawnShell(shMake~ " clean\""));
            string buildCmd = buildConfigCommand(key, androidVersion, toolchainPath, outputPath);
            string configure = sh~shOpts~"\""~ffmpegPath~"configure "~buildCmd~"\"";
            writeln("Configuring build with... \n"~configure);
            wait(spawnShell(configure));
            wait(spawnShell(make ~ " "~ makeOpts));
            wait(spawnShell(make~ " install"));
        }
    }
    else
    {
        writeln("Cleaning build with: "~shMake~" clean\"");
        wait(spawnShell(shMake~ " clean\""));
        string buildCmd = buildConfigCommand(buildTarget, androidVersion, toolchainPath, outputPath);
        string configure = sh~shOpts~"\""~ffmpegPath~"configure "~buildCmd~"\"";
        writeln("Configuring build with... \n"~configure);
        wait(spawnShell(configure));
        wait(spawnShell(shMake ~ " "~ makeOpts~"\""));
        wait(spawnShell(shMake~ " install\""));
    }

    return SUCCESS;
}