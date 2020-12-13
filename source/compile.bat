set androidPath=C:\Users\Hipreme\AppData\Local\Android\Sdk\ndk\21.3.6528147\toolchains\llvm\prebuilt\windows-x86_64\sysroot\usr\lib\aarch64-linux-android\21\

set slesPath=../bindbc-opensles/bindbc
set outputFile=libopensles_interface.so

set bindbcSrc=%slesPath%/OpenSLES/types.d %slesPath%/OpenSLES/android.d %slesPath%/OpenSLES/android_metadata.d %slesPath%/OpenSLES/android_configuration.d %slesPath%/OpenSLES/package.d

set slesInterfaceSrc= sli/sliformats.d ^
sli/slilocators.d ^
sli/slioutputmix.d ^
sli/sliaudioplayer.d ^
sli/backend/opensles_interface.d ^
sli/backend/opensles_helper.d ^
sli/backend/opensles_utils.d ^
sli/backend/opensles_decode.d

set vendorSrc= vendor/arsd/jni.d 

set androidSrc= android/asset_manager.d ^
android/asset_manager_jni.d ^
android/helper/log.d

set libs= -L=-lOpenSLES -L=-llog -L=-landroid
set mtriple= -mtriple=aarch64--linux-android

@REM set bindbcSrc=%slesPath%/OpenSLES/sles.d

ldc2 -I=%slesPath%  -L=-L%androidPath%  %libs% %mtriple% --shared --of=%outputFile% ^
%slesInterfaceSrc% ^
%bindbcSrc% ^
%androidSrc% ^
%vendorSrc% ^
app.d

if %errorlevel%==0 (
	MOVE %outputFile% D:\Programming\Android\Apps\app\src\main\jniLibs\arm64-v8a
	cd D:\Programming\Android\Apps
	@REM gradlew assembleDebug
	@REM adb shell am start -n "com.hipreme.zenambience/com.hipreme.zenambience.MainActivity" -a android.intent.action.MAIN -c android.intent.category.LAUNCHER
	cd D:\Programming\Open\bindbc-opensles\source
)