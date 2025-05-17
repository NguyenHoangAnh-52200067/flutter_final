import 'package:ecommerce_app/models/product_model.dart';
import 'package:ecommerce_app/utils/utils.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';

class MailService {
  final String username = 'trandokhanhminh@gmail.com';
  final String password = 'cgcirpzspzjtxyjm';

  // EmailJS credentials
  final String emailJsServiceId = 'service_bytxku9';
  final String emailJsTemplateId =
      'template_onr40nb'; // Order confirmation template
  final String emailJsDeliveryTemplateId =
      'template_eskx4tu'; // Replace with your new template ID
  final String emailJsUserId = '4SKScCbLDRa1-mSd2';

  Future<void> sendOrderConfirmationEmail(
    String email,
    String name,
    String orderId,
    String total,
    List<ProductModel> products,
    String shippingFee,
    double pointsConversion,
  ) async {
    try {
      if (kIsWeb) {
        // Use EmailJS for web
        await _sendViaEmailJS(
          email,
          name,
          orderId,
          total,
          products,
          shippingFee,
          pointsConversion,
        );
        print('Email sent successfully via EmailJS');
      } else {
        // Use direct SMTP for mobile
        final smtpServer = gmail(username, password);
        final emailHtml = _buildOrderConfirmationTemplate(
          name: name,
          orderId: orderId,
          products: products,
          shippingFee: shippingFee,
          pointsConversion: pointsConversion,
          total: total,
        );

        final message =
            Message()
              ..from = Address(username, 'Ecommerce App')
              ..recipients.add(email)
              ..subject = 'Bạn đã đặt hàng thành công!'
              ..html = emailHtml;

        final sendReport = await send(message, smtpServer);
        print('Email sent successfully: ${sendReport.toString()}');
      }
    } catch (e) {
      print('Failed to send email: $e');
      throw Exception(
        'Failed to send order confirmation email: ${e.toString()}',
      );
    }
  }

  Future<void> _sendViaEmailJS(
    String email,
    String name,
    String orderId,
    String total,
    List<ProductModel> products,
    String shippingFee,
    double pointsConversion,
  ) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final productsText = products
        .map((p) {
          final price =
              p.discount > 0 ? p.price * (1 - p.discount / 100) : p.price;
          return '${p.productName} - ${formatCurrency(price)}';
        })
        .join('<br>');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'service_id': emailJsServiceId,
        'template_id': emailJsTemplateId,
        'user_id': emailJsUserId,
        'template_params': {
          'email': email,
          'to_name': name,
          'order_id': orderId,
          'total': total,
          'products_list': productsText,
          'shipping_fee': shippingFee,
          'points_conversion': pointsConversion.toString(),
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send email: ${response.body}');
    }
  }

  String formatCurrency(double amount) {
    return '${amount.toStringAsFixed(0)}đ';
  }

  Future<void> sendOTPEmail(String email, String otp) async {
    try {
      final smtpServer = gmail(username, password);
      final emailHtml = _buildOTPTemplate(email: email, otp: otp);
      final message =
          Message()
            ..from = Address(username, 'Ecommerce App')
            ..recipients.add(email)
            ..subject = 'Mã OTP xác minh!'
            ..html = emailHtml;

      final sendReport = await send(message, smtpServer);
      print('Email sent successfully: ${sendReport.toString()}');
    } catch (e) {
      print('Failed to send email: $e');
      throw Exception('Failed to send OTP confirmation email: ${e.toString()}');
    }
  }

  String _buildOTPTemplate({required String email, required String otp}) {
    return '''
      <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f9f9f9; padding: 30px;">
        <div style="max-width: 600px; margin: auto; background-color: #ffffff; padding: 25px 30px; border-radius: 10px; box-shadow: 0 4px 8px rgba(0,0,0,0.05);">
          <h2 style="color: #27ae60; margin-bottom: 10px;">🎉 Cảm ơn bạn đã đặt hàng tại <span style="color: #2c3e50;">Ecommerce App</span>!</h2>
          <p style="font-size: 16px; color: #333;">Xin chào <strong>${email}</strong>,</p>
          <p style="font-size: 16px; color: #333;">Chúng tôi đã nhận được yêu cầu đặt lại mật khẩu của bạn.</p>
          
          <hr style="margin: 20px 0; border: none; border-top: 1px solid #eee;" />
          <div style="margin: 20px 0;">
            <div style="background-color: #f0f0f0; padding: 15px; border-radius: 8px; text-align: center; margin: 20px 0;">
              <div style="font-size: 24px; font-weight: bold; letter-spacing: 8px; color: #2c3e50; padding: 10px;">
                ${otp}
              </div>
            </div>
            
          </div>
          
          <p style="margin-top: 20px; font-size: 15px; color: #555;">
            Vui lòng nhập mã OTP này để khôi phục mật khẩu của bạn.
          </p>

          <p style="margin-top: 30px; font-size: 14px; color: #888;">Nếu bạn có bất kỳ câu hỏi nào, hãy liên hệ với chúng tôi bất cứ lúc nào.</p>
          <p style="font-size: 14px; color: #888;">Trân trọng,<br/><strong style="color: #2c3e50;">Ecommerce App Team</strong></p>
        </div>
      </div>
    ''';
  }

  String _buildOrderConfirmationTemplate({
    required String name,
    required String orderId,
    required List<ProductModel> products,
    required String shippingFee,
    required double pointsConversion,
    required String total,
  }) {
    return '''
      <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f9f9f9; padding: 30px;">
        <div style="max-width: 600px; margin: auto; background-color: #ffffff; padding: 25px 30px; border-radius: 10px; box-shadow: 0 4px 8px rgba(0,0,0,0.05);">
          <h2 style="color: #27ae60; margin-bottom: 10px;">🎉 Cảm ơn bạn đã đặt hàng tại <span style="color: #2c3e50;">Ecommerce App</span>!</h2>
          <p style="font-size: 16px; color: #333;">Xin chào <strong>${name}</strong>,</p>
          <p style="font-size: 16px; color: #333;">Chúng tôi đã nhận được đơn hàng của bạn với mã đơn hàng: <strong>#${orderId}</strong>.</p>
          
          <hr style="margin: 20px 0; border: none; border-top: 1px solid #eee;" />
          <div style="margin: 20px 0;">
            <h3 style="color: #2c3e50; margin-bottom: 20px; border-bottom: 2px solid #eee; padding-bottom: 10px;">Chi tiết đơn hàng:</h3>
            <table style="width: 100%; border-collapse: collapse;">
              <tr>
                <td style="width: 20%; padding: 10px; vertical-align: top;">
                  ${_buildProductImages(products)}
                </td>
                <td style="width: 80%; padding: 10px; vertical-align: top;">
                  ${_buildProductDetails(products)}
                </td>
              </tr>
            </table>
          </div>
          ${_buildOrderSummary(shippingFee, pointsConversion, total)}
          
          <p style="margin-top: 20px; font-size: 15px; color: #555;">
            Vui lòng đăng nhập vào tài khoản trên ứng dụng để xem chi tiết đơn hàng của bạn.
          </p>

          <p style="margin-top: 30px; font-size: 14px; color: #888;">Nếu bạn có bất kỳ câu hỏi nào, hãy liên hệ với chúng tôi bất cứ lúc nào.</p>
          <p style="font-size: 14px; color: #888;">Trân trọng,<br/><strong style="color: #2c3e50;">Ecommerce App Team</strong></p>
        </div>
      </div>
    ''';
  }

  String _buildProductImages(List<ProductModel> products) {
    return products
        .map(
          (product) => '''
      <div style="margin-bottom: 15px; padding: 10px; background-color: #f8f9fa; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.05);">
        <img src="${product.images.first}" alt="${product.productName}" 
             style="width: 100%; height: auto; object-fit: cover; border-radius: 6px;">
      </div>
    ''',
        )
        .join('');
  }

  String _buildProductDetails(List<ProductModel> products) {
    return products
        .map(
          (product) => '''
      <div style="margin-bottom: 15px; padding: 15px; background-color: #f8f9fa; border-radius: 8px; box-shadow: 0 2px 4px rgba(0,0,0,0.05);">
        <div style="font-weight: bold; color: #2c3e50; margin-bottom: 8px; font-size: 16px;">
          ${product.productName}
        </div>
        
        ${_buildPriceSection(product)}
      </div>
    ''',
        )
        .join('');
  }

  String _buildPriceSection(ProductModel product) {
    if (product.discount > 0) {
      return '''
        <div style="text-decoration: line-through; color: #95a5a6; font-size: 13px;">
          Giá gốc: ${Utils.formatCurrency(product.price)}
        </div>
        <div style="color: #e74c3c; font-weight: bold; font-size: 15px;">
          Giá sau giảm: ${Utils.formatCurrency(product.priceAfterDiscount!)}
        </div>
      ''';
    }
    return '''
      <div style="color: #e74c3c; font-weight: bold; font-size: 15px;">
        Giá: ${Utils.formatCurrency(product.price)}
      </div>
    ''';
  }

  String _buildOrderSummary(
    String shippingFee,
    double pointsConversion,
    String total,
  ) {
    return '''
      <p style="font-size: 14px; color: #2c3e50;"><strong>Phí vận chuyển:</strong> <span style="color: #e67e22;">${Utils.formatCurrency(double.parse(shippingFee))}</span></p>
      ${pointsConversion > 0.0 ? '''
        <p style="font-size: 14px; color: #2c3e50;"><strong>Điểm quy đổi:</strong> <span style="color: #e67e22;">${Utils.formatCurrency(pointsConversion)} </span></p>
      ''' : ''}
      <p style="font-size: 14px; color: #2c3e50;"><strong>Tổng tiền thanh toán:</strong> <span style="color: #e67e22;">${total}</span></p>
    ''';
  }

  Future<void> sendOrderDeliveredEmail(
    String? email,
    String name,
    String orderId,
    String total,
    List<ProductModel> products,
    String shippingFee,
    double pointsEarned, // Points earned from this purchase
  ) async {
    try {
      // Check if email is null or empty
      if (email == null || email.trim().isEmpty) {
        print('Cannot send delivery email: recipient email address is empty');
        return;
      }

      if (kIsWeb) {
        // Use EmailJS for web
        await _sendDeliveryEmailViaEmailJS(
          email,
          name,
          orderId,
          total,
          products,
          shippingFee,
          pointsEarned,
        );
        print('Delivery email sent successfully via EmailJS');
      } else {
        // Use direct SMTP for mobile
        final smtpServer = gmail(username, password);
        final emailHtml = _buildOrderDeliveredTemplate(
          name: name,
          orderId: orderId,
          products: products,
          shippingFee: shippingFee,
          pointsEarned: pointsEarned,
          total: total,
        );

        final message =
            Message()
              ..from = Address(username, 'Ecommerce App')
              ..recipients.add(email)
              ..subject = 'Đơn hàng của bạn đã được giao thành công!'
              ..html = emailHtml;

        final sendReport = await send(message, smtpServer);
        print('Delivery email sent successfully: ${sendReport.toString()}');
      }
    } catch (e) {
      print('Failed to send delivery email: $e');
    }
  }

  Future<void> _sendDeliveryEmailViaEmailJS(
    String email,
    String name,
    String orderId,
    String total,
    List<ProductModel> products,
    String shippingFee,
    double pointsEarned,
  ) async {
    final url = Uri.parse('https://api.emailjs.com/api/v1.0/email/send');

    final productsText = products
        .map((p) {
          final price =
              p.discount > 0 ? p.price * (1 - p.discount / 100) : p.price;
          return '${p.productName} - ${Utils.formatCurrency(price)}';
        })
        .join('<br>');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: json.encode({
        'service_id': emailJsServiceId,
        'template_id': emailJsDeliveryTemplateId,
        'user_id': emailJsUserId,
        'template_params': {
          'email': email,
          'to_name': name,
          'order_id': orderId,
          'total': total,
          'products_list': productsText,
          'shipping_fee': shippingFee,
          'points_earned': pointsEarned.toString(),
          'delivery_date': DateFormat('dd/MM/yyyy').format(DateTime.now()),
        },
      }),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to send delivery email: ${response.body}');
    }
  }

  String _buildOrderDeliveredTemplate({
    required String name,
    required String orderId,
    required List<ProductModel> products,
    required String shippingFee,
    required double pointsEarned,
    required String total,
  }) {
    return '''
      <div style="font-family: 'Segoe UI', Tahoma, Geneva, Verdana, sans-serif; background-color: #f9f9f9; padding: 30px;">
        <div style="max-width: 600px; margin: auto; background-color: #ffffff; padding: 25px 30px; border-radius: 10px; box-shadow: 0 4px 8px rgba(0,0,0,0.05);">
          <h2 style="color: #27ae60; margin-bottom: 10px;">✅ Đơn hàng đã được giao thành công!</h2>
          <p style="font-size: 16px; color: #333;">Xin chào <strong>${name}</strong>,</p>
          <p style="font-size: 16px; color: #333;">Đơn hàng của bạn với mã <strong>#${orderId}</strong> đã được giao thành công.</p>
          
          <hr style="margin: 20px 0; border: none; border-top: 1px solid #eee;" />
          <div style="margin: 20px 0;">
            <h3 style="color: #2c3e50; margin-bottom: 20px; border-bottom: 2px solid #eee; padding-bottom: 10px;">Chi tiết đơn hàng:</h3>
            <table style="width: 100%; border-collapse: collapse;">
              <tr>
                <td style="width: 20%; padding: 10px; vertical-align: top;">
                  ${_buildProductImages(products)}
                </td>
                <td style="width: 80%; padding: 10px; vertical-align: top;">
                  ${_buildProductDetails(products)}
                </td>
              </tr>
            </table>
          </div>
          
          <div style="background-color: #e8f5e9; padding: 15px; border-radius: 8px; margin-top: 20px;">
            <p style="font-size: 15px; color: #2e7d32; margin: 0;">
              <strong>Bạn đã nhận được ${pointsEarned.toInt()} điểm thưởng</strong> từ đơn hàng này!
            </p>
          </div>
          
          <div style="background-color: #f0f0f0; padding: 15px; border-radius: 8px; margin-top: 20px;">
            <p style="font-size: 15px; color: #333; margin: 0;">
              <strong>Chúng tôi rất mong nhận được đánh giá của bạn về sản phẩm.</strong> Hãy đăng nhập vào ứng dụng để đánh giá sản phẩm bạn đã mua.
            </p>
          </div>

          <p style="margin-top: 30px; font-size: 14px; color: #888;">Nếu bạn có bất kỳ câu hỏi nào, hãy liên hệ với chúng tôi bất cứ lúc nào.</p>
          <p style="font-size: 14px; color: #888;">Trân trọng,<br/><strong style="color: #2c3e50;">Ecommerce App Team</strong></p>
        </div>
      </div>
    ''';
  }
}
