//
//  RazorpayCheckoutWebView.swift
//  RSMS
//

import SwiftUI
import WebKit

struct RazorpayPaymentResult {
    let paymentId: String
    let orderId: String
    let signature: String
}

struct RazorpayCheckoutWebView: UIViewRepresentable {
    let orderId: String
    let amount: Int
    let currency: String
    let customerName: String
    let email: String
    let phone: String
    let cartId: String
    let clientId: String

    var onSuccess: (RazorpayPaymentResult) -> Void
    var onFailure: (String) -> Void
    var onDismiss: () -> Void

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()
        let userContentController = WKUserContentController()
        userContentController.add(context.coordinator, name: "paymentSuccess")
        userContentController.add(context.coordinator, name: "paymentFailure")
        userContentController.add(context.coordinator, name: "paymentDismiss")
        configuration.userContentController = userContentController

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.isOpaque = false
        webView.backgroundColor = .clear
        webView.customUserAgent = "Mozilla/5.0 (iPhone; CPU iPhone OS 16_0 like Mac OS X) AppleWebKit/605.1.15 (KHTML, like Gecko) Version/16.0 Mobile/15E148 Safari/604.1"

        let html = generateHTML()
        webView.loadHTMLString(html, baseURL: URL(string: "https://razorpay.com"))

        return webView
    }

    func updateUIView(_ uiView: WKWebView, context: Context) {}

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    class Coordinator: NSObject, WKScriptMessageHandler {
        var parent: RazorpayCheckoutWebView

        init(_ parent: RazorpayCheckoutWebView) {
            self.parent = parent
        }

        func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
            if message.name == "paymentSuccess", let dict = message.body as? [String: Any] {
                let result = RazorpayPaymentResult(
                    paymentId: dict["paymentId"] as? String ?? "",
                    orderId: dict["orderId"] as? String ?? "",
                    signature: dict["signature"] as? String ?? ""
                )
                parent.onSuccess(result)
            } else if message.name == "paymentFailure", let reason = message.body as? String {
                parent.onFailure(reason)
            } else if message.name == "paymentDismiss" {
                parent.onDismiss()
            }
        }
    }

    private func generateHTML() -> String {
        return """
        <!DOCTYPE html>
        <html>
        <head>
            <meta name="viewport" content="width=device-width, initial-scale=1.0">
            <script src="https://checkout.razorpay.com/v1/checkout.js"></script>
            <style>
                body { margin: 0; padding: 0; background: transparent; }
            </style>
        </head>
        <body>
            <script>
                var options = {
                    "key": "\(RazorpayService.sandboxKeyId)",
                    "amount": "\(amount)",
                    "currency": "\(currency)",
                    "name": "RSMS Luxury Retail",
                    "description": "Order Payment",
                    "order_id": "\(orderId)",
                    "handler": function (response) {
                        window.webkit.messageHandlers.paymentSuccess.postMessage({
                            "paymentId": response.razorpay_payment_id,
                            "orderId": response.razorpay_order_id,
                            "signature": response.razorpay_signature
                        });
                    },
                    "prefill": {
                        "name": "\(customerName)",
                        "email": "\(email)",
                        "contact": "\(phone)"
                    },
                    "notes": {
                        "cart_id": "\(cartId)",
                        "client_id": "\(clientId)"
                    },
                    "theme": {
                        "color": "#701A30"
                    },
                    "modal": {
                        "ondismiss": function() {
                            window.webkit.messageHandlers.paymentDismiss.postMessage("");
                        }
                    }
                };
                options.handler = function (response){
                    window.webkit.messageHandlers.paymentSuccess.postMessage({
                        "paymentId": response.razorpay_payment_id,
                        "orderId": response.razorpay_order_id,
                        "signature": response.razorpay_signature
                    });
                };
                
                // Hack for catching failure event 
                options.modal = {
                   ondismiss: function(){
                        window.webkit.messageHandlers.paymentDismiss.postMessage("");
                   }
                };
                var rzp1 = new Razorpay(options);
                rzp1.on('payment.failed', function (response){
                    window.webkit.messageHandlers.paymentFailure.postMessage(response.error.description);
                });
                
                window.onload = function() {
                    rzp1.open();
                };
            </script>
        </body>
        </html>
        """
    }
}
