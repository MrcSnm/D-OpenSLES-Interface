module android.helper.log;

import android.log;
import std.functional:partial;


alias LOGW = partial!(__android_log_print, android_LogPriority.ANDROID_LOG_WARN);
alias LOGE = partial!(__android_log_print, android_LogPriority.ANDROID_LOG_ERROR);
alias LOGI = partial!(__android_log_print, android_LogPriority.ANDROID_LOG_INFO);
alias LOGD = partial!(__android_log_print, android_LogPriority.ANDROID_LOG_DEBUG);