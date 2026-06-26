import mongoose from 'mongoose';
import User from './models/User';
import Question from './models/MedicalPost';
import dotenv from 'dotenv';

dotenv.config();

const MONGO_URI = process.env.MONGO_URI || 'mongodb://127.0.0.1:27017/smart_clinic';

const seedQAPosts = async () => {
  try {
    await mongoose.connect(MONGO_URI);
    console.log('MongoDB connected for seeding QA posts...');

    // Clear existing QA posts to avoid duplication
    await Question.deleteMany();
    console.log('Cleared old Q&A posts.');

    // Fetch the Dev Doctor user to reference as answerer
    const doctorUser = await User.findOne({ role: 'doctor' });
    if (!doctorUser) {
      console.log('❌ Error: No doctor user found in database. Run seed_dev_accounts.ts first.');
      process.exit(1);
    }

    // Fetch a patient user to reference as author
    const patientUser = await User.findOne({ role: 'patient' });
    if (!patientUser) {
      console.log('❌ Error: No patient user found in database. Run seed_dev_accounts.ts first.');
      process.exit(1);
    }
    const patientId = patientUser._id;

    const samplePosts = [
      {
        patientId: patientId,
        doctorId: doctorUser._id,
        isAnonymous: true,
        title: "Hỏi về triệu chứng ngứa nổi mẩn đỏ sau khi ăn hải sản",
        content: "Chào bác sĩ, hôm qua sau khi ăn ghẹ em bị nổi nhiều mẩn đỏ ngứa ngáy khắp người. Em đã uống nhiều nước nhưng vẫn không đỡ. Mong bác sĩ tư vấn ạ.",
        tags: ["Da liễu", "Dị ứng"],
        status: "approved",
        comments: [
          {
            senderId: doctorUser._id,
            content: "Chào em, đây là biểu hiện của dị ứng hải sản cấp tính. Em nên tránh tiếp tục ăn hải sản lúc này, có thể ra nhà thuốc mua thuốc kháng Histamin thế hệ mới (như Cetirizine hoặc Loratadine) uống 1 viên. Nếu có triệu chứng khó thở hay sưng môi mắt, hãy đến cơ sở y tế ngay nhé!",
            createdAt: new Date(Date.now() - 2 * 60 * 60 * 1000) // 2 hours ago
          }
        ]
      },
      {
        patientId: patientId,
        doctorId: doctorUser._id,
        isAnonymous: false,
        title: "Bệnh tiểu đường tuýp 2 có chữa dứt điểm được không?",
        content: "Bác sĩ cho tôi hỏi, tôi mới đi khám được chẩn đoán tiểu đường tuýp 2. Tôi có thể chữa khỏi hoàn toàn bằng cách ăn uống kiêng khem hay thuốc nam không?",
        tags: ["Nội tiết", "Tiểu đường"],
        status: "approved",
        comments: [
          {
            senderId: doctorUser._id,
            content: "Chào bác, tiểu đường tuýp 2 là bệnh lý mãn tính không thể chữa khỏi dứt điểm hoàn toàn. Tuy nhiên, bằng cách duy trì lối sống lành mạnh, kiêng đồ ngọt tinh bột, tăng cường vận động và dùng thuốc theo chỉ định bác sĩ, bác hoàn toàn có thể kiểm soát tốt chỉ số HbA1c dưới 6.5% và sống khỏe mạnh bình thường.",
            createdAt: new Date(Date.now() - 24 * 60 * 60 * 1000) // 1 day ago
          }
        ]
      },
      {
        patientId: patientId,
        doctorId: null,
        isAnonymous: true,
        title: "Răng khôn mọc lệch nhưng không đau có cần nhổ không?",
        content: "Em đi chụp X-quang răng thì thấy răng khôn số 8 hàm dưới mọc lệch 90 độ đâm vào răng số 7. Hiện tại răng không đau nhức gì thì em có bắt buộc phải nhổ không ạ?",
        tags: ["Nha khoa", "Răng khôn"],
        status: "approved",
        comments: [] // Unanswered - allows doctor user to test inline reply
      }
    ];

    await Question.insertMany(samplePosts);
    console.log('✅ Successfully seeded 3 sample Q&A posts using new Question schema!');
    process.exit(0);
  } catch (error) {
    console.error('❌ Error seeding QA posts:', error);
    process.exit(1);
  }
};

seedQAPosts();
