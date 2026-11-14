SET NAMES utf8mb4;
SET time_zone = '+03:00';

CREATE TABLE IF NOT EXISTS users (
    id INT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    role VARCHAR(30) NOT NULL DEFAULT 'employee',
    name VARCHAR(190) NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS customers (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    name VARCHAR(255) NULL,
    vat VARCHAR(100) NULL,
    cr VARCHAR(100) NULL,
    mobile VARCHAR(100) NULL,
    email VARCHAR(255) NULL,
    address TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_customers_name (name),
    INDEX idx_customers_mobile (mobile)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS policies (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    customer_id BIGINT UNSIGNED NULL,
    policy_no VARCHAR(190) NULL,
    type VARCHAR(190) NULL,
    start_date DATE NULL,
    end_date DATE NULL,
    premium DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_policies_customer (customer_id),
    INDEX idx_policies_number (policy_no),
    CONSTRAINT fk_policies_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS invoices (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    invoice_no VARCHAR(190) NULL,
    policy_no VARCHAR(190) NULL,
    endorsement_no VARCHAR(190) NULL,
    customer_id BIGINT UNSIGNED NULL,
    invoice_date DATE NULL,
    description TEXT NULL,
    amount DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    vat_rate DECIMAL(7,2) NOT NULL DEFAULT 0.00,
    vat_amount DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    total DECIMAL(15,2) NOT NULL DEFAULT 0.00,
    mobile VARCHAR(100) NULL,
    email VARCHAR(255) NULL,
    address TEXT NULL,
    created_by INT UNSIGNED NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    INDEX idx_invoices_customer (customer_id),
    INDEX idx_invoices_number (invoice_no),
    INDEX idx_invoices_policy (policy_no),
    INDEX idx_invoices_date (invoice_date),
    CONSTRAINT fk_invoices_customer FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL ON UPDATE CASCADE,
    CONSTRAINT fk_invoices_user FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS company_settings (
    id TINYINT UNSIGNED PRIMARY KEY,
    name_ar VARCHAR(255) NULL,
    name_en VARCHAR(255) NULL,
    vat VARCHAR(100) NULL,
    cr VARCHAR(100) NULL,
    address TEXT NULL,
    phone VARCHAR(100) NULL,
    email VARCHAR(255) NULL,
    website VARCHAR(255) NULL,
    vat_rate DECIMAL(7,2) NOT NULL DEFAULT 0.00,
    footer_text TEXT NULL,
    logo LONGTEXT NULL,
    stamp LONGTEXT NULL,
    logo_size INT NULL DEFAULT 80,
    logo_enabled TINYINT(1) NOT NULL DEFAULT 1,
    stamp_size INT NULL DEFAULT 100,
    stamp_x DECIMAL(7,2) NULL DEFAULT 70,
    stamp_y DECIMAL(7,2) NULL DEFAULT 60,
    stamp_enabled TINYINT(1) NOT NULL DEFAULT 1,
    updated_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

CREATE TABLE IF NOT EXISTS audit_logs (
    id BIGINT UNSIGNED AUTO_INCREMENT PRIMARY KEY,
    user_id INT UNSIGNED NULL,
    user_name VARCHAR(190) NULL,
    action VARCHAR(190) NULL,
    detail TEXT NULL,
    created_at TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_audit_created (created_at),
    CONSTRAINT fk_audit_user FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;

INSERT IGNORE INTO users (id, username, password_hash, role, name) VALUES
(1, 'admin', '$2y$12$Q/SZB6WJEy5Sp2phpAeaXeR41DiTAV9xxpbOzfLIfHpt3wWdFU0ga', 'admin', 'محمد العمري'),
(2, 'emp', '$2y$12$r7ppDmukmKZimug5tg6iReW8MkPH6ub/yJX4BFyyOWQVOF0/irNPu', 'employee', 'سارة الزهراني');

INSERT IGNORE INTO company_settings (
    id, name_ar, name_en, vat, cr, address, phone, email, website, vat_rate,
    footer_text, logo_size, logo_enabled, stamp_size, stamp_x, stamp_y, stamp_enabled
) VALUES (
    1,
    'شركة الحماية للتأمين الطبي',
    'Al Himaya Medical Insurance Co.',
    '310000000000003',
    '1010000001',
    'الرياض - طريق الملك فهد - برج المملكة، الدور 15',
    '920001234',
    'info@alhimaya.com.sa',
    'www.alhimaya.com.sa',
    15.00,
    'شكراً لثقتكم بنا - هذه فاتورة ضريبية معتمدة وفق متطلبات هيئة الزكاة والضريبة والجمارك',
    80, 1, 100, 70, 60, 1
);

INSERT IGNORE INTO customers (id, name, vat, cr, mobile, email, address) VALUES
(1, 'شركة الأفق للمقاولات', '310111222333', '1010234567', '0501234567', 'info@ufuq.com.sa', 'الرياض - حي العليا'),
(2, 'مستشفى النور الطبي', '310444555666', '1010987654', '0509876543', 'billing@alnoor-hosp.com.sa', 'جدة - الحمراء'),
(3, 'مجموعة الخليج للتجارة', '310777888999', '2050111222', '0555551111', 'accounts@gulf-group.sa', 'الدمام - العزيزية');

INSERT IGNORE INTO policies (id, customer_id, policy_no, type, start_date, end_date, premium) VALUES
(1, 1, 'POL-2025-001', 'تأمين طبي جماعي', '2025-01-01', '2025-12-31', 85000.00),
(2, 2, 'POL-2025-002', 'تأمين طبي مميز', '2025-03-01', '2026-02-28', 120000.00),
(3, 3, 'POL-2025-003', 'تأمين طبي شامل', '2025-06-01', '2026-05-31', 200000.00);

INSERT IGNORE INTO invoices (
    id, invoice_no, policy_no, endorsement_no, customer_id, invoice_date,
    description, amount, vat_rate, vat_amount, total, mobile, email, address,
    created_by, created_at
) VALUES
(1, 'INV-2025-0001', 'POL-2025-001', 'END-001', 1, '2025-01-15', 'قسط التأمين الطبي - الربع الأول', 21250.00, 15.00, 3187.50, 24437.50, '0501234567', 'info@ufuq.com.sa', 'الرياض - حي العليا', 1, '2025-01-15 10:30:00'),
(2, 'INV-2025-0002', 'POL-2025-002', 'END-002', 2, '2025-03-01', 'قسط التأمين الطبي المميز - سنوي', 120000.00, 15.00, 18000.00, 138000.00, '0509876543', 'billing@alnoor-hosp.com.sa', 'جدة - الحمراء', 1, '2025-03-01 09:00:00'),
(3, 'INV-2025-0003', 'POL-2025-003', 'END-003', 3, '2025-06-01', 'قسط التأمين الطبي الشامل - نصف سنوي', 100000.00, 15.00, 15000.00, 115000.00, '0555551111', 'accounts@gulf-group.sa', 'الدمام - العزيزية', 2, '2025-06-01 11:15:00');
