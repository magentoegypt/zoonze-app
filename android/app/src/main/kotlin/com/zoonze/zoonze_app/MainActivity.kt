package com.zoonze.zoonze_app

import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import payment.sdk.android.payments.PaymentsLauncher

/**
 * Hosts the Flutter engine and the N-Genius payment bridge (card + Samsung Pay).
 *
 * Extends [FlutterFragmentActivity] rather than `FlutterActivity` because the
 * N-Genius SDK's [PaymentsLauncher] needs `registerForActivityResult`, which
 * only exists on `ComponentActivity` — `FlutterActivity` extends plain
 * `Activity`. The alternative was the SDK's deprecated
 * `PaymentClient.launchCardPayment` + `onActivityResult` path.
 */
class MainActivity : FlutterFragmentActivity() {
    private val payments = PaymentChannel()

    // Both are field initialisers on purpose: registerForActivityResult must
    // run before the activity reaches STARTED, while configureFlutterEngine is
    // called from super.onCreate() — so building this in onCreate would be too
    // late for the former and too early for the latter.
    private val paymentLauncher = PaymentsLauncher(this) { result ->
        payments.onPaymentResult(result)
    }

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        // `this` is for the Samsung Pay client, which needs an Activity to
        // present its custom sheet over.
        payments.attach(flutterEngine, paymentLauncher, this)
    }
}
