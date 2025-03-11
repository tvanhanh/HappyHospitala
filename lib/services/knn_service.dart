class KnnService {
  // Giả lập thuật toán KNN để dự đoán bệnh
  String predictDiabetes(double glucose, double bmi, double age) {
    // Giả lập logic dự đoán
    if (glucose > 140 || bmi > 30) {
      return "Có nguy cơ mắc bệnh tiểu đường";
    }
    return "Không có nguy cơ mắc bệnh";
  }
}
