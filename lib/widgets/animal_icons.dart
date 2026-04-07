import 'package:flutter/material.dart';

/// 可爱小动物图标 - 用 CustomPainter 绘制
class AnimalIcon extends StatelessWidget {
  final AnimalType type;
  final double size;
  final Color? backgroundColor;

  const AnimalIcon({
    super.key,
    required this.type,
    this.size = 40,
    this.backgroundColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? _getDefaultBgColor(),
        shape: BoxShape.circle,
      ),
      child: CustomPaint(
        size: Size(size, size),
        painter: _AnimalPainter(type: type),
      ),
    );
  }

  Color _getDefaultBgColor() {
    switch (type) {
      case AnimalType.chicken:
        return const Color(0xFFFFE4B5);
      case AnimalType.bunny:
        return const Color(0xFFE8F5E9);
      case AnimalType.bear:
        return const Color(0xFFFFE4E1);
      case AnimalType.cat:
        return const Color(0xFFFFF8DC);
      case AnimalType.pig:
        return const Color(0xFFFFE4EC);
      case AnimalType.fish:
        return const Color(0xFFE3F2FD);
      case AnimalType.duck:
        return const Color(0xFFFFF9C4);
      case AnimalType.cow:
        return const Color(0xFFF3E5F5);
    }
  }
}

enum AnimalType {
  chicken,  // 小鸡 - 热菜
  bunny,    // 小兔 - 凉菜
  bear,     // 小熊 - 汤羹
  cat,      // 小猫 - 主食
  pig,      // 小猪 - 小吃
  fish,     // 小鱼 - 水产
  duck,     // 小鸭 - 蛋奶
  cow,      // 小牛 - 烘焙
}

class _AnimalPainter extends CustomPainter {
  final AnimalType type;

  _AnimalPainter({required this.type});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final scale = size.width / 40; // 基准尺寸 40

    switch (type) {
      case AnimalType.chicken:
        _drawChicken(canvas, center, scale);
        break;
      case AnimalType.bunny:
        _drawBunny(canvas, center, scale);
        break;
      case AnimalType.bear:
        _drawBear(canvas, center, scale);
        break;
      case AnimalType.cat:
        _drawCat(canvas, center, scale);
        break;
      case AnimalType.pig:
        _drawPig(canvas, center, scale);
        break;
      case AnimalType.fish:
        _drawFish(canvas, center, scale);
        break;
      case AnimalType.duck:
        _drawDuck(canvas, center, scale);
        break;
      case AnimalType.cow:
        _drawCow(canvas, center, scale);
        break;
    }
  }

  // 小鸡 🐔
  void _drawChicken(Canvas canvas, Offset center, double scale) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 身体 - 黄色圆
    paint.color = const Color(0xFFFFD54F);
    canvas.drawCircle(center + Offset(0, 2 * scale), 10 * scale, paint);

    // 翅膀
    paint.color = const Color(0xFFFFB300);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(-8 * scale, 2 * scale),
        width: 6 * scale,
        height: 8 * scale,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(8 * scale, 2 * scale),
        width: 6 * scale,
        height: 8 * scale,
      ),
      paint,
    );

    // 头 - 黄色圆
    paint.color = const Color(0xFFFFD54F);
    canvas.drawCircle(center + Offset(0, -6 * scale), 8 * scale, paint);

    // 鸡冠 - 红色
    paint.color = const Color(0xFFE53935);
    final combPath = Path();
    combPath.moveTo(center.dx - 3 * scale, center.dy - 13 * scale);
    combPath.quadraticBezierTo(
      center.dx - 2 * scale, center.dy - 18 * scale,
      center.dx, center.dy - 14 * scale,
    );
    combPath.quadraticBezierTo(
      center.dx + 2 * scale, center.dy - 18 * scale,
      center.dx + 3 * scale, center.dy - 13 * scale,
    );
    combPath.close();
    canvas.drawPath(combPath, paint);

    // 眼睛
    paint.color = Colors.black;
    canvas.drawCircle(center + Offset(-3 * scale, -7 * scale), 1.5 * scale, paint);
    canvas.drawCircle(center + Offset(3 * scale, -7 * scale), 1.5 * scale, paint);

    // 眼睛高光
    paint.color = Colors.white;
    canvas.drawCircle(center + Offset(-2.5 * scale, -7.5 * scale), 0.5 * scale, paint);
    canvas.drawCircle(center + Offset(3.5 * scale, -7.5 * scale), 0.5 * scale, paint);

    // 嘴巴 - 橙色三角
    paint.color = const Color(0xFFFF6D00);
    final beakPath = Path();
    beakPath.moveTo(center.dx, center.dy - 4 * scale);
    beakPath.lineTo(center.dx - 2 * scale, center.dy - 2 * scale);
    beakPath.lineTo(center.dx + 2 * scale, center.dy - 2 * scale);
    beakPath.close();
    canvas.drawPath(beakPath, paint);

    // 腮红
    paint.color = const Color(0xFFFFAB91).withValues(alpha: 0.6);
    canvas.drawCircle(center + Offset(-6 * scale, -4 * scale), 2 * scale, paint);
    canvas.drawCircle(center + Offset(6 * scale, -4 * scale), 2 * scale, paint);
  }

  // 小兔 🐰
  void _drawBunny(Canvas canvas, Offset center, double scale) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 耳朵 - 白色长椭圆
    paint.color = Colors.white;
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(-5 * scale, -14 * scale),
        width: 5 * scale,
        height: 12 * scale,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(5 * scale, -14 * scale),
        width: 5 * scale,
        height: 12 * scale,
      ),
      paint,
    );

    // 耳朵内部 - 粉色
    paint.color = const Color(0xFFFFCDD2);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(-5 * scale, -13 * scale),
        width: 2.5 * scale,
        height: 8 * scale,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(5 * scale, -13 * scale),
        width: 2.5 * scale,
        height: 8 * scale,
      ),
      paint,
    );

    // 头/身体 - 白色圆
    paint.color = Colors.white;
    canvas.drawCircle(center + Offset(0, 2 * scale), 12 * scale, paint);

    // 眼睛
    paint.color = const Color(0xFF424242);
    canvas.drawCircle(center + Offset(-4 * scale, -1 * scale), 2 * scale, paint);
    canvas.drawCircle(center + Offset(4 * scale, -1 * scale), 2 * scale, paint);

    // 眼睛高光
    paint.color = Colors.white;
    canvas.drawCircle(center + Offset(-3.5 * scale, -1.5 * scale), 0.8 * scale, paint);
    canvas.drawCircle(center + Offset(4.5 * scale, -1.5 * scale), 0.8 * scale, paint);

    // 鼻子 - 粉色小三角
    paint.color = const Color(0xFFFF8A80);
    canvas.drawCircle(center + Offset(0, 2 * scale), 1.5 * scale, paint);

    // 嘴巴 - Y形
    paint.color = const Color(0xFF8D6E63);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1 * scale;
    paint.strokeCap = StrokeCap.round;
    final mouthPath = Path();
    mouthPath.moveTo(center.dx, center.dy + 3.5 * scale);
    mouthPath.lineTo(center.dx, center.dy + 6 * scale);
    mouthPath.moveTo(center.dx - 3 * scale, center.dy + 8 * scale);
    mouthPath.quadraticBezierTo(
      center.dx, center.dy + 5 * scale,
      center.dx + 3 * scale, center.dy + 8 * scale,
    );
    canvas.drawPath(mouthPath, paint);

    // 腮红
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFFFFCDD2).withValues(alpha: 0.7);
    canvas.drawCircle(center + Offset(-8 * scale, 3 * scale), 2.5 * scale, paint);
    canvas.drawCircle(center + Offset(8 * scale, 3 * scale), 2.5 * scale, paint);
  }

  // 小熊 🐻
  void _drawBear(Canvas canvas, Offset center, double scale) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 耳朵
    paint.color = const Color(0xFF8D6E63);
    canvas.drawCircle(center + Offset(-9 * scale, -9 * scale), 5 * scale, paint);
    canvas.drawCircle(center + Offset(9 * scale, -9 * scale), 5 * scale, paint);

    // 耳朵内部
    paint.color = const Color(0xFFFFCCBC);
    canvas.drawCircle(center + Offset(-9 * scale, -9 * scale), 2.5 * scale, paint);
    canvas.drawCircle(center + Offset(9 * scale, -9 * scale), 2.5 * scale, paint);

    // 头/脸 - 棕色圆
    paint.color = const Color(0xFF8D6E63);
    canvas.drawCircle(center + Offset(0, 0), 12 * scale, paint);

    // 脸部浅色区域
    paint.color = const Color(0xFFD7CCC8);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, 4 * scale),
        width: 10 * scale,
        height: 8 * scale,
      ),
      paint,
    );

    // 眼睛
    paint.color = const Color(0xFF3E2723);
    canvas.drawCircle(center + Offset(-4 * scale, -2 * scale), 2 * scale, paint);
    canvas.drawCircle(center + Offset(4 * scale, -2 * scale), 2 * scale, paint);

    // 眼睛高光
    paint.color = Colors.white;
    canvas.drawCircle(center + Offset(-3.5 * scale, -2.5 * scale), 0.8 * scale, paint);
    canvas.drawCircle(center + Offset(4.5 * scale, -2.5 * scale), 0.8 * scale, paint);

    // 鼻子
    paint.color = const Color(0xFF3E2723);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, 3 * scale),
        width: 4 * scale,
        height: 3 * scale,
      ),
      paint,
    );

    // 嘴巴
    paint.color = const Color(0xFF5D4037);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1 * scale;
    paint.strokeCap = StrokeCap.round;
    final mouthPath = Path();
    mouthPath.moveTo(center.dx - 3 * scale, center.dy + 7 * scale);
    mouthPath.quadraticBezierTo(
      center.dx, center.dy + 9 * scale,
      center.dx + 3 * scale, center.dy + 7 * scale,
    );
    canvas.drawPath(mouthPath, paint);

    // 腮红
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFFFFAB91).withValues(alpha: 0.5);
    canvas.drawCircle(center + Offset(-8 * scale, 2 * scale), 2 * scale, paint);
    canvas.drawCircle(center + Offset(8 * scale, 2 * scale), 2 * scale, paint);
  }

  // 小猫 🐱
  void _drawCat(Canvas canvas, Offset center, double scale) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 耳朵 - 三角形
    paint.color = const Color(0xFFFFB74D);
    final leftEarPath = Path();
    leftEarPath.moveTo(center.dx - 10 * scale, center.dy - 4 * scale);
    leftEarPath.lineTo(center.dx - 6 * scale, center.dy - 14 * scale);
    leftEarPath.lineTo(center.dx - 2 * scale, center.dy - 4 * scale);
    leftEarPath.close();
    canvas.drawPath(leftEarPath, paint);

    final rightEarPath = Path();
    rightEarPath.moveTo(center.dx + 10 * scale, center.dy - 4 * scale);
    rightEarPath.lineTo(center.dx + 6 * scale, center.dy - 14 * scale);
    rightEarPath.lineTo(center.dx + 2 * scale, center.dy - 4 * scale);
    rightEarPath.close();
    canvas.drawPath(rightEarPath, paint);

    // 耳朵内部 - 粉色
    paint.color = const Color(0xFFFFCDD2);
    final leftInnerEarPath = Path();
    leftInnerEarPath.moveTo(center.dx - 8 * scale, center.dy - 5 * scale);
    leftInnerEarPath.lineTo(center.dx - 6 * scale, center.dy - 11 * scale);
    leftInnerEarPath.lineTo(center.dx - 4 * scale, center.dy - 5 * scale);
    leftInnerEarPath.close();
    canvas.drawPath(leftInnerEarPath, paint);

    final rightInnerEarPath = Path();
    rightInnerEarPath.moveTo(center.dx + 8 * scale, center.dy - 5 * scale);
    rightInnerEarPath.lineTo(center.dx + 6 * scale, center.dy - 11 * scale);
    rightInnerEarPath.lineTo(center.dx + 4 * scale, center.dy - 5 * scale);
    rightInnerEarPath.close();
    canvas.drawPath(rightInnerEarPath, paint);

    // 头/脸 - 橙黄色圆
    paint.color = const Color(0xFFFFB74D);
    canvas.drawCircle(center + Offset(0, 2 * scale), 12 * scale, paint);

    // 眼睛 - 大圆眼
    paint.color = const Color(0xFF4CAF50);
    canvas.drawCircle(center + Offset(-4 * scale, 0), 3 * scale, paint);
    canvas.drawCircle(center + Offset(4 * scale, 0), 3 * scale, paint);

    // 瞳孔
    paint.color = Colors.black;
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(-4 * scale, 0),
        width: 2 * scale,
        height: 4 * scale,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(4 * scale, 0),
        width: 2 * scale,
        height: 4 * scale,
      ),
      paint,
    );

    // 眼睛高光
    paint.color = Colors.white;
    canvas.drawCircle(center + Offset(-3 * scale, -1 * scale), 1 * scale, paint);
    canvas.drawCircle(center + Offset(5 * scale, -1 * scale), 1 * scale, paint);

    // 鼻子 - 粉色小三角
    paint.color = const Color(0xFFFF8A80);
    final nosePath = Path();
    nosePath.moveTo(center.dx, center.dy + 3 * scale);
    nosePath.lineTo(center.dx - 2 * scale, center.dy + 5.5 * scale);
    nosePath.lineTo(center.dx + 2 * scale, center.dy + 5.5 * scale);
    nosePath.close();
    canvas.drawPath(nosePath, paint);

    // 嘴巴 - W形
    paint.color = const Color(0xFF795548);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 1 * scale;
    paint.strokeCap = StrokeCap.round;
    final mouthPath = Path();
    mouthPath.moveTo(center.dx - 4 * scale, center.dy + 8 * scale);
    mouthPath.quadraticBezierTo(
      center.dx - 2 * scale, center.dy + 6 * scale,
      center.dx, center.dy + 7 * scale,
    );
    mouthPath.quadraticBezierTo(
      center.dx + 2 * scale, center.dy + 6 * scale,
      center.dx + 4 * scale, center.dy + 8 * scale,
    );
    canvas.drawPath(mouthPath, paint);

    // 胡须
    paint.color = const Color(0xFF795548);
    paint.strokeWidth = 0.8 * scale;
    // 左边胡须
    canvas.drawLine(
      center + Offset(-6 * scale, 5 * scale),
      center + Offset(-13 * scale, 3 * scale),
      paint,
    );
    canvas.drawLine(
      center + Offset(-6 * scale, 6 * scale),
      center + Offset(-13 * scale, 6 * scale),
      paint,
    );
    canvas.drawLine(
      center + Offset(-6 * scale, 7 * scale),
      center + Offset(-13 * scale, 9 * scale),
      paint,
    );
    // 右边胡须
    canvas.drawLine(
      center + Offset(6 * scale, 5 * scale),
      center + Offset(13 * scale, 3 * scale),
      paint,
    );
    canvas.drawLine(
      center + Offset(6 * scale, 6 * scale),
      center + Offset(13 * scale, 6 * scale),
      paint,
    );
    canvas.drawLine(
      center + Offset(6 * scale, 7 * scale),
      center + Offset(13 * scale, 9 * scale),
      paint,
    );

    // 腮红
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFFFFCDD2).withValues(alpha: 0.6);
    canvas.drawCircle(center + Offset(-8 * scale, 4 * scale), 2 * scale, paint);
    canvas.drawCircle(center + Offset(8 * scale, 4 * scale), 2 * scale, paint);
  }

  // 小猪 🐷
  void _drawPig(Canvas canvas, Offset center, double scale) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 耳朵
    paint.color = const Color(0xFFF48FB1);
    final leftEarPath = Path();
    leftEarPath.moveTo(center.dx - 8 * scale, center.dy - 6 * scale);
    leftEarPath.quadraticBezierTo(
      center.dx - 12 * scale, center.dy - 14 * scale,
      center.dx - 4 * scale, center.dy - 10 * scale,
    );
    leftEarPath.close();
    canvas.drawPath(leftEarPath, paint);

    final rightEarPath = Path();
    rightEarPath.moveTo(center.dx + 8 * scale, center.dy - 6 * scale);
    rightEarPath.quadraticBezierTo(
      center.dx + 12 * scale, center.dy - 14 * scale,
      center.dx + 4 * scale, center.dy - 10 * scale,
    );
    rightEarPath.close();
    canvas.drawPath(rightEarPath, paint);

    // 头/脸 - 粉色圆
    paint.color = const Color(0xFFFFCDD2);
    canvas.drawCircle(center + Offset(0, 0), 12 * scale, paint);

    // 眼睛
    paint.color = const Color(0xFF424242);
    canvas.drawCircle(center + Offset(-4 * scale, -2 * scale), 2 * scale, paint);
    canvas.drawCircle(center + Offset(4 * scale, -2 * scale), 2 * scale, paint);

    // 眼睛高光
    paint.color = Colors.white;
    canvas.drawCircle(center + Offset(-3.5 * scale, -2.5 * scale), 0.8 * scale, paint);
    canvas.drawCircle(center + Offset(4.5 * scale, -2.5 * scale), 0.8 * scale, paint);

    // 鼻子 - 椭圆
    paint.color = const Color(0xFFF48FB1);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, 3 * scale),
        width: 10 * scale,
        height: 7 * scale,
      ),
      paint,
    );

    // 鼻孔
    paint.color = const Color(0xFFAD1457).withValues(alpha: 0.6);
    canvas.drawCircle(center + Offset(-2 * scale, 3 * scale), 1.5 * scale, paint);
    canvas.drawCircle(center + Offset(2 * scale, 3 * scale), 1.5 * scale, paint);

    // 腮红
    paint.color = const Color(0xFFF48FB1).withValues(alpha: 0.5);
    canvas.drawCircle(center + Offset(-9 * scale, 1 * scale), 2.5 * scale, paint);
    canvas.drawCircle(center + Offset(9 * scale, 1 * scale), 2.5 * scale, paint);
  }

  // 小鱼 🐟
  void _drawFish(Canvas canvas, Offset center, double scale) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 尾巴
    paint.color = const Color(0xFF64B5F6);
    final tailPath = Path();
    tailPath.moveTo(center.dx + 8 * scale, center.dy);
    tailPath.lineTo(center.dx + 14 * scale, center.dy - 6 * scale);
    tailPath.lineTo(center.dx + 14 * scale, center.dy + 6 * scale);
    tailPath.close();
    canvas.drawPath(tailPath, paint);

    // 身体 - 椭圆
    paint.color = const Color(0xFF90CAF9);
    canvas.drawOval(
      Rect.fromCenter(
        center: center,
        width: 20 * scale,
        height: 14 * scale,
      ),
      paint,
    );

    // 背鳍
    paint.color = const Color(0xFF64B5F6);
    final finPath = Path();
    finPath.moveTo(center.dx - 2 * scale, center.dy - 6 * scale);
    finPath.quadraticBezierTo(
      center.dx, center.dy - 12 * scale,
      center.dx + 4 * scale, center.dy - 6 * scale,
    );
    finPath.close();
    canvas.drawPath(finPath, paint);

    // 眼睛
    paint.color = Colors.white;
    canvas.drawCircle(center + Offset(-4 * scale, -1 * scale), 3 * scale, paint);
    paint.color = const Color(0xFF1565C0);
    canvas.drawCircle(center + Offset(-4 * scale, -1 * scale), 2 * scale, paint);
    paint.color = Colors.black;
    canvas.drawCircle(center + Offset(-4 * scale, -1 * scale), 1 * scale, paint);

    // 眼睛高光
    paint.color = Colors.white;
    canvas.drawCircle(center + Offset(-3.5 * scale, -1.5 * scale), 0.6 * scale, paint);

    // 鱼鳞纹理
    paint.color = const Color(0xFF64B5F6).withValues(alpha: 0.5);
    paint.style = PaintingStyle.stroke;
    paint.strokeWidth = 0.8 * scale;
    for (int i = 0; i < 3; i++) {
      canvas.drawArc(
        Rect.fromCenter(
          center: center + Offset((2 + i * 3) * scale, 0),
          width: 4 * scale,
          height: 6 * scale,
        ),
        -1.5,
        3,
        false,
        paint,
      );
    }

    // 腮红
    paint.style = PaintingStyle.fill;
    paint.color = const Color(0xFFFFCDD2).withValues(alpha: 0.6);
    canvas.drawCircle(center + Offset(-6 * scale, 2 * scale), 1.5 * scale, paint);
  }

  // 小鸭 🦆
  void _drawDuck(Canvas canvas, Offset center, double scale) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 身体
    paint.color = const Color(0xFFFFF59D);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, 4 * scale),
        width: 18 * scale,
        height: 12 * scale,
      ),
      paint,
    );

    // 翅膀
    paint.color = const Color(0xFFFFF176);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(-6 * scale, 4 * scale),
        width: 5 * scale,
        height: 8 * scale,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(6 * scale, 4 * scale),
        width: 5 * scale,
        height: 8 * scale,
      ),
      paint,
    );

    // 头
    paint.color = const Color(0xFFFFF59D);
    canvas.drawCircle(center + Offset(0, -5 * scale), 8 * scale, paint);

    // 嘴巴 - 橙色扁圆
    paint.color = const Color(0xFFFF9800);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, -2 * scale),
        width: 8 * scale,
        height: 4 * scale,
      ),
      paint,
    );

    // 眼睛
    paint.color = Colors.black;
    canvas.drawCircle(center + Offset(-3 * scale, -7 * scale), 1.5 * scale, paint);
    canvas.drawCircle(center + Offset(3 * scale, -7 * scale), 1.5 * scale, paint);

    // 眼睛高光
    paint.color = Colors.white;
    canvas.drawCircle(center + Offset(-2.5 * scale, -7.5 * scale), 0.5 * scale, paint);
    canvas.drawCircle(center + Offset(3.5 * scale, -7.5 * scale), 0.5 * scale, paint);

    // 腮红
    paint.color = const Color(0xFFFFAB91).withValues(alpha: 0.5);
    canvas.drawCircle(center + Offset(-6 * scale, -4 * scale), 2 * scale, paint);
    canvas.drawCircle(center + Offset(6 * scale, -4 * scale), 2 * scale, paint);
  }

  // 小牛 🐮
  void _drawCow(Canvas canvas, Offset center, double scale) {
    final paint = Paint()..style = PaintingStyle.fill;

    // 耳朵
    paint.color = const Color(0xFFFFCCBC);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(-10 * scale, -5 * scale),
        width: 6 * scale,
        height: 4 * scale,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(10 * scale, -5 * scale),
        width: 6 * scale,
        height: 4 * scale,
      ),
      paint,
    );

    // 头/脸 - 白色
    paint.color = Colors.white;
    canvas.drawCircle(center + Offset(0, 0), 11 * scale, paint);

    // 斑点
    paint.color = const Color(0xFF8D6E63);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(-5 * scale, -6 * scale),
        width: 5 * scale,
        height: 4 * scale,
      ),
      paint,
    );
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(6 * scale, -4 * scale),
        width: 4 * scale,
        height: 5 * scale,
      ),
      paint,
    );

    // 鼻子区域 - 肉粉色
    paint.color = const Color(0xFFFFCCBC);
    canvas.drawOval(
      Rect.fromCenter(
        center: center + Offset(0, 5 * scale),
        width: 10 * scale,
        height: 7 * scale,
      ),
      paint,
    );

    // 鼻孔
    paint.color = const Color(0xFF8D6E63);
    canvas.drawCircle(center + Offset(-2 * scale, 5 * scale), 1.2 * scale, paint);
    canvas.drawCircle(center + Offset(2 * scale, 5 * scale), 1.2 * scale, paint);

    // 眼睛
    paint.color = Colors.black;
    canvas.drawCircle(center + Offset(-4 * scale, -2 * scale), 2 * scale, paint);
    canvas.drawCircle(center + Offset(4 * scale, -2 * scale), 2 * scale, paint);

    // 眼睛高光
    paint.color = Colors.white;
    canvas.drawCircle(center + Offset(-3.5 * scale, -2.5 * scale), 0.8 * scale, paint);
    canvas.drawCircle(center + Offset(4.5 * scale, -2.5 * scale), 0.8 * scale, paint);

    // 腮红
    paint.color = const Color(0xFFFFAB91).withValues(alpha: 0.5);
    canvas.drawCircle(center + Offset(-8 * scale, 1 * scale), 2 * scale, paint);
    canvas.drawCircle(center + Offset(8 * scale, 1 * scale), 2 * scale, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
