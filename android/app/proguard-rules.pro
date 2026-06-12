# Keep generic signature of TypeToken and annotations to prevent code shrinking errors
-keepattributes Signature, *Annotation*, InnerClasses, EnclosingMethod

# Gson specific rules
-keep class com.google.gson.reflect.TypeToken { *; }
-keep class * extends com.google.gson.reflect.TypeToken
-keepclassmembers class * {
    @com.google.gson.annotations.SerializedName <fields>;
}

# Flutter Local Notifications specific rules
-keep class com.dexterous.flutterlocalnotifications.** { *; }
