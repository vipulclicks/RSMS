// ══════════════════════════════════════════════════════════
// RSMS BOPIS Checkout Front-End Logic
// ══════════════════════════════════════════════════════════

document.addEventListener('DOMContentLoaded', () => {
    // Parse Token from Pathname (/c/:token)
    const pathParts = window.location.pathname.split('/');
    const token = pathParts[pathParts.indexOf('c') + 1];

    if (!token) {
        alert("Invalid Checkout URL: Token is missing.");
        return;
    }

    // State Variables
    let sessionData = null;
    let productsMap = {};
    let currentFulfillment = 'pickup';

    // DOM Elements
    const elLoading = document.getElementById('loading');
    const elCard = document.getElementById('checkout-card');
    
    // Screens
    const elScreen1 = document.getElementById('screen-1');
    const elScreen2 = document.getElementById('screen-2');
    const elScreen3 = document.getElementById('screen-3');
    const elScreenSuccess = document.getElementById('screen-success');
    
    // Step indicators
    const elStep1Ind = document.getElementById('step-1-indicator');
    const elStep2Ind = document.getElementById('step-2-indicator');
    const elStep3Ind = document.getElementById('step-3-indicator');

    // Screen 1 Fields
    const elBoutiqueName = document.getElementById('boutique-name');
    const elCartItems = document.getElementById('cart-items');
    const elSubtotal = document.getElementById('price-subtotal');
    const elTax = document.getElementById('price-tax');
    const elTotal = document.getElementById('price-total');
    const elBtnGoTo2 = document.getElementById('btn-goto-step-2');

    // Screen 2 Fields
    const elRadioPickup = document.getElementById('fulfillment-pickup');
    const elRadioShipping = document.getElementById('fulfillment-shipping');
    const elPickupPanel = document.getElementById('pickup-details-panel');
    const elShippingPanel = document.getElementById('shipping-address-panel');
    const elPickupAddress = document.getElementById('pickup-address');
    const elShippingForm = document.getElementById('shipping-form');
    const elBtnBack1 = document.getElementById('btn-back-to-step-1');
    const elBtnGoTo3 = document.getElementById('btn-goto-step-3');

    // Screen 3 Fields
    const elRadioOnline = document.getElementById('payment-online');
    const elRadioInStore = document.getElementById('payment-instore');
    const elPayInStoreCard = document.getElementById('pay-in-store-card');
    const elBtnBack2 = document.getElementById('btn-back-to-step-2');
    const elBtnPayConfirm = document.getElementById('btn-pay-confirm');

    // Success Screen Fields
    const elSuccessMsg = document.getElementById('success-message');
    const elSuccessMethod = document.getElementById('success-detail-method');
    const elSuccessCode = document.getElementById('success-detail-code');

    // Initialize - Fetch Session Data
    fetchSession();

    async function fetchSession() {
        try {
            const response = await fetch(`/api/checkout/${token}`);
            if (!response.ok) {
                throw new Error("Unable to retrieve order details.");
            }
            
            const data = await response.json();
            sessionData = data.session;
            productsMap = data.products.reduce((acc, p) => { acc[p.id] = p; return acc; }, {});
            
            // Populate screen 1
            elBoutiqueName.innerText = data.store ? data.store.name : "Maison Lumière Store";
            elPickupAddress.innerText = data.store ? data.store.address : "Boutique Location Address";
            calculateTotals(data.cartItems, data.totals);
            
            // Check status for completed or already-reserved sessions
            if (sessionData.status === 'paid' || sessionData.status === 'readyForPickup' || sessionData.status === 'readyForShipping' || sessionData.status === 'completed' || sessionData.status === 'pendingStorePayment') {
                showSuccessScreen(sessionData);
                return;
            }
            
            // Hide spinner and show card
            elLoading.classList.add('hide');
            elCard.classList.remove('hide');
            
        } catch (err) {
            console.error(err);
            elLoading.innerHTML = `<p class="gold-text" style="font-weight:600;">Error: ${err.message}</p>`;
        }
    }

    function renderCartItems(items) {
        elCartItems.innerHTML = '';
        items.forEach(item => {
            const prod = productsMap[item.product_id] || { name: "Luxury Product", brand: "Maison Lumière" };
            const price = item.unit_price || prod.price || 0;
            
            const row = document.createElement('div');
            row.className = 'cart-item-row';
            row.innerHTML = `
                <div class="item-meta">
                    <span class="item-name">${prod.name}</span>
                    <span class="item-qty">Qty: ${item.quantity}</span>
                </div>
                <span class="item-price">₹${Math.round(price).toLocaleString()}</span>
            `;
            elCartItems.appendChild(row);
        });
    }

    function calculateTotals(items, serverTotals) {
    const elSubtotal = document.getElementById('price-subtotal');
    const elDiscountRow = document.getElementById('price-discount-row'); // Assume we might add this
    const elDiscount = document.getElementById('price-discount');
    const elTax = document.getElementById('price-tax');
    const elTotal = document.getElementById('price-total');
    const elBtnPayConfirm = document.getElementById('btn-pay-confirm');
    const elBtnPayInstore = document.getElementById('btn-pay-instore');

    if (serverTotals) {
        // Use pre-calculated totals from server/app if available
        const { subtotal, discount, tax, total } = serverTotals;
        if (elSubtotal) elSubtotal.innerText = `₹${Math.round(subtotal).toLocaleString()}`;
        if (elTax) elTax.innerText = `₹${Math.round(tax).toLocaleString()}`;
        if (elTotal) elTotal.innerText = `₹${Math.round(total).toLocaleString()}`;
        
        // Handle discount if we have an element for it (optional)
        if (elDiscountRow && elDiscount && discount > 0) {
            elDiscountRow.style.display = 'flex';
            elDiscount.innerText = `- ₹${Math.round(discount).toLocaleString()}`;
        } else if (elDiscountRow) {
            elDiscountRow.style.display = 'none';
        }

        if (elBtnPayConfirm) elBtnPayConfirm.innerText = `Confirm & Pay ₹${Math.round(total).toLocaleString()}`;
        if (elBtnPayInstore) elBtnPayInstore.innerText = `Confirm & Pay Later`;
    } else {
        // Fallback calculation
        const subtotal = items.reduce((sum, item) => sum + ((item.unit_price || 0) * item.quantity), 0);
        const tax = subtotal * 0.20;
        const total = subtotal + tax;
        
        if (elSubtotal) elSubtotal.innerText = `₹${Math.round(subtotal).toLocaleString()}`;
        if (elTax) elTax.innerText = `₹${Math.round(tax).toLocaleString()}`;
        if (elTotal) elTotal.innerText = `₹${Math.round(total).toLocaleString()}`;
        
        if (elBtnPayConfirm) elBtnPayConfirm.innerText = `Confirm & Pay ₹${Math.round(total).toLocaleString()}`;
        if (elBtnPayInstore) elBtnPayInstore.innerText = `Confirm & Pay Later`;
    }
}



    // Navigation Step 1 -> Step 2
    elBtnGoTo2.addEventListener('click', () => {
        elScreen1.classList.add('hide');
        elScreen2.classList.remove('hide');
        elStep2Ind.classList.add('active');
    });

    // Toggle Fulfillment Options
    elRadioPickup.addEventListener('change', () => {
        currentFulfillment = 'pickup';
        elPickupPanel.classList.remove('hide');
        elShippingPanel.classList.add('hide');
        elPayInStoreCard.classList.remove('hide');
        
        document.querySelectorAll('.fulfillment-options-grid .option-card').forEach(c => c.classList.remove('active'));
        elRadioPickup.closest('.option-card').classList.add('active');
    });

    elRadioShipping.addEventListener('change', () => {
        currentFulfillment = 'shipping';
        elPickupPanel.classList.add('hide');
        elShippingPanel.classList.remove('hide');
        
        // Force Pay Online for Home Delivery
        elRadioOnline.checked = true;
        elRadioOnline.dispatchEvent(new Event('change'));
        elPayInStoreCard.classList.add('hide');
        
        document.querySelectorAll('.fulfillment-options-grid .option-card').forEach(c => c.classList.remove('active'));
        elRadioShipping.closest('.option-card').classList.add('active');
    });

    // Navigation Step 2 -> Step 3
    elBtnGoTo3.addEventListener('click', async () => {
        if (currentFulfillment === 'shipping') {
            // Validate form
            if (!elShippingForm.reportValidity()) {
                return;
            }
        }

        // Submit fulfillment details to backend
        const shippingDetails = currentFulfillment === 'shipping' ? {
            name: document.getElementById('shipping-name').value,
            phone: document.getElementById('shipping-phone').value,
            address: document.getElementById('shipping-address').value,
            city: document.getElementById('shipping-city').value,
            state: document.getElementById('shipping-state').value,
            pincode: document.getElementById('shipping-pincode').value,
        } : null;

        elBtnGoTo3.innerText = "Saving...";
        elBtnGoTo3.disabled = true;

        try {
            const res = await fetch(`/api/checkout/${token}/fulfillment`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ fulfillmentMethod: currentFulfillment, shippingDetails })
            });

            if (!res.ok) throw new Error("Fulfillment save failed.");
            
            // Advance screen
            elScreen2.classList.add('hide');
            elScreen3.classList.remove('hide');
            elStep3Ind.classList.add('active');

        } catch (err) {
            alert(err.message);
        } finally {
            elBtnGoTo3.innerText = "Proceed to Payment";
            elBtnGoTo3.disabled = false;
        }
    });

    // Back Buttons
    elBtnBack1.addEventListener('click', () => {
        elScreen2.classList.add('hide');
        elScreen1.classList.remove('hide');
        elStep2Ind.classList.remove('active');
    });

    elBtnBack2.addEventListener('click', () => {
        elScreen3.classList.add('hide');
        elScreen2.classList.remove('hide');
        elStep3Ind.classList.remove('active');
    });

    // Toggle Payment Cards style
    elRadioOnline.addEventListener('change', () => {
        document.querySelectorAll('.payment-options-grid .option-card').forEach(c => c.classList.remove('active'));
        elRadioOnline.closest('.option-card').classList.add('active');
        elBtnPayConfirm.innerText = elTotal.innerText.replace('₹', 'Pay ₹');
    });

    elRadioInStore.addEventListener('change', () => {
        document.querySelectorAll('.payment-options-grid .option-card').forEach(c => c.classList.remove('active'));
        elRadioInStore.closest('.option-card').classList.add('active');
        elBtnPayConfirm.innerText = "Reserve Order & Pay In Store";
    });

    // Confirm Payment CTA
    elBtnPayConfirm.addEventListener('click', async () => {
        const paymentMethod = elRadioOnline.checked ? 'online' : 'instore';
        
        elBtnPayConfirm.innerText = "Processing...";
        elBtnPayConfirm.disabled = true;

        try {
            if (paymentMethod === 'instore') {
                // Submit store payment preference
                const res = await fetch(`/api/checkout/${token}/payment`, {
                    method: 'POST',
                    headers: { 'Content-Type': 'application/json' },
                    body: JSON.stringify({ paymentMethod })
                });
                
                if (!res.ok) throw new Error("Unable to set payment method.");
                const data = await res.json();
                
                showSuccessScreen(data.session);
            } else {
                // Razorpay Online Payment Flow
                // First: fetch checkout session again to make sure backend details are fresh, and get Razorpay key ID
                const detailsRes = await fetch(`/api/checkout/${token}`);
                const details = await detailsRes.json();
                
                // Construct total in paise using server totals if available
                let totalAmount = 0;
                if (details.totals) {
                    totalAmount = Math.round(details.totals.total);
                } else {
                    totalAmount = Math.round(details.cartItems.reduce((sum, item) => sum + ((item.unit_price || 0) * item.quantity), 0) * 1.20);
                }
                
                // Initialize Razorpay Checkout
                const options = {
                    "key": details.razorpayKeyId,
                    "amount": totalAmount * 100, // paise
                    "currency": "INR",
                    "name": "LUXORA Boutique",
                    "description": "Order Payment",
                    "handler": async function (response) {
                        // Success callback: send razorpay_payment_id back to update status
                        const payConfirm = await fetch(`/api/checkout/${token}/payment`, {
                            method: 'POST',
                            headers: { 'Content-Type': 'application/json' },
                            body: JSON.stringify({ paymentMethod: 'online', razorpayPaymentId: response.razorpay_payment_id })
                        });
                        
                        if (payConfirm.ok) {
                            const payConfirmData = await payConfirm.json();
                            showSuccessScreen(payConfirmData.session);
                        } else {
                            alert("Payment verification failed. Please contact boutique support.");
                        }
                    },
                    "prefill": {
                        "name": details.session.clientId ? "Customer" : "",
                    },
                    "theme": {
                        "color": "#701A30" // Burgundy brand color
                    }
                };
                
                const rzp = new Razorpay(options);
                rzp.open();
                elBtnPayConfirm.innerText = elTotal.innerText.replace('₹', 'Pay ₹');
                elBtnPayConfirm.disabled = false;
            }
        } catch (err) {
            alert(err.message);
            elBtnPayConfirm.innerText = "Try Again";
            elBtnPayConfirm.disabled = false;
        }
    });

    function showSuccessScreen(session) {
        elCard.classList.remove('hide');
        elLoading.classList.add('hide');
        
        elScreen1.classList.add('hide');
        elScreen2.classList.add('hide');
        elScreen3.classList.add('hide');
        elScreenSuccess.classList.remove('hide');
        
        document.querySelectorAll('.step').forEach(s => s.classList.add('active'));
        
        const method = session.fulfillment_method === 'pickup' ? "Pick Up In Store (BOPIS)" : "Home Delivery";
        elSuccessMethod.innerHTML = `<strong>Fulfillment:</strong> ${method}`;
        elSuccessCode.innerHTML = `<strong>Link Token:</strong> ${session.token}`;
        
        if (session.status === 'pendingStorePayment' || session.payment_method === 'instore') {
            elSuccessMsg.innerText = "Your order has been reserved! Please complete payment when you arrive at the boutique for pickup. Our associate will have your items ready.";
        } else {
            elSuccessMsg.innerText = "Your payment has been received. Thank you for your purchase. Our team will prepare your items and confirm the pickup time.";
        }
    }
});
