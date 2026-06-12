/// Flutter data model for an AI Prediction result.
///
/// Maps to the [AIPredictions] MongoDB collection defined in the ERD.
///
/// ERD Relationships:
/// - AIPredictions --[conducted_by]--> Users (patient via [patientId])
/// - AIPredictions --[reviewed_by]--> Users (doctor via [doctorId])
///
/// AI Models Supported (per ERD & thesis):
/// - [AiModelType.knn] — Custom Weighted KNN + Fuzzy KNN for Diabetes prediction
///   Input features: Gender, AGE, Urea, Cr, HbA1c, Chol, TG, HDL, LDL, VLDL, BMI
///   Output classes: N (No diabetes), Y (Diabetic), P (Pre-diabetic)
///
/// - [AiModelType.cnn] — MobileNetV2 Transfer Learning for Skin Lesion analysis
///   Input: Base64-encoded dermoscopy image
///   Output: Benign / Malignant / Acne / classification with confidence score
library;

/// Identifies which AI model produced this prediction.
/// Defined as `aiModel: Enum(KNN, CNN)` in the ERD.
enum AiModelType {
  /// Custom Weighted KNN + Fuzzy KNN for Diabetes prediction (Scikit-Learn).
  knn,

  /// MobileNetV2 Transfer Learning for Skin Lesion / Acne analysis (TensorFlow).
  cnn;

  /// Converts a raw API string to [AiModelType].
  static AiModelType fromString(String? value) {
    switch (value?.toUpperCase()) {
      case 'CNN':
        return AiModelType.cnn;
      case 'KNN':
      default:
        return AiModelType.knn;
    }
  }

  /// Raw string stored in the database.
  String get value => this == AiModelType.knn ? 'KNN' : 'CNN';

  /// Human-readable description for UI display.
  String get displayName {
    switch (this) {
      case AiModelType.knn:
        return 'Dự đoán Tiểu đường (KNN)';
      case AiModelType.cnn:
        return 'Phân tích Da liễu (MobileNetV2)';
    }
  }
}

/// Possible statuses of an AI prediction request.
/// Maps to `predictionStatus: String` in the ERD.
enum PredictionStatus {
  /// The AI service is currently processing the request.
  processing,

  /// Prediction completed successfully.
  completed,

  /// The AI service returned an error.
  failed;

  /// Converts a raw API string to [PredictionStatus].
  static PredictionStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'completed':
        return PredictionStatus.completed;
      case 'failed':
        return PredictionStatus.failed;
      case 'processing':
      default:
        return PredictionStatus.processing;
    }
  }

  /// Raw string stored in the database.
  String get value {
    switch (this) {
      case PredictionStatus.processing:
        return 'processing';
      case PredictionStatus.completed:
        return 'completed';
      case PredictionStatus.failed:
        return 'failed';
    }
  }
}

/// Holds the quantitative metrics returned by the AI model.
///
/// Maps to `metrics: Object (embedded)` in the ERD.
/// Structure varies by [AiModelType]:
/// - KNN: `{ prediction: "Y|N|P", confidence: 0.95, probabilities: {...} }`
/// - CNN: `{ label: "Malignant", confidence: 0.88, topClasses: [...] }`
class PredictionMetrics {
  /// The raw predicted class label (e.g., "Y", "N", "P" for KNN;
  /// "Benign", "Malignant" for CNN).
  final String? predictedLabel;

  /// Confidence score (0.0 – 1.0) for the top predicted class.
  final double? confidence;

  /// Full probability distribution across all classes.
  /// Key: class label, Value: probability (0.0 – 1.0).
  final Map<String, double> probabilities;

  /// Additional model-specific metadata (e.g., k value for KNN, layer info for CNN).
  final Map<String, dynamic> extra;

  /// Creates a [PredictionMetrics].
  const PredictionMetrics({
    this.predictedLabel,
    this.confidence,
    this.probabilities = const {},
    this.extra = const {},
  });

  /// Deserializes [PredictionMetrics] from the embedded metrics JSON object.
  factory PredictionMetrics.fromJson(Map<String, dynamic> json) {
    final rawProbabilities = json['probabilities'];
    final Map<String, double> probMap = rawProbabilities is Map
        ? rawProbabilities
            .map((k, v) => MapEntry(k.toString(), (v as num).toDouble()))
        : {};

    return PredictionMetrics(
      predictedLabel: json['predictedLabel']?.toString() ??
          json['prediction']?.toString() ??
          json['label']?.toString(),
      confidence: (json['confidence'] as num?)?.toDouble(),
      probabilities: probMap,
      extra: Map<String, dynamic>.from(json)
        ..removeWhere(
            (k, _) => ['predictedLabel', 'prediction', 'label',
                        'confidence', 'probabilities'].contains(k)),
    );
  }

  /// Confidence as a percentage string (e.g., "94.3%").
  String get confidencePercent =>
      confidence != null ? '${(confidence! * 100).toStringAsFixed(1)}%' : '--';
}

/// The canonical Flutter model for a persisted AI Prediction record.
///
/// Created each time a patient or doctor triggers an AI analysis.
/// Stored in the [AIPredictions] collection for historical tracking
/// and doctor review, enabling follow-up care decisions.
class AiPrediction {
  // ── Identity ───────────────────────────────────────────────────────────────

  /// MongoDB ObjectId string. Maps to `_id`.
  final String id;

  /// ObjectId of the patient who initiated this prediction.
  /// Maps to `patientId: ObjectId <ref>` in the ERD.
  final String patientId;

  /// ObjectId of the doctor who reviewed or ordered this prediction.
  /// Maps to `doctorId: ObjectId <ref>` in the ERD.
  final String? doctorId;

  // ── AI Model & Results ─────────────────────────────────────────────────────

  /// Which AI model produced this prediction.
  /// Maps to `aiModel: Enum(KNN, CNN)` in the ERD.
  final AiModelType aiModel;

  /// Quantitative metrics returned by the AI inference engine.
  /// Maps to `metrics: Object (embedded)` in the ERD.
  final PredictionMetrics metrics;

  /// Current status of the prediction request.
  /// Maps to `predictionStatus: String` in the ERD.
  final PredictionStatus predictionStatus;

  // ── Input Data ─────────────────────────────────────────────────────────────

  /// The raw input data sent to the AI model.
  ///
  /// For KNN: lab values map (urea, hba1c, bmi, etc.)
  /// For CNN: `{ imageBase64: "..." }` or Cloudinary URL reference.
  final Map<String, dynamic> inputData;

  // ── Metadata ───────────────────────────────────────────────────────────────

  /// Patient display name for list views (denormalized).
  final String? patientName;

  /// Timestamp when this prediction was created.
  final DateTime? createdAt;

  /// Creates an [AiPrediction].
  const AiPrediction({
    required this.id,
    required this.patientId,
    this.doctorId,
    required this.aiModel,
    required this.metrics,
    required this.predictionStatus,
    this.inputData = const {},
    this.patientName,
    this.createdAt,
  });

  /// Deserializes an [AiPrediction] from a backend API JSON payload.
  factory AiPrediction.fromJson(Map<String, dynamic> json) {
    final rawMetrics = json['metrics'];
    final metricsObj = rawMetrics is Map<String, dynamic>
        ? PredictionMetrics.fromJson(rawMetrics)
        : const PredictionMetrics();

    return AiPrediction(
      id: json['_id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      doctorId: json['doctorId']?.toString(),
      aiModel: AiModelType.fromString(json['aiModel']?.toString()),
      metrics: metricsObj,
      predictionStatus:
          PredictionStatus.fromString(json['predictionStatus']?.toString()),
      inputData: json['inputData'] is Map<String, dynamic>
          ? json['inputData'] as Map<String, dynamic>
          : {},
      patientName: json['patientName']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  /// Serializes this [AiPrediction] to a JSON map for API submission.
  Map<String, dynamic> toJson() => {
        'patientId': patientId,
        if (doctorId != null) 'doctorId': doctorId,
        'aiModel': aiModel.value,
        'predictionStatus': predictionStatus.value,
        'inputData': inputData,
      };

  /// Returns true if this prediction has completed successfully.
  bool get isCompleted => predictionStatus == PredictionStatus.completed;

  /// Creates a copy with optionally updated fields.
  AiPrediction copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    AiModelType? aiModel,
    PredictionMetrics? metrics,
    PredictionStatus? predictionStatus,
    Map<String, dynamic>? inputData,
    String? patientName,
    DateTime? createdAt,
  }) {
    return AiPrediction(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      aiModel: aiModel ?? this.aiModel,
      metrics: metrics ?? this.metrics,
      predictionStatus: predictionStatus ?? this.predictionStatus,
      inputData: inputData ?? this.inputData,
      patientName: patientName ?? this.patientName,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
