<?php
require_once __DIR__ . '/db.php';

$message = '';
$error = '';
$installed = false;

function table_exists($pdo, $table)
{
    $stmt = $pdo->prepare('SELECT COUNT(*) FROM information_schema.tables WHERE table_schema = ? AND table_name = ?');
    $stmt->execute(array(DB_NAME, $table));
    return (int) $stmt->fetchColumn() > 0;
}

function split_sql_statements($sql)
{
    $statements = array();
    $buffer = '';
    $quote = null;
    $escaped = false;
    $length = strlen($sql);

    for ($i = 0; $i < $length; $i++) {
        $char = $sql[$i];
        $next = $i + 1 < $length ? $sql[$i + 1] : '';

        if ($quote === null && $char === '-' && $next === '-') {
            while ($i < $length && $sql[$i] !== "\n") $i++;
            $buffer .= "\n";
            continue;
        }
        if ($quote === null && $char === '#') {
            while ($i < $length && $sql[$i] !== "\n") $i++;
            $buffer .= "\n";
            continue;
        }

        if ($escaped) {
            $buffer .= $char;
            $escaped = false;
            continue;
        }

        if ($char === '\\' && $quote !== null) {
            $buffer .= $char;
            $escaped = true;
            continue;
        }

        if (($char === "'" || $char === '"') && ($quote === null || $quote === $char)) {
            $quote = $quote === null ? $char : null;
            $buffer .= $char;
            continue;
        }

        if ($char === ';' && $quote === null) {
            $statement = trim($buffer);
            if ($statement !== '') $statements[] = $statement;
            $buffer = '';
            continue;
        }

        $buffer .= $char;
    }

    $last = trim($buffer);
    if ($last !== '') $statements[] = $last;
    return $statements;
}

try {
    $pdo = db();
    $requiredTables = array('users', 'customers', 'policies', 'invoices', 'company_settings', 'audit_logs');
    $missingTables = array();
    foreach ($requiredTables as $requiredTable) {
        if (!table_exists($pdo, $requiredTable)) $missingTables[] = $requiredTable;
    }
    $installed = count($missingTables) === 0;

    if ($_SERVER['REQUEST_METHOD'] === 'POST') {
        $sqlFile = __DIR__ . '/database.sql';
        if (!is_file($sqlFile)) throw new RuntimeException('ملف database.sql غير موجود.');
        $sql = file_get_contents($sqlFile);
        if ($sql === false) throw new RuntimeException('تعذر قراءة ملف database.sql.');

        foreach (split_sql_statements($sql) as $statement) {
            $pdo->exec($statement);
        }
        $missingTables = array();
        foreach ($requiredTables as $requiredTable) {
            if (!table_exists($pdo, $requiredTable)) $missingTables[] = $requiredTable;
        }
        $installed = count($missingTables) === 0;
        if (!$installed) {
            throw new RuntimeException('لم يكتمل إنشاء الجداول: ' . implode(', ', $missingTables));
        }
        $message = 'تم إنشاء/استكمال جميع جداول قاعدة البيانات بنجاح. يمكنك الآن فتح النظام وتسجيل الدخول.';
    }
} catch (Throwable $e) {
    $error = $e->getMessage();
}
?>
<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1">
    <title>تثبيت نظام الفواتير</title>
    <style>
        *{box-sizing:border-box} body{margin:0;background:#f0f2f5;font-family:Tahoma,Arial,sans-serif;color:#1a1a2e}
        .wrap{min-height:100vh;display:flex;align-items:center;justify-content:center;padding:20px}
        .card{width:100%;max-width:700px;background:#fff;border-radius:16px;padding:28px;box-shadow:0 18px 50px rgba(0,0,0,.14)}
        h1{margin:0 0 12px;color:#0a3d62;font-size:25px}.info{background:#eef7ff;border:1px solid #2980b9;padding:12px 14px;border-radius:9px;line-height:1.8;margin:14px 0}
        .success{background:#eafaf1;border:1px solid #27ae60;color:#1e8449;padding:12px 14px;border-radius:9px;margin:14px 0;line-height:1.8}
        .error{background:#fde8e8;border:1px solid #c0392b;color:#a93226;padding:12px 14px;border-radius:9px;margin:14px 0;line-height:1.8;word-break:break-word}
        table{width:100%;border-collapse:collapse;margin:14px 0;font-size:14px}td{padding:9px;border-bottom:1px solid #eee}td:first-child{font-weight:bold;width:38%}
        button,.btn{display:inline-block;background:#0a3d62;color:#fff;border:0;border-radius:8px;padding:11px 20px;text-decoration:none;font-size:15px;cursor:pointer}
        .danger-note{color:#c0392b;font-weight:bold;line-height:1.8}.muted{color:#666;line-height:1.8;font-size:14px}
        code{direction:ltr;display:inline-block;background:#f4f4f4;padding:2px 6px;border-radius:4px}
    </style>
</head>
<body>
<div class="wrap"><div class="card">
    <h1>تثبيت نظام إدارة الفواتير</h1>
    <p class="muted">هذه الصفحة تنشئ جداول MySQL وتضيف البيانات التجريبية وحسابات الدخول.</p>

    <table>
        <tr><td>MySQL Host</td><td><code><?= htmlspecialchars(DB_HOST, ENT_QUOTES, 'UTF-8') ?></code></td></tr>
        <tr><td>Database</td><td><code><?= htmlspecialchars(DB_NAME, ENT_QUOTES, 'UTF-8') ?></code></td></tr>
        <tr><td>Username</td><td><code><?= htmlspecialchars(DB_USER, ENT_QUOTES, 'UTF-8') ?></code></td></tr>
    </table>

    <?php if ($message): ?><div class="success"><?= htmlspecialchars($message, ENT_QUOTES, 'UTF-8') ?></div><?php endif; ?>
    <?php if ($error): ?><div class="error"><strong>خطأ:</strong> <?= htmlspecialchars($error, ENT_QUOTES, 'UTF-8') ?></div><?php endif; ?>

    <?php if (!$error && !$installed): ?>
        <div class="info">الاتصال بقاعدة البيانات ناجح.<?php if (!empty($missingTables)): ?> الجداول الناقصة: <code><?= htmlspecialchars(implode(', ', $missingTables), ENT_QUOTES, 'UTF-8') ?></code>.<?php endif; ?> اضغط الزر لإنشاء/استكمال الجداول.</div>
        <form method="post"><button type="submit">إنشاء / إصلاح قاعدة البيانات</button></form>
    <?php elseif (!$error && $installed): ?>
        <div class="success">قاعدة البيانات جاهزة بالفعل.</div>
        <a class="btn" href="index.php">فتح النظام</a>
        <p class="danger-note">بعد نجاح التثبيت احذف ملف <code>install.php</code> وملف <code>database.sql</code> من الاستضافة.</p>
        <p class="muted">بيانات الدخول الافتراضية: <code>admin / admin123</code> و <code>emp / emp123</code>. غيّر كلمة المرور فور الدخول من قسم «تغيير كلمة المرور».</p>
    <?php else: ?>
        <div class="info">افتح ملف <code>config.php</code> وضع كلمة مرور MySQL الصحيحة في <code>DB_PASS</code>، ثم أعد تحميل الصفحة.</div>
    <?php endif; ?>
</div></div>
</body>
</html>
