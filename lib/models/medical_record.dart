class MedicalRecord {
  final String patientId;
  final String diagnosis;
  final double urea;
  final double cr;
  final double hba1c;
  final double chol;
  final double tg;
  final double hdl;
  final double ldl;
  final double vldl;
  final double bmi;
  final String status; // Mắc bệnh, không mắc, có nguy cơ
  final String doctorNote;
  final DateTime date;

  MedicalRecord({
    required this.patientId,
    required this.diagnosis,
    required this.urea,
    required this.cr,
    required this.hba1c,
    required this.chol,
    required this.tg,
    required this.hdl,
    required this.ldl,
    required this.vldl,
    required this.bmi,
    required this.status,
    required this.doctorNote,
    required this.date,
  });
}