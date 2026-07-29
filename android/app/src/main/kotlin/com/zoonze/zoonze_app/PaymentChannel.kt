package com.zoonze.zoonze_app

import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject
import payment.sdk.android.payments.PaymentsLauncher
import payment.sdk.android.payments.PaymentsRequest
import payment.sdk.android.payments.PaymentsResult

/**
 * Android half of the `zoonze/payments` MethodChannel — the N-Genius (Network
 * International) card SDK. Contract: docs/backend/payment-contract.md §③.
 *
 * Tabby is deliberately not handled here: its SDK ships as a Flutter package
 * (`tabby_flutter_inapp_sdk`), so it lives in Dart and needs no native code on
 * either platform.
 *
 * The launcher is owned by [MainActivity], because `registerForActivityResult`
 * has to run before the activity reaches STARTED and therefore cannot be
 * created on demand when `pay` arrives.
 */
class PaymentChannel {
    companion object {
        private const val CHANNEL = "zoonze/payments"

        /** Order JSON link names — see the SDK's Order model (`_links`). */
        private const val LINK_AUTHORIZATION = "payment-authorization"
        private const val LINK_PAY_PAGE = "payment"
    }

    private var launcher: PaymentsLauncher? = null

    /**
     * The in-flight Flutter result. Held because the SDK answers on an activity
     * result long after `pay` returns; without it the callback would have
     * nothing to resolve and checkout would hang.
     */
    private var pending: MethodChannel.Result? = null
    private var pendingOrderNumber: String = ""

    fun attach(engine: FlutterEngine, launcher: PaymentsLauncher) {
        this.launcher = launcher
        MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .setMethodCallHandler { call, result -> handle(call, result) }
    }

    private fun handle(call: MethodCall, result: MethodChannel.Result) {
        if (call.method != "pay") {
            result.notImplemented()
            return
        }
        // Anything that isn't N-Genius is handled in Dart. Reporting "not
        // implemented" lets the Dart layer fall back rather than fail hard.
        if (call.argument<String>("gateway") != "ngenius") {
            result.notImplemented()
            return
        }

        val orderNumber = call.argument<String>("orderNumber").orEmpty()
        val orderJson = call.argument<String>("orderResponse")

        // Android needs two DIFFERENT order links: _links.payment-authorization
        // (the API the SDK authorizes against) and _links.payment (the hosted
        // pay page, which carries the ?code=). The order JSON is authoritative
        // for both.
        //
        // The `paymentAuthorizationHref` argument is only a fallback and is
        // deliberately NOT preferred: the backend fills it from
        // _links.payment.href — the pay-page link, despite its name — so
        // trusting it put the same URL in both fields and the SDK authorized
        // against the pay page, which answered with an HTML error page.
        val links = parseLinks(orderJson)
        val authorizationUrl = links[LINK_AUTHORIZATION]
            ?: call.argument<String>("paymentAuthorizationHref")
        val payPageUrl = links[LINK_PAY_PAGE]

        if (authorizationUrl.isNullOrEmpty() || payPageUrl.isNullOrEmpty()) {
            result.success(
                payload(
                    status = "FAILED",
                    orderNumber = orderNumber,
                    raw = "missing payment links (authorization=" +
                        "${!authorizationUrl.isNullOrEmpty()}, " +
                        "payPage=${!payPageUrl.isNullOrEmpty()})",
                ),
            )
            return
        }

        val activeLauncher = launcher
        if (activeLauncher == null) {
            result.success(
                payload("FAILED", orderNumber, raw = "payment launcher unavailable"),
            )
            return
        }

        // Only one payment can be in flight; resolving a MethodChannel.Result
        // twice throws, so retire any earlier one as cancelled first.
        pending?.success(payload("CANCELLED", pendingOrderNumber, raw = "superseded"))
        pending = result
        pendingOrderNumber = orderNumber

        activeLauncher.launch(
            PaymentsRequest.builder()
                .gatewayAuthorizationUrl(authorizationUrl)
                .payPageUrl(payPageUrl)
                .build(),
        )
    }

    /** Invoked by [MainActivity] when the SDK's activity returns. */
    fun onPaymentResult(result: PaymentsResult) {
        val target = pending ?: return
        pending = null
        val orderNumber = pendingOrderNumber
        pendingOrderNumber = ""

        val (status, raw) = when (result) {
            // Authorised now, captured later — the contract treats both as
            // success and the app re-queries Magento for the real state.
            is PaymentsResult.Authorised -> "AUTHORISED" to null
            is PaymentsResult.Success -> "SUCCESS" to null
            is PaymentsResult.PostAuthReview -> "POST_AUTH_REVIEW" to null

            is PaymentsResult.PartialAuthDeclined,
            is PaymentsResult.PartialAuthDeclineFailed,
            -> "DECLINED" to result::class.simpleName

            // Only part of the amount cleared. Passed through unmapped so Dart
            // treats it as failed and routes to CompletePaymentScreen, rather
            // than showing success for an order that isn't fully paid. Matches
            // the iOS module.
            is PaymentsResult.PartiallyAuthorised -> "PARTIALLY_AUTHORISED" to null

            is PaymentsResult.Cancelled -> "CANCELLED" to null
            is PaymentsResult.Failed -> "FAILED" to result.error
        }
        target.success(payload(status, orderNumber, raw = raw))
    }

    /** Reads `_links` out of the raw order JSON, tolerating a malformed body. */
    private fun parseLinks(orderJson: String?): Map<String, String> {
        if (orderJson.isNullOrEmpty()) return emptyMap()
        return try {
            val links = JSONObject(orderJson).optJSONObject("_links")
                ?: return emptyMap()
            listOf(LINK_AUTHORIZATION, LINK_PAY_PAGE)
                .mapNotNull { name ->
                    links.optJSONObject(name)?.optString("href")
                        ?.takeIf { it.isNotEmpty() }
                        ?.let { name to it }
                }
                .toMap()
        } catch (error: Exception) {
            emptyMap()
        }
    }

    /** Result map shape from the contract. */
    private fun payload(
        status: String,
        orderNumber: String,
        reference: String? = null,
        raw: String? = null,
    ): Map<String, Any> = buildMap {
        put("status", status)
        put("gateway", "ngenius")
        put("orderNumber", orderNumber)
        reference?.let { put("reference", it) }
        raw?.let { put("raw", it) }
    }
}
