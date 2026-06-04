#!/usr/bin/env python3
import http.server
import socketserver
import json
import urllib.request
import urllib.error
import uuid
import os
import re
from datetime import datetime

PORT = 3000
SUPABASE_REST_URL = "https://lidoouszbcutddwrxbgy.supabase.co/rest/v1"
SUPABASE_ANON_KEY = "sb_publishable_X11_v94UKdMch6EBFq1eyA_9jGIJuD8"
RAZORPAY_KEY_ID = "rzp_test_Sv7udg2RZ8M3K0"

# Local In-Memory Fallback DB (If Supabase tables don't exist yet)
memoryDb = {
    "checkoutSessions": [],
    "shippingAddresses": [],
    "inventoryReservations": [],
    "orders": [],
    "transactions": [],
    "tenders": [],
    "cartItems": [],
    "products": []
}

supabaseHeaders = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": f"Bearer {SUPABASE_ANON_KEY}",
    "Content-Type": "application/json",
    "Prefer": "return=representation"
}

def send_json(handler, data, status=200):
    handler.send_response(status)
    handler.send_header('Content-Type', 'application/json')
    handler.end_headers()
    handler.wfile.write(json.dumps(data).encode('utf-8'))

def http_request(url, method='GET', headers=None, data=None):
    if headers is None:
        headers = {}
    req = urllib.request.Request(url, method=method, headers=headers)
    if data is not None:
        req.data = json.dumps(data).encode('utf-8')
    try:
        with urllib.request.urlopen(req) as response:
            return response.status, json.loads(response.read().decode('utf-8'))
    except urllib.error.HTTPError as e:
        try:
            err_body = json.loads(e.read().decode('utf-8'))
        except Exception:
            err_body = e.reason
        return e.code, {"error": err_body}
    except Exception as e:
        return 500, {"error": str(e)}

def get_session_by_token(token):
    # Try fetching from Supabase
    url = f"{SUPABASE_REST_URL}/checkout_sessions?token=eq.{token}"
    code, res = http_request(url, headers=supabaseHeaders)
    if code == 200 and isinstance(res, list) and len(res) > 0:
        return res[0]
    
    # Try memoryDb
    for s in memoryDb["checkoutSessions"]:
        if s.get("token") == token:
            return s
    return None

def get_session_by_cart_id(cart_id):
    # Try fetching from Supabase
    url = f"{SUPABASE_REST_URL}/checkout_sessions?cart_id=eq.{cart_id}"
    code, res = http_request(url, headers=supabaseHeaders)
    if code == 200 and isinstance(res, list) and len(res) > 0:
        return res[0]
    
    # Try memoryDb
    for s in memoryDb["checkoutSessions"]:
        if s.get("cart_id") == cart_id:
            return s
    return None

def update_session_in_backend(session):
    # Supabase patch
    url = f"{SUPABASE_REST_URL}/checkout_sessions?id=eq.{session['id']}"
    code, res = http_request(url, method='PATCH', headers=supabaseHeaders, data=session)
    
    # Update memoryDb
    found = False
    for idx, s in enumerate(memoryDb["checkoutSessions"]):
        if s.get("id") == session["id"]:
            memoryDb["checkoutSessions"][idx] = session
            found = True
            break
    if not found:
        memoryDb["checkoutSessions"].append(session)

def save_shipping_address(address):
    # Supabase post
    url = f"{SUPABASE_REST_URL}/checkout_shipping_addresses"
    http_request(url, method='POST', headers=supabaseHeaders, data=address)
    memoryDb["shippingAddresses"].append(address)

def fetch_session_cart_details(session_id, token):
    # Retrieve from memory DB first
    mem_data = memoryDb.get(session_id)
    if mem_data and mem_data.get('cartItems'):
        return mem_data['cartItems'], mem_data.get('products', []), mem_data.get('totals', None)
    
    # Fallback/Default implementation if session not found in specific memory block
    return [], [], None

def calculate_cart_total(cart_id):
    try:
        # Try fetching from memoryDb first
        cart_items = [i for i in memoryDb.get("cartItems", []) if i.get("cart_id") == cart_id]
        if cart_items:
            subtotal = sum((item.get("unit_price") or 24500) * item.get("quantity", 1) for item in cart_items)
            return subtotal * 1.20
            
        url_items = f"{SUPABASE_REST_URL}/universal_cart_items?cart_id=eq.{cart_id}"
        code_items, items = http_request(url_items, headers=supabaseHeaders)
        if code_items == 200 and items:
            subtotal = sum((item.get("unit_price") or 24500) * item["quantity"] for item in items)
            return subtotal * 1.20
    except Exception:
        pass
    return 24500 * 1.20

def create_transaction_and_order(session, payment_id):
    cart_items, products, totals = fetch_session_cart_details(session["id"], session.get("token"))
    
    # Fetch actual store_id from Supabase using session['cart_id']
    store_id = "00000000-0000-0000-0000-000000000001"
    try:
        url_c = f"{SUPABASE_REST_URL}/universal_carts?id=eq.{session['cart_id']}"
        code_c, carts = http_request(url_c, headers=supabaseHeaders)
        if code_c == 200 and carts and len(carts) > 0:
            store_id = carts[0].get("store_id", store_id)
            print(f"[Webhook/Payment] Fetched cart's store_id: {store_id}")
        else:
            print(f"[Webhook/Payment] Failed to fetch cart {session['cart_id']}. Code: {code_c}")
    except Exception as ex:
        print(f"[Webhook/Payment] Exception fetching cart: {ex}")

    if totals:
        total = totals.get("total", 0)
        tax_amount = totals.get("tax", 0)
        subtotal = totals.get("subtotal", 0)
        discount_amount = totals.get("discount", 0)
    else:
        total = calculate_cart_total(session["cart_id"])
        subtotal = total / 1.20
        tax_amount = total - subtotal
        discount_amount = 0

    print(f"[Webhook/Payment] Processing transaction/order totals: subtotal={subtotal}, discount={discount_amount}, tax={tax_amount}, total={total}")

    transaction_id = str(uuid.uuid4())
    
    # 1. Save Transaction record
    transaction = {
        "id": transaction_id,
        "cart_id": session["cart_id"],
        "store_id": store_id,
        "associate_id": session["associate_id"],
        "client_id": session["client_id"],
        "total_amount": total,
        "tax_amount": tax_amount,
        "currency": "INR",
        "status": "completed",
        "is_tax_free": False,
        "created_at": datetime.utcnow().isoformat() + "Z"
    }
    
    # Post transaction
    url_tx = f"{SUPABASE_REST_URL}/transactions"
    tx_code, tx_res = http_request(url_tx, method='POST', headers=supabaseHeaders, data=transaction)
    print(f"[Webhook/Payment] Supabase Transaction POST returned code {tx_code}: {tx_res}")
    memoryDb["transactions"].append(transaction)
    
    # 2. Save Tender record
    tender = {
        "id": str(uuid.uuid4()),
        "transaction_id": transaction_id,
        "method": "card",
        "amount": total,
        "reference": f"ONLINE ({payment_id})" if payment_id else "ONLINE"
    }
    url_tender = f"{SUPABASE_REST_URL}/tenders"
    t_code, t_res = http_request(url_tender, method='POST', headers=supabaseHeaders, data=tender)
    print(f"[Webhook/Payment] Supabase Tender POST returned code {t_code}: {t_res}")
    memoryDb["tenders"].append(tender)
    
    # 3. Save Order record
    order = {
        "id": str(uuid.uuid4()),
        "client_id": session["client_id"],
        "transaction_id": transaction_id,
        "cart_id": session["cart_id"],
        "status": "confirmed",
        "total_amount": subtotal,
        "discount_amount": discount_amount,
        "final_amount": total,
        "created_at": datetime.utcnow().isoformat() + "Z",
        "fulfillment_method": session["fulfillment_method"],
        "pickup_store_id": store_id if session["fulfillment_method"] == "pickup" else None,
        "shipping_address": "Home Address" if session["fulfillment_method"] == "shipping" else None,
        "checkout_session_id": session["id"]
    }
    url_order = f"{SUPABASE_REST_URL}/orders"
    o_code, o_res = http_request(url_order, method='POST', headers=supabaseHeaders, data=order)
    print(f"[Webhook/Payment] Supabase Order POST returned code {o_code}: {o_res}")
    memoryDb["orders"].append(order)
    
    # 4. Update cart status to completed
    url_cart = f"{SUPABASE_REST_URL}/universal_carts?id=eq.{session['cart_id']}"
    c_code, c_res = http_request(url_cart, method='PATCH', headers=supabaseHeaders, data={"status": "completed", "updated_at": datetime.utcnow().isoformat() + "Z"})
    print(f"[Webhook/Payment] Supabase Cart PATCH returned code {c_code}: {c_res}")

    # 5. Delete all cart items for this cart
    url_items = f"{SUPABASE_REST_URL}/universal_cart_items?cart_id=eq.{session['cart_id']}"
    http_request(url_items, method='DELETE', headers=supabaseHeaders, data=None)
    # Also clear from memoryDb
    memoryDb["cartItems"] = [i for i in memoryDb.get("cartItems", []) if i.get("cart_id") != session["cart_id"]]
    memoryDb["carts"] = [c for c in memoryDb.get("carts", []) if c.get("id") != session["cart_id"]]

class CheckoutHTTPHandler(http.server.SimpleHTTPRequestHandler):
    def address_string(self):
        return self.client_address[0]
        
    def end_headers(self):
        self.send_header('Access-Control-Allow-Origin', '*')
        self.send_header('Access-Control-Allow-Methods', 'GET, POST, OPTIONS')
        self.send_header('Access-Control-Allow-Headers', 'Content-Type')
        super().end_headers()

    def do_OPTIONS(self):
        self.send_response(200)
        self.end_headers()

    def do_GET(self):
        # Local iOS App Sync Endpoints
        if self.path == '/api/checkout/sessions':
            return send_json(self, memoryDb["checkoutSessions"])
            
        if self.path == '/api/checkout/shipping-addresses':
            return send_json(self, memoryDb["shippingAddresses"])

        # 1. c/:token route -> Serve index.html
        match = re.match(r'^/c/([^/]+)$', self.path)
        if match:
            self.send_response(200)
            self.send_header('Content-Type', 'text/html')
            self.end_headers()
            file_path = os.path.join(os.path.dirname(__file__), 'public', 'index.html')
            with open(file_path, 'rb') as f:
                self.wfile.write(f.read())
            return
            
        # 2. Get status API
        match = re.match(r'^/api/checkout/status/([^/]+)$', self.path)
        if match:
            token = match.group(1)
            session = get_session_by_token(token)
            if not session:
                return send_json(self, {"error": "Session not found."}, 404)
            return send_json(self, {"status": session["status"], "session": session})
            
        # 3. Get session details API
        match = re.match(r'^/api/checkout/([^/]+)$', self.path)
        if match:
            token = match.group(1)
            session = get_session_by_token(token)
            if not session:
                return send_json(self, {"error": "Checkout session not found."}, 404)
                
            if session.get("status") in ['draft', 'linkGenerated']:
                session["status"] = "viewed"
                session["updated_at"] = datetime.utcnow().isoformat() + "Z"
                update_session_in_backend(session)
                
            cart_items, products, totals = fetch_session_cart_details(session["id"], token)
            return send_json(self, {
                "session": session,
                "razorpayKeyId": RAZORPAY_KEY_ID,
                "cartItems": cart_items,
                "products": products,
                "totals": totals
            })
            
        # Serve static files from 'public' directory
        clean_path = self.path.split('?')[0].split('#')[0]
        if clean_path == '/':
            clean_path = '/index.html'
            
        public_dir = os.path.join(os.path.dirname(__file__), 'public')
        if clean_path.startswith('/'):
            clean_path = clean_path[1:]
        file_path = os.path.join(public_dir, clean_path)
        
        if os.path.exists(file_path) and os.path.isfile(file_path):
            content_type = 'text/plain'
            if file_path.endswith('.html'):
                content_type = 'text/html'
            elif file_path.endswith('.css'):
                content_type = 'text/css'
            elif file_path.endswith('.js'):
                content_type = 'application/javascript'
            elif file_path.endswith('.svg'):
                content_type = 'image/svg+xml'
            elif file_path.endswith('.png'):
                content_type = 'image/png'
                
            self.send_response(200)
            self.send_header('Content-Type', content_type)
            self.end_headers()
            with open(file_path, 'rb') as f:
                self.wfile.write(f.read())
            return
            
        self.send_response(404)
        self.end_headers()

    def do_POST(self):
        content_length = int(self.headers.get('Content-Length', 0))
        post_data = self.rfile.read(content_length)
        body = {}
        if post_data:
            try:
                body = json.loads(post_data.decode('utf-8'))
            except Exception:
                pass
                
        # Test Inject Session
        if self.path == '/api/checkout/test/inject-session':
            import random
            import string
            token = ''.join(random.choices(string.ascii_lowercase + string.digits, k=11))
            session_id = str(uuid.uuid4())
            cart_id = body.get("cart_id", str(uuid.uuid4()))
            client_id = body.get("client_id", str(uuid.uuid4()))
            associate_id = body.get("associate_id", str(uuid.uuid4()))
            totals       = body.get("totals")

            session = {
                "id": session_id,
                "cart_id": cart_id,
                "token": token,
                "client_id": client_id,
                "associate_id": associate_id,
                "status": "linkGenerated",
                "fulfillment_method": None,
                "payment_method": None,
                "expires_at": datetime.utcnow().isoformat() + "Z",
                "created_at": datetime.utcnow().isoformat() + "Z",
                "updated_at": datetime.utcnow().isoformat() + "Z"
            }
            memoryDb["checkoutSessions"].append(session)
            # Use the Host header to build the correct public URL (works with tunnels like Pinggy)
            host = self.headers.get("Host", f"localhost:{PORT}")
            scheme = "https" if "pinggy" in host or "ngrok" in host or "localtunnel" in host else "http"
            checkout_url = f"{scheme}://{host}/c/{token}"
            return send_json(self, {"success": True, "session": session, "url": checkout_url})

        # Send Pickup Confirmation Email
        if self.path == '/api/checkout/send-pickup-email':
            session_id     = body.get("sessionId", "")
            token          = body.get("token", "")
            client_email   = body.get("clientEmail", "")
            client_name    = body.get("clientName", "Valued Client")
            scheduled_at   = body.get("scheduledPickupAt", "Not yet scheduled")
            pickup_code    = body.get("pickupCode")
            payment_method = body.get("paymentMethod", "unknown")
            fulfillment    = body.get("fulfillmentMethod", "pickup")
            items          = body.get("items", [])

            # Build a readable item list
            item_lines = "\n".join(
                f"  - {i.get('name','Item')} x {i.get('quantity',1)}  Rs.{int(i.get('price',0)):,}"
                for i in items
            ) or "  (Item details unavailable)"

            payment_note = (
                "Your payment has been received online. No payment is required at the boutique."
                if payment_method == "online" else
                "Your order is reserved. Please complete payment at the boutique register upon arrival."
            )

            subject = "Your Pickup is Scheduled - Maison Lumiere"
            body_text = f"""Dear {client_name},

We are delighted to confirm your pickup appointment at Maison Lumiere.

------------------------------------------------------------
  ORDER DETAILS
------------------------------------------------------------
  Token:       {token}
  Pickup At:   {scheduled_at}
{f"  Pickup Code: {pickup_code}" if pickup_code else ""}

  ITEMS IN YOUR ORDER:
{item_lines}

------------------------------------------------------------
  PAYMENT
------------------------------------------------------------
  {payment_note}

------------------------------------------------------------
  BOUTIQUE LOCATION
------------------------------------------------------------
  Maison Lumiere - Paris Vendome
  23 Place Vendome, 75001 Paris

We look forward to welcoming you.

With warm regards,
Maison Lumiere Boutique Team
"""

            import smtplib, os as _os
            from email.mime.text import MIMEText
            from email.mime.multipart import MIMEMultipart

            smtp_host  = _os.environ.get("SMTP_HOST", "")
            smtp_port  = int(_os.environ.get("SMTP_PORT", "587"))
            smtp_user  = _os.environ.get("SMTP_USER", "")
            smtp_pass  = _os.environ.get("SMTP_PASS", "")
            from_email = _os.environ.get("SMTP_FROM", smtp_user)

            sent = False
            if smtp_host and smtp_user and smtp_pass and client_email:
                try:
                    msg = MIMEMultipart("alternative")
                    msg["Subject"] = subject
                    msg["From"]    = from_email
                    msg["To"]      = client_email
                    msg.attach(MIMEText(body_text, "plain"))

                    with smtplib.SMTP(smtp_host, smtp_port, timeout=10) as server:
                        server.ehlo()
                        server.starttls()
                        server.login(smtp_user, smtp_pass)
                        server.sendmail(from_email, [client_email], msg.as_string())
                    sent = True
                    print(f"[Email] Pickup confirmation sent to {client_email} (token: {token})")
                except Exception as e:
                    print(f"[Email] SMTP send failed: {e}")
            else:
                # Dev mode: print the full email to console for verification
                print(f"\n[Email] DEV MODE - Would send to: {client_email or '(no email on file)'}")
                print(f"  Subject: {subject}")
                print(body_text)
                sent = True  # treat as success in dev so iOS doesn't retry

            return send_json(self, {"success": sent, "to": client_email, "token": token})

        # Sync Session from iOS App
        if self.path == '/api/checkout/sync-session':
            session = body.get("session")
            cart_items = body.get("cartItems", [])
            products = body.get("products", [])
            
            if session:
                found = False
                for idx, s in enumerate(memoryDb["checkoutSessions"]):
                    if s.get("id") == session["id"]:
                        memoryDb["checkoutSessions"][idx] = session
                        found = True
                        break
                if not found:
                    memoryDb["checkoutSessions"].append(session)
                    
                # Save cart items and products to global lists
                for item in cart_items:
                    if not any(i.get("id") == item["id"] for i in memoryDb.setdefault("cartItems", [])):
                        memoryDb["cartItems"].append(item)
                for prod in products:
                    if not any(p.get("id") == prod["id"] for p in memoryDb.setdefault("products", [])):
                        memoryDb["products"].append(prod)
                        
                # ALSO store them indexed by session ID so fetch_session_cart_details can find them!
                memoryDb[session["id"]] = {
                    "cartItems": cart_items,
                    "products": products,
                    "totals": body.get("totals")
                }
                        
                return send_json(self, {"success": True})
            return send_json(self, {"error": "Invalid session data."}, 400)

        # 1. Fulfillment
        match = re.match(r'^/api/checkout/([^/]+)/fulfillment$', self.path)
        if match:
            token = match.group(1)
            session = get_session_by_token(token)
            if not session:
                return send_json(self, {"error": "Checkout session not found."}, 404)
            
            fulfillment_method = body.get("fulfillmentMethod")
            shipping_details = body.get("shippingDetails")
            
            session["fulfillment_method"] = fulfillment_method
            session["status"] = "pendingPayment"
            session["updated_at"] = datetime.utcnow().isoformat() + "Z"
            
            update_session_in_backend(session)
            
            if fulfillment_method == 'shipping' and shipping_details:
                address_record = {
                    "id": str(uuid.uuid4()),
                    "checkout_session_id": session["id"],
                    "name": shipping_details.get("name"),
                    "phone": shipping_details.get("phone"),
                    "address": shipping_details.get("address"),
                    "city": shipping_details.get("city"),
                    "state": shipping_details.get("state"),
                    "pincode": shipping_details.get("pincode"),
                    "created_at": datetime.utcnow().isoformat() + "Z",
                    "updated_at": datetime.utcnow().isoformat() + "Z"
                }
                save_shipping_address(address_record)
                
            return send_json(self, {"success": True, "session": session})
            
        # 2. Payment
        match = re.match(r'^/api/checkout/([^/]+)/payment$', self.path)
        if match:
            token = match.group(1)
            session = get_session_by_token(token)
            if not session:
                return send_json(self, {"error": "Checkout session not found."}, 404)
                
            payment_method = body.get("paymentMethod")
            razorpay_payment_id = body.get("razorpayPaymentId")
            
            session["payment_method"] = payment_method
            session["updated_at"] = datetime.utcnow().isoformat() + "Z"
            
            if payment_method == 'instore':
                session["status"] = "pendingStorePayment"
                update_session_in_backend(session)
                return send_json(self, {"success": True, "status": "pendingStorePayment", "session": session})
            else:
                session["status"] = "readyForPickup" if session.get("fulfillment_method") == "pickup" else "readyForShipping"
                update_session_in_backend(session)
                create_transaction_and_order(session, razorpay_payment_id)
                return send_json(self, {"success": True, "status": session["status"], "session": session})
                
        # 3. Webhook for Razorpay
        if self.path == '/api/checkout/webhook/razorpay':
            event = body.get("event")
            if event == 'payment.captured':
                payment_payload = body.get("payload", {}).get("payment", {}).get("entity", {})
                cart_id = payment_payload.get("notes", {}).get("cart_id")
                payment_id = payment_payload.get("id")
                
                session = get_session_by_cart_id(cart_id)
                if session and session.get("status") in ['pendingPayment', 'viewed']:
                    session["payment_method"] = "online"
                    session["status"] = "readyForPickup" if session.get("fulfillment_method") == "pickup" else "readyForShipping"
                    session["updated_at"] = datetime.utcnow().isoformat() + "Z"
                    update_session_in_backend(session)
                    create_transaction_and_order(session, payment_id)
            return send_json(self, {"status": "ok"})
            
        self.send_response(404)
        self.end_headers()

if __name__ == "__main__":
    # Change working directory to script location
    os.chdir(os.path.dirname(os.path.abspath(__file__)))
    
    # Enable socket re-use to prevent "Address already in use" errors on restarts
    socketserver.TCPServer.allow_reuse_address = True
    
    with socketserver.TCPServer(("", PORT), CheckoutHTTPHandler) as httpd:
        print(f"[Python Server] RSMS BOPIS Checkout Website listening at http://localhost:{PORT}")
        try:
            httpd.serve_forever()
        except KeyboardInterrupt:
            print("\nShutting down server.")
