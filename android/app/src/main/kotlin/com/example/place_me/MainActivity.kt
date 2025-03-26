package com.example.place_me

import android.content.pm.PackageManager
import android.os.Bundle
import android.util.Base64
import android.util.Log
import io.flutter.embedding.android.FlutterActivity
import java.security.MessageDigest

class MainActivity: FlutterActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        printKeyHash()
    }

    private fun printKeyHash() {
        try {
            val info = packageManager.getPackageInfo(
                packageName,
                PackageManager.GET_SIGNATURES
            )
            // אם signatures שווה null, לא נמשיך בלולאה
            info.signatures?.let { signatures ->
                for (signature in signatures) {
                    val md = MessageDigest.getInstance("SHA")
                    md.update(signature.toByteArray())
                    val keyHash = Base64.encodeToString(md.digest(), Base64.DEFAULT)
                    Log.d("KeyHash", keyHash)
                }
            }
        } catch (e: Exception) {
            e.printStackTrace()
        }
    }
}
