import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../theme/colors.dart';
import '../stores/menu_store.dart';

class ScanPage extends StatefulWidget {
  const ScanPage({super.key});

  @override
  State<ScanPage> createState() => _ScanPageState();
}

class _ScanPageState extends State<ScanPage> {
  final MobileScannerController _controller = MobileScannerController();
  final ImagePicker _picker = ImagePicker();
  bool _isProcessing = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    if (_isProcessing) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode == null || barcode.rawValue == null) return;

    final value = barcode.rawValue!;

    // 检查是否是我们的菜单二维码
    if (value.startsWith('meishi://menu?ids=')) {
      _isProcessing = true;
      _processMenuQr(value);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
      if (image == null) return;

      setState(() => _isProcessing = true);

      // 使用 MobileScanner 分析图片
      final result = await _controller.analyzeImage(image.path);

      if (result == null || result.barcodes.isEmpty) {
        _showError('未识别到二维码');
        return;
      }

      final barcode = result.barcodes.first;
      if (barcode.rawValue == null) {
        _showError('二维码内容为空');
        return;
      }

      final value = barcode.rawValue!;

      if (value.startsWith('meishi://menu?ids=')) {
        _processMenuQr(value);
      } else {
        _showError('不是有效的菜单二维码');
      }
    } catch (e) {
      _showError('识别失败: $e');
    }
  }

  void _processMenuQr(String qrData) {
    try {
      // 解析 meishi://menu?ids=id1,id2,id3
      final uri = Uri.parse(qrData);
      final idsStr = uri.queryParameters['ids'];

      if (idsStr == null || idsStr.isEmpty) {
        _showError('无效的二维码');
        return;
      }

      final ids = idsStr.split(',').where((id) => id.isNotEmpty).toList();

      if (ids.isEmpty) {
        _showError('菜单为空');
        return;
      }

      // 显示确认对话框
      _showImportDialog(ids);
    } catch (e) {
      _showError('解析失败');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
    setState(() => _isProcessing = false);
  }

  void _showImportDialog(List<String> ids) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('导入菜单'),
        content: Text('发现 ${ids.length} 道菜，是否导入到今日菜单？'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              setState(() => _isProcessing = false);
            },
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _importMenu(ids);
            },
            child: const Text(
              '导入',
              style: TextStyle(color: AppColors.primary),
            ),
          ),
        ],
      ),
    );
  }

  void _importMenu(List<String> ids) {
    final menuStore = context.read<MenuStore>();

    // 清空现有菜单并添加新的
    menuStore.clear();
    for (final id in ids) {
      menuStore.add(id);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('已导入 ${ids.length} 道菜到今日菜单')),
    );

    Navigator.pop(context, true); // 返回并标记已导入
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          '扫描二维码',
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
      ),
      body: Stack(
        children: [
          // Scanner
          MobileScanner(
            controller: _controller,
            onDetect: _onDetect,
          ),

          // Overlay
          CustomPaint(
            painter: ScanOverlayPainter(),
            child: const SizedBox.expand(),
          ),

          // Instructions
          Positioned(
            left: 0,
            right: 0,
            bottom: 140,
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    '将二维码放入框内扫描',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bottom buttons
          Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // 相册按钮
                _buildBottomButton(
                  icon: Icons.photo_library,
                  label: '相册',
                  onTap: _pickImage,
                ),
                // 闪光灯按钮
                ValueListenableBuilder(
                  valueListenable: _controller,
                  builder: (context, state, child) {
                    return _buildBottomButton(
                      icon: state.torchState == TorchState.on
                          ? Icons.flash_on
                          : Icons.flash_off,
                      label: '闪光灯',
                      onTap: () => _controller.toggleTorch(),
                    );
                  },
                ),
              ],
            ),
          ),

          // Loading overlay
          if (_isProcessing)
            Container(
              color: Colors.black54,
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomButton({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(28),
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class ScanOverlayPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black54
      ..style = PaintingStyle.fill;

    final scanArea = Rect.fromCenter(
      center: Offset(size.width / 2, size.height / 2 - 50),
      width: 250,
      height: 250,
    );

    // Draw overlay
    final path = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height))
      ..addRRect(RRect.fromRectAndRadius(scanArea, const Radius.circular(12)))
      ..fillType = PathFillType.evenOdd;

    canvas.drawPath(path, paint);

    // Draw corners
    final cornerPaint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    const cornerLength = 30.0;

    // Top left
    canvas.drawLine(
      scanArea.topLeft + const Offset(0, cornerLength),
      scanArea.topLeft,
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.topLeft,
      scanArea.topLeft + const Offset(cornerLength, 0),
      cornerPaint,
    );

    // Top right
    canvas.drawLine(
      scanArea.topRight + const Offset(-cornerLength, 0),
      scanArea.topRight,
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.topRight,
      scanArea.topRight + const Offset(0, cornerLength),
      cornerPaint,
    );

    // Bottom left
    canvas.drawLine(
      scanArea.bottomLeft + const Offset(0, -cornerLength),
      scanArea.bottomLeft,
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.bottomLeft,
      scanArea.bottomLeft + const Offset(cornerLength, 0),
      cornerPaint,
    );

    // Bottom right
    canvas.drawLine(
      scanArea.bottomRight + const Offset(-cornerLength, 0),
      scanArea.bottomRight,
      cornerPaint,
    );
    canvas.drawLine(
      scanArea.bottomRight,
      scanArea.bottomRight + const Offset(0, -cornerLength),
      cornerPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
