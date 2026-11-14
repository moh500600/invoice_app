<!DOCTYPE html>
<html lang="ar" dir="rtl">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=yes" />
  <title>نظام إدارة الفواتير - التأمين الطبي</title>

  <link rel="stylesheet" href="https://cdnjs.cloudflare.com/ajax/libs/font-awesome/6.0.0-beta3/css/all.min.css" />
  <link href="https://fonts.googleapis.com/css2?family=Tajawal:wght@400;500;700&family=Cairo:wght@400;600;700&display=swap" rel="stylesheet" />

  <script src="https://cdn.jsdelivr.net/npm/react@18.2.0/umd/react.production.min.js"></script>
  <script src="https://cdn.jsdelivr.net/npm/react-dom@18.2.0/umd/react-dom.production.min.js"></script>

  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }

    :root {
      --primary: #0a3d62;
      --primary-light: #1a5276;
      --background-primary: #ffffff;
      --background-secondary: #f8f9fa;
      --background-tertiary: #f0f2f5;
      --text-primary: #1a1a2e;
      --text-secondary: #5a5a6e;
      --border: #e0e0e0;
      --success-bg: #eafaf1;
      --success: #27ae60;
      --danger-bg: #fde8e8;
      --danger: #c0392b;
      --radius-lg: 12px;
      --radius-md: 8px;
    }

    body {
      background: var(--background-tertiary);
      font-family: "Tajawal", "Cairo", sans-serif;
      color: var(--text-primary);
    }

    button, input, select, textarea { font-family: inherit; }
    button { transition: all 0.2s ease; cursor: pointer; }
    button:hover { opacity: 0.88; transform: translateY(-1px); }
    input:focus, select:focus, textarea:focus {
      outline: none;
      border-color: #2980b9 !important;
      box-shadow: 0 0 0 3px rgba(41, 128, 185, 0.1);
    }

    ::-webkit-scrollbar { width: 6px; height: 6px; }
    ::-webkit-scrollbar-track { background: #e0e0e0; border-radius: 10px; }
    ::-webkit-scrollbar-thumb { background: var(--primary); border-radius: 10px; }

    .page-title { margin: 0; font-size: 20px; font-weight: 600; }
    .card {
      background: var(--background-primary);
      border-radius: var(--radius-lg);
      border: 0.5px solid var(--border);
    }
    .form-control {
      width: 100%;
      padding: 9px 12px;
      border: 1px solid var(--border);
      border-radius: 8px;
      font-size: 13px;
      background: #fff;
    }
    .form-label {
      display: block;
      margin-bottom: 5px;
      font-size: 13px;
      font-weight: 500;
      color: var(--text-primary);
    }
    .form-grid-2 {
      display: grid;
      grid-template-columns: repeat(2, minmax(0, 1fr));
      gap: 16px;
      margin-bottom: 14px;
    }
    .form-grid-3 {
      display: grid;
      grid-template-columns: repeat(3, minmax(0, 1fr));
      gap: 12px;
      margin-bottom: 12px;
    }
    .btn-primary {
      padding: 9px 16px;
      background: var(--primary);
      color: #fff;
      border: none;
      border-radius: 8px;
      font-size: 13px;
    }
    .btn-secondary {
      padding: 9px 16px;
      background: var(--background-secondary);
      color: var(--text-primary);
      border: 1px solid var(--border);
      border-radius: 8px;
      font-size: 13px;
    }
    .table-wrap { overflow-x: auto; }
    table { width: 100%; border-collapse: collapse; }
    th, td { vertical-align: middle; }

    @media (max-width: 900px) {
      .sidebar { width: 185px !important; }
      .main-content { padding: 16px !important; }
      .form-grid-3 { grid-template-columns: repeat(2, minmax(0, 1fr)); }
    }

    @media (max-width: 680px) {
      .app-layout { display: block !important; }
      .sidebar {
        width: 100% !important;
        min-height: auto !important;
        position: static !important;
      }
      .sidebar nav { display: flex; overflow-x: auto; padding: 8px !important; }
      .sidebar nav button {
        min-width: max-content;
        border-right: none !important;
        border-bottom: 3px solid transparent !important;
      }
      .sidebar-footer { display: flex; align-items: center; gap: 10px; }
      .form-grid-2, .form-grid-3 { grid-template-columns: 1fr; }
      .invoice-meta-grid { grid-template-columns: 1fr !important; }
      .invoice-header { flex-direction: column; gap: 16px; }
    }

    @media print {
      body * { visibility: hidden !important; }
      #invoice-print-area, #invoice-print-area * { visibility: visible !important; }
      #invoice-print-area {
        position: absolute !important;
        top: 0 !important;
        right: 0 !important;
        width: 100% !important;
        margin: 0 !important;
        padding: 20px !important;
        border: none !important;
      }
    }
  </style>
</head>
<body>
  <div id="root"></div>

  <script src="app.js?v=<?= rawurlencode((string) @filemtime(__DIR__ . '/app.js')) ?>"></script>
</body>
</html>
