<?php
function db()
{
    static $pdo = null;
    if ($pdo instanceof PDO) {
        return $pdo;
    }

    $dbFile = __DIR__ . '/invoice_database.sqlite';
    $pdo = new PDO('sqlite:' . $dbFile, null, null, array(
        PDO::ATTR_ERRMODE            => PDO::ERRMODE_EXCEPTION,
        PDO::ATTR_DEFAULT_FETCH_MODE => PDO::FETCH_ASSOC,
        PDO::ATTR_EMULATE_PREPARES   => false,
    ));
    $pdo->exec('PRAGMA journal_mode = WAL;');
    $pdo->exec('PRAGMA foreign_keys = ON;');
    return $pdo;
}
