<?php
/**
 * نظام إدارة الفواتير - الباك إند الكامل والموحد (SQLite Edition)
 * ملف مستقل بذاته (Standalone) يعمل بقاعدة بيانات SQLite المحلية
 * لا يحتاج إلى MySQL، ولا إعدادات مستخدم أو كلمة مرور!
 * ينشئ قاعدة البيانات والجداول تلقائياً في نفس المجلد باسم: invoice_database.sqlite
 */

// ==========================================
// 1. إعدادات CORS والهيدرز والجلسة (CORS & Headers)
// ==========================================
if (isset($_SERVER['HTTP_ORIGIN'])) {
    header("Access-Control-Allow-Origin: {$_SERVER['HTTP_ORIGIN']}");
    header('Access-Control-Allow-Credentials: true');
} else {
    header('Access-Control-Allow-Origin: *');
}
header('Access-Control-Allow-Methods: GET, POST, OPTIONS');
header('Access-Control-Allow-Headers: Content-Type, Authorization, X-Requested-With, X-CSRF-Token, X-User-Id, Cookie, Accept, Cache-Control');
header('Access-Control-Max-Age: 86400');
header('Content-Type: application/json; charset=utf-8');
header('Cache-Control: no-store, no-cache, must-revalidate, max-age=0');

// الرد الفوري لطلبات Pre-flight OPTIONS
if (isset($_SERVER['REQUEST_METHOD']) && strtoupper($_SERVER['REQUEST_METHOD']) === 'OPTIONS') {
    http_response_code(200);
    exit;
}

// إعدادات الكوكيز والجلسة
$secureCookie = !empty($_SERVER['HTTPS']) && $_SERVER['HTTPS'] !== 'off';
ini_set('session.use_strict_mode', '1');
session_set_cookie_params(array(
    'lifetime' => 0,
    'path'     => '/',
    'secure'   => $secureCookie,
    'httponly' => true,
    'samesite' => 'Lax',
));
if (session_status() === PHP_SESSION_NONE) {
    session_start();
}

// ==========================================
// 2. إعدادات مسار قاعدة بيانات SQLite
// ==========================================
defined('DB_SQLITE_FILE') or define('DB_SQLITE_FILE', __DIR__ . '/invoice_database.sqlite');
defined('APP_DEBUG') or define('APP_DEBUG', true);

// ==========================================
// 3. الاتصال بقاعدة البيانات والتثبيت التلقائي
// ==========================================
function db()
{
    static $pdo = null;

    if ($pdo instanceof PDO) {
        return $pdo;
    }

    $dsn = 'sqlite:' . DB_SQLITE_FILE;

    $pdo = new PDO($dsn, null, null, array(
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ));

    $pdo->exec('PRAGMA journal_mode = WAL;');
    $pdo->exec('PRAGMA foreign_keys = ON;');

    // تسجيل دالة DATE_FORMAT للتوافق التام
    $pdo->sqliteCreateFunction('DATE_FORMAT', function ($date, $format = null) {
        if (!$date) return null;
        if (strpos($date, 'T') !== false) {
            $parts = explode('T', $date);
            return $parts[0];
        }
        $parts = explode(' ', $date);
        return $parts[0];
    }, 2);

    $pdo->sqliteCreateFunction('NOW', function () {
        return date('Y-m-d H:i:s');
    }, 0);

    // فحص وإنشاء الجداول تلقائياً إن لم تكن موجودة
    auto_install_sqlite_tables_if_needed($pdo);

    // حماية ملف قاعدة البيانات من التحميل المباشر
    protect_sqlite_file();

    return $pdo;
}

/**
 * إنشاء ملف .htaccess لحماية ملف قاعدة البيانات من التحميل المباشر
 */
function protect_sqlite_file()
{
    static $protected = false;
    if ($protected) return;
    $protected = true;

    $htaccess = __DIR__ . '/.htaccess';
    if (!file_exists($htaccess)) {
        @file_put_contents($htaccess, "<Files ~ \"\\.sqlite$\">\nOrder allow,deny\nDeny from all\n</Files>\n");
    }
}

/**
 * إنشاء جداول SQLite تلقائياً وتعبئة البيانات الافتراضية
 */
function auto_install_sqlite_tables_if_needed($pdo)
{
    static $checked = false;
    if ($checked) return;
    $checked = true;

    try {
        $check = $pdo->query("SELECT name FROM sqlite_master WHERE type='table' AND name='users'")->fetch();
        if ($check) {
            return; // الجداول مثبتة بالفعل
        }

        // 1. جدول المستخدمين
        $pdo->exec("CREATE TABLE IF NOT EXISTS users (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            username TEXT NOT NULL UNIQUE,
            password_hash TEXT NOT NULL,
            role TEXT NOT NULL DEFAULT 'employee',
            name TEXT NULL,
            created_at TEXT DEFAULT (datetime('now','localtime')),
            updated_at TEXT DEFAULT (datetime('now','localtime'))
        );");

        // 2. جدول العملاء
        $pdo->exec("CREATE TABLE IF NOT EXISTS customers (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT NULL,
            vat TEXT NULL,
            cr TEXT NULL,
            mobile TEXT NULL,
            email TEXT NULL,
            address TEXT NULL,
            created_at TEXT DEFAULT (datetime('now','localtime')),
            updated_at TEXT DEFAULT (datetime('now','localtime'))
        );");

        // 3. جدول وثائق التأمين
        $pdo->exec("CREATE TABLE IF NOT EXISTS policies (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            customer_id INTEGER NULL,
            policy_no TEXT NULL,
            type TEXT NULL,
            start_date TEXT NULL,
            end_date TEXT NULL,
            premium REAL NOT NULL DEFAULT 0.00,
            created_at TEXT DEFAULT (datetime('now','localtime')),
            updated_at TEXT DEFAULT (datetime('now','localtime')),
            FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL ON UPDATE CASCADE
        );");

        // 4. جدول الفواتير
        $pdo->exec("CREATE TABLE IF NOT EXISTS invoices (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            invoice_no TEXT NULL,
            policy_no TEXT NULL,
            endorsement_no TEXT NULL,
            customer_id INTEGER NULL,
            invoice_date TEXT NULL,
            description TEXT NULL,
            amount REAL NOT NULL DEFAULT 0.00,
            vat_rate REAL NOT NULL DEFAULT 0.00,
            vat_amount REAL NOT NULL DEFAULT 0.00,
            total REAL NOT NULL DEFAULT 0.00,
            mobile TEXT NULL,
            email TEXT NULL,
            address TEXT NULL,
            created_by INTEGER NULL,
            created_at TEXT DEFAULT (datetime('now','localtime')),
            updated_at TEXT DEFAULT (datetime('now','localtime')),
            FOREIGN KEY (customer_id) REFERENCES customers(id) ON DELETE SET NULL ON UPDATE CASCADE,
            FOREIGN KEY (created_by) REFERENCES users(id) ON DELETE SET NULL ON UPDATE CASCADE
        );");

        // 5. جدول إعدادات الشركة
        $pdo->exec("CREATE TABLE IF NOT EXISTS company_settings (
            id INTEGER PRIMARY KEY,
            name_ar TEXT NULL,
            name_en TEXT NULL,
            vat TEXT NULL,
            cr TEXT NULL,
            address TEXT NULL,
            phone TEXT NULL,
            email TEXT NULL,
            website TEXT NULL,
            vat_rate REAL NOT NULL DEFAULT 0.00,
            footer_text TEXT NULL,
            logo TEXT NULL,
            stamp TEXT NULL,
            logo_size INTEGER NULL DEFAULT 80,
            logo_enabled INTEGER NOT NULL DEFAULT 1,
            stamp_size INTEGER NULL DEFAULT 100,
            stamp_x REAL NULL DEFAULT 70,
            stamp_y REAL NULL DEFAULT 60,
            stamp_enabled INTEGER NOT NULL DEFAULT 1,
            updated_at TEXT DEFAULT (datetime('now','localtime'))
        );");

        // 6. جدول سجل التدقيق
        $pdo->exec("CREATE TABLE IF NOT EXISTS audit_logs (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            user_id INTEGER NULL,
            user_name TEXT NULL,
            action TEXT NULL,
            detail TEXT NULL,
            created_at TEXT DEFAULT (datetime('now','localtime'))
        );");

        // إضافة المستخدمين الافتراضيين (admin / admin123 و emp / emp123)
        $pdo->exec("INSERT OR IGNORE INTO users (id, username, password_hash, role, name) VALUES
        (1, 'admin', '$2y$12\$Q/SZB6WJEy5Sp2phpAeaXeR41DiTAV9xxpbOzfLIfHpt3wWdFU0ga', 'admin', 'مدير النظام'),
        (2, 'emp', '$2y$12\$r7ppDmukmKZimug5tg6iReW8MkPH6ub/yJX4BFyyOWQVOF0/irNPu', 'employee', 'موظف النظام');");

        // إعدادات الشركة الافتراضية
        $pdo->exec("INSERT OR IGNORE INTO company_settings (
            id, name_ar, name_en, vat, cr, address, phone, email, website, vat_rate,
            footer_text, logo_size, logo_enabled, stamp_size, stamp_x, stamp_y, stamp_enabled
        ) VALUES (
            1,
            'شركة التأمين الطبي والفواتير',
            'Medical Invoicing Co.',
            '310000000000003',
            '1010000001',
            'المملكة العربية السعودية',
            '920001234',
            'info@example.com',
            'www.example.com',
            15.00,
            'شكراً لتعاملكم معنا - فاتورة ضريبية إلكترونية معتمدة',
            80, 1, 100, 70, 60, 1
        );");
    } catch (Throwable $t) {}
}

// ==========================================
// 4. الدوال المساعدة (Helper Functions)
// ==========================================
function respond($data, $status = 200)
{
    http_response_code($status);
    echo json_encode($data, JSON_UNESCAPED_UNICODE | JSON_UNESCAPED_SLASHES);
    exit;
}

function fail_response($message, $status = 400)
{
    respond(array('ok' => false, 'message' => $message), $status);
}

function request_data()
{
    $raw = file_get_contents('php://input');
    if ($raw === false || trim($raw) === '') {
        return $_POST;
    }

    $decoded = json_decode($raw, true);
    if (!is_array($decoded)) {
        fail_response('صيغة البيانات المرسلة غير صحيحة.', 400);
    }
    return $decoded;
}

function csrf_token()
{
    if (empty($_SESSION['csrf_token'])) {
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
    }
    return $_SESSION['csrf_token'];
}

function current_user()
{
    return isset($_SESSION['user']) && is_array($_SESSION['user']) ? $_SESSION['user'] : null;
}

function require_login()
{
    $user = current_user();
    if (!$user) {
        fail_response('انتهت جلسة الدخول. يرجى تسجيل الدخول مرة أخرى.', 401);
    }
    return $user;
}

function require_admin()
{
    $user = require_login();
    if (($user['role'] ?? '') !== 'admin') {
        fail_response('ليس لديك صلاحية لتنفيذ هذا الإجراء.', 403);
    }
    return $user;
}

function verify_csrf()
{
    $token = isset($_SERVER['HTTP_X_CSRF_TOKEN']) ? (string) $_SERVER['HTTP_X_CSRF_TOKEN'] : '';
    if (!empty($_SESSION['csrf_token']) && !empty($token)) {
        if (!hash_equals($_SESSION['csrf_token'], $token)) {
            fail_response('رمز الحماية غير صحيح. أعد تحميل الصفحة وحاول مرة أخرى.', 419);
        }
    }
}

function optional_text($value)
{
    if ($value === null) return null;
    $text = trim((string) $value);
    return $text === '' ? null : $text;
}

function optional_id($value)
{
    if ($value === null || $value === '') return null;
    $number = filter_var($value, FILTER_VALIDATE_INT);
    return ($number !== false && $number > 0) ? (int) $number : null;
}

function numeric_value($value, $fallback = 0.0)
{
    return is_numeric($value) ? (float) $value : (float) $fallback;
}

function optional_date($value)
{
    $text = optional_text($value);
    if ($text === null) return null;
    $date = DateTime::createFromFormat('Y-m-d', $text);
    return ($date && $date->format('Y-m-d') === $text) ? $text : null;
}

function bool_value($value)
{
    return filter_var($value, FILTER_VALIDATE_BOOLEAN) ? 1 : 0;
}

function audit_log($action, $detail)
{
    try {
        $user = current_user();
        $stmt = db()->prepare('INSERT INTO audit_logs (user_id, user_name, action, detail, created_at) VALUES (?, ?, ?, ?, ?)');
        $stmt->execute(array(
            $user['id'] ?? null,
            $user['name'] ?? $user['username'] ?? 'مستخدم',
            optional_text($action),
            optional_text($detail),
            date('Y-m-d H:i:s'),
        ));
    } catch (Throwable $e) {}
}

function fetch_customer($id)
{
    $stmt = db()->prepare('SELECT id, name, vat, cr, mobile, email, address FROM customers WHERE id = ? LIMIT 1');
    $stmt->execute(array($id));
    return $stmt->fetch();
}

function fetch_policy($id)
{
    $stmt = db()->prepare("SELECT id, customer_id AS customerId, policy_no AS policyNo, type,
        start_date AS startDate, end_date AS endDate, premium
        FROM policies WHERE id = ? LIMIT 1");
    $stmt->execute(array($id));
    $row = $stmt->fetch();
    if ($row) {
        $row['id'] = (int) $row['id'];
        $row['customerId'] = $row['customerId'] === null ? null : (int) $row['customerId'];
        $row['premium'] = (float) $row['premium'];
    }
    return $row;
}

function fetch_invoice($id)
{
    $stmt = db()->prepare("SELECT i.id, i.invoice_no AS invoiceNo, i.policy_no AS policyNo,
        i.endorsement_no AS endorsementNo, i.customer_id AS customerId,
        i.invoice_date AS date, i.description,
        i.amount, i.vat_rate AS vatRate, i.vat_amount AS vatAmount, i.total,
        i.mobile, i.email, i.address, COALESCE(u.username, '') AS createdBy,
        i.created_at AS createdAt
        FROM invoices i LEFT JOIN users u ON u.id = i.created_by
        WHERE i.id = ? LIMIT 1");
    $stmt->execute(array($id));
    $row = $stmt->fetch();
    if ($row) {
        $row['id'] = (int) $row['id'];
        $row['customerId'] = $row['customerId'] === null ? null : (int) $row['customerId'];
        $row['amount'] = (float) $row['amount'];
        $row['vatRate'] = (float) $row['vatRate'];
        $row['vatAmount'] = (float) $row['vatAmount'];
        $row['total'] = (float) $row['total'];
    }
    return $row;
}

function fetch_company()
{
    $row = db()->query("SELECT name_ar AS nameAr, name_en AS nameEn, vat, cr, address, phone, email,
        website, vat_rate AS vatRate, footer_text AS footerText, logo, stamp,
        logo_size AS logoSize, logo_enabled AS logoEnabled,
        stamp_size AS stampSize, stamp_x AS stampX, stamp_y AS stampY,
        stamp_enabled AS stampEnabled
        FROM company_settings WHERE id = 1 LIMIT 1")->fetch();

    if (!$row) return null;
    $row['vatRate'] = (float) $row['vatRate'];
    $row['logoSize'] = (int) $row['logoSize'];
    $row['logoEnabled'] = (bool) $row['logoEnabled'];
    $row['stampSize'] = (int) $row['stampSize'];
    $row['stampX'] = (float) $row['stampX'];
    $row['stampY'] = (float) $row['stampY'];
    $row['stampEnabled'] = (bool) $row['stampEnabled'];
    return $row;
}

function fetch_audits()
{
    $rows = db()->query("SELECT id, user_name AS user, action, detail,
        created_at AS at
        FROM audit_logs ORDER BY id DESC LIMIT 500")->fetchAll();
    foreach ($rows as &$row) {
        $row['id'] = (int) $row['id'];
    }
    unset($row);
    return $rows;
}

// ==========================================
// 5. توجيه الطلبات والمسارات (API Routes)
// ==========================================
$action = isset($_GET['action']) ? (string) $_GET['action'] : 'session';
$method = isset($_SERVER['REQUEST_METHOD']) ? strtoupper($_SERVER['REQUEST_METHOD']) : 'GET';

try {
    // 1. فحص الجلسة (Session)
    if ($action === 'session') {
        $user = current_user();
        respond(array(
            'ok'            => true,
            'authenticated' => (bool) $user,
            'user'          => $user,
            'csrfToken'     => csrf_token(),
            'database'      => 'SQLite',
        ));
    }

    // 2. تسجيل الدخول (Login)
    if ($action === 'login') {
        if ($method !== 'POST') fail_response('الطريقة غير مسموحة.', 405);
        $data = request_data();
        $username = trim((string) ($data['username'] ?? ''));
        $password = (string) ($data['password'] ?? '');

        $stmt = db()->prepare('SELECT id, username, password_hash, role, name FROM users WHERE username = ? LIMIT 1');
        $stmt->execute(array($username));
        $row = $stmt->fetch();

        if (!$row || !password_verify($password, $row['password_hash'])) {
            fail_response('اسم المستخدم أو كلمة المرور غير صحيحة.', 401);
        }

        session_regenerate_id(true);
        $_SESSION['user'] = array(
            'id'       => (int) $row['id'],
            'username' => $row['username'],
            'role'     => $row['role'],
            'name'     => $row['name'],
        );
        $_SESSION['csrf_token'] = bin2hex(random_bytes(32));
        audit_log('تسجيل دخول', 'قام ' . ($row['name'] ?: $row['username']) . ' بتسجيل الدخول');

        respond(array('ok' => true, 'user' => $_SESSION['user'], 'csrfToken' => $_SESSION['csrf_token']));
    }

    // 3. تسجيل الخروج (Logout)
    if ($action === 'logout') {
        require_login();
        if ($method !== 'POST') fail_response('الطريقة غير مسموحة.', 405);
        verify_csrf();
        audit_log('تسجيل خروج', 'تم تسجيل الخروج من النظام');
        $_SESSION = array();
        if (ini_get('session.use_cookies')) {
            $params = session_get_cookie_params();
            setcookie(session_name(), '', time() - 42000, $params['path'], $params['domain'] ?? '', $params['secure'], $params['httponly']);
        }
        session_destroy();
        respond(array('ok' => true));
    }

    // يتطلب باقي الإجراءات تسجيل الدخول
    require_login();

    // 4. جلب كافة البيانات الأولية للنظام (Bootstrap)
    if ($action === 'bootstrap') {
        $customers = db()->query('SELECT id, name, vat, cr, mobile, email, address FROM customers ORDER BY id ASC')->fetchAll();
        foreach ($customers as &$customer) $customer['id'] = (int) $customer['id'];
        unset($customer);

        $policies = db()->query("SELECT id, customer_id AS customerId, policy_no AS policyNo, type,
            start_date AS startDate, end_date AS endDate, premium
            FROM policies ORDER BY id ASC")->fetchAll();
        foreach ($policies as &$policy) {
            $policy['id'] = (int) $policy['id'];
            $policy['customerId'] = $policy['customerId'] === null ? null : (int) $policy['customerId'];
            $policy['premium'] = (float) $policy['premium'];
        }
        unset($policy);

        $invoices = db()->query("SELECT i.id, i.invoice_no AS invoiceNo, i.policy_no AS policyNo,
            i.endorsement_no AS endorsementNo, i.customer_id AS customerId,
            i.invoice_date AS date, i.description,
            i.amount, i.vat_rate AS vatRate, i.vat_amount AS vatAmount, i.total,
            i.mobile, i.email, i.address, COALESCE(u.username, '') AS createdBy,
            i.created_at AS createdAt
            FROM invoices i LEFT JOIN users u ON u.id = i.created_by ORDER BY i.id ASC")->fetchAll();
        foreach ($invoices as &$invoice) {
            $invoice['id'] = (int) $invoice['id'];
            $invoice['customerId'] = $invoice['customerId'] === null ? null : (int) $invoice['customerId'];
            $invoice['amount'] = (float) $invoice['amount'];
            $invoice['vatRate'] = (float) $invoice['vatRate'];
            $invoice['vatAmount'] = (float) $invoice['vatAmount'];
            $invoice['total'] = (float) $invoice['total'];
        }
        unset($invoice);

        $user = current_user();
        respond(array(
            'ok'        => true,
            'customers' => $customers,
            'policies'  => $policies,
            'invoices'  => $invoices,
            'company'   => fetch_company(),
            'auditLog'  => ($user['role'] === 'admin') ? fetch_audits() : array(),
            'csrfToken' => csrf_token(),
        ));
    }

    if ($method !== 'POST') fail_response('الطريقة غير مسموحة.', 405);
    verify_csrf();
    $data = request_data();

    // 5. حفظ / تعديل عميل
    if ($action === 'customer_save') {
        $id = optional_id($data['id'] ?? null);
        $values = array(
            optional_text($data['name'] ?? null),
            optional_text($data['vat'] ?? null),
            optional_text($data['cr'] ?? null),
            optional_text($data['mobile'] ?? null),
            optional_text($data['email'] ?? null),
            optional_text($data['address'] ?? null),
        );

        if ($id) {
            $stmt = db()->prepare('UPDATE customers SET name=?, vat=?, cr=?, mobile=?, email=?, address=? WHERE id=?');
            $stmt->execute(array_merge($values, array($id)));
            if (!fetch_customer($id)) fail_response('العميل المطلوب تعديله غير موجود.', 404);
            audit_log('تعديل عميل', 'تم تعديل العميل ' . (($data['name'] ?? '') ?: 'بدون اسم'));
        } else {
            $stmt = db()->prepare('INSERT INTO customers (name, vat, cr, mobile, email, address) VALUES (?, ?, ?, ?, ?, ?)');
            $stmt->execute($values);
            $id = (int) db()->lastInsertId();
            audit_log('إضافة عميل', 'تمت إضافة العميل ' . (($data['name'] ?? '') ?: 'بدون اسم'));
        }
        respond(array('ok' => true, 'customer' => fetch_customer($id)));
    }

    // 6. حذف عميل
    if ($action === 'customer_delete') {
        $id = optional_id($data['id'] ?? null);
        if (!$id) fail_response('معرّف العميل غير صحيح.');
        $customer = fetch_customer($id);
        $stmt = db()->prepare('DELETE FROM customers WHERE id=?');
        $stmt->execute(array($id));
        audit_log('حذف عميل', 'تم حذف العميل ' . (($customer['name'] ?? '') ?: 'بدون اسم'));
        respond(array('ok' => true));
    }

    // 7. حفظ / تعديل وثيقة تأمين
    if ($action === 'policy_save') {
        $id = optional_id($data['id'] ?? null);
        $values = array(
            optional_id($data['customerId'] ?? null),
            optional_text($data['policyNo'] ?? null),
            optional_text($data['type'] ?? null),
            optional_date($data['startDate'] ?? null),
            optional_date($data['endDate'] ?? null),
            numeric_value($data['premium'] ?? 0),
        );
        if ($id) {
            $stmt = db()->prepare('UPDATE policies SET customer_id=?, policy_no=?, type=?, start_date=?, end_date=?, premium=? WHERE id=?');
            $stmt->execute(array_merge($values, array($id)));
            if (!fetch_policy($id)) fail_response('الوثيقة المطلوب تعديلها غير موجودة.', 404);
            audit_log('تعديل وثيقة', 'تم تعديل الوثيقة ' . (($data['policyNo'] ?? '') ?: 'بدون رقم'));
        } else {
            $stmt = db()->prepare('INSERT INTO policies (customer_id, policy_no, type, start_date, end_date, premium) VALUES (?, ?, ?, ?, ?, ?)');
            $stmt->execute($values);
            $id = (int) db()->lastInsertId();
            audit_log('إضافة وثيقة', 'تمت إضافة الوثيقة ' . (($data['policyNo'] ?? '') ?: 'بدون رقم'));
        }
        respond(array('ok' => true, 'policy' => fetch_policy($id)));
    }

    // 8. حذف وثيقة
    if ($action === 'policy_delete') {
        $id = optional_id($data['id'] ?? null);
        if (!$id) fail_response('معرّف الوثيقة غير صحيح.');
        $policy = fetch_policy($id);
        $stmt = db()->prepare('DELETE FROM policies WHERE id=?');
        $stmt->execute(array($id));
        audit_log('حذف وثيقة', 'تم حذف الوثيقة ' . (($policy['policyNo'] ?? '') ?: 'بدون رقم'));
        respond(array('ok' => true));
    }

    // 9. إنشاء وحفظ فاتورة
    if ($action === 'invoice_save') {
        $amount = numeric_value($data['amount'] ?? 0);
        $vatRate = numeric_value($data['vatRate'] ?? 0);
        $vatAmount = round($amount * $vatRate / 100, 2);
        $total = round($amount + $vatAmount, 2);
        $user = current_user();

        $stmt = db()->prepare('INSERT INTO invoices (
            invoice_no, policy_no, endorsement_no, customer_id, invoice_date, description,
            amount, vat_rate, vat_amount, total, mobile, email, address, created_by, created_at
        ) VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
        $stmt->execute(array(
            optional_text($data['invoiceNo'] ?? null),
            optional_text($data['policyNo'] ?? null),
            optional_text($data['endorsementNo'] ?? null),
            optional_id($data['customerId'] ?? null),
            optional_date($data['date'] ?? null),
            optional_text($data['description'] ?? null),
            $amount,
            $vatRate,
            $vatAmount,
            $total,
            optional_text($data['mobile'] ?? null),
            optional_text($data['email'] ?? null),
            optional_text($data['address'] ?? null),
            $user['id'],
            date('Y-m-d H:i:s'),
        ));
        $id = (int) db()->lastInsertId();
        audit_log('إنشاء فاتورة', 'تم إنشاء الفاتورة ' . (($data['invoiceNo'] ?? '') ?: 'بدون رقم'));
        respond(array('ok' => true, 'invoice' => fetch_invoice($id)));
    }

    // 10. حفظ إعدادات الشركة (SQLite INSERT OR REPLACE)
    if ($action === 'settings_save') {
        require_admin();
        $stmt = db()->prepare('INSERT OR REPLACE INTO company_settings (
            id, name_ar, name_en, vat, cr, address, phone, email, website, vat_rate,
            footer_text, logo, stamp, logo_size, logo_enabled, stamp_size, stamp_x, stamp_y, stamp_enabled
        ) VALUES (1, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)');
        $stmt->execute(array(
            optional_text($data['nameAr'] ?? null), optional_text($data['nameEn'] ?? null),
            optional_text($data['vat'] ?? null), optional_text($data['cr'] ?? null),
            optional_text($data['address'] ?? null), optional_text($data['phone'] ?? null),
            optional_text($data['email'] ?? null), optional_text($data['website'] ?? null),
            numeric_value($data['vatRate'] ?? 0), optional_text($data['footerText'] ?? null),
            optional_text($data['logo'] ?? null), optional_text($data['stamp'] ?? null),
            (int) numeric_value($data['logoSize'] ?? 80, 80), bool_value($data['logoEnabled'] ?? false),
            (int) numeric_value($data['stampSize'] ?? 100, 100), numeric_value($data['stampX'] ?? 70, 70),
            numeric_value($data['stampY'] ?? 60, 60), bool_value($data['stampEnabled'] ?? false),
        ));
        audit_log('تعديل الإعدادات', 'تم تحديث إعدادات الشركة');
        $savedCompany = fetch_company();
        if (!$savedCompany) fail_response('تعذر التحقق من حفظ إعدادات الشركة.', 500);
        respond(array('ok' => true, 'company' => $savedCompany));
    }

    // 11. سجل الأحداث والتدقيق (المدير فقط)
    if ($action === 'audit_list') {
        require_admin();
        respond(array('ok' => true, 'auditLog' => fetch_audits()));
    }

    // 12. تغيير كلمة المرور
    if ($action === 'change_password') {
        $user = current_user();
        $currentPassword = (string) ($data['currentPassword'] ?? '');
        $newPassword = (string) ($data['newPassword'] ?? '');
        $confirmPassword = (string) ($data['confirmPassword'] ?? '');

        if (strlen($newPassword) < 6) fail_response('كلمة المرور الجديدة يجب ألا تقل عن 6 أحرف.');
        if ($newPassword !== $confirmPassword) fail_response('تأكيد كلمة المرور غير مطابق.');

        $stmt = db()->prepare('SELECT password_hash FROM users WHERE id=? LIMIT 1');
        $stmt->execute(array($user['id']));
        $hash = $stmt->fetchColumn();
        if (!$hash || !password_verify($currentPassword, $hash)) {
            fail_response('كلمة المرور الحالية غير صحيحة.', 422);
        }

        $newHash = password_hash($newPassword, PASSWORD_DEFAULT);
        $stmt = db()->prepare('UPDATE users SET password_hash=? WHERE id=?');
        $stmt->execute(array($newHash, $user['id']));
        audit_log('تغيير كلمة المرور', 'تم تغيير كلمة مرور الحساب');
        respond(array('ok' => true));
    }

    fail_response('الإجراء المطلوب غير موجود.', 404);
} catch (PDOException $e) {
    $message = APP_DEBUG ? $e->getMessage() : 'حدث خطأ أثناء تنفيذ العملية في قاعدة البيانات SQLite.';
    fail_response($message, 500);
} catch (Throwable $e) {
    $message = APP_DEBUG ? $e->getMessage() : $e->getMessage();
    fail_response($message, 500);
}
