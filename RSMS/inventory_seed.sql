-- RSMS Inventory Mock Data Seed
-- This script contains ONLY the INSERT statements for the comprehensive inventory mock data.

-- ==========================================
-- 0. PREREQUISITES (STORES & USERS)
-- ==========================================
INSERT INTO stores (id, name, code, country, city, address, timezone, phone, email, is_active, created_at, updated_at) VALUES
('00000000-0000-0000-0000-000000000001', 'Maison Lumière — Paris Vendôme', 'PAR-VND-01', 'France', 'Paris', '23 Place Vendôme, 75001 Paris', 'Europe/Paris', '+33 1 42 60 00 00', 'vendome@maisonlumiere.com', true, NOW(), NOW()),
('00000000-0000-0000-0000-000000000002', 'Maison Lumière — Mumbai Palladium', 'MUM-PLD-01', 'India', 'Mumbai', 'Palladium Mall, Lower Parel, Mumbai 400013', 'Asia/Kolkata', '+91 22 4000 0000', 'mumbai@maisonlumiere.com', true, NOW(), NOW())
ON CONFLICT (id) DO NOTHING;

UPDATE user_profiles SET store_id = '00000000-0000-0000-0000-000000000001', role = 'inventory_controller' WHERE id = 'ada6eb74-0b6d-43bb-8612-3f265960dae1';

-- ==========================================
-- 1. PRODUCTS
-- ==========================================
INSERT INTO products (id, sku, name, category, subcategory, brand, collection, material, price, currency, description, image_url, is_active, created_at, updated_at) VALUES
('30000000-0000-0000-0000-000000000001', 'WA-CHR-RG-42', 'Chronograph Royale - 42mm', 'Watches', 'Chronograph', 'Maison Lumière', 'Royale', 'Rose Gold', 24500.00, 'EUR', '18k Rose Gold chronograph with alligator strap.', NULL, true, NOW() - INTERVAL '90 days', NOW()),
('30000000-0000-0000-0000-000000000002', 'RG-DIA-ET-52', 'Eternity Diamond Ring', 'Jewelry', 'Rings', 'Maison Lumière', 'Eternity', 'Platinum', 8900.00, 'EUR', 'Platinum eternity ring with 2ct pavé diamonds.', NULL, true, NOW() - INTERVAL '60 days', NOW()),
('30000000-0000-0000-0000-000000000003', 'JW-NKL-SAP-18', 'Sapphire Cascade Necklace', 'Jewelry', 'Necklaces', 'Maison Lumière', 'Cascade', '18K White Gold', 15200.00, 'EUR', 'Ceylon sapphire and diamond pendant necklace.', NULL, true, NOW() - INTERVAL '45 days', NOW()),
('30000000-0000-0000-0000-000000000004', 'JW-BRC-GLD-20', 'Torsade Gold Bracelet', 'Jewelry', 'Bracelets', 'Maison Lumière', 'Torsade', '18K Yellow Gold', 6800.00, 'EUR', 'Twisted rope bracelet with pavé diamond clasp.', NULL, true, NOW() - INTERVAL '30 days', NOW()),
('30000000-0000-0000-0000-000000000005', 'LG-HBG-CLF-MD', 'Cuir Classique Tote', 'Leather Goods', 'Handbags', 'Maison Lumière', 'Classique', 'Calfskin Leather', 3900.00, 'EUR', 'Medium structured tote in smooth calfskin.', NULL, true, NOW() - INTERVAL '25 days', NOW()),
('30000000-0000-0000-0000-000000000006', 'LG-WLT-CRO-SM', 'Crocodile Card Wallet', 'Leather Goods', 'Wallets', 'Maison Lumière', 'Exotique', 'Crocodile Leather', 2100.00, 'EUR', 'Slim card wallet in Nilo crocodile.', NULL, true, NOW() - INTERVAL '20 days', NOW()),
('30000000-0000-0000-0000-000000000007', 'AC-SUN-AVT-01', 'Aviateur Sunglasses', 'Accessories', 'Eyewear', 'Maison Lumière', 'Aviateur', 'Titanium', 890.00, 'EUR', 'Aviator frames with polarized gradient lenses.', NULL, true, NOW() - INTERVAL '15 days', NOW()),
('30000000-0000-0000-0000-000000000008', 'AC-SCF-CSH-LG', 'Cachemire Étoile Scarf', 'Accessories', 'Scarves', 'Maison Lumière', 'Étoile', 'Cashmere', 750.00, 'EUR', 'Large cashmere scarf with star jacquard pattern.', NULL, true, NOW() - INTERVAL '12 days', NOW()),
('30000000-0000-0000-0000-000000000009', 'FR-EDP-NTR-75', 'Nuit Royale Eau de Parfum', 'Fragrances', 'Eau de Parfum', 'Maison Lumière', 'Nuit', NULL, 320.00, 'EUR', '75ml EDP with oud, amber, and rose notes.', NULL, true, NOW() - INTERVAL '10 days', NOW()),
('30000000-0000-0000-0000-00000000000A', 'JW-EAR-DRP-PL', 'Diamond Drop Earrings', 'Jewelry', 'Earrings', 'Maison Lumière', 'Éternité', 'Platinum', 5600.00, 'EUR', 'Pear-cut diamond drop earrings, 1.5ct total.', NULL, true, NOW() - INTERVAL '8 days', NOW()),
('30000000-0000-0000-0000-00000000000B', 'LG-BLT-REV-85', 'Reversible Signature Belt', 'Leather Goods', 'Belts', 'Maison Lumière', 'Signature', 'Calfskin Leather', 680.00, 'EUR', 'Reversible belt, black/brown, gold buckle.', NULL, true, NOW() - INTERVAL '5 days', NOW()),
('30000000-0000-0000-0000-00000000000C', 'WA-DIV-TT-44', 'Abyss Diver - 44mm', 'Watches', 'Diver', 'Maison Lumière', 'Abyss', 'Titanium / Ceramic', 18900.00, 'EUR', '300m diver in titanium with ceramic bezel.', NULL, true, NOW() - INTERVAL '3 days', NOW())
ON CONFLICT (id) DO NOTHING;

-- ==========================================
-- 2. STOCK ITEMS
-- ==========================================
-- Assume Store.preview.id = '00000000-0000-0000-0000-000000000001' (Paris)
-- Assume Store.previewMumbai.id = '00000000-0000-0000-0000-000000000002' (Mumbai)
INSERT INTO stock_items (id, product_id, store_id, quantity, rfid_tag, location, status, last_scanned_at, updated_at) VALUES
('30000000-0000-0000-0000-000000000010', '30000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000001', 3, 'RFID-WA-CHR-001', 'Display Case A', 'available', NOW() - INTERVAL '30 minutes', NOW()),
('30000000-0000-0000-0000-000000000011', '30000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 1, 'RFID-RG-DIA-001', 'Vault', 'available', NOW() - INTERVAL '1 hour', NOW()),
('30000000-0000-0000-0000-000000000012', '30000000-0000-0000-0000-000000000003', '00000000-0000-0000-0000-000000000001', 2, 'RFID-JW-NKL-001', 'Display Case B', 'available', NOW() - INTERVAL '2 hours', NOW()),
('30000000-0000-0000-0000-000000000013', '30000000-0000-0000-0000-000000000004', '00000000-0000-0000-0000-000000000001', 4, 'RFID-JW-BRC-001', 'Display Case B', 'available', NOW() - INTERVAL '90 minutes', NOW()),
('30000000-0000-0000-0000-000000000014', '30000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', 6, 'RFID-LG-HBG-001', 'Showroom Floor', 'available', NOW() - INTERVAL '2.5 hours', NOW()),
('30000000-0000-0000-0000-000000000015', '30000000-0000-0000-0000-000000000006', '00000000-0000-0000-0000-000000000001', 8, 'RFID-LG-WLT-001', 'Accessories Wall', 'available', NOW() - INTERVAL '3 hours', NOW()),
('30000000-0000-0000-0000-000000000016', '30000000-0000-0000-0000-000000000007', '00000000-0000-0000-0000-000000000001', 12, 'RFID-AC-SUN-001', 'Eyewear Display', 'available', NOW() - INTERVAL '3.5 hours', NOW()),
('30000000-0000-0000-0000-000000000017', '30000000-0000-0000-0000-000000000008', '00000000-0000-0000-0000-000000000001', 15, 'RFID-AC-SCF-001', 'Accessories Wall', 'available', NOW() - INTERVAL '4 hours', NOW()),
('30000000-0000-0000-0000-000000000018', '30000000-0000-0000-0000-000000000009', '00000000-0000-0000-0000-000000000001', 20, NULL, 'Fragrance Counter', 'available', NOW() - INTERVAL '4.5 hours', NOW()),
('30000000-0000-0000-0000-000000000019', '30000000-0000-0000-0000-00000000000A', '00000000-0000-0000-0000-000000000001', 2, 'RFID-JW-EAR-001', 'Vault', 'reserved', NOW() - INTERVAL '5 hours', NOW()),
('30000000-0000-0000-0000-00000000001A', '30000000-0000-0000-0000-00000000000B', '00000000-0000-0000-0000-000000000001', 10, 'RFID-LG-BLT-001', 'Accessories Wall', 'available', NOW() - INTERVAL '5.5 hours', NOW()),
('30000000-0000-0000-0000-00000000001B', '30000000-0000-0000-0000-00000000000C', '00000000-0000-0000-0000-000000000001', 2, 'RFID-WA-DIV-001', 'Display Case A', 'in_transit', NULL, NOW() - INTERVAL '1 day'),
('30000000-0000-0000-0000-00000000001C', '30000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000002', 1, 'RFID-RG-DIA-MUM', 'Display Case', 'available', NOW(), NOW()),
('30000000-0000-0000-0000-00000000001D', '30000000-0000-0000-0000-000000000005', '00000000-0000-0000-0000-000000000001', 1, 'RFID-LG-HBG-DMG', 'Back Office', 'damaged', NOW() - INTERVAL '12 hours', NOW())
ON CONFLICT (id) DO NOTHING;

-- ==========================================
-- 3. RFID SCAN RECORDS
-- ==========================================
-- Assume UserProfile.previewInventory.id = 'ada6eb74-0b6d-43bb-8612-3f265960dae1'
-- Assume UserProfile.previewManager.id = 'ada6eb74-0b6d-43bb-8612-3f265960dae1'
INSERT INTO rfid_scan_records (id, store_id, scanned_by, scanned_at, items_scanned, exceptions_found, notes) VALUES
('30000000-0000-0000-0000-000000000020', '00000000-0000-0000-0000-000000000001', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', NOW() - INTERVAL '1 hour', 450, 2, 'Routine morning scan. Missing 2 items from display case C.'),
('30000000-0000-0000-0000-000000000021', '00000000-0000-0000-0000-000000000001', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', NOW() - INTERVAL '5 hours', 455, 0, 'Afternoon full-floor RFID scan. All items accounted for.'),
('30000000-0000-0000-0000-000000000022', '00000000-0000-0000-0000-000000000001', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', NOW() - INTERVAL '1 day', 448, 3, 'End-of-day closing scan. 3 items not yet returned from client try-on.'),
('30000000-0000-0000-0000-000000000023', '00000000-0000-0000-0000-000000000001', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', NOW() - INTERVAL '2 hours', 42, 0, 'Vault high-value inventory scan. All pieces matched.')
ON CONFLICT (id) DO NOTHING;

-- ==========================================
-- 4. INVENTORY VARIANCES
-- ==========================================
INSERT INTO inventory_variances (id, store_id, product_id, expected_qty, actual_qty, variance, reported_by, status, cycle_count_id, resolution, reported_at, resolved_at) VALUES
('30000000-0000-0000-0000-000000000030', '00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000002', 2, 1, -1, 'ada6eb74-0b6d-43bb-8612-3f265960dae1', 'investigating', NULL, NULL, NOW() - INTERVAL '2 hours', NULL),
('30000000-0000-0000-0000-000000000031', '00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000006', 10, 8, -2, 'ada6eb74-0b6d-43bb-8612-3f265960dae1', 'open', NULL, NULL, NOW() - INTERVAL '1 hour', NULL),
('30000000-0000-0000-0000-000000000032', '00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000008', 14, 15, 1, 'ada6eb74-0b6d-43bb-8612-3f265960dae1', 'resolved', NULL, 'Mis-shipped item from DC found during recount. Adjusted system qty.', NOW() - INTERVAL '2 days', NOW() - INTERVAL '1 day'),
('30000000-0000-0000-0000-000000000033', '00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000007', 13, 12, -1, 'ada6eb74-0b6d-43bb-8612-3f265960dae1', 'write_off', NULL, 'Item confirmed missing after 30-day investigation. Written off as shrinkage.', NOW() - INTERVAL '30 days', NOW() - INTERVAL '1 day'),
('30000000-0000-0000-0000-000000000034', '00000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000003', 3, 2, -1, 'ada6eb74-0b6d-43bb-8612-3f265960dae1', 'open', NULL, NULL, NOW() - INTERVAL '30 minutes', NULL)
ON CONFLICT (id) DO NOTHING;

-- ==========================================
-- 5. INVENTORY MOVEMENTS
-- ==========================================
INSERT INTO inventory_movements (id, type, source_id, destination_id, status, requested_by, approved_by, requested_at, shipped_at, received_at, asn_number, items_expected, items_received, reason, notes) VALUES
('30000000-0000-0000-0000-000000000040', 'store_transfer', '00000000-0000-0000-0000-000000000001', '00000000-0000-0000-0000-000000000002', 'in_transit', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', NOW() - INTERVAL '2 days', NOW() - INTERVAL '1 day', NULL, NULL, 3, NULL, 'Customer request transfer — VIP client in Mumbai.', 'Handle with care, high-value items.'),
('30000000-0000-0000-0000-000000000050', 'dc_replenishment', 'DC-EUROPE-01', '00000000-0000-0000-0000-000000000001', 'in_transit', NULL, NULL, NULL, NOW() - INTERVAL '1 day', NULL, 'ASN-2026-05-987654', 15, NULL, NULL, 'Weekly replenishment — fragrances and small leather goods.'),
('30000000-0000-0000-0000-000000000060', 'vendor_return', '00000000-0000-0000-0000-000000000001', 'VEND-MAISON-001', 'requested', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', NULL, NOW(), NULL, NULL, NULL, 1, NULL, 'Defective clasp on handbag, warranty claim.', NULL),
('30000000-0000-0000-0000-000000000061', 'store_transfer', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'completed', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', NOW() - INTERVAL '7 days', NOW() - INTERVAL '5 days', NOW() - INTERVAL '3 days', NULL, 2, 2, 'Seasonal rebalancing — move Abyss Diver to Paris.', 'Both items received in good condition.'),
('30000000-0000-0000-0000-000000000062', 'dc_replenishment', 'DC-ASIA-01', '00000000-0000-0000-0000-000000000002', 'partial', NULL, NULL, NULL, NOW() - INTERVAL '4 days', NOW() - INTERVAL '2 days', 'ASN-2026-05-654321', 20, 17, NULL, '3 items back-ordered, expected next shipment.'),
('30000000-0000-0000-0000-000000000063', 'dc_replenishment', 'DC-EUROPE-02', '00000000-0000-0000-0000-000000000001', 'in_transit', NULL, NULL, NULL, NOW() - INTERVAL '3 days', NULL, 'ASN-2026-05-888888', 8, NULL, NULL, 'High-end watches restock.'),
('30000000-0000-0000-0000-000000000064', 'store_transfer', '00000000-0000-0000-0000-000000000002', '00000000-0000-0000-0000-000000000001', 'in_transit', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', NOW() - INTERVAL '5 days', NOW() - INTERVAL '2 days', NULL, 'ASN-2026-05-777777', 12, NULL, 'Mumbai boutique transfer.', 'Jewelry collection transfer.'),
('30000000-0000-0000-0000-000000000065', 'dc_replenishment', 'DC-EUROPE-01', '00000000-0000-0000-0000-000000000001', 'in_transit', NULL, NULL, NULL, NOW() - INTERVAL '12 hours', NULL, 'ASN-2026-05-999999', 40, NULL, NULL, 'Monthly leather goods replenishment.'),
('30000000-0000-0000-0000-000000000066', 'dc_replenishment', 'DC-EUROPE-01', '00000000-0000-0000-0000-000000000001', 'received', NULL, NULL, NULL, NOW() - INTERVAL '10 days', NOW() - INTERVAL '8 days', 'ASN-2026-05-111111', 20, 20, NULL, 'Accessories and eyewear restock. All items received.'),
('30000000-0000-0000-0000-000000000067', 'dc_replenishment', 'DC-EUROPE-02', '00000000-0000-0000-0000-000000000001', 'completed', NULL, NULL, NULL, NOW() - INTERVAL '18 days', NOW() - INTERVAL '15 days', 'ASN-2026-04-555555', 10, 10, NULL, 'Bracelets and handbags quarterly replenishment.'),
('30000000-0000-0000-0000-000000000068', 'vendor_return', '00000000-0000-0000-0000-000000000001', 'VEND-LUMIERE-HQ', 'in_transit', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', NULL, NOW() - INTERVAL '2 days', NOW() - INTERVAL '1 day', NULL, NULL, 5, NULL, 'Overstock return for previous season items.', '[OVERSTOCK]'),
('30000000-0000-0000-0000-000000000069', 'vendor_return', '00000000-0000-0000-0000-000000000001', 'VEND-EXT-042', 'completed', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', NOW() - INTERVAL '14 days', NOW() - INTERVAL '12 days', NOW() - INTERVAL '10 days', NULL, 2, 2, 'Defective smart watch mechanisms.', '[DEFECTIVE]')
ON CONFLICT (id) DO NOTHING;

-- ==========================================
-- 6. MOVEMENT ITEMS
-- ==========================================
INSERT INTO movement_items (id, movement_id, product_id, quantity, reason) VALUES
('30000000-0000-0000-0000-000000000045', '30000000-0000-0000-0000-000000000040', '30000000-0000-0000-0000-000000000001', 1, NULL),
('30000000-0000-0000-0000-000000000046', '30000000-0000-0000-0000-000000000040', '30000000-0000-0000-0000-000000000002', 1, 'VIP reservation'),
('30000000-0000-0000-0000-000000000047', '30000000-0000-0000-0000-000000000040', '30000000-0000-0000-0000-000000000003', 1, NULL),
('30000000-0000-0000-0000-000000000048', '30000000-0000-0000-0000-000000000060', '30000000-0000-0000-0000-000000000005', 1, 'Defective clasp'),
('30000000-0000-0000-0000-000000000049', '30000000-0000-0000-0000-000000000063', '30000000-0000-0000-0000-000000000001', 5, NULL),
('30000000-0000-0000-0000-00000000004A', '30000000-0000-0000-0000-000000000063', '30000000-0000-0000-0000-00000000000C', 3, NULL),
('30000000-0000-0000-0000-00000000004B', '30000000-0000-0000-0000-000000000064', '30000000-0000-0000-0000-000000000002', 6, NULL),
('30000000-0000-0000-0000-00000000004C', '30000000-0000-0000-0000-000000000064', '30000000-0000-0000-0000-000000000003', 6, NULL),
('30000000-0000-0000-0000-00000000004E', '30000000-0000-0000-0000-000000000065', '30000000-0000-0000-0000-000000000005', 20, NULL),
('30000000-0000-0000-0000-00000000004F', '30000000-0000-0000-0000-000000000065', '30000000-0000-0000-0000-000000000006', 20, NULL),
-- Movement items for ASN-2026-05-987654 (DC replenishment to Paris, 15 items expected)
('30000000-0000-0000-0000-000000000051', '30000000-0000-0000-0000-000000000050', '30000000-0000-0000-0000-000000000009', 8, 'Nuit Royale EDP restock'),
('30000000-0000-0000-0000-000000000052', '30000000-0000-0000-0000-000000000050', '30000000-0000-0000-0000-000000000006', 4, 'Crocodile wallet restock'),
('30000000-0000-0000-0000-000000000053', '30000000-0000-0000-0000-000000000050', '30000000-0000-0000-0000-00000000000B', 3, 'Belt restock'),
-- Movement items for completed DC replenishments
('30000000-0000-0000-0000-000000000054', '30000000-0000-0000-0000-000000000066', '30000000-0000-0000-0000-000000000007', 10, 'Sunglasses seasonal push'),
('30000000-0000-0000-0000-000000000055', '30000000-0000-0000-0000-000000000066', '30000000-0000-0000-0000-000000000008', 8, 'Scarf restock'),
('30000000-0000-0000-0000-000000000056', '30000000-0000-0000-0000-000000000066', '30000000-0000-0000-0000-00000000000A', 2, 'Diamond earrings replenishment'),
('30000000-0000-0000-0000-000000000057', '30000000-0000-0000-0000-000000000067', '30000000-0000-0000-0000-000000000004', 6, NULL),
('30000000-0000-0000-0000-000000000058', '30000000-0000-0000-0000-000000000067', '30000000-0000-0000-0000-000000000005', 4, NULL),
-- Vendor Return items
('30000000-0000-0000-0000-000000000059', '30000000-0000-0000-0000-000000000068', '30000000-0000-0000-0000-000000000004', 3, 'Overstock'),
('30000000-0000-0000-0000-00000000005A', '30000000-0000-0000-0000-000000000068', '30000000-0000-0000-0000-00000000000B', 2, 'Overstock'),
('30000000-0000-0000-0000-00000000005B', '30000000-0000-0000-0000-000000000069', '30000000-0000-0000-0000-00000000000C', 2, 'Defective')
ON CONFLICT (id) DO NOTHING;

-- ==========================================
-- 7. CYCLE COUNTS
-- ==========================================
INSERT INTO cycle_counts (id, store_id, scheduled_date, status, conducted_by, completed_at, notes, created_at) VALUES
('30000000-0000-0000-0000-000000000070', '00000000-0000-0000-0000-000000000001', NOW() + INTERVAL '2 days', 'scheduled', NULL, NULL, 'Monthly full-floor cycle count — all categories.', NOW() - INTERVAL '3 days'),
('30000000-0000-0000-0000-000000000071', '00000000-0000-0000-0000-000000000001', NOW(), 'in_progress', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', NULL, 'High-value vault audit in progress.', NOW() - INTERVAL '1 day'),
('30000000-0000-0000-0000-000000000072', '00000000-0000-0000-0000-000000000001', NOW() - INTERVAL '7 days', 'completed', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', NOW() - INTERVAL '7 days', 'Weekly spot-check completed. 2 variances reported.', NOW() - INTERVAL '14 days'),
('30000000-0000-0000-0000-000000000073', '00000000-0000-0000-0000-000000000001', NOW() - INTERVAL '3 days', 'cancelled', NULL, NULL, 'Cancelled due to store renovation.', NOW() - INTERVAL '10 days')
ON CONFLICT (id) DO NOTHING;

-- ==========================================
-- 8. AUDIT TRAILS
-- ==========================================
INSERT INTO audit_trails (id, store_id, action, entity_type, entity_id, performed_by, timestamp, details) VALUES
('30000000-0000-0000-0000-000000000080', '00000000-0000-0000-0000-000000000001', 'Stock Adjusted', 'StockItem', '30000000-0000-0000-0000-000000000010', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', NOW() - INTERVAL '5 minutes', 'Chronograph Royale qty adjusted +1, found during recount.'),
('00000000-0000-0000-0000-000000000171', '00000000-0000-0000-0000-000000000001', 'RFID Scan Complete', 'RFIDScanRecord', '30000000-0000-0000-0000-000000000020', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', NOW() - INTERVAL '15 minutes', '450 items scanned, 2 exceptions found in Display Case C.'),
('00000000-0000-0000-0000-000000000173', '00000000-0000-0000-0000-000000000001', 'Low Stock Alert', 'StockItem', '30000000-0000-0000-0000-000000000011', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', NOW() - INTERVAL '30 minutes', 'Eternity Diamond Ring — only 1 unit remaining at Paris Vendôme.'),
('30000000-0000-0000-0000-000000000081', '00000000-0000-0000-0000-000000000001', 'Stock In — Barcode Scan', 'Product', '30000000-0000-0000-0000-000000000009', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', NOW() - INTERVAL '45 minutes', 'SKU: FR-EDP-NTR-75 · Nuit Royale Eau de Parfum'),
('30000000-0000-0000-0000-000000000082', '00000000-0000-0000-0000-000000000001', 'Transfer Shipped', 'InventoryMovement', '30000000-0000-0000-0000-000000000040', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', NOW() - INTERVAL '1 day', '3 items shipped to Mumbai store via secure courier.'),
('30000000-0000-0000-0000-000000000083', '00000000-0000-0000-0000-000000000001', 'Variance Reported', 'InventoryVariance', '30000000-0000-0000-0000-000000000031', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', NOW() - INTERVAL '1 hour', 'Crocodile Card Wallet: expected 10, found 8. Investigation initiated.'),
('30000000-0000-0000-0000-000000000084', '00000000-0000-0000-0000-000000000001', 'Cycle Count Started', 'CycleCount', '30000000-0000-0000-0000-000000000071', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', NOW() - INTERVAL '75 minutes', 'High-value vault audit initiated per monthly schedule.'),
('30000000-0000-0000-0000-000000000085', '00000000-0000-0000-0000-000000000001', 'Verification — Barcode Scan', 'Product', '30000000-0000-0000-0000-000000000001', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', NOW() - INTERVAL '90 minutes', 'SKU: WA-CHR-RG-42 · Chronograph Royale - 42mm — verified in Display Case A.'),
('30000000-0000-0000-0000-000000000086', '00000000-0000-0000-0000-000000000001', 'Replenishment Received', 'InventoryMovement', '30000000-0000-0000-0000-000000000062', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', NOW() - INTERVAL '2 days', '17 of 20 items received from DC-ASIA-01. 3 items back-ordered.'),
('30000000-0000-0000-0000-000000000087', '00000000-0000-0000-0000-000000000001', 'Damage Reported', 'StockItem', '30000000-0000-0000-0000-00000000001D', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', NOW() - INTERVAL '12 hours', 'Cuir Classique Tote — clasp broken during display setup. Moved to Back Office.')
ON CONFLICT (id) DO NOTHING;

-- ==========================================
-- 9. SERIAL CAPTURES
-- ==========================================
INSERT INTO serial_captures (id, product_id, serial_number, captured_by, captured_at) VALUES
('30000000-0000-0000-0000-000000000090', '30000000-0000-0000-0000-000000000001', 'SN-CHR-2024-001', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', NOW() - INTERVAL '1 day'),
('30000000-0000-0000-0000-000000000091', '30000000-0000-0000-0000-000000000002', 'SN-RNG-2024-042', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', NOW() - INTERVAL '2 days'),
('30000000-0000-0000-0000-000000000092', '30000000-0000-0000-0000-000000000003', 'SN-NKL-2024-019', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', NOW() - INTERVAL '3 days'),
('30000000-0000-0000-0000-000000000093', '30000000-0000-0000-0000-00000000000C', 'SN-DIV-2024-007', 'ada6eb74-0b6d-43bb-8612-3f265960dae1', NOW() - INTERVAL '12 hours')
ON CONFLICT (id) DO NOTHING;

-- ==========================================
-- 10. AUTH CERTIFICATES
-- ==========================================
INSERT INTO auth_certificates (id, product_id, serial_number, certificate_url, issued_at, issued_by) VALUES
('30000000-0000-0000-0000-0000000000A0', '30000000-0000-0000-0000-000000000001', 'SN-CHR-2024-001', 'https://certs.maisonlumiere.com/SN-CHR-2024-001.pdf', NOW() - INTERVAL '1 day', 'ada6eb74-0b6d-43bb-8612-3f265960dae1'),
('30000000-0000-0000-0000-0000000000A1', '30000000-0000-0000-0000-000000000002', 'SN-RNG-2024-042', 'https://certs.maisonlumiere.com/SN-RNG-2024-042.pdf', NOW() - INTERVAL '2 days', 'ada6eb74-0b6d-43bb-8612-3f265960dae1'),
('30000000-0000-0000-0000-0000000000A2', '30000000-0000-0000-0000-000000000003', 'SN-NKL-2024-019', 'https://certs.maisonlumiere.com/SN-NKL-2024-019.pdf', NOW() - INTERVAL '3 days', 'ada6eb74-0b6d-43bb-8612-3f265960dae1')
ON CONFLICT (id) DO NOTHING;

-- ==========================================
-- 11. SHRINKAGE ANALYTICS
-- ==========================================
INSERT INTO shrinkage_analytics (id, store_id, period_start, period_end, total_loss_units, total_loss_value, currency, top_category, primary_cause) VALUES
('30000000-0000-0000-0000-0000000000B0', '00000000-0000-0000-0000-000000000001', NOW() - INTERVAL '90 days', NOW(), 5, 14750.00, 'EUR', 'Accessories', 'Theft'),
('30000000-0000-0000-0000-0000000000B1', '00000000-0000-0000-0000-000000000001', NOW() - INTERVAL '180 days', NOW() - INTERVAL '90 days', 3, 8200.00, 'EUR', 'Leather Goods', 'Administrative Error'),
('30000000-0000-0000-0000-0000000000B2', '00000000-0000-0000-0000-000000000002', NOW() - INTERVAL '90 days', NOW(), 2, 4100.00, 'EUR', 'Fragrances', 'Damage')
ON CONFLICT (id) DO NOTHING;

-- END OF MOCK DATA SEED
