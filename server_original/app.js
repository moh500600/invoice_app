const { useState, useEffect, useRef, useCallback } = React;
// ===================== البيانات الثابتة =====================
const defaultCompany = {
    nameAr: "شركة الحماية للتأمين الطبي",
    nameEn: "Al Himaya Medical Insurance Co.",
    vat: "310000000000003",
    cr: "1010000001",
    address: "الرياض - طريق الملك فهد - برج المملكة، الدور 15",
    phone: "920001234",
    email: "info@alhimaya.com.sa",
    website: "www.alhimaya.com.sa",
    vatRate: 15,
    footerText: "شكراً لثقتكم بنا - هذه فاتورة ضريبية معتمدة وفق متطلبات هيئة الزكاة والضريبة والجمارك",
    logo: null,
    stamp: null,
    logoSize: 80,
    logoEnabled: true,
    stampSize: 100,
    stampX: 70,
    stampY: 60,
    stampEnabled: true,
};
const users = [
    { id: 1, username: "admin", password: "admin123", role: "admin", name: "محمد العمري" },
    { id: 2, username: "emp", password: "emp123", role: "employee", name: "سارة الزهراني" },
];
const sampleCustomers = [
    { id: 1, name: "شركة الأفق للمقاولات", vat: "310111222333", cr: "1010234567", mobile: "0501234567", email: "info@ufuq.com.sa", address: "الرياض - حي العليا" },
    { id: 2, name: "مستشفى النور الطبي", vat: "310444555666", cr: "1010987654", mobile: "0509876543", email: "billing@alnoor-hosp.com.sa", address: "جدة - الحمراء" },
    { id: 3, name: "مجموعة الخليج للتجارة", vat: "310777888999", cr: "2050111222", mobile: "0555551111", email: "accounts@gulf-group.sa", address: "الدمام - العزيزية" },
];
const samplePolicies = [
    { id: 1, customerId: 1, policyNo: "POL-2025-001", type: "تأمين طبي جماعي", startDate: "2025-01-01", endDate: "2025-12-31", premium: 85000 },
    { id: 2, customerId: 2, policyNo: "POL-2025-002", type: "تأمين طبي مميز", startDate: "2025-03-01", endDate: "2026-02-28", premium: 120000 },
    { id: 3, customerId: 3, policyNo: "POL-2025-003", type: "تأمين طبي شامل", startDate: "2025-06-01", endDate: "2026-05-31", premium: 200000 },
];
const initialInvoices = [
    { id: 1, invoiceNo: "INV-2025-0001", policyNo: "POL-2025-001", endorsementNo: "END-001", customerId: 1, date: "2025-01-15", description: "قسط التأمين الطبي - الربع الأول", amount: 21250, vatRate: 15, vatAmount: 3187.5, total: 24437.5, mobile: "0501234567", email: "info@ufuq.com.sa", address: "الرياض - حي العليا", createdBy: "admin", createdAt: "2025-01-15T10:30:00" },
    { id: 2, invoiceNo: "INV-2025-0002", policyNo: "POL-2025-002", endorsementNo: "END-002", customerId: 2, date: "2025-03-01", description: "قسط التأمين الطبي المميز - سنوي", amount: 120000, vatRate: 15, vatAmount: 18000, total: 138000, mobile: "0509876543", email: "billing@alnoor-hosp.com.sa", address: "جدة - الحمراء", createdBy: "admin", createdAt: "2025-03-01T09:00:00" },
    { id: 3, invoiceNo: "INV-2025-0003", policyNo: "POL-2025-003", endorsementNo: "END-003", customerId: 3, date: "2025-06-01", description: "قسط التأمين الطبي الشامل - نصف سنوي", amount: 100000, vatRate: 15, vatAmount: 15000, total: 115000, mobile: "0555551111", email: "accounts@gulf-group.sa", address: "الدمام - العزيزية", createdBy: "emp", createdAt: "2025-06-01T11:15:00" },
];
// ===================== دوال آمنة للحقول الاختيارية =====================
function safeText(value) {
    return value === null || value === undefined ? "" : String(value);
}
function displayValue(value, fallback = "-") {
    const text = safeText(value).trim();
    return text || fallback;
}
function safeNumber(value, fallback = 0) {
    const number = Number(value);
    return Number.isFinite(number) ? number : fallback;
}
function optionalInteger(value) {
    if (value === "" || value === null || value === undefined)
        return null;
    const number = parseInt(value, 10);
    return Number.isFinite(number) ? number : null;
}
function formatCurrency(value) {
    return new Intl.NumberFormat("ar-SA", {
        style: "currency",
        currency: "SAR",
        minimumFractionDigits: 2,
    }).format(safeNumber(value));
}
function generateQRData(invoice, company) {
    const sellerName = safeText(company === null || company === void 0 ? void 0 : company.nameAr);
    const vatNo = safeText(company === null || company === void 0 ? void 0 : company.vat);
    let dateValue = new Date();
    if (invoice === null || invoice === void 0 ? void 0 : invoice.date) {
        const candidate = new Date(invoice.date);
        if (!Number.isNaN(candidate.getTime()))
            dateValue = candidate;
    }
    const dateTime = dateValue.toISOString().replace("T", " ").substring(0, 19);
    const total = safeNumber(invoice === null || invoice === void 0 ? void 0 : invoice.total).toFixed(2);
    const vat = safeNumber(invoice === null || invoice === void 0 ? void 0 : invoice.vatAmount).toFixed(2);
    const tlvEncode = (tag, value) => {
        const encoded = new TextEncoder().encode(safeText(value));
        return String.fromCharCode(tag, encoded.length, ...encoded);
    };
    const tlv = tlvEncode(1, sellerName) +
        tlvEncode(2, vatNo) +
        tlvEncode(3, dateTime) +
        tlvEncode(4, total) +
        tlvEncode(5, vat);
    return btoa(unescape(encodeURIComponent(tlv)));
}
function escapeCSV(value) {
    const text = safeText(value).replace(/"/g, '""');
    return `"${text}"`;
}
// ===================== رمز QR مبسط للعرض =====================
function QRCode({ data, size = 100 }) {
    const canvasRef = useRef(null);
    useEffect(() => {
        if (!canvasRef.current)
            return;
        const canvas = canvasRef.current;
        const ctx = canvas.getContext("2d");
        ctx.fillStyle = "#fff";
        ctx.fillRect(0, 0, size, size);
        if (!data)
            return;
        const cells = 21;
        const cellSize = size / cells;
        const hash = Array.from(data).reduce((a, c) => ((a << 5) - a + c.charCodeAt(0)) | 0, 0);
        const pseudoRandom = (i, j) => ((hash ^ (i * 31 + j * 17)) & 1) === 0;
        for (let i = 0; i < cells; i++) {
            for (let j = 0; j < cells; j++) {
                if (pseudoRandom(i, j)) {
                    ctx.fillStyle = "#000";
                    ctx.fillRect(j * cellSize, i * cellSize, cellSize, cellSize);
                }
            }
        }
        const drawFinder = (row, col) => {
            for (let r = 0; r <= 6; r++) {
                for (let c = 0; c <= 6; c++) {
                    const black = r === 0 || r === 6 || c === 0 || c === 6 ||
                        (r >= 2 && r <= 4 && c >= 2 && c <= 4);
                    ctx.fillStyle = black ? "#000" : "#fff";
                    ctx.fillRect((col + c) * cellSize, (row + r) * cellSize, cellSize, cellSize);
                }
            }
        };
        drawFinder(0, 0);
        drawFinder(0, cells - 7);
        drawFinder(cells - 7, 0);
    }, [data, size]);
    return React.createElement("canvas", { ref: canvasRef, width: size, height: size, style: { display: "block" } });
}
// ===================== الاتصال بواجهة PHP =====================
let csrfToken = "";
async function apiRequest(action, options = {}) {
    const method = options.method || "GET";
    const requestOptions = {
        method,
        credentials: "same-origin",
        cache: "no-store",
        headers: { "Accept": "application/json", "X-Requested-With": "XMLHttpRequest" },
    };
    if (method !== "GET") {
        requestOptions.headers["Content-Type"] = "application/json";
        if (csrfToken && action !== "login")
            requestOptions.headers["X-CSRF-Token"] = csrfToken;
        requestOptions.body = JSON.stringify(options.data || {});
    }
    const response = await fetch(`api.php?action=${encodeURIComponent(action)}`, requestOptions);
    let result;
    try {
        result = await response.json();
    }
    catch (error) {
        throw new Error("تعذر قراءة استجابة الخادم. تأكد من رفع ملفات PHP وتشغيل المثبّت.");
    }
    if (result.csrfToken)
        csrfToken = result.csrfToken;
    if (!response.ok || result.ok === false) {
        const error = new Error(result.message || "فشلت العملية المطلوبة.");
        error.status = response.status;
        throw error;
    }
    return result;
}
function LoadingScreen({ message = "جاري تحميل النظام..." }) {
    return (React.createElement("div", { dir: "rtl", style: { minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center", background: "#f0f2f5", fontFamily: "'Tajawal','Cairo',sans-serif" } },
        React.createElement("div", { style: { background: "#fff", padding: "28px 36px", borderRadius: 14, boxShadow: "0 12px 35px rgba(0,0,0,.12)", color: "var(--primary)", fontWeight: 700 } },
            React.createElement("i", { className: "fas fa-spinner fa-spin", style: { marginLeft: 8 } }),
            " ",
            message)));
}
// ===================== التطبيق =====================
function App() {
    const [currentUser, setCurrentUser] = useState(null);
    const [page, setPage] = useState("dashboard");
    const [invoices, setInvoices] = useState([]);
    const [customers, setCustomers] = useState([]);
    const [policies, setPolicies] = useState([]);
    const [company, setCompany] = useState(defaultCompany);
    const [auditLog, setAuditLog] = useState([]);
    const [notification, setNotification] = useState(null);
    const [loginForm, setLoginForm] = useState({ username: "", password: "" });
    const [loginError, setLoginError] = useState("");
    const [initializing, setInitializing] = useState(true);
    const [connectionError, setConnectionError] = useState("");
    const notify = useCallback((msg, type = "success") => {
        setNotification({ msg, type });
        window.setTimeout(() => setNotification(null), 3000);
    }, []);
    const loadData = useCallback(async () => {
        const result = await apiRequest("bootstrap");
        setInvoices(Array.isArray(result.invoices) ? result.invoices : []);
        setCustomers(Array.isArray(result.customers) ? result.customers : []);
        setPolicies(Array.isArray(result.policies) ? result.policies : []);
        setCompany(result.company ? { ...defaultCompany, ...result.company } : defaultCompany);
        setAuditLog(Array.isArray(result.auditLog) ? result.auditLog : []);
    }, []);
    useEffect(() => {
        let active = true;
        (async () => {
            try {
                const session = await apiRequest("session");
                if (!active)
                    return;
                if (session.authenticated && session.user) {
                    setCurrentUser(session.user);
                    await loadData();
                }
            }
            catch (error) {
                if (active)
                    setConnectionError(error.message);
            }
            finally {
                if (active)
                    setInitializing(false);
            }
        })();
        return () => { active = false; };
    }, [loadData]);
    useEffect(() => {
        if (page === "audit" && (currentUser === null || currentUser === void 0 ? void 0 : currentUser.role) === "admin") {
            apiRequest("audit_list", { method: "POST", data: {} })
                .then((result) => setAuditLog(result.auditLog || []))
                .catch((error) => notify(error.message, "error"));
        }
    }, [page, currentUser, notify]);
    const handleLogin = async () => {
        setLoginError("");
        try {
            const result = await apiRequest("login", { method: "POST", data: loginForm });
            setCurrentUser(result.user);
            setPage("dashboard");
            await loadData();
        }
        catch (error) {
            setLoginError(error.message);
        }
    };
    const handleLogout = async () => {
        try {
            await apiRequest("logout", { method: "POST", data: {} });
        }
        catch (error) {
            // يتم إنهاء الواجهة محلياً حتى لو انقطعت الشبكة.
        }
        setCurrentUser(null);
        setInvoices([]);
        setCustomers([]);
        setPolicies([]);
        setAuditLog([]);
        setPage("dashboard");
    };
    // بعد كل عملية كتابة نعيد تحميل البيانات من MySQL بدلاً من الاعتماد على الذاكرة فقط.
    // هذا يجعل الواجهة تعرض ما تم تخزينه فعلياً ويمنع ظهور بيانات مؤقتة تختفي بعد التحديث.
    const saveInvoice = async (invoiceData) => {
        const result = await apiRequest("invoice_save", { method: "POST", data: invoiceData });
        if (!result.invoice || !result.invoice.id)
            throw new Error("تم إرسال الفاتورة لكن تعذر التحقق من تخزينها في قاعدة البيانات.");
        await loadData();
        return result.invoice;
    };
    const saveCustomer = async (customerData, id = null) => {
        const result = await apiRequest("customer_save", { method: "POST", data: { ...customerData, id } });
        if (!result.customer || !result.customer.id)
            throw new Error("تم إرسال بيانات العميل لكن تعذر التحقق من تخزينها في قاعدة البيانات.");
        await loadData();
        return result.customer;
    };
    const deleteCustomer = async (id) => {
        await apiRequest("customer_delete", { method: "POST", data: { id } });
        await loadData();
    };
    const savePolicy = async (policyData, id = null) => {
        const result = await apiRequest("policy_save", { method: "POST", data: { ...policyData, id } });
        if (!result.policy || !result.policy.id)
            throw new Error("تم إرسال بيانات الوثيقة لكن تعذر التحقق من تخزينها في قاعدة البيانات.");
        await loadData();
        return result.policy;
    };
    const deletePolicy = async (id) => {
        await apiRequest("policy_delete", { method: "POST", data: { id } });
        await loadData();
    };
    const saveCompany = async (companyData) => {
        const result = await apiRequest("settings_save", { method: "POST", data: companyData });
        if (!result.company)
            throw new Error("تم إرسال الإعدادات لكن تعذر التحقق من تخزينها في قاعدة البيانات.");
        await loadData();
        return result.company;
    };
    const changePassword = async (passwordData) => {
        await apiRequest("change_password", { method: "POST", data: passwordData });
    };
    if (initializing)
        return React.createElement(LoadingScreen, null);
    if (connectionError) {
        return (React.createElement("div", { dir: "rtl", style: { minHeight: "100vh", display: "flex", alignItems: "center", justifyContent: "center", background: "#f0f2f5", padding: 20 } },
            React.createElement("div", { style: { background: "white", maxWidth: 620, padding: 28, borderRadius: 14, boxShadow: "0 12px 35px rgba(0,0,0,.12)" } },
                React.createElement("h2", { style: { color: "var(--danger)", marginBottom: 12 } },
                    React.createElement("i", { className: "fas fa-database" }),
                    " \u062A\u0639\u0630\u0631 \u062A\u0634\u063A\u064A\u0644 \u0642\u0627\u0639\u062F\u0629 \u0627\u0644\u0628\u064A\u0627\u0646\u0627\u062A"),
                React.createElement("p", { style: { lineHeight: 1.8, color: "#555" } }, connectionError),
                React.createElement("p", { style: { marginTop: 10, lineHeight: 1.8, color: "#555" } },
                    "\u0639\u062F\u0651\u0644 \u0643\u0644\u0645\u0629 \u0645\u0631\u0648\u0631 MySQL \u0641\u064A \u0645\u0644\u0641 ",
                    React.createElement("strong", null, "config.php"),
                    "\u060C \u062B\u0645 \u0627\u0641\u062A\u062D ",
                    React.createElement("strong", null, "install.php"),
                    " \u0645\u0631\u0629 \u0648\u0627\u062D\u062F\u0629 \u0644\u0625\u0646\u0634\u0627\u0621 \u0627\u0644\u062C\u062F\u0627\u0648\u0644."),
                React.createElement("button", { onClick: () => window.location.reload(), className: "btn-primary", style: { marginTop: 14 } }, "\u0625\u0639\u0627\u062F\u0629 \u0627\u0644\u0645\u062D\u0627\u0648\u0644\u0629"))));
    }
    if (!currentUser) {
        return React.createElement(LoginScreen, { form: loginForm, setForm: setLoginForm, onLogin: handleLogin, error: loginError });
    }
    return (React.createElement("div", { dir: "rtl", style: { minHeight: "100vh", position: "relative" } },
        notification && (React.createElement("div", { style: {
                position: "fixed", top: 16, left: "50%", transform: "translateX(-50%)", zIndex: 9999,
                background: notification.type === "success" ? "var(--success-bg)" : "var(--danger-bg)",
                color: notification.type === "success" ? "var(--success)" : "var(--danger)",
                padding: "10px 24px", borderRadius: 8,
                border: `1px solid ${notification.type === "success" ? "var(--success)" : "var(--danger)"}`,
                fontWeight: 500, fontSize: 14, boxShadow: "0 8px 24px rgba(0,0,0,0.12)",
            } }, notification.msg)),
        React.createElement("div", { className: "app-layout", style: { display: "flex", minHeight: "100vh" } },
            React.createElement(Sidebar, { page: page, setPage: setPage, user: currentUser, onLogout: handleLogout }),
            React.createElement("main", { className: "main-content", style: { flex: 1, padding: 24, overflow: "auto", minWidth: 0 } },
                page === "dashboard" && React.createElement(Dashboard, { invoices: invoices, customers: customers, policies: policies }),
                page === "invoices" && React.createElement(InvoiceList, { invoices: invoices, customers: customers, setPage: setPage, company: company, notify: notify }),
                page === "new-invoice" && (React.createElement(InvoiceForm, { invoices: invoices, customers: customers, policies: policies, company: company, setPage: setPage, notify: notify, onSaveInvoice: saveInvoice })),
                page === "customers" && (React.createElement(CustomerManager, { customers: customers, notify: notify, onSaveCustomer: saveCustomer, onDeleteCustomer: deleteCustomer })),
                page === "policies" && (React.createElement(PolicyManager, { policies: policies, customers: customers, notify: notify, onSavePolicy: savePolicy, onDeletePolicy: deletePolicy })),
                page === "settings" && currentUser.role === "admin" && (React.createElement(CompanySettings, { company: company, notify: notify, onSaveCompany: saveCompany })),
                page === "password" && React.createElement(PasswordManager, { notify: notify, onChangePassword: changePassword }),
                page === "audit" && currentUser.role === "admin" && React.createElement(AuditLogView, { log: auditLog })))));
}
// ===================== تسجيل الدخول =====================
function LoginScreen({ form, setForm, onLogin, error }) {
    return (React.createElement("div", { dir: "rtl", style: {
            minHeight: "100vh",
            display: "flex",
            alignItems: "center",
            justifyContent: "center",
            background: "linear-gradient(135deg, #0a3d62 0%, #1a5276 50%, #0a3d62 100%)",
            padding: 20,
        } },
        React.createElement("div", { style: {
                background: "white",
                borderRadius: 16,
                padding: "40px 48px",
                width: "100%",
                maxWidth: 420,
                boxShadow: "0 20px 60px rgba(0,0,0,0.3)",
            } },
            React.createElement("div", { style: { textAlign: "center", marginBottom: 32 } },
                React.createElement("div", { style: {
                        width: 64,
                        height: 64,
                        background: "var(--primary)",
                        borderRadius: 16,
                        display: "flex",
                        alignItems: "center",
                        justifyContent: "center",
                        margin: "0 auto 16px",
                        fontSize: 28,
                    } }, "\uD83C\uDFE5"),
                React.createElement("h2", { style: { margin: "0 0 4px", color: "var(--primary)", fontSize: 22 } }, "\u0646\u0638\u0627\u0645 \u0625\u062F\u0627\u0631\u0629 \u0627\u0644\u0641\u0648\u0627\u062A\u064A\u0631"),
                React.createElement("p", { style: { margin: 0, color: "#666", fontSize: 14 } }, "\u0627\u0644\u062A\u0623\u0645\u064A\u0646 \u0627\u0644\u0637\u0628\u064A - \u0641\u0648\u0627\u062A\u064A\u0631 \u0636\u0631\u064A\u0628\u064A\u0629")),
            React.createElement("div", { style: { marginBottom: 16 } },
                React.createElement("label", { className: "form-label" }, "\u0627\u0633\u0645 \u0627\u0644\u0645\u0633\u062A\u062E\u062F\u0645"),
                React.createElement("input", { className: "form-control", value: form.username, onChange: (event) => setForm((previous) => ({ ...previous, username: event.target.value })), onKeyDown: (event) => event.key === "Enter" && onLogin(), placeholder: "\u0623\u062F\u062E\u0644 \u0627\u0633\u0645 \u0627\u0644\u0645\u0633\u062A\u062E\u062F\u0645" })),
            React.createElement("div", { style: { marginBottom: 20 } },
                React.createElement("label", { className: "form-label" }, "\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631"),
                React.createElement("input", { className: "form-control", type: "password", value: form.password, onChange: (event) => setForm((previous) => ({ ...previous, password: event.target.value })), onKeyDown: (event) => event.key === "Enter" && onLogin(), placeholder: "\u0623\u062F\u062E\u0644 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631" })),
            error && (React.createElement("div", { style: { background: "var(--danger-bg)", color: "var(--danger)", padding: "10px 14px", borderRadius: 8, marginBottom: 16, fontSize: 13, textAlign: "center" } }, error)),
            React.createElement("button", { className: "btn-primary", onClick: onLogin, style: { width: "100%", padding: 12, fontSize: 16, fontWeight: 600 } }, "\u062F\u062E\u0648\u0644"),
            React.createElement("div", { style: { marginTop: 16, padding: 12, background: "#f0f8ff", borderRadius: 8, fontSize: 12, color: "#666", textAlign: "center" } }, "\u0627\u0644\u0645\u062F\u064A\u0631: admin / admin123 \u00A0 | \u00A0 \u0645\u0648\u0638\u0641: emp / emp123"))));
}
// ===================== الشريط الجانبي =====================
function Sidebar({ page, setPage, user, onLogout }) {
    const navItems = [
        { id: "dashboard", label: "لوحة التحكم", icon: "fa-tachometer-alt" },
        { id: "invoices", label: "الفواتير", icon: "fa-file-invoice" },
        { id: "new-invoice", label: "فاتورة جديدة", icon: "fa-file-circle-plus" },
        { id: "customers", label: "العملاء", icon: "fa-users" },
        { id: "policies", label: "الوثائق", icon: "fa-shield-alt" },
        { id: "password", label: "تغيير كلمة المرور", icon: "fa-key" },
        ...(user.role === "admin"
            ? [
                { id: "settings", label: "إعدادات الشركة", icon: "fa-cogs" },
                { id: "audit", label: "سجل التدقيق", icon: "fa-history" },
            ]
            : []),
    ];
    return (React.createElement("aside", { className: "sidebar", style: { width: 220, background: "var(--primary)", color: "#fff", display: "flex", flexDirection: "column", minHeight: "100vh", flexShrink: 0 } },
        React.createElement("div", { style: { padding: "20px 16px", borderBottom: "1px solid rgba(255,255,255,0.1)" } },
            React.createElement("div", { style: { display: "flex", alignItems: "center", gap: 10 } },
                React.createElement("span", { style: { fontSize: 24 } }, "\uD83C\uDFE5"),
                React.createElement("div", null,
                    React.createElement("div", { style: { fontWeight: 700, fontSize: 13 } }, "\u0646\u0638\u0627\u0645 \u0627\u0644\u0641\u0648\u0627\u062A\u064A\u0631"),
                    React.createElement("div", { style: { fontSize: 11, opacity: 0.7 } }, "\u0627\u0644\u062A\u0623\u0645\u064A\u0646 \u0627\u0644\u0637\u0628\u064A")))),
        React.createElement("nav", { style: { flex: 1, padding: "12px 0" } }, navItems.map((item) => (React.createElement("button", { key: item.id, onClick: () => setPage(item.id), style: {
                display: "flex",
                alignItems: "center",
                gap: 10,
                width: "100%",
                padding: "10px 16px",
                background: page === item.id ? "rgba(255,255,255,0.15)" : "transparent",
                color: "#fff",
                border: "none",
                fontSize: 13,
                textAlign: "right",
                borderRight: page === item.id ? "3px solid #3498db" : "3px solid transparent",
            } },
            React.createElement("i", { className: `fas ${item.icon}`, style: { fontSize: 17, width: 20 } }),
            item.label)))),
        React.createElement("div", { className: "sidebar-footer", style: { padding: 16, borderTop: "1px solid rgba(255,255,255,0.1)" } },
            React.createElement("div", { style: { fontSize: 12, opacity: 0.75, marginBottom: 8 } },
                user.name,
                " \u2022 ",
                user.role === "admin" ? "مدير" : "موظف"),
            React.createElement("button", { onClick: onLogout, style: {
                    display: "flex",
                    alignItems: "center",
                    gap: 8,
                    color: "#fff",
                    background: "rgba(255,255,255,0.1)",
                    border: "none",
                    borderRadius: 6,
                    padding: "8px 12px",
                    fontSize: 12,
                    width: "100%",
                } },
                React.createElement("i", { className: "fas fa-sign-out-alt" }),
                " \u062A\u0633\u062C\u064A\u0644 \u0627\u0644\u062E\u0631\u0648\u062C"))));
}
// ===================== لوحة التحكم =====================
function Dashboard({ invoices, customers, policies }) {
    const totalRevenue = invoices.reduce((sum, invoice) => sum + safeNumber(invoice.amount), 0);
    const totalVAT = invoices.reduce((sum, invoice) => sum + safeNumber(invoice.vatAmount), 0);
    const totalWithVAT = invoices.reduce((sum, invoice) => sum + safeNumber(invoice.total), 0);
    const stats = [
        { label: "إجمالي الفواتير", value: invoices.length, icon: "fa-file-alt", color: "#2980b9", bg: "#ebf5fb" },
        { label: "إجمالي الإيرادات", value: formatCurrency(totalRevenue), icon: "fa-dollar-sign", color: "#27ae60", bg: "#eafaf1" },
        { label: "ضريبة القيمة المضافة", value: formatCurrency(totalVAT), icon: "fa-receipt", color: "#8e44ad", bg: "#f5eef8" },
        { label: "الإجمالي مع الضريبة", value: formatCurrency(totalWithVAT), icon: "fa-money-bill", color: "#e67e22", bg: "#fef9e7" },
        { label: "عدد العملاء", value: customers.length, icon: "fa-users", color: "#2ecc71", bg: "#eafaf1" },
        { label: "الوثائق", value: policies.length, icon: "fa-shield-alt", color: "#3498db", bg: "#ebf5fb" },
    ];
    const getCustomerName = (id) => { var _a; return displayValue((_a = customers.find((customer) => customer.id === id)) === null || _a === void 0 ? void 0 : _a.name); };
    return (React.createElement("div", null,
        React.createElement("h2", { className: "page-title", style: { marginBottom: 20 } }, "\u0644\u0648\u062D\u0629 \u0627\u0644\u062A\u062D\u0643\u0645"),
        React.createElement("div", { style: { display: "grid", gridTemplateColumns: "repeat(auto-fit, minmax(170px, 1fr))", gap: 14, marginBottom: 28 } }, stats.map((stat) => (React.createElement("div", { key: stat.label, style: { background: stat.bg, borderRadius: 12, padding: "16px 18px", border: `1px solid ${stat.color}30` } },
            React.createElement("div", { style: { display: "flex", alignItems: "center", justifyContent: "space-between", marginBottom: 8 } },
                React.createElement("span", { style: { fontSize: 12, color: stat.color, fontWeight: 500 } }, stat.label),
                React.createElement("i", { className: `fas ${stat.icon}`, style: { fontSize: 20, color: stat.color } })),
            React.createElement("div", { style: { fontSize: 18, fontWeight: 700, color: stat.color } }, stat.value))))),
        React.createElement("div", { className: "card", style: { overflow: "hidden" } },
            React.createElement("div", { style: { padding: "14px 18px", borderBottom: "1px solid var(--border)", fontWeight: 600 } }, "\u0623\u062D\u062F\u062B \u0627\u0644\u0641\u0648\u0627\u062A\u064A\u0631"),
            React.createElement("div", { className: "table-wrap" },
                React.createElement("table", { style: { fontSize: 13 } },
                    React.createElement("thead", null,
                        React.createElement("tr", { style: { background: "var(--background-secondary)" } }, ["رقم الفاتورة", "العميل", "التاريخ", "المبلغ", "الضريبة", "الإجمالي"].map((heading) => (React.createElement("th", { key: heading, style: { padding: "10px 14px", textAlign: "right", color: "var(--text-secondary)", fontWeight: 500, borderBottom: "1px solid var(--border)", whiteSpace: "nowrap" } }, heading))))),
                    React.createElement("tbody", null, invoices.slice(-5).reverse().map((invoice) => (React.createElement("tr", { key: invoice.id, style: { borderBottom: "1px solid var(--border)" } },
                        React.createElement("td", { style: { padding: "10px 14px", color: "#2980b9", fontWeight: 500 } }, displayValue(invoice.invoiceNo)),
                        React.createElement("td", { style: { padding: "10px 14px" } }, getCustomerName(invoice.customerId)),
                        React.createElement("td", { style: { padding: "10px 14px", color: "var(--text-secondary)" } }, displayValue(invoice.date)),
                        React.createElement("td", { style: { padding: "10px 14px" } }, formatCurrency(invoice.amount)),
                        React.createElement("td", { style: { padding: "10px 14px" } }, formatCurrency(invoice.vatAmount)),
                        React.createElement("td", { style: { padding: "10px 14px", fontWeight: 600, color: "var(--success)" } }, formatCurrency(invoice.total)))))))))));
}
// ===================== قائمة الفواتير =====================
function InvoiceList({ invoices, customers, setPage, company, notify }) {
    const [search, setSearch] = useState("");
    const [dateFrom, setDateFrom] = useState("");
    const [dateTo, setDateTo] = useState("");
    const [viewInvoice, setViewInvoice] = useState(null);
    const getCustomer = (id) => customers.find((customer) => customer.id === id) || {};
    const filtered = invoices.filter((invoice) => {
        const customer = getCustomer(invoice.customerId);
        const query = search.trim().toLowerCase();
        const searchable = [
            invoice.invoiceNo,
            invoice.policyNo,
            invoice.endorsementNo,
            customer.name,
            invoice.mobile,
        ].map((value) => safeText(value).toLowerCase());
        const matchesSearch = !query || searchable.some((value) => value.includes(query));
        const invoiceDate = safeText(invoice.date);
        const matchesFrom = !dateFrom || (invoiceDate && invoiceDate >= dateFrom);
        const matchesTo = !dateTo || (invoiceDate && invoiceDate <= dateTo);
        return matchesSearch && matchesFrom && matchesTo;
    });
    const exportToCSV = () => {
        const rows = [
            ["رقم الفاتورة", "رقم الوثيقة", "العميل", "التاريخ", "المبلغ", "الضريبة", "الإجمالي"],
            ...filtered.map((invoice) => {
                const customer = getCustomer(invoice.customerId);
                return [
                    invoice.invoiceNo,
                    invoice.policyNo,
                    customer.name,
                    invoice.date,
                    safeNumber(invoice.amount),
                    safeNumber(invoice.vatAmount),
                    safeNumber(invoice.total),
                ];
            }),
        ];
        const csv = rows.map((row) => row.map(escapeCSV).join(",")).join("\n");
        const blob = new Blob(["\uFEFF" + csv], { type: "text/csv;charset=utf-8" });
        const link = document.createElement("a");
        link.href = URL.createObjectURL(blob);
        link.download = "invoices.csv";
        link.click();
        URL.revokeObjectURL(link.href);
        notify("تم تصدير الفواتير بنجاح");
    };
    return (React.createElement("div", null,
        React.createElement("div", { style: { display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12, flexWrap: "wrap", marginBottom: 20 } },
            React.createElement("h2", { className: "page-title" }, "\u0623\u0631\u0634\u064A\u0641 \u0627\u0644\u0641\u0648\u0627\u062A\u064A\u0631"),
            React.createElement("div", { style: { display: "flex", gap: 8, flexWrap: "wrap" } },
                React.createElement("button", { onClick: exportToCSV, className: "btn-primary", style: { background: "var(--success)" } },
                    React.createElement("i", { className: "fas fa-download" }),
                    " \u062A\u0635\u062F\u064A\u0631 CSV"),
                React.createElement("button", { onClick: () => setPage("new-invoice"), className: "btn-primary" },
                    React.createElement("i", { className: "fas fa-plus" }),
                    " \u0641\u0627\u062A\u0648\u0631\u0629 \u062C\u062F\u064A\u062F\u0629"))),
        React.createElement("div", { className: "card", style: { padding: 16, marginBottom: 16, display: "flex", gap: 10, flexWrap: "wrap" } },
            React.createElement("input", { className: "form-control", value: search, onChange: (event) => setSearch(event.target.value), placeholder: "\u0628\u062D\u062B \u0628\u0631\u0642\u0645 \u0627\u0644\u0641\u0627\u062A\u0648\u0631\u0629\u060C \u0627\u0644\u0648\u062B\u064A\u0642\u0629\u060C \u0627\u0644\u0639\u0645\u064A\u0644\u060C \u0627\u0644\u062C\u0648\u0627\u0644...", style: { flex: 1, minWidth: 220 } }),
            React.createElement("input", { className: "form-control", type: "date", value: dateFrom, onChange: (event) => setDateFrom(event.target.value), style: { width: "auto" } }),
            React.createElement("input", { className: "form-control", type: "date", value: dateTo, onChange: (event) => setDateTo(event.target.value), style: { width: "auto" } }),
            React.createElement("button", { className: "btn-secondary", onClick: () => {
                    setSearch("");
                    setDateFrom("");
                    setDateTo("");
                } }, "\u0645\u0633\u062D")),
        React.createElement("div", { className: "card", style: { overflow: "hidden" } },
            React.createElement("div", { className: "table-wrap" },
                React.createElement("table", { style: { fontSize: 13 } },
                    React.createElement("thead", null,
                        React.createElement("tr", { style: { background: "var(--primary)" } }, ["رقم الفاتورة", "رقم الوثيقة", "رقم التأشيرة", "العميل", "التاريخ", "المبلغ", "الضريبة", "الإجمالي", "الإجراءات"].map((heading) => (React.createElement("th", { key: heading, style: { padding: "10px 12px", textAlign: "right", color: "#fff", fontWeight: 500, fontSize: 12, whiteSpace: "nowrap" } }, heading))))),
                    React.createElement("tbody", null,
                        filtered.length === 0 && (React.createElement("tr", null,
                            React.createElement("td", { colSpan: "9", style: { padding: 32, textAlign: "center", color: "var(--text-secondary)" } }, "\u0644\u0627 \u062A\u0648\u062C\u062F \u0641\u0648\u0627\u062A\u064A\u0631"))),
                        filtered.map((invoice) => {
                            const customer = getCustomer(invoice.customerId);
                            return (React.createElement("tr", { key: invoice.id, style: { borderBottom: "1px solid var(--border)" } },
                                React.createElement("td", { style: { padding: "9px 12px", color: "#2980b9", fontWeight: 600, whiteSpace: "nowrap" } }, displayValue(invoice.invoiceNo)),
                                React.createElement("td", { style: { padding: "9px 12px", whiteSpace: "nowrap" } }, displayValue(invoice.policyNo)),
                                React.createElement("td", { style: { padding: "9px 12px", whiteSpace: "nowrap" } }, displayValue(invoice.endorsementNo)),
                                React.createElement("td", { style: { padding: "9px 12px", whiteSpace: "nowrap" } }, displayValue(customer.name)),
                                React.createElement("td", { style: { padding: "9px 12px", whiteSpace: "nowrap", color: "var(--text-secondary)" } }, displayValue(invoice.date)),
                                React.createElement("td", { style: { padding: "9px 12px", whiteSpace: "nowrap" } }, formatCurrency(invoice.amount)),
                                React.createElement("td", { style: { padding: "9px 12px", whiteSpace: "nowrap" } }, formatCurrency(invoice.vatAmount)),
                                React.createElement("td", { style: { padding: "9px 12px", fontWeight: 700, color: "var(--success)", whiteSpace: "nowrap" } }, formatCurrency(invoice.total)),
                                React.createElement("td", { style: { padding: "9px 12px", whiteSpace: "nowrap" } },
                                    React.createElement("div", { style: { display: "flex", gap: 6 } },
                                        React.createElement("button", { onClick: () => setViewInvoice(invoice), title: "\u0639\u0631\u0636", style: { padding: "5px 9px", background: "#ebf5fb", color: "#2980b9", border: "none", borderRadius: 6 } },
                                            React.createElement("i", { className: "fas fa-eye" })),
                                        React.createElement("button", { onClick: () => {
                                                setViewInvoice(invoice);
                                                window.setTimeout(() => window.print(), 350);
                                            }, title: "\u0637\u0628\u0627\u0639\u0629", style: { padding: "5px 9px", background: "var(--success-bg)", color: "var(--success)", border: "none", borderRadius: 6 } },
                                            React.createElement("i", { className: "fas fa-print" }))))));
                        }))))),
        viewInvoice && (React.createElement(InvoiceModal, { invoice: viewInvoice, customer: getCustomer(viewInvoice.customerId), company: company, onClose: () => setViewInvoice(null) }))));
}
// ===================== نافذة الفاتورة =====================
function InvoiceModal({ invoice, customer, company, onClose }) {
    const qrData = generateQRData(invoice, company);
    return (React.createElement("div", { style: { position: "fixed", inset: 0, background: "rgba(0,0,0,0.5)", zIndex: 1000, display: "flex", alignItems: "flex-start", justifyContent: "center", overflowY: "auto", padding: 20 }, onClick: (event) => event.target === event.currentTarget && onClose() },
        React.createElement("div", { style: { background: "#fff", borderRadius: 12, maxWidth: 820, width: "100%", overflow: "hidden" } },
            React.createElement("div", { style: { display: "flex", alignItems: "center", justifyContent: "space-between", padding: "14px 20px", background: "var(--primary)", color: "#fff" } },
                React.createElement("span", { style: { fontWeight: 600 } },
                    "\u0639\u0631\u0636 \u0627\u0644\u0641\u0627\u062A\u0648\u0631\u0629 - ",
                    displayValue(invoice.invoiceNo)),
                React.createElement("div", { style: { display: "flex", gap: 8 } },
                    React.createElement("button", { onClick: () => window.print(), style: { padding: "6px 14px", background: "rgba(255,255,255,0.15)", color: "#fff", border: "none", borderRadius: 6, fontSize: 13 } },
                        React.createElement("i", { className: "fas fa-print" }),
                        " \u0637\u0628\u0627\u0639\u0629"),
                    React.createElement("button", { onClick: onClose, style: { background: "none", border: "none", color: "#fff", fontSize: 20 } }, "\u2715"))),
            React.createElement("div", { style: { padding: 20, maxHeight: "78vh", overflowY: "auto" } },
                React.createElement(PrintableInvoice, { invoice: invoice, customer: customer, company: company, qrData: qrData })))));
}
// ===================== الفاتورة القابلة للطباعة =====================
function PrintableInvoice({ invoice, customer, company, qrData }) {
    const customerRows = [
        ["اسم العميل:", customer.name],
        ["الرقم الضريبي:", customer.vat],
        ["السجل التجاري:", customer.cr],
        ["رقم الجوال:", invoice.mobile || customer.mobile],
        ["البريد الإلكتروني:", invoice.email || customer.email],
        ["العنوان:", invoice.address || customer.address],
    ];
    const invoiceRows = [
        ["رقم الفاتورة:", invoice.invoiceNo],
        ["تاريخ الفاتورة:", invoice.date],
        ["رقم الوثيقة:", invoice.policyNo],
        ["رقم التأشيرة:", invoice.endorsementNo],
    ];
    return (React.createElement("div", { id: "invoice-print-area", dir: "rtl", style: {
            background: "#fff",
            padding: "28px 32px",
            minHeight: 900,
            color: "#1a1a2e",
            fontSize: 13,
            border: "1px solid var(--border)",
            borderRadius: 8,
            position: "relative",
        } },
        React.createElement("div", { className: "invoice-header", style: { borderBottom: "3px solid var(--primary)", paddingBottom: 18, marginBottom: 18, display: "flex", alignItems: "flex-start", justifyContent: "space-between" } },
            React.createElement("div", { style: { flex: 1 } },
                company.logo && company.logoEnabled ? (React.createElement("img", { src: company.logo, alt: "\u0634\u0639\u0627\u0631 \u0627\u0644\u0634\u0631\u0643\u0629", style: { height: safeNumber(company.logoSize, 60), maxWidth: 200, marginBottom: 8, objectFit: "contain" } })) : (React.createElement("div", { style: { width: 56, height: 56, background: "var(--primary)", borderRadius: 12, display: "flex", alignItems: "center", justifyContent: "center", fontSize: 28, marginBottom: 8 } }, "\uD83C\uDFE5")),
                React.createElement("div", { style: { fontWeight: 700, fontSize: 18, color: "var(--primary)" } }, displayValue(company.nameAr, "")),
                React.createElement("div", { style: { fontSize: 12, color: "#666", marginTop: 2 } }, displayValue(company.nameEn, "")),
                React.createElement("div", { style: { fontSize: 12, color: "#555", marginTop: 6, lineHeight: 1.8 } },
                    React.createElement("div", null,
                        "\uD83D\uDCCD ",
                        displayValue(company.address)),
                    React.createElement("div", null,
                        "\uD83D\uDCDE ",
                        displayValue(company.phone),
                        " | \uD83D\uDCE7 ",
                        displayValue(company.email)),
                    React.createElement("div", null,
                        "\uD83C\uDF10 ",
                        displayValue(company.website)),
                    React.createElement("div", null,
                        "\u0631\u0642\u0645 \u0627\u0644\u0633\u062C\u0644 \u0627\u0644\u062A\u062C\u0627\u0631\u064A: ",
                        displayValue(company.cr)),
                    React.createElement("div", null,
                        "\u0627\u0644\u0631\u0642\u0645 \u0627\u0644\u0636\u0631\u064A\u0628\u064A: ",
                        displayValue(company.vat)))),
            React.createElement("div", { style: { textAlign: "center" } },
                React.createElement("div", { style: { background: "var(--primary)", color: "#fff", padding: "8px 18px", borderRadius: 8, fontWeight: 700, fontSize: 15, marginBottom: 10 } }, "\u0641\u0627\u062A\u0648\u0631\u0629 \u0636\u0631\u064A\u0628\u064A\u0629"),
                React.createElement("div", { style: { fontSize: 11, color: "#666", marginBottom: 6 } }, "Tax Invoice"),
                React.createElement("div", { style: { border: "2px solid var(--primary)", borderRadius: 6, padding: 6, marginBottom: 8 } },
                    React.createElement(QRCode, { data: qrData, size: 90 })),
                React.createElement("div", { style: { fontSize: 10, color: "#888", whiteSpace: "pre-line" } },
                    "\u0631\u0645\u0632 \u0627\u0644\u0627\u0633\u062A\u062C\u0627\u0628\u0629 \u0627\u0644\u0633\u0631\u064A\u0639\u0629",
                    "\n",
                    "ZATCA Compliant QR"))),
        React.createElement("div", { className: "invoice-meta-grid", style: { display: "grid", gridTemplateColumns: "1fr 1fr", gap: 16, marginBottom: 18 } },
            React.createElement(InfoBox, { title: "\u0628\u064A\u0627\u0646\u0627\u062A \u0627\u0644\u0639\u0645\u064A\u0644", rows: customerRows }),
            React.createElement(InfoBox, { title: "\u0628\u064A\u0627\u0646\u0627\u062A \u0627\u0644\u0641\u0627\u062A\u0648\u0631\u0629", rows: invoiceRows })),
        React.createElement("table", { style: { marginBottom: 18, fontSize: 13 } },
            React.createElement("thead", null,
                React.createElement("tr", { style: { background: "var(--primary)", color: "#fff" } },
                    React.createElement("th", { style: { padding: "10px 14px", textAlign: "right", fontWeight: 500 } }, "\u0645"),
                    React.createElement("th", { style: { padding: "10px 14px", textAlign: "right", fontWeight: 500 } }, "\u0627\u0644\u0628\u064A\u0627\u0646"),
                    React.createElement("th", { style: { padding: "10px 14px", textAlign: "right", fontWeight: 500 } }, "\u0627\u0644\u0645\u0628\u0644\u063A (\u0631\u064A\u0627\u0644)"))),
            React.createElement("tbody", null,
                React.createElement("tr", { style: { borderBottom: "1px solid var(--border)" } },
                    React.createElement("td", { style: { padding: "12px 14px", color: "#666" } }, "1"),
                    React.createElement("td", { style: { padding: "12px 14px" } }, displayValue(invoice.description)),
                    React.createElement("td", { style: { padding: "12px 14px", fontWeight: 600 } }, formatCurrency(invoice.amount))))),
        React.createElement("div", { style: { display: "flex", justifyContent: "flex-start", marginBottom: 20 } },
            React.createElement("div", { style: { width: 300, maxWidth: "100%" } },
                React.createElement("table", { style: { fontSize: 13 } },
                    React.createElement("tbody", null,
                        React.createElement("tr", { style: { borderBottom: "1px solid var(--border)" } },
                            React.createElement("td", { style: { padding: "8px 14px", color: "#555" } }, "\u0627\u0644\u0645\u0628\u0644\u063A \u0642\u0628\u0644 \u0627\u0644\u0636\u0631\u064A\u0628\u0629:"),
                            React.createElement("td", { style: { padding: "8px 14px", textAlign: "left", fontWeight: 600 } }, formatCurrency(invoice.amount))),
                        React.createElement("tr", { style: { borderBottom: "1px solid var(--border)" } },
                            React.createElement("td", { style: { padding: "8px 14px", color: "#555" } },
                                "\u0636\u0631\u064A\u0628\u0629 \u0627\u0644\u0642\u064A\u0645\u0629 \u0627\u0644\u0645\u0636\u0627\u0641\u0629 (",
                                safeNumber(invoice.vatRate),
                                "%):"),
                            React.createElement("td", { style: { padding: "8px 14px", textAlign: "left", fontWeight: 600, color: "#8e44ad" } }, formatCurrency(invoice.vatAmount))),
                        React.createElement("tr", { style: { background: "var(--primary)", color: "#fff" } },
                            React.createElement("td", { style: { padding: "10px 14px", fontWeight: 700 } }, "\u0627\u0644\u0625\u062C\u0645\u0627\u0644\u064A \u0634\u0627\u0645\u0644 \u0627\u0644\u0636\u0631\u064A\u0628\u0629:"),
                            React.createElement("td", { style: { padding: "10px 14px", textAlign: "left", fontWeight: 700, fontSize: 15 } }, formatCurrency(invoice.total))))))),
        company.stampEnabled && company.stamp && (React.createElement("div", { style: {
                position: "absolute",
                left: `${safeNumber(company.stampX, 70)}%`,
                top: `${safeNumber(company.stampY, 60)}%`,
                opacity: 0.5,
                transform: "translate(-50%, -50%)",
            } },
            React.createElement("img", { src: company.stamp, alt: "\u0627\u0644\u062E\u062A\u0645", style: { width: safeNumber(company.stampSize, 100), height: safeNumber(company.stampSize, 100), objectFit: "contain" } }))),
        React.createElement("div", { style: { borderTop: "2px solid var(--primary)", paddingTop: 12, textAlign: "center", color: "#555", fontSize: 12 } }, displayValue(company.footerText, ""))));
}
function InfoBox({ title, rows }) {
    return (React.createElement("div", { style: { background: "var(--background-secondary)", border: "1px solid var(--border)", borderRadius: 8, padding: "12px 14px" } },
        React.createElement("div", { style: { color: "var(--primary)", fontWeight: 700, marginBottom: 8, fontSize: 13, borderBottom: "1px solid #ddd", paddingBottom: 6 } }, title),
        React.createElement("table", { style: { fontSize: 12 } },
            React.createElement("tbody", null, rows.map(([key, value]) => (React.createElement("tr", { key: key },
                React.createElement("td", { style: { padding: "3px 0", color: "#666", fontWeight: 500, width: "45%" } }, key),
                React.createElement("td", { style: { padding: "3px 0", color: "#333" } }, displayValue(value)))))))));
}
// ===================== إنشاء فاتورة: جميع الحقول اختيارية =====================
function InvoiceForm({ invoices, customers, policies, company, setPage, notify, onSaveInvoice }) {
    const nextInvoiceNumber = `INV-${new Date().getFullYear()}-${String(invoices.length + 1).padStart(4, "0")}`;
    const [saving, setSaving] = useState(false);
    const [form, setForm] = useState({
        invoiceNo: nextInvoiceNumber,
        customerId: "",
        policyNo: "",
        endorsementNo: "",
        date: new Date().toISOString().slice(0, 10),
        description: "",
        amount: "",
        vatRate: safeNumber(company.vatRate),
        mobile: "",
        email: "",
        address: "",
    });
    const amount = safeNumber(form.amount);
    const vatRate = safeNumber(form.vatRate);
    const vatAmount = amount * vatRate / 100;
    const total = amount + vatAmount;
    const setField = (name, value) => setForm((previous) => ({ ...previous, [name]: value }));
    const onCustomerChange = (value) => {
        const customer = customers.find((item) => item.id === optionalInteger(value));
        setForm((previous) => ({
            ...previous,
            customerId: value,
            mobile: customer ? safeText(customer.mobile) : previous.mobile,
            email: customer ? safeText(customer.email) : previous.email,
            address: customer ? safeText(customer.address) : previous.address,
        }));
    };
    const handleSubmit = async () => {
        try {
            setSaving(true);
            await onSaveInvoice({
                ...form,
                customerId: optionalInteger(form.customerId),
                amount,
                vatRate,
            });
            notify("تم حفظ الفاتورة في قاعدة البيانات بنجاح");
            setPage("invoices");
        }
        catch (error) {
            notify(error.message, "error");
        }
        finally {
            setSaving(false);
        }
    };
    return (React.createElement("div", null,
        React.createElement("div", { style: { display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12, flexWrap: "wrap", marginBottom: 20 } },
            React.createElement("h2", { className: "page-title" }, "\u0625\u0646\u0634\u0627\u0621 \u0641\u0627\u062A\u0648\u0631\u0629 \u062C\u062F\u064A\u062F\u0629"),
            React.createElement("button", { onClick: () => setPage("invoices"), className: "btn-secondary" },
                React.createElement("i", { className: "fas fa-arrow-right" }),
                " \u0627\u0644\u0639\u0648\u062F\u0629")),
        React.createElement("div", { className: "card", style: { padding: 24 } },
            React.createElement("div", { style: { background: "#f0f8ff", border: "1px solid #2980b9", borderRadius: 8, padding: "10px 14px", marginBottom: 12, fontSize: 13, color: "var(--primary)", fontWeight: 500 } },
                "\u0631\u0642\u0645 \u0627\u0644\u0641\u0627\u062A\u0648\u0631\u0629 \u0627\u0644\u062A\u0644\u0642\u0627\u0626\u064A: ",
                React.createElement("strong", null, form.invoiceNo)),
            React.createElement("div", { style: { background: "var(--success-bg)", border: "1px solid var(--success)", color: "#1e8449", borderRadius: 8, padding: "9px 14px", marginBottom: 20, fontSize: 12 } }, "\u062C\u0645\u064A\u0639 \u0628\u064A\u0627\u0646\u0627\u062A \u0627\u0644\u0641\u0627\u062A\u0648\u0631\u0629 \u0627\u062E\u062A\u064A\u0627\u0631\u064A\u0629\u060C \u0648\u064A\u0645\u0643\u0646\u0643 \u0627\u0644\u062D\u0641\u0638 \u062D\u062A\u0649 \u0639\u0646\u062F \u062A\u0631\u0643 \u0627\u0644\u062D\u0642\u0648\u0644 \u0641\u0627\u0631\u063A\u0629."),
            React.createElement("div", { className: "form-grid-2" },
                React.createElement(Field, { label: "\u0627\u0644\u0639\u0645\u064A\u0644" },
                    React.createElement("select", { className: "form-control", value: form.customerId, onChange: (event) => onCustomerChange(event.target.value) },
                        React.createElement("option", { value: "" }, "-- \u0628\u062F\u0648\u0646 \u0627\u062E\u062A\u064A\u0627\u0631 --"),
                        customers.map((customer) => React.createElement("option", { key: customer.id, value: customer.id }, displayValue(customer.name))))),
                React.createElement(Field, { label: "\u0631\u0642\u0645 \u0627\u0644\u0648\u062B\u064A\u0642\u0629" },
                    React.createElement("select", { className: "form-control", value: form.policyNo, onChange: (event) => setField("policyNo", event.target.value) },
                        React.createElement("option", { value: "" }, "-- \u0628\u062F\u0648\u0646 \u0627\u062E\u062A\u064A\u0627\u0631 --"),
                        policies
                            .filter((policy) => !form.customerId || policy.customerId === optionalInteger(form.customerId))
                            .map((policy) => (React.createElement("option", { key: policy.id, value: safeText(policy.policyNo) },
                            displayValue(policy.policyNo),
                            " - ",
                            displayValue(policy.type))))))),
            React.createElement("div", { className: "form-grid-2" },
                React.createElement(TextField, { label: "\u0631\u0642\u0645 \u0627\u0644\u062A\u0623\u0634\u064A\u0631\u0629 / \u0627\u0644\u062A\u0648\u062B\u064A\u0642", value: form.endorsementNo, onChange: (value) => setField("endorsementNo", value), placeholder: "\u0645\u062B\u0627\u0644: END-001" }),
                React.createElement(TextField, { label: "\u062A\u0627\u0631\u064A\u062E \u0627\u0644\u0641\u0627\u062A\u0648\u0631\u0629", type: "date", value: form.date, onChange: (value) => setField("date", value) })),
            React.createElement(Field, { label: "\u0627\u0644\u0628\u064A\u0627\u0646 / \u0627\u0644\u0648\u0635\u0641", style: { marginBottom: 14 } },
                React.createElement("textarea", { className: "form-control", value: form.description, onChange: (event) => setField("description", event.target.value), rows: "2", placeholder: "\u0645\u062B\u0627\u0644: \u0642\u0633\u0637 \u0627\u0644\u062A\u0623\u0645\u064A\u0646 \u0627\u0644\u0637\u0628\u064A \u0627\u0644\u062C\u0645\u0627\u0639\u064A \u0644\u0644\u0631\u0628\u0639 \u0627\u0644\u0623\u0648\u0644", style: { resize: "vertical" } })),
            React.createElement("div", { className: "form-grid-2" },
                React.createElement(TextField, { label: "\u0627\u0644\u0645\u0628\u0644\u063A (\u0631\u064A\u0627\u0644)", type: "number", value: form.amount, onChange: (value) => setField("amount", value), placeholder: "0.00", min: "0", step: "0.01" }),
                React.createElement(TextField, { label: "\u0646\u0633\u0628\u0629 \u0636\u0631\u064A\u0628\u0629 \u0627\u0644\u0642\u064A\u0645\u0629 \u0627\u0644\u0645\u0636\u0627\u0641\u0629 (%)", type: "number", value: form.vatRate, onChange: (value) => setField("vatRate", value), min: "0", max: "100", step: "0.01" })),
            React.createElement("div", { style: { background: "var(--background-secondary)", border: "1px solid var(--border)", borderRadius: 8, padding: "14px 16px", marginBottom: 16, display: "grid", gridTemplateColumns: "repeat(3, 1fr)", gap: 12 } },
                React.createElement(AmountSummary, { label: "\u0645\u0628\u0644\u063A \u0627\u0644\u0636\u0631\u064A\u0628\u0629", value: vatAmount, color: "#8e44ad" }),
                React.createElement(AmountSummary, { label: "\u0627\u0644\u0645\u0628\u0644\u063A \u0642\u0628\u0644 \u0627\u0644\u0636\u0631\u064A\u0628\u0629", value: amount }),
                React.createElement(AmountSummary, { label: "\u0627\u0644\u0625\u062C\u0645\u0627\u0644\u064A \u0634\u0627\u0645\u0644 \u0627\u0644\u0636\u0631\u064A\u0628\u0629", value: total, color: "var(--success)", large: true })),
            React.createElement("div", { className: "form-grid-2" },
                React.createElement(TextField, { label: "\u0631\u0642\u0645 \u0627\u0644\u062C\u0648\u0627\u0644", type: "tel", value: form.mobile, onChange: (value) => setField("mobile", value), placeholder: "05XXXXXXXX" }),
                React.createElement(TextField, { label: "\u0627\u0644\u0628\u0631\u064A\u062F \u0627\u0644\u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A", type: "email", value: form.email, onChange: (value) => setField("email", value), placeholder: "example@domain.com" })),
            React.createElement(TextField, { label: "\u0627\u0644\u0639\u0646\u0648\u0627\u0646", value: form.address, onChange: (value) => setField("address", value), placeholder: "\u0627\u0644\u0645\u062F\u064A\u0646\u0629 - \u0627\u0644\u062D\u064A", style: { marginBottom: 20 } }),
            React.createElement("div", { style: { display: "flex", gap: 10, justifyContent: "flex-end", flexWrap: "wrap" } },
                React.createElement("button", { onClick: () => setPage("invoices"), className: "btn-secondary" }, "\u0625\u0644\u063A\u0627\u0621"),
                React.createElement("button", { disabled: saving, onClick: handleSubmit, className: "btn-primary", style: { padding: "10px 24px", fontSize: 14, fontWeight: 600 } },
                    React.createElement("i", { className: `fas ${saving ? "fa-spinner fa-spin" : "fa-check"}` }),
                    " ",
                    saving ? "جاري الحفظ..." : "حفظ الفاتورة")))));
}
function Field({ label, children, style = {} }) {
    return (React.createElement("div", { style: style },
        React.createElement("label", { className: "form-label" }, label),
        children));
}
function TextField({ label, value, onChange, type = "text", placeholder = "", style = {}, ...inputProps }) {
    return (React.createElement(Field, { label: label, style: style },
        React.createElement("input", { className: "form-control", type: type, value: value !== null && value !== void 0 ? value : "", onChange: (event) => onChange(event.target.value), placeholder: placeholder, ...inputProps })));
}
function AmountSummary({ label, value, color = "var(--text-primary)", large = false }) {
    return (React.createElement("div", { style: { textAlign: "center" } },
        React.createElement("div", { style: { fontSize: 12, color: "#666", marginBottom: 4 } }, label),
        React.createElement("div", { style: { fontSize: large ? 18 : 16, fontWeight: 700, color } }, formatCurrency(value))));
}
// ===================== إدارة العملاء: كل الحقول اختيارية =====================
function CustomerManager({ customers, notify, onSaveCustomer, onDeleteCustomer }) {
    const emptyForm = { name: "", vat: "", cr: "", mobile: "", email: "", address: "" };
    const [form, setForm] = useState(emptyForm);
    const [editing, setEditing] = useState(null);
    const [showForm, setShowForm] = useState(false);
    const [saving, setSaving] = useState(false);
    const resetForm = () => {
        setForm(emptyForm);
        setEditing(null);
        setShowForm(false);
    };
    const handleSave = async () => {
        try {
            setSaving(true);
            await onSaveCustomer(form, editing);
            notify(editing !== null ? "تم تعديل العميل في قاعدة البيانات" : "تمت إضافة العميل إلى قاعدة البيانات");
            resetForm();
        }
        catch (error) {
            notify(error.message, "error");
        }
        finally {
            setSaving(false);
        }
    };
    const handleEdit = (customer) => {
        setForm({
            name: safeText(customer.name),
            vat: safeText(customer.vat),
            cr: safeText(customer.cr),
            mobile: safeText(customer.mobile),
            email: safeText(customer.email),
            address: safeText(customer.address),
        });
        setEditing(customer.id);
        setShowForm(true);
    };
    const handleDelete = async (id) => {
        if (!window.confirm("هل تريد حذف هذا العميل؟ ستبقى فواتيره ووثائقه محفوظة بدون ربط بالعميل."))
            return;
        try {
            await onDeleteCustomer(id);
            notify("تم حذف العميل من قاعدة البيانات");
        }
        catch (error) {
            notify(error.message, "error");
        }
    };
    return (React.createElement("div", null,
        React.createElement("div", { style: { display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12, flexWrap: "wrap", marginBottom: 20 } },
            React.createElement("h2", { className: "page-title" }, "\u0625\u062F\u0627\u0631\u0629 \u0627\u0644\u0639\u0645\u0644\u0627\u0621"),
            React.createElement("button", { onClick: () => {
                    if (showForm)
                        resetForm();
                    else {
                        setForm(emptyForm);
                        setEditing(null);
                        setShowForm(true);
                    }
                }, className: "btn-primary" },
                React.createElement("i", { className: "fas fa-plus" }),
                " \u0625\u0636\u0627\u0641\u0629 \u0639\u0645\u064A\u0644")),
        showForm && (React.createElement("div", { className: "card", style: { padding: 20, marginBottom: 16 } },
            React.createElement("h3", { style: { margin: "0 0 10px", fontSize: 16 } }, editing !== null ? "تعديل عميل" : "إضافة عميل جديد"),
            React.createElement("div", { style: { background: "var(--success-bg)", border: "1px solid var(--success)", color: "#1e8449", borderRadius: 8, padding: "8px 12px", marginBottom: 14, fontSize: 12 } }, "\u062C\u0645\u064A\u0639 \u0628\u064A\u0627\u0646\u0627\u062A \u0627\u0644\u0639\u0645\u064A\u0644 \u0627\u062E\u062A\u064A\u0627\u0631\u064A\u0629."),
            React.createElement("div", { className: "form-grid-3" },
                React.createElement(TextField, { label: "\u0627\u0633\u0645 \u0627\u0644\u0639\u0645\u064A\u0644", value: form.name, onChange: (value) => setForm((previous) => ({ ...previous, name: value })) }),
                React.createElement(TextField, { label: "\u0627\u0644\u0631\u0642\u0645 \u0627\u0644\u0636\u0631\u064A\u0628\u064A", value: form.vat, onChange: (value) => setForm((previous) => ({ ...previous, vat: value })) }),
                React.createElement(TextField, { label: "\u0627\u0644\u0633\u062C\u0644 \u0627\u0644\u062A\u062C\u0627\u0631\u064A", value: form.cr, onChange: (value) => setForm((previous) => ({ ...previous, cr: value })) }),
                React.createElement(TextField, { label: "\u0631\u0642\u0645 \u0627\u0644\u062C\u0648\u0627\u0644", type: "tel", value: form.mobile, onChange: (value) => setForm((previous) => ({ ...previous, mobile: value })) }),
                React.createElement(TextField, { label: "\u0627\u0644\u0628\u0631\u064A\u062F \u0627\u0644\u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A", type: "email", value: form.email, onChange: (value) => setForm((previous) => ({ ...previous, email: value })) }),
                React.createElement(TextField, { label: "\u0627\u0644\u0639\u0646\u0648\u0627\u0646", value: form.address, onChange: (value) => setForm((previous) => ({ ...previous, address: value })) })),
            React.createElement("div", { style: { display: "flex", gap: 8 } },
                React.createElement("button", { disabled: saving, onClick: handleSave, className: "btn-primary" }, saving ? "جاري الحفظ..." : "حفظ"),
                React.createElement("button", { onClick: resetForm, className: "btn-secondary" }, "\u0625\u0644\u063A\u0627\u0621")))),
        React.createElement("div", { className: "card", style: { overflow: "hidden" } },
            React.createElement("div", { className: "table-wrap" },
                React.createElement("table", { style: { fontSize: 13 } },
                    React.createElement("thead", null,
                        React.createElement("tr", { style: { background: "var(--primary)", color: "#fff" } }, ["الاسم", "الرقم الضريبي", "السجل التجاري", "الجوال", "البريد", "العنوان", ""].map((heading) => (React.createElement("th", { key: heading, style: { padding: "10px 14px", textAlign: "right", fontWeight: 500, fontSize: 12, whiteSpace: "nowrap" } }, heading))))),
                    React.createElement("tbody", null, customers.map((customer) => (React.createElement("tr", { key: customer.id, style: { borderBottom: "1px solid var(--border)" } },
                        React.createElement("td", { style: { padding: "10px 14px", fontWeight: 600 } }, displayValue(customer.name)),
                        React.createElement("td", { style: { padding: "10px 14px", color: "var(--text-secondary)" } }, displayValue(customer.vat)),
                        React.createElement("td", { style: { padding: "10px 14px", color: "var(--text-secondary)" } }, displayValue(customer.cr)),
                        React.createElement("td", { style: { padding: "10px 14px" } }, displayValue(customer.mobile)),
                        React.createElement("td", { style: { padding: "10px 14px", color: "var(--text-secondary)", fontSize: 12 } }, displayValue(customer.email)),
                        React.createElement("td", { style: { padding: "10px 14px", color: "var(--text-secondary)", fontSize: 12 } }, displayValue(customer.address)),
                        React.createElement("td", { style: { padding: "10px 14px" } },
                            React.createElement("div", { style: { display: "flex", gap: 6 } },
                                React.createElement("button", { onClick: () => handleEdit(customer), style: { padding: "5px 9px", background: "#ebf5fb", color: "#2980b9", border: "none", borderRadius: 5 } },
                                    React.createElement("i", { className: "fas fa-edit" })),
                                React.createElement("button", { onClick: () => handleDelete(customer.id), style: { padding: "5px 9px", background: "var(--danger-bg)", color: "var(--danger)", border: "none", borderRadius: 5 } },
                                    React.createElement("i", { className: "fas fa-trash" })))))))))))));
}
// ===================== إدارة الوثائق: كل الحقول اختيارية =====================
function PolicyManager({ policies, customers, notify, onSavePolicy, onDeletePolicy }) {
    const emptyForm = { customerId: "", policyNo: "", type: "", startDate: "", endDate: "", premium: "" };
    const [form, setForm] = useState(emptyForm);
    const [showForm, setShowForm] = useState(false);
    const [editing, setEditing] = useState(null);
    const [saving, setSaving] = useState(false);
    const types = ["تأمين طبي جماعي", "تأمين طبي مميز", "تأمين طبي شامل", "تأمين طبي أساسي", "تأمين طبي تكميلي"];
    const getCustomer = (id) => customers.find((customer) => customer.id === id) || {};
    const resetForm = () => {
        setForm(emptyForm);
        setEditing(null);
        setShowForm(false);
    };
    const handleSave = async () => {
        try {
            setSaving(true);
            await onSavePolicy({
                ...form,
                customerId: optionalInteger(form.customerId),
                premium: safeNumber(form.premium),
            }, editing);
            notify(editing !== null ? "تم تعديل الوثيقة في قاعدة البيانات" : "تمت إضافة الوثيقة إلى قاعدة البيانات");
            resetForm();
        }
        catch (error) {
            notify(error.message, "error");
        }
        finally {
            setSaving(false);
        }
    };
    const handleDelete = async (id) => {
        if (!window.confirm("هل تريد حذف هذه الوثيقة؟"))
            return;
        try {
            await onDeletePolicy(id);
            notify("تم حذف الوثيقة من قاعدة البيانات");
        }
        catch (error) {
            notify(error.message, "error");
        }
    };
    return (React.createElement("div", null,
        React.createElement("div", { style: { display: "flex", alignItems: "center", justifyContent: "space-between", gap: 12, flexWrap: "wrap", marginBottom: 20 } },
            React.createElement("h2", { className: "page-title" }, "\u0625\u062F\u0627\u0631\u0629 \u0648\u062B\u0627\u0626\u0642 \u0627\u0644\u062A\u0623\u0645\u064A\u0646"),
            React.createElement("button", { onClick: () => {
                    if (showForm)
                        resetForm();
                    else {
                        setForm(emptyForm);
                        setEditing(null);
                        setShowForm(true);
                    }
                }, className: "btn-primary" },
                React.createElement("i", { className: "fas fa-plus" }),
                " \u0625\u0636\u0627\u0641\u0629 \u0648\u062B\u064A\u0642\u0629")),
        showForm && (React.createElement("div", { className: "card", style: { padding: 20, marginBottom: 16 } },
            React.createElement("h3", { style: { margin: "0 0 10px", fontSize: 16 } }, editing !== null ? "تعديل وثيقة" : "إضافة وثيقة جديدة"),
            React.createElement("div", { style: { background: "var(--success-bg)", border: "1px solid var(--success)", color: "#1e8449", borderRadius: 8, padding: "8px 12px", marginBottom: 14, fontSize: 12 } }, "\u062C\u0645\u064A\u0639 \u0628\u064A\u0627\u0646\u0627\u062A \u0627\u0644\u0648\u062B\u064A\u0642\u0629 \u0627\u062E\u062A\u064A\u0627\u0631\u064A\u0629."),
            React.createElement("div", { className: "form-grid-3" },
                React.createElement(Field, { label: "\u0627\u0644\u0639\u0645\u064A\u0644" },
                    React.createElement("select", { className: "form-control", value: form.customerId, onChange: (event) => setForm((previous) => ({ ...previous, customerId: event.target.value })) },
                        React.createElement("option", { value: "" }, "-- \u0628\u062F\u0648\u0646 \u0627\u062E\u062A\u064A\u0627\u0631 --"),
                        customers.map((customer) => React.createElement("option", { key: customer.id, value: customer.id }, displayValue(customer.name))))),
                React.createElement(TextField, { label: "\u0631\u0642\u0645 \u0627\u0644\u0648\u062B\u064A\u0642\u0629", value: form.policyNo, onChange: (value) => setForm((previous) => ({ ...previous, policyNo: value })) }),
                React.createElement(Field, { label: "\u0646\u0648\u0639 \u0627\u0644\u062A\u0623\u0645\u064A\u0646" },
                    React.createElement("select", { className: "form-control", value: form.type, onChange: (event) => setForm((previous) => ({ ...previous, type: event.target.value })) },
                        React.createElement("option", { value: "" }, "-- \u0628\u062F\u0648\u0646 \u0627\u062E\u062A\u064A\u0627\u0631 --"),
                        types.map((type) => React.createElement("option", { key: type, value: type }, type)))),
                React.createElement(TextField, { label: "\u062A\u0627\u0631\u064A\u062E \u0627\u0644\u0628\u062F\u0627\u064A\u0629", type: "date", value: form.startDate, onChange: (value) => setForm((previous) => ({ ...previous, startDate: value })) }),
                React.createElement(TextField, { label: "\u062A\u0627\u0631\u064A\u062E \u0627\u0644\u0646\u0647\u0627\u064A\u0629", type: "date", value: form.endDate, onChange: (value) => setForm((previous) => ({ ...previous, endDate: value })) }),
                React.createElement(TextField, { label: "\u0627\u0644\u0642\u0633\u0637 \u0627\u0644\u0633\u0646\u0648\u064A", type: "number", value: form.premium, onChange: (value) => setForm((previous) => ({ ...previous, premium: value })), min: "0", step: "0.01" })),
            React.createElement("div", { style: { display: "flex", gap: 8 } },
                React.createElement("button", { disabled: saving, onClick: handleSave, className: "btn-primary" }, saving ? "جاري الحفظ..." : "حفظ"),
                React.createElement("button", { onClick: resetForm, className: "btn-secondary" }, "\u0625\u0644\u063A\u0627\u0621")))),
        React.createElement("div", { className: "card", style: { overflow: "hidden" } },
            React.createElement("div", { className: "table-wrap" },
                React.createElement("table", { style: { fontSize: 13 } },
                    React.createElement("thead", null,
                        React.createElement("tr", { style: { background: "var(--primary)", color: "#fff" } }, ["رقم الوثيقة", "نوع التأمين", "العميل", "تاريخ البداية", "تاريخ النهاية", "القسط السنوي", ""].map((heading) => (React.createElement("th", { key: heading, style: { padding: "10px 14px", textAlign: "right", fontWeight: 500, fontSize: 12, whiteSpace: "nowrap" } }, heading))))),
                    React.createElement("tbody", null, policies.map((policy) => {
                        const customer = getCustomer(policy.customerId);
                        return (React.createElement("tr", { key: policy.id, style: { borderBottom: "1px solid var(--border)" } },
                            React.createElement("td", { style: { padding: "10px 14px", fontWeight: 600, color: "#2980b9" } }, displayValue(policy.policyNo)),
                            React.createElement("td", { style: { padding: "10px 14px" } }, displayValue(policy.type)),
                            React.createElement("td", { style: { padding: "10px 14px" } }, displayValue(customer.name)),
                            React.createElement("td", { style: { padding: "10px 14px", color: "var(--text-secondary)" } }, displayValue(policy.startDate)),
                            React.createElement("td", { style: { padding: "10px 14px", color: "var(--text-secondary)" } }, displayValue(policy.endDate)),
                            React.createElement("td", { style: { padding: "10px 14px", fontWeight: 600, color: "var(--success)" } }, formatCurrency(policy.premium)),
                            React.createElement("td", { style: { padding: "10px 14px" } },
                                React.createElement("div", { style: { display: "flex", gap: 6 } },
                                    React.createElement("button", { onClick: () => {
                                            var _a;
                                            setForm({
                                                customerId: (_a = policy.customerId) !== null && _a !== void 0 ? _a : "",
                                                policyNo: safeText(policy.policyNo),
                                                type: safeText(policy.type),
                                                startDate: safeText(policy.startDate),
                                                endDate: safeText(policy.endDate),
                                                premium: safeText(policy.premium),
                                            });
                                            setEditing(policy.id);
                                            setShowForm(true);
                                        }, style: { padding: "5px 9px", background: "#ebf5fb", color: "#2980b9", border: "none", borderRadius: 5 } },
                                        React.createElement("i", { className: "fas fa-edit" })),
                                    React.createElement("button", { onClick: () => handleDelete(policy.id), style: { padding: "5px 9px", background: "var(--danger-bg)", color: "var(--danger)", border: "none", borderRadius: 5 } },
                                        React.createElement("i", { className: "fas fa-trash" }))))));
                    })))))));
}
// ===================== إعدادات الشركة =====================
function CompanySettings({ company, notify, onSaveCompany }) {
    var _a;
    const [form, setForm] = useState(company);
    const [saving, setSaving] = useState(false);
    const setField = (name, value) => setForm((previous) => ({ ...previous, [name]: value }));
    const readImage = (event, fieldName) => {
        var _a;
        const file = (_a = event.target.files) === null || _a === void 0 ? void 0 : _a[0];
        if (!file)
            return;
        const reader = new FileReader();
        reader.onload = (loadEvent) => setField(fieldName, loadEvent.target.result);
        reader.readAsDataURL(file);
    };
    const handleSave = async () => {
        try {
            setSaving(true);
            const saved = await onSaveCompany({
                ...form,
                vatRate: safeNumber(form.vatRate),
                logoSize: safeNumber(form.logoSize, 80),
                stampSize: safeNumber(form.stampSize, 100),
                stampX: safeNumber(form.stampX, 70),
                stampY: safeNumber(form.stampY, 60),
            });
            setForm({ ...defaultCompany, ...saved });
            notify("تم حفظ إعدادات الشركة في قاعدة البيانات بنجاح");
        }
        catch (error) {
            notify(error.message, "error");
        }
        finally {
            setSaving(false);
        }
    };
    const SectionTitle = ({ children }) => (React.createElement("div", { style: { fontSize: 14, fontWeight: 700, color: "var(--primary)", borderBottom: "2px solid var(--primary)", paddingBottom: 6, marginBottom: 14, marginTop: 20 } }, children));
    return (React.createElement("div", null,
        React.createElement("h2", { className: "page-title", style: { marginBottom: 20 } }, "\u0625\u0639\u062F\u0627\u062F\u0627\u062A \u0627\u0644\u0634\u0631\u0643\u0629"),
        React.createElement("div", { className: "card", style: { padding: 24 } },
            React.createElement("div", { style: { background: "var(--success-bg)", border: "1px solid var(--success)", color: "#1e8449", borderRadius: 8, padding: "8px 12px", marginBottom: 14, fontSize: 12 } }, "\u062C\u0645\u064A\u0639 \u0625\u0639\u062F\u0627\u062F\u0627\u062A \u0627\u0644\u0634\u0631\u0643\u0629 \u0627\u062E\u062A\u064A\u0627\u0631\u064A\u0629 \u0648\u064A\u0645\u0643\u0646 \u062D\u0641\u0638\u0647\u0627 \u0641\u0627\u0631\u063A\u0629."),
            React.createElement(SectionTitle, null, "\u0645\u0639\u0644\u0648\u0645\u0627\u062A \u0627\u0644\u0634\u0631\u0643\u0629"),
            React.createElement("div", { className: "form-grid-2" },
                React.createElement(TextField, { label: "\u0627\u0633\u0645 \u0627\u0644\u0634\u0631\u0643\u0629 (\u0639\u0631\u0628\u064A)", value: form.nameAr, onChange: (value) => setField("nameAr", value) }),
                React.createElement(TextField, { label: "\u0627\u0633\u0645 \u0627\u0644\u0634\u0631\u0643\u0629 (\u0625\u0646\u062C\u0644\u064A\u0632\u064A)", value: form.nameEn, onChange: (value) => setField("nameEn", value) }),
                React.createElement(TextField, { label: "\u0627\u0644\u0631\u0642\u0645 \u0627\u0644\u0636\u0631\u064A\u0628\u064A", value: form.vat, onChange: (value) => setField("vat", value) }),
                React.createElement(TextField, { label: "\u0627\u0644\u0633\u062C\u0644 \u0627\u0644\u062A\u062C\u0627\u0631\u064A", value: form.cr, onChange: (value) => setField("cr", value) }),
                React.createElement(TextField, { label: "\u0631\u0642\u0645 \u0627\u0644\u0647\u0627\u062A\u0641", type: "tel", value: form.phone, onChange: (value) => setField("phone", value) }),
                React.createElement(TextField, { label: "\u0627\u0644\u0628\u0631\u064A\u062F \u0627\u0644\u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A", type: "email", value: form.email, onChange: (value) => setField("email", value) }),
                React.createElement(TextField, { label: "\u0627\u0644\u0645\u0648\u0642\u0639 \u0627\u0644\u0625\u0644\u0643\u062A\u0631\u0648\u0646\u064A", value: form.website, onChange: (value) => setField("website", value) }),
                React.createElement(TextField, { label: "\u0646\u0633\u0628\u0629 \u0636\u0631\u064A\u0628\u0629 \u0627\u0644\u0642\u064A\u0645\u0629 \u0627\u0644\u0645\u0636\u0627\u0641\u0629 (%)", type: "number", value: form.vatRate, onChange: (value) => setField("vatRate", value) })),
            React.createElement(TextField, { label: "\u0627\u0644\u0639\u0646\u0648\u0627\u0646", value: form.address, onChange: (value) => setField("address", value), style: { marginBottom: 14 } }),
            React.createElement(Field, { label: "\u0646\u0635 \u062A\u0630\u064A\u064A\u0644 \u0627\u0644\u0641\u0627\u062A\u0648\u0631\u0629", style: { marginBottom: 14 } },
                React.createElement("textarea", { className: "form-control", value: (_a = form.footerText) !== null && _a !== void 0 ? _a : "", onChange: (event) => setField("footerText", event.target.value), rows: "2", style: { resize: "vertical" } })),
            React.createElement(SectionTitle, null, "\u0627\u0644\u0634\u0639\u0627\u0631 (Logo)"),
            React.createElement("div", { className: "form-grid-2" },
                React.createElement("div", null,
                    React.createElement("label", { className: "form-label" }, "\u0631\u0641\u0639 \u0627\u0644\u0634\u0639\u0627\u0631"),
                    React.createElement("input", { type: "file", accept: "image/*", onChange: (event) => readImage(event, "logo"), style: { fontSize: 13 } }),
                    form.logo && React.createElement("img", { src: form.logo, alt: "\u0634\u0639\u0627\u0631", style: { height: 60, maxWidth: 180, objectFit: "contain", display: "block", marginTop: 8, borderRadius: 6, border: "1px solid #ddd" } })),
                React.createElement("div", { className: "form-grid-2", style: { marginBottom: 0 } },
                    React.createElement(TextField, { label: "\u0627\u0644\u062D\u062C\u0645 (px)", type: "number", value: form.logoSize, onChange: (value) => setField("logoSize", value) }),
                    React.createElement("div", { style: { display: "flex", alignItems: "center", gap: 8, paddingTop: 25 } },
                        React.createElement("input", { type: "checkbox", id: "logoEnabled", checked: Boolean(form.logoEnabled), onChange: (event) => setField("logoEnabled", event.target.checked) }),
                        React.createElement("label", { htmlFor: "logoEnabled", style: { fontSize: 13 } }, "\u062A\u0641\u0639\u064A\u0644 \u0627\u0644\u0634\u0639\u0627\u0631")))),
            React.createElement(SectionTitle, null, "\u0627\u0644\u062E\u062A\u0645 \u0627\u0644\u0631\u0633\u0645\u064A (Stamp)"),
            React.createElement("div", { className: "form-grid-2" },
                React.createElement("div", null,
                    React.createElement("label", { className: "form-label" }, "\u0631\u0641\u0639 \u0627\u0644\u062E\u062A\u0645"),
                    React.createElement("input", { type: "file", accept: "image/*", onChange: (event) => readImage(event, "stamp"), style: { fontSize: 13 } }),
                    form.stamp && React.createElement("img", { src: form.stamp, alt: "\u062E\u062A\u0645", style: { height: 80, maxWidth: 180, objectFit: "contain", display: "block", marginTop: 8, borderRadius: 6, border: "1px solid #ddd", opacity: 0.75 } })),
                React.createElement("div", { className: "form-grid-2", style: { marginBottom: 0 } },
                    React.createElement(TextField, { label: "\u062D\u062C\u0645 \u0627\u0644\u062E\u062A\u0645 (px)", type: "number", value: form.stampSize, onChange: (value) => setField("stampSize", value) }),
                    React.createElement(TextField, { label: "\u0645\u0648\u0636\u0639 \u0623\u0641\u0642\u064A (%)", type: "number", value: form.stampX, onChange: (value) => setField("stampX", value) }),
                    React.createElement(TextField, { label: "\u0645\u0648\u0636\u0639 \u0631\u0623\u0633\u064A (%)", type: "number", value: form.stampY, onChange: (value) => setField("stampY", value) }),
                    React.createElement("div", { style: { display: "flex", alignItems: "center", gap: 8, paddingTop: 25 } },
                        React.createElement("input", { type: "checkbox", id: "stampEnabled", checked: Boolean(form.stampEnabled), onChange: (event) => setField("stampEnabled", event.target.checked) }),
                        React.createElement("label", { htmlFor: "stampEnabled", style: { fontSize: 13 } }, "\u062A\u0641\u0639\u064A\u0644 \u0627\u0644\u062E\u062A\u0645")))),
            React.createElement("button", { disabled: saving, onClick: handleSave, className: "btn-primary", style: { padding: "10px 28px", fontSize: 14, fontWeight: 600 } },
                React.createElement("i", { className: `fas ${saving ? "fa-spinner fa-spin" : "fa-save"}` }),
                " ",
                saving ? "جاري الحفظ..." : "حفظ الإعدادات"))));
}
// ===================== تغيير كلمة المرور =====================
function PasswordManager({ notify, onChangePassword }) {
    const [form, setForm] = useState({ currentPassword: "", newPassword: "", confirmPassword: "" });
    const [saving, setSaving] = useState(false);
    const handleSubmit = async () => {
        try {
            setSaving(true);
            await onChangePassword(form);
            setForm({ currentPassword: "", newPassword: "", confirmPassword: "" });
            notify("تم تغيير كلمة المرور بنجاح");
        }
        catch (error) {
            notify(error.message, "error");
        }
        finally {
            setSaving(false);
        }
    };
    return (React.createElement("div", null,
        React.createElement("h2", { className: "page-title", style: { marginBottom: 20 } }, "\u062A\u063A\u064A\u064A\u0631 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631"),
        React.createElement("div", { className: "card", style: { padding: 24, maxWidth: 620 } },
            React.createElement("div", { style: { background: "#f0f8ff", border: "1px solid #2980b9", color: "var(--primary)", borderRadius: 8, padding: "10px 14px", marginBottom: 18, fontSize: 13 } }, "\u0628\u0639\u062F \u0631\u0641\u0639 \u0627\u0644\u0645\u0634\u0631\u0648\u0639 \u0627\u0633\u062A\u062E\u062F\u0645 \u0647\u0630\u0647 \u0627\u0644\u0635\u0641\u062D\u0629 \u0644\u062A\u063A\u064A\u064A\u0631 \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 \u0627\u0644\u0627\u0641\u062A\u0631\u0627\u0636\u064A\u0629 \u0645\u0628\u0627\u0634\u0631\u0629."),
            React.createElement(TextField, { label: "\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 \u0627\u0644\u062D\u0627\u0644\u064A\u0629", type: "password", value: form.currentPassword, onChange: (value) => setForm((previous) => ({ ...previous, currentPassword: value })) }),
            React.createElement(TextField, { label: "\u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 \u0627\u0644\u062C\u062F\u064A\u062F\u0629", type: "password", value: form.newPassword, onChange: (value) => setForm((previous) => ({ ...previous, newPassword: value })) }),
            React.createElement(TextField, { label: "\u062A\u0623\u0643\u064A\u062F \u0643\u0644\u0645\u0629 \u0627\u0644\u0645\u0631\u0648\u0631 \u0627\u0644\u062C\u062F\u064A\u062F\u0629", type: "password", value: form.confirmPassword, onChange: (value) => setForm((previous) => ({ ...previous, confirmPassword: value })), style: { marginBottom: 18 } }),
            React.createElement("button", { disabled: saving, onClick: handleSubmit, className: "btn-primary" },
                React.createElement("i", { className: `fas ${saving ? "fa-spinner fa-spin" : "fa-key"}` }),
                " ",
                saving ? "جاري التغيير..." : "تغيير كلمة المرور"))));
}
// ===================== سجل التدقيق =====================
function AuditLogView({ log }) {
    return (React.createElement("div", null,
        React.createElement("h2", { className: "page-title", style: { marginBottom: 20 } }, "\u0633\u062C\u0644 \u0627\u0644\u062A\u062F\u0642\u064A\u0642"),
        React.createElement("div", { className: "card", style: { overflow: "hidden" } }, log.length === 0 ? (React.createElement("div", { style: { padding: 40, textAlign: "center", color: "var(--text-secondary)" } }, "\u0644\u0627 \u062A\u0648\u062C\u062F \u0633\u062C\u0644\u0627\u062A \u0628\u0639\u062F")) : (React.createElement("div", { className: "table-wrap" },
            React.createElement("table", { style: { fontSize: 13 } },
                React.createElement("thead", null,
                    React.createElement("tr", { style: { background: "var(--primary)", color: "#fff" } }, ["المستخدم", "الإجراء", "التفاصيل", "التاريخ والوقت"].map((heading) => (React.createElement("th", { key: heading, style: { padding: "10px 14px", textAlign: "right", fontWeight: 500, fontSize: 12, whiteSpace: "nowrap" } }, heading))))),
                React.createElement("tbody", null, log.map((entry) => (React.createElement("tr", { key: entry.id, style: { borderBottom: "1px solid var(--border)" } },
                    React.createElement("td", { style: { padding: "10px 14px", fontWeight: 600 } }, displayValue(entry.user)),
                    React.createElement("td", { style: { padding: "10px 14px" } },
                        React.createElement("span", { style: { background: "#ebf5fb", color: "#2980b9", padding: "3px 8px", borderRadius: 4, fontSize: 12 } }, displayValue(entry.action))),
                    React.createElement("td", { style: { padding: "10px 14px", color: "var(--text-secondary)" } }, displayValue(entry.detail)),
                    React.createElement("td", { style: { padding: "10px 14px", color: "var(--text-secondary)", fontSize: 12 } }, new Date(entry.at).toLocaleString("ar-SA"))))))))))));
}
ReactDOM.createRoot(document.getElementById("root")).render(React.createElement(App, null));
