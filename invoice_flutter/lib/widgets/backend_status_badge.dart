import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../services/api_config.dart';

class BackendStatusBadge extends StatelessWidget {
  final InvoiceState state;
  final bool isDarkText;

  const BackendStatusBadge({
    super.key,
    required this.state,
    this.isDarkText = false,
  });

  void _showStatusDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) {
        return ListenableBuilder(
          listenable: state,
          builder: (context, _) {
            final isOnline = state.isBackendOnline;
            final isChecking = state.isCheckingBackend;
            final color = isChecking
                ? Colors.amber.shade700
                : (isOnline ? Colors.green.shade600 : Colors.red.shade600);

            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              title: Row(
                children: [
                  Icon(
                    isChecking
                        ? Icons.sync
                        : (isOnline ? Icons.cloud_done : Icons.cloud_off),
                    color: color,
                    size: 28,
                  ),
                  const SizedBox(width: 10),
                  const Text('حالة الباك إند', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: color.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(radius: 5, backgroundColor: color),
                          const SizedBox(width: 8),
                          Text(
                            isChecking
                                ? 'جاري التحقق من الاتصال...'
                                : (isOnline ? 'السيرفر متصل ويعمل' : 'السيرفر غير متصل / خطأ'),
                            style: TextStyle(
                              color: color,
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text('رابط السيرفر (API URL):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                    const SizedBox(height: 4),
                    SelectableText(
                      ApiConfig.baseUrl,
                      style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: Colors.black87),
                    ),
                    if (state.backendStatusMessage != null) ...[
                      const SizedBox(height: 16),
                      const Text('تفاصيل الاستجابة:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.grey)),
                      const SizedBox(height: 4),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: SelectableText(
                          state.backendStatusMessage!,
                          style: TextStyle(
                            fontSize: 12,
                            color: isOnline ? Colors.green.shade800 : Colors.red.shade800,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                OutlinedButton.icon(
                  onPressed: isChecking ? null : () => state.checkBackendStatus(),
                  icon: isChecking
                      ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                      : const Icon(Icons.refresh, size: 18),
                  label: const Text('إعادة الفحص الآن'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('إغلاق'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: state,
      builder: (context, _) {
        final isOnline = state.isBackendOnline;
        final isChecking = state.isCheckingBackend;

        final Color statusColor = isChecking
            ? Colors.amber.shade700
            : (isOnline ? const Color(0xFF27AE60) : const Color(0xFFE74C3C));

        final String label = isChecking
            ? 'فحص السيرفر...'
            : (isOnline ? 'الباك إند: متصل' : 'الباك إند: غير متصل');

        final IconData iconData = isChecking
            ? Icons.sync
            : (isOnline ? Icons.check_circle : Icons.error);

        return InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => _showStatusDialog(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            margin: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
            decoration: BoxDecoration(
              color: isDarkText
                  ? statusColor.withOpacity(0.12)
                  : Colors.white.withOpacity(0.18),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isDarkText ? statusColor.withOpacity(0.4) : Colors.white38,
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isChecking)
                  SizedBox(
                    width: 12,
                    height: 12,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: isDarkText ? statusColor : Colors.white,
                    ),
                  )
                else
                  Icon(
                    iconData,
                    size: 14,
                    color: isDarkText ? statusColor : (isOnline ? Colors.lightGreenAccent : Colors.redAccent.shade100),
                  ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDarkText ? statusColor : Colors.white,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

