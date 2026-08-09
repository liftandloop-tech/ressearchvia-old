# Add project specific ProGuard rules here.
# By default, the flags in this file are appended to flags specified
# in /Users/username/Library/Android/sdk/tools/proguard/proguard-android.txt

## Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class com.google.firebase.** { *; }

## Play Core for Flutter deferred components
-keep class com.google.android.play.core.** { *; }
-dontwarn com.google.android.play.core.**

## Razorpay
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keepattributes *Annotation*
-dontwarn com.razorpay.**
-keep class com.razorpay.** {*;}
-optimizations !method/inlining/short
-keep class com.razorpay.CheckoutActivity {*;}
-keep class com.razorpay.PaymentResultListener {*;}
-keep class com.razorpay.PaymentData {*;}
-keep class com.razorpay.CheckoutPresenter {*;}
-keep class com.razorpay.BasePresenter {*;}

## OkHttp
-dontwarn okhttp3.**
-dontwarn okio.**
-keep class okhttp3.** { *; }
-keep interface okhttp3.** { *; }

## Gson
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class com.google.gson.** { *; }
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

## Digio SDK
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes JavascriptInterface
-keepattributes *Annotation*
-keepattributes Signature
-optimizations !method/inlining/*
-keeppackagenames
-keepnames class androidx.navigation.fragment.NavHostFragment
-keep class * extends androidx.fragment.app.Fragment{}
-keepnames class * extends android.os.Parcelable
-keepnames class * extends java.io.Serializable
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}
-dontwarn androidx.databinding.**
-keep class androidx.databinding.** { *; }
-keepclassmembers class * extends androidx.databinding.** { *; }
-dontwarn org.json.**
-keep class org.json** { *; }
-keep public class org.simpleframework.**{ *; }
-keep class org.simpleframework.xml.**{ *; }
-keep class org.simpleframework.xml.core.**{ *; }
-keep class org.simpleframework.xml.util.**{ *; }
-dontwarn com.google.android.gms.**
-keep class com.google.android.gms.** { *; }
-keep class com.google.android.material.** { *; }
-dontwarn org.simpleframework.**
-keepattributes ElementList, Root
-keepclassmembers class * {
    @org.simpleframework.xml.* *;
}
-keep class org.spongycastle.** { *; }
-keep class com.ecs.rdlibrary.request.** { *; }
-keep class com.ecs.rdlibrary.response.** { *; }
-keep class com.ecs.rdlibrary.utils.** { *; }
-keep class com.ecs.rdlibrary.ECSBioCaptureActivity { *; }
-keep class org.simpleframework.xml.** { *; }
-keepattributes Exceptions, InnerClasses
-keep class com.google.android.gms.location.LocationSettingsRequest$Builder { *; }
-keepnames class ** { *; }
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keepattributes RuntimeVisibleAnnotations, RuntimeVisibleParameterAnnotations
-keepattributes AnnotationDefault
-keepclassmembers,allowshrinking,allowobfuscation interface * {
    @retrofit2.http.* <methods>;
}
-dontwarn javax.annotation.**
-dontwarn kotlin.Unit
-dontwarn retrofit2.KotlinExtensions
-dontwarn retrofit2.KotlinExtensions
-if interface * { @retrofit2.http.* <methods>; }
-keep,allowobfuscation interface <1>
-if interface * { @retrofit2.http.* <methods>; }
-keep,allowobfuscation interface * extends <1>
-keep,allowobfuscation,allowshrinking class kotlin.coroutines.Continuation
-if interface * { @retrofit2.http.* public *** *(...); }
-keep,allowoptimization,allowshrinking,allowobfuscation class <3>
-keep,allowobfuscation,allowshrinking class retrofit2.Response
-adaptresourcefilenames okhttp3/internal/publicsuffix/PublicSuffixDatabase.gz
-dontwarn org.codehaus.mojo.animal_sniffer.*
-dontwarn okhttp3.internal.platform.**
-dontwarn org.conscrypt.**
-dontwarn org.bouncycastle.**
-dontwarn org.openjsse.**
-keep class * extends androidx.databinding.DataBinderMapper
-keep class javax.xml.bind.annotation.** { *; }
-dontwarn javax.xml.bind.annotation.**
-keep class com.ecs.cdslxsds.ESignProcessorResponse { *; }
