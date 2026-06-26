import nodemailer from 'nodemailer';
import twilio from 'twilio';

// Cấu hình Nodemailer cho Gmail
const getTransporter = () => {
  return nodemailer.createTransport({
    service: 'gmail',
    auth: {
      user: process.env.EMAIL_USER,
      pass: process.env.EMAIL_APP_PASSWORD,
    },
  });
};

export const sendEmailOTP = async (email: string, otpCode: string, type: 'register' | 'forgot' = 'register'): Promise<boolean> => {
  if (!process.env.EMAIL_USER || !process.env.EMAIL_APP_PASSWORD) {
    console.warn("⚠️ [CẢNH BÁO] Chưa cấu hình EMAIL_USER và EMAIL_APP_PASSWORD trong file .env");
    return false; // Trả về false để Controller biết mà fallback về Console
  }

  try {
    const transporter = getTransporter();
    
    const isForgot = type === 'forgot';
    const subject = isForgot ? 'Mã xác thực Đặt lại Mật khẩu - HappyClinic' : 'Mã xác thực Đăng ký Tài khoản - HappyClinic';
    const actionText = isForgot ? 'đặt lại mật khẩu tài khoản' : 'đăng ký tài khoản';

    const mailOptions = {
      from: `"HappyClinic" <${process.env.EMAIL_USER}>`,
      to: email,
      subject,
      html: `
        <div style="font-family: Arial, sans-serif; max-width: 600px; margin: auto; padding: 20px; border: 1px solid #ddd; border-radius: 10px;">
          <h2 style="color: #1976D2; text-align: center;">HappyClinic</h2>
          <p>Xin chào,</p>
          <p>Bạn đã yêu cầu mã OTP để ${actionText} trên hệ thống HappyClinic.</p>
          <div style="text-align: center; margin: 20px 0;">
            <span style="font-size: 32px; font-weight: bold; color: #D32F2F; letter-spacing: 5px; padding: 10px 20px; background-color: #fce4e4; border-radius: 8px;">
              ${otpCode}
            </span>
          </div>
          <p>Vui lòng nhập mã này vào ứng dụng. Mã OTP có giá trị trong vòng 5 phút.</p>
          <p style="color: #777; font-size: 12px; margin-top: 30px;">Nếu bạn không yêu cầu mã này, vui lòng bỏ qua email này.</p>
        </div>
      `,
    };

    await transporter.sendMail(mailOptions);
    console.log(`✅ Đã gửi Email chứa OTP thành công tới: ${email}`);
    return true;
  } catch (error) {
    console.error("❌ Lỗi gửi Email OTP:", error);
    return false;
  }
};

export const sendSmsOTP = async (phoneNumber: string, otpCode: string, type: 'register' | 'forgot' = 'register'): Promise<boolean> => {
  if (!process.env.TWILIO_SID || !process.env.TWILIO_AUTH_TOKEN || !process.env.TWILIO_PHONE_NUMBER) {
    console.warn("⚠️ [CẢNH BÁO] Chưa cấu hình đủ TWILIO_SID, TWILIO_AUTH_TOKEN, TWILIO_PHONE_NUMBER trong .env");
    return false;
  }

  try {
    const client = twilio(process.env.TWILIO_SID, process.env.TWILIO_AUTH_TOKEN);
    
    // Twilio yêu cầu format số điện thoại quốc tế (ví dụ: +84...)
    // Nếu sđt nhập vào bắt đầu bằng số 0, ta đổi thành +84
    let formattedPhone = phoneNumber.replace(/\s+/g, '');
    if (formattedPhone.startsWith('0')) {
      // Ép đúng định dạng +84 968 470 318 theo ý của bạn
      if (formattedPhone.length === 10) {
        formattedPhone = '+84 ' + formattedPhone.substring(1, 4) + ' ' + formattedPhone.substring(4, 7) + ' ' + formattedPhone.substring(7);
      } else {
        formattedPhone = '+84' + formattedPhone.substring(1);
      }
    }

    const actionText = type === 'forgot' ? 'dat lai mat khau' : 'dang ky';

    await client.messages.create({
      body: `[HappyClinic] Ma xac thuc ${actionText} cua ban la: ${otpCode}. Khong chia se ma nay voi bat ky ai.`,
      from: process.env.TWILIO_PHONE_NUMBER,
      to: formattedPhone
    });

    console.log(`✅ Đã gửi SMS chứa OTP thành công tới: ${formattedPhone}`);
    return true;
  } catch (error) {
    console.error("❌ Lỗi gửi SMS OTP:", error);
    return false;
  }
};
