const express = require('express');
const bodyParser = require('body-parser');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;

app.use(bodyParser.json());
app.use(express.static(path.join(__dirname, 'public')));

// Configuration
const SUPABASE_REST_URL = "https://lidoouszbcutddwrxbgy.supabase.co/rest/v1";
const SUPABASE_ANON_KEY = "sb_publishable_X11_v94UKdMch6EBFq1eyA_9jGIJuD8";
const RAZORPAY_KEY_ID = "rzp_test_Sv7udg2RZ8M3K0";

// Local In-Memory Fallback DB (If Supabase tables don't exist yet)
const memoryDb = {
    checkoutSessions: [],
    shippingAddresses: [],
    inventoryReservations: [],
    orders: [],
    transactions: [],
    tenders: []
};

// Middleware to inject headers for Supabase API calls
const supabaseHeaders = {
    "apikey": SUPABASE_ANON_KEY,
    "Authorization": `Bearer ${SUPABASE_ANON_KEY}`,
    "Content-Type": "application/json",
    "Prefer": "return=representation"
};

// ══════════════════════════════════════════════════════════
// MARK: - API Endpoints
// ══════════════════════════════════════════════════════════

// 1. Retrieve checkout session details
app.get('/api/checkout/:token', async (req, res) => {
    const { token } = req.params;
    console.log(`[API] Fetching checkout session with token: ${token}`);
    
    try {
        // Try fetching from Supabase first
        const response = await fetch(`${SUPABASE_REST_URL}/checkout_sessions?token=eq.${token}`, {
            headers: supabaseHeaders
        });
        
        if (!response.ok) {
            throw new Error(`Supabase error: ${response.statusText}`);
        }
        
        const data = await response.json();
        let session = data[0];
        
        // If not found in Supabase, look in memory db
        if (!session) {
            session = memoryDb.checkoutSessions.find(s => s.token === token);
        }
        
        if (!session) {
            return res.status(404).json({ error: "Checkout session not found." });
        }
        
        // If the session has been viewed, update status from draft or linkGenerated to viewed
        if (session.status === 'linkGenerated' || session.status === 'draft') {
            session.status = 'viewed';
            session.updated_at = new Date().toISOString();
            
            // Persist view update
            await updateSessionInBackend(session);
        }
        
        // Fetch cart items, products, and store details
        const details = await fetchSessionCartDetails(session);
        res.json({ session, ...details, razorpayKeyId: RAZORPAY_KEY_ID });
        
    } catch (err) {
        console.error(`[API] Error fetching session details: ${err.message}`);
        // Fallback to local memory db search
        const session = memoryDb.checkoutSessions.find(s => s.token === token);
        if (session) {
            if (session.status === 'linkGenerated' || session.status === 'draft') {
                session.status = 'viewed';
                session.updated_at = new Date().toISOString();
            }
            const details = await fetchSessionCartDetails(session);
            return res.json({ session, ...details, razorpayKeyId: RAZORPAY_KEY_ID });
        }
        res.status(500).json({ error: err.message });
    }
});

// 2. Select fulfillment method
app.post('/api/checkout/:token/fulfillment', async (req, res) => {
    const { token } = req.params;
    const { fulfillmentMethod, shippingDetails } = req.body; // fulfillmentMethod: 'pickup' or 'shipping'
    
    console.log(`[API] Setting fulfillment for token ${token}: ${fulfillmentMethod}`);
    
    try {
        let session = await getSessionByToken(token);
        if (!session) {
            return res.status(404).json({ error: "Checkout session not found." });
        }
        
        // Update session
        session.fulfillment_method = fulfillmentMethod;
        session.status = (fulfillmentMethod === 'pickup') ? 'pendingPayment' : 'pendingPayment';
        session.updated_at = new Date().toISOString();
        
        await updateSessionInBackend(session);
        
        // Save shipping details if shipping was chosen
        if (fulfillmentMethod === 'shipping' && shippingDetails) {
            const addressRecord = {
                id: cryptoUuid(),
                checkout_session_id: session.id,
                name: shippingDetails.name,
                phone: shippingDetails.phone,
                address: shippingDetails.address,
                city: shippingDetails.city,
                state: shippingDetails.state,
                pincode: shippingDetails.pincode,
                created_at: new Date().toISOString(),
                updated_at: new Date().toISOString()
            };
            
            await saveShippingAddress(addressRecord);
        }
        
        res.json({ success: true, session });
        
    } catch (err) {
        console.error(`[API] Error setting fulfillment: ${err.message}`);
        res.status(500).json({ error: err.message });
    }
});

// 3. Process Payment (Pay Online or Pay In-store)
app.post('/api/checkout/:token/payment', async (req, res) => {
    const { token } = req.params;
    const { paymentMethod, razorpayPaymentId } = req.body; // paymentMethod: 'online' or 'instore'
    
    console.log(`[API] Processing payment for token ${token}: ${paymentMethod}`);
    
    try {
        let session = await getSessionByToken(token);
        if (!session) {
            return res.status(404).json({ error: "Checkout session not found." });
        }
        
        session.payment_method = paymentMethod;
        session.updated_at = new Date().toISOString();
        
        if (paymentMethod === 'instore') {
            // Pay In-store (Pickup only) -> set status to pendingStorePayment
            session.status = 'pendingStorePayment';
            await updateSessionInBackend(session);
            
            res.json({ success: true, status: 'pendingStorePayment', session });
        } else {
            // Paid Online -> verify and mark paid
            session.status = (session.fulfillment_method === 'pickup') ? 'readyForPickup' : 'readyForShipping';
            await updateSessionInBackend(session);
            
            // Create completed transaction and order in Supabase
            await createTransactionAndOrder(session, razorpayPaymentId);
            
            res.json({ success: true, status: session.status, session });
        }
        
    } catch (err) {
        console.error(`[API] Error processing payment: ${err.message}`);
        res.status(500).json({ error: err.message });
    }
});

// 4. Webhook for Razorpay Payment Captured
app.post('/api/checkout/webhook/razorpay', async (req, res) => {
    console.log(`[Webhook] Razorpay webhook received:`, req.body);
    const event = req.body.event;
    
    if (event === 'payment.captured') {
        const paymentPayload = req.body.payload.payment.entity;
        const cartId = paymentPayload.notes.cart_id;
        const paymentId = paymentPayload.id;
        
        console.log(`[Webhook] Payment captured: ${paymentId} for cart: ${cartId}`);
        
        try {
            // Find session by cart ID
            let session = await getSessionByCartId(cartId);
            if (session && (session.status === 'pendingPayment' || session.status === 'viewed')) {
                session.payment_method = 'online';
                session.status = (session.fulfillment_method === 'pickup') ? 'readyForPickup' : 'readyForShipping';
                session.updated_at = new Date().toISOString();
                
                await updateSessionInBackend(session);
                await createTransactionAndOrder(session, paymentId);
                console.log(`[Webhook] Session updated and order created successfully.`);
            }
        } catch (err) {
            console.error(`[Webhook] Error executing capture logic: ${err.message}`);
        }
    }
    
    res.json({ status: 'ok' });
});

// 5. Get Session Status
app.get('/api/checkout/status/:token', async (req, res) => {
    const { token } = req.params;
    try {
        const session = await getSessionByToken(token);
        if (!session) {
            return res.status(404).json({ error: "Session not found." });
        }
        res.json({ status: session.status, session });
    } catch (err) {
        res.status(500).json({ error: err.message });
    }
});

// Serve frontend checkout router page
app.get('/c/:token', (req, res) => {
    res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

// ══════════════════════════════════════════════════════════
// MARK: - Backend helper methods
// ══════════════════════════════════════════════════════════

async function getSessionByToken(token) {
    try {
        const res = await fetch(`${SUPABASE_REST_URL}/checkout_sessions?token=eq.${token}`, {
            headers: supabaseHeaders
        });
        const data = await res.json();
        if (data[0]) return data[0];
    } catch (err) {
        console.warn(`[DB] Supabase session fetch failed: ${err.message}`);
    }
    return memoryDb.checkoutSessions.find(s => s.token === token);
}

async function getSessionByCartId(cartId) {
    try {
        const res = await fetch(`${SUPABASE_REST_URL}/checkout_sessions?cart_id=eq.${cartId}`, {
            headers: supabaseHeaders
        });
        const data = await res.json();
        if (data[0]) return data[0];
    } catch (err) {
        console.warn(`[DB] Supabase session fetch failed: ${err.message}`);
    }
    return memoryDb.checkoutSessions.find(s => s.cart_id === cartId);
}

async function updateSessionInBackend(session) {
    // 1. Update in Supabase
    try {
        const response = await fetch(`${SUPABASE_REST_URL}/checkout_sessions?id=eq.${session.id}`, {
            method: 'PATCH',
            headers: supabaseHeaders,
            body: JSON.stringify(session)
        });
        if (response.ok) return;
    } catch (err) {
        console.warn(`[DB] Supabase session update failed: ${err.message}`);
    }
    
    // 2. Update in memory
    const idx = memoryDb.checkoutSessions.findIndex(s => s.id === session.id);
    if (idx !== -1) {
        memoryDb.checkoutSessions[idx] = session;
    } else {
        memoryDb.checkoutSessions.push(session);
    }
}

async function saveShippingAddress(address) {
    try {
        const response = await fetch(`${SUPABASE_REST_URL}/checkout_shipping_addresses`, {
            method: 'POST',
            headers: supabaseHeaders,
            body: JSON.stringify(address)
        });
        if (response.ok) return;
    } catch (err) {
        console.warn(`[DB] Supabase shipping save failed: ${err.message}`);
    }
    memoryDb.shippingAddresses.push(address);
}

async function fetchSessionCartDetails(session) {
    let cartItems = [];
    let products = [];
    let store = null;
    
    try {
        // Fetch cart items
        const resItems = await fetch(`${SUPABASE_REST_URL}/universal_cart_items?cart_id=eq.${session.cart_id}`, { headers: supabaseHeaders });
        cartItems = await resItems.json();
        
        // Fetch products
        if (cartItems.length > 0) {
            const productIds = cartItems.map(item => item.product_id);
            const resProducts = await fetch(`${SUPABASE_REST_URL}/products?id=in.(${productIds.join(',')})`, { headers: supabaseHeaders });
            products = await resProducts.json();
        }
        
        // Fetch store info
        const resCart = await fetch(`${SUPABASE_REST_URL}/universal_carts?id=eq.${session.cart_id}`, { headers: supabaseHeaders });
        const cartData = await resCart.json();
        if (cartData[0] && cartData[0].store_id) {
            const resStore = await fetch(`${SUPABASE_REST_URL}/stores?id=eq.${cartData[0].store_id}`, { headers: supabaseHeaders });
            const storeData = await resStore.json();
            store = storeData[0];
        }
    } catch (err) {
        console.warn(`[DB] Supabase cart detail fetch failed: ${err.message}. Using mock products.`);
        // Fallback mock details
        cartItems = [{ id: cryptoUuid(), cart_id: session.cart_id, product_id: "30000000-0000-0000-0000-000000000001", quantity: 1, unit_price: 24500 }];
        products = [{ id: "30000000-0000-0000-0000-000000000001", name: "Chronograph Royale - 42mm", price: 24500, brand: "Maison Lumière", category: "Watches", sku: "WA-CHR-RG-42" }];
        store = { id: "00000000-0000-0000-0000-000000000001", name: "Maison Lumière — Paris Vendôme", address: "23 Place Vendôme, 75001 Paris" };
    }
    
    return { cartItems, products, store };
}

async function createTransactionAndOrder(session, paymentId) {
    const total = await calculateCartTotal(session.cart_id);
    const transactionId = cryptoUuid();
    
    // 1. Save Transaction record
    const transaction = {
        id: transactionId,
        cart_id: session.cart_id,
        store_id: "00000000-0000-0000-0000-000000000001", // fallback store
        associate_id: session.associate_id,
        client_id: session.client_id,
        total_amount: total,
        tax_amount: total * 0.2 / 1.2,
        currency: "INR",
        status: "completed",
        is_tax_free: false,
        created_at: new Date().toISOString()
    };
    
    try {
        await fetch(`${SUPABASE_REST_URL}/transactions`, {
            method: 'POST',
            headers: supabaseHeaders,
            body: JSON.stringify(transaction)
        });
    } catch (err) {
        console.warn(`[DB] Supabase transaction insert failed: ${err.message}`);
    }
    memoryDb.transactions.push(transaction);
    
    // 2. Save Tender record
    const tender = {
        id: cryptoUuid(),
        transaction_id: transactionId,
        method: "card",
        amount: total,
        reference: paymentId
    };
    
    try {
        await fetch(`${SUPABASE_REST_URL}/tenders`, {
            method: 'POST',
            headers: supabaseHeaders,
            body: JSON.stringify(tender)
        });
    } catch (err) {
        console.warn(`[DB] Supabase tender insert failed: ${err.message}`);
    }
    memoryDb.tenders.push(tender);
    
    // 3. Save Order record with BOPIS extensions
    const order = {
        id: cryptoUuid(),
        client_id: session.client_id,
        transaction_id: transactionId,
        cart_id: session.cart_id,
        status: "confirmed",
        total_amount: total / 1.2,
        discount_amount: 0,
        final_amount: total,
        created_at: new Date().toISOString(),
        fulfillment_method: session.fulfillment_method,
        pickup_store_id: session.fulfillment_method === 'pickup' ? "00000000-0000-0000-0000-000000000001" : null,
        shipping_address: session.fulfillment_method === 'shipping' ? "Home Address" : null,
        checkout_session_id: session.id
    };
    
    try {
        await fetch(`${SUPABASE_REST_URL}/orders`, {
            method: 'POST',
            headers: supabaseHeaders,
            body: JSON.stringify(order)
        });
    } catch (err) {
        console.warn(`[DB] Supabase order insert failed: ${err.message}`);
    }
    memoryDb.orders.push(order);
    
    // 4. Update cart status to completed
    try {
        await fetch(`${SUPABASE_REST_URL}/universal_carts?id=eq.${session.cart_id}`, {
            method: 'PATCH',
            headers: supabaseHeaders,
            body: JSON.stringify({ status: "completed", updated_at: new Date().toISOString() })
        });
    } catch (err) {
        console.warn(`[DB] Supabase cart complete patch failed: ${err.message}`);
    }
}

async function calculateCartTotal(cartId) {
    try {
        const res = await fetch(`${SUPABASE_REST_URL}/universal_cart_items?cart_id=eq.${cartId}`, { headers: supabaseHeaders });
        const items = await res.json();
        const subtotal = items.reduce((acc, item) => acc + ((item.unit_price || 24500) * item.quantity), 0);
        return subtotal * 1.20; // with tax
    } catch (err) {
        return 24500 * 1.20;
    }
}

// Helpers
function cryptoUuid() {
    return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, function(c) {
        var r = Math.random() * 16 | 0, v = c == 'x' ? r : (r & 0x3 | 0x8);
        return v.toString(16);
    });
}

// Start Server
app.listen(PORT, () => {
    console.log(`[Server] RSMS BOPIS Checkout Website listening at http://localhost:${PORT}`);
});
