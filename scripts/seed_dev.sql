-- =============================================================================
-- Lokalaku Development & CI Database Seed Script
-- Idempotent: safe to run repeatedly (uses ON CONFLICT DO NOTHING)
-- Default password for all seeded accounts: Password123!
-- =============================================================================

-- 1. Village Clusters
INSERT INTO village_clusters (id, name, code, status, created_at, updated_at)
VALUES
    ('00000000-0000-0000-0000-000000000001', 'Desa Sukamaju', 'sukamaju-001', 'active', NOW(), NOW()),
    ('00000000-0000-0000-0000-000000000002', 'Desa Harapan Jaya', 'harapan-002', 'active', NOW(), NOW())
ON CONFLICT (code) DO NOTHING;

-- 2. Accounts
-- Note: bcrypt hash for 'Password123!' is $2a$10$FYhT0Gn5EH2jXX9jgDKOw.tekarvrkZHcluni6ukB00FfwxhnLddS
INSERT INTO accounts (id, village_cluster_id, phone, email, password_hash, role, status, created_at, updated_at)
VALUES
    -- Superadmin (Cluster Independent)
    (
        '10000000-0000-0000-0000-000000000001',
        NULL,
        '+6281111111111',
        'admin@lokalaku.id',
        '$2a$10$FYhT0Gn5EH2jXX9jgDKOw.tekarvrkZHcluni6ukB00FfwxhnLddS',
        'superadmin',
        'active',
        NOW(),
        NOW()
    ),
    -- Backoffice Admin (Bound to Desa Sukamaju)
    (
        '10000000-0000-0000-0000-000000000002',
        '00000000-0000-0000-0000-000000000001',
        '+6281666666666',
        'admin.sukamaju@lokalaku.id',
        '$2a$10$FYhT0Gn5EH2jXX9jgDKOw.tekarvrkZHcluni6ukB00FfwxhnLddS',
        'backoffice_admin',
        'active',
        NOW(),
        NOW()
    ),
    -- Merchant (Warung Budi - Bound to Desa Sukamaju)
    (
        '10000000-0000-0000-0000-000000000003',
        '00000000-0000-0000-0000-000000000001',
        '+6281222222222',
        'warung.budi@lokalaku.id',
        '$2a$10$FYhT0Gn5EH2jXX9jgDKOw.tekarvrkZHcluni6ukB00FfwxhnLddS',
        'merchant',
        'active',
        NOW(),
        NOW()
    ),
    -- Wholesaler (Grosir Jaya - Cluster Independent)
    (
        '10000000-0000-0000-0000-000000000004',
        NULL,
        '+6281333333333',
        'grosir.jaya@lokalaku.id',
        '$2a$10$FYhT0Gn5EH2jXX9jgDKOw.tekarvrkZHcluni6ukB00FfwxhnLddS',
        'wholesaler',
        'active',
        NOW(),
        NOW()
    ),
    -- Courier (Kurir Agus - Cluster Independent)
    (
        '10000000-0000-0000-0000-000000000005',
        NULL,
        '+6281444444444',
        'kurir.agus@lokalaku.id',
        '$2a$10$FYhT0Gn5EH2jXX9jgDKOw.tekarvrkZHcluni6ukB00FfwxhnLddS',
        'courier',
        'active',
        NOW(),
        NOW()
    ),
    -- Consumer (Warga Siti - Cluster Independent)
    (
        '10000000-0000-0000-0000-000000000006',
        NULL,
        '+6281555555555',
        'warga.siti@lokalaku.id',
        '$2a$10$FYhT0Gn5EH2jXX9jgDKOw.tekarvrkZHcluni6ukB00FfwxhnLddS',
        'consumer',
        'active',
        NOW(),
        NOW()
    )
ON CONFLICT (phone) DO NOTHING;
