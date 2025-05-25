# Flutter rules
-keep class io.flutter.** { *; }
-dontwarn io.flutter.**

# Firebase rules
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**
-keepattributes Signature
-keepattributes *Annotation*

# Google Play services
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# HTTP client (if using http or dio for TMDB API)
-keep class com.squareup.okhttp.** { *; }
-dontwarn com.squareup.okhttp.**
-keep class retrofit2.** { *; }
-dontwarn retrofit2.**
-keep class okio.** { *; }
-dontwarn okio.**

# JSON serialization (if using json_annotation or similar)
-keep class com.google.gson.** { *; }
-dontwarn com.google.gson.**
-keep class your.package.model.** { *; } # Replace with your model package (e.g., com.sungura.app.model)

# Prevent R8 from removing unused classes
-keepattributes InnerClasses
-keepattributes EnclosingMethod