# Règles ProGuard pour la biométrie Android

# Garder les classes biométriques
-keep class androidx.biometric.** { *; }
-keep class android.hardware.biometrics.** { *; }
-keep class android.hardware.fingerprint.** { *; }

# Garder les classes de local_auth
-keep class io.flutter.plugins.localauth.** { *; }

# Garder les interfaces et annotations biométriques
-keepattributes Signature
-keepattributes *Annotation*

# Éviter l'obfuscation des méthodes biométriques
-keepclassmembers class * {
    @androidx.biometric.* <methods>;
}

# Support pour les types de biométrie Samsung/Android
-keep class * implements android.hardware.biometrics.BiometricPrompt$AuthenticationCallback { *; }
-keep class * extends androidx.biometric.BiometricPrompt$AuthenticationCallback { *; }

# Garder les énums de types biométriques
-keepclassmembers enum * {
    public static **[] values();
    public static ** valueOf(java.lang.String);
}

# Support pour les exceptions biométriques
-keep class androidx.biometric.BiometricPrompt$AuthenticationError { *; }
-keep class androidx.biometric.BiometricPrompt$AuthenticationFailed { *; }
-keep class androidx.biometric.BiometricPrompt$AuthenticationHelp { *; }
-keep class androidx.biometric.BiometricPrompt$AuthenticationSucceeded { *; }