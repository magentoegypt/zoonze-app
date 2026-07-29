import Flutter
import UIKit

#if canImport(NISdk)
  import NISdk
#endif

/// Native half of the `zoonze/payments` MethodChannel — the N-Genius (Network
/// International) card SDK. Contract: docs/backend/payment-contract.md §③.
///
/// The whole NISdk dependency is behind `#if canImport(NISdk)` on purpose. If
/// the pod is missing or fails to install, this still compiles and `pay`
/// answers `FlutterMethodNotImplemented`, which Dart already handles as
/// `MissingPluginException` -> `PaymentGatewayUnavailable` -> "awaiting
/// payment". That's exactly the behaviour before this module existed, so a
/// broken dependency degrades instead of breaking the build or the checkout.
///
/// Tabby is deliberately NOT handled here: its SDK ships as a Flutter package
/// (`tabby_flutter_inapp_sdk`), so it belongs in Dart, not in this module.
final class PaymentChannel: NSObject {
  private static let channelName = "zoonze/payments"

  static func register(with registrar: FlutterPluginRegistrar) {
    let channel = FlutterMethodChannel(
      name: channelName, binaryMessenger: registrar.messenger())
    let instance = PaymentChannel()
    channel.setMethodCallHandler { call, result in
      instance.handle(call, result: result)
    }
    // Retained by the handler closure above; keep an explicit reference so the
    // delegate isn't deallocated mid-payment while NISdk holds it weakly.
    Self.retained = instance
  }

  private static var retained: PaymentChannel?

  /// Held for the duration of one payment. NISdk keeps only a weak reference to
  /// the delegate, so without this the callback never arrives and the Flutter
  /// result is never fulfilled — the checkout would hang forever.
  private var activeSession: NGeniusSession?

  private func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    guard call.method == "pay" else {
      result(FlutterMethodNotImplemented)
      return
    }
    let args = call.arguments as? [String: Any] ?? [:]
    let gateway = args["gateway"] as? String ?? ""

    guard gateway == "ngenius" else {
      // Tabby (and anything else) is handled in Dart. Reporting "not
      // implemented" lets the Dart layer fall back rather than fail hard.
      result(FlutterMethodNotImplemented)
      return
    }

    #if canImport(NISdk)
      startNGenius(args: args, result: result)
    #else
      result(FlutterMethodNotImplemented)
    #endif
  }

  #if canImport(NISdk)
    private func startNGenius(args: [String: Any], result: @escaping FlutterResult) {
      let orderNumber = args["orderNumber"] as? String ?? ""

      // iOS drives the SDK from the full order JSON (Android uses the
      // payment-authorization href instead). Both are always sent.
      guard let orderJson = args["orderResponse"] as? String,
        let data = orderJson.data(using: .utf8)
      else {
        result(Self.payload(status: "FAILED", orderNumber: orderNumber,
                            raw: "orderResponse missing or not a string"))
        return
      }

      let order: OrderResponse
      do {
        order = try OrderResponse.decodeFrom(data: data)
      } catch {
        result(Self.payload(status: "FAILED", orderNumber: orderNumber,
                            raw: "orderResponse did not decode: \(error)"))
        return
      }

      guard let parent = Self.topViewController() else {
        result(Self.payload(status: "FAILED", orderNumber: orderNumber,
                            raw: "no view controller to present over"))
        return
      }

      // Render the SDK's own UI in the customer's language.
      if let language = args["language"] as? String, !language.isEmpty {
        NISdk.sharedInstance.setSDKLanguage(language: language)
      }

      let session = NGeniusSession(orderNumber: orderNumber) { [weak self] payload in
        self?.activeSession = nil
        result(payload)
      }
      activeSession = session

      DispatchQueue.main.async {
        NISdk.sharedInstance.showCardPaymentViewWith(
          cardPaymentDelegate: session, overParent: parent, for: order)
      }
    }
  #endif

  /// Result map shape from the contract: status / gateway / orderNumber /
  /// reference / raw.
  static func payload(
    status: String, orderNumber: String, reference: String? = nil, raw: String? = nil
  ) -> [String: Any] {
    var map: [String: Any] = [
      "status": status,
      "gateway": "ngenius",
      "orderNumber": orderNumber,
    ]
    if let reference { map["reference"] = reference }
    if let raw { map["raw"] = raw }
    return map
  }

  /// The app is scene-based (see SceneDelegate), so `window` on the app
  /// delegate is not reliable — walk the active scene's key window instead,
  /// then down through anything already presented.
  static func topViewController() -> UIViewController? {
    let window = UIApplication.shared.connectedScenes
      .compactMap { $0 as? UIWindowScene }
      .flatMap(\.windows)
      .first { $0.isKeyWindow }
    var top = window?.rootViewController
    while let presented = top?.presentedViewController {
      top = presented
    }
    return top
  }
}

#if canImport(NISdk)
  /// One payment attempt. NISdk reports the outcome through
  /// `CardPaymentDelegate`; this normalises it to the contract's canonical
  /// status string and fulfils the Flutter result exactly once.
  final class NGeniusSession: NSObject, CardPaymentDelegate {
    private let orderNumber: String
    private var complete: (([String: Any]) -> Void)?
    /// Captured from the 3DS/authorization callbacks so a later generic
    /// `PaymentFailed` can be reported as the more specific cause.
    private var failureCause: String?

    init(orderNumber: String, complete: @escaping ([String: Any]) -> Void) {
      self.orderNumber = orderNumber
      self.complete = complete
    }

    private func finish(_ status: String, raw: String? = nil) {
      // NISdk can fire more than one terminal callback (e.g. a 3DS failure
      // followed by paymentDidComplete). Fulfilling a FlutterResult twice is a
      // hard crash, so only the first one counts.
      guard let complete else { return }
      self.complete = nil
      complete(PaymentChannel.payload(
        status: status, orderNumber: orderNumber, raw: raw))
    }

    func authorizationDidComplete(with status: AuthorizationStatus) {
      if status == .AuthFailed { failureCause = "AUTH_FAILED" }
    }

    func threeDSChallengeDidComplete(with status: ThreeDSStatus) {
      if status == .ThreeDSFailed { failureCause = "THREE_DS_FAILURE" }
    }

    func paymentDidComplete(with status: PaymentStatus) {
      switch status {
      case .PaymentSuccess:
        finish("SUCCESS", raw: status.rawVal)

      // Authorised now, captured asynchronously. The contract treats this as
      // success; the app re-queries Magento for the real order state anyway.
      case .PaymentPostAuthReview:
        finish("POST_AUTH_REVIEW", raw: status.rawVal)

      case .PaymentCancelled:
        finish("CANCELLED", raw: status.rawVal)

      case .PartialAuthDeclined, .PartialAuthDeclineFailed:
        finish("DECLINED", raw: status.rawVal)

      case .PaymentFailed, .InValidRequest:
        // Prefer the specific cause when 3DS or authorization already failed,
        // so the customer sees "declined" rather than a generic error.
        finish(failureCause ?? "FAILED", raw: status.rawVal)

      // Only part of the amount was authorised — not a clean success and not a
      // plain failure. Pass the SDK's own string through: it maps to `failed`
      // in Dart, which routes to CompletePaymentScreen rather than showing a
      // success screen for an order that isn't fully paid.
      case .PartiallyAuthorised:
        finish("PARTIALLY_AUTHORISED", raw: status.rawVal)

      @unknown default:
        finish("FAILED", raw: "unknown PaymentStatus")
      }
    }
  }
#endif
