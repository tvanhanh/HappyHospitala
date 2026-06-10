/// Flutter data model for a Prescription.
///
/// Maps to the [Prescriptions] MongoDB collection defined in the ERD.
///
/// ERD Relationships:
/// - Prescriptions --[belongs_to]--> MedicalRecords (via [recordId])
/// - Prescriptions --[processed_by]--> pharmacy
/// - Prescriptions --[checks_stock]--> Inventories
///
/// Blockchain Anchor:
/// The [prescriptionHash] field stores the SHA-256 hash of the prescription
/// data anchored on the Ethereum chain for tamper-proof verification.
/// This corresponds to the ERD's `prescriptionHash: String (Blockchain Anchor)`.
library;

/// Represents a single line item within a prescription.
///
/// Maps to the embedded `items: Array[Object]` field in the Prescriptions collection.
class PrescriptionItem {
  /// MongoDB ObjectId of the drug in the [Inventories] collection.
  final String drugId;

  /// Human-readable name of the drug (denormalized for display).
  final String drugName;

  /// Prescribed dosage instructions (e.g., "2 viên/ngày sau ăn").
  final String dosage;

  /// Number of units prescribed.
  final int quantity;

  /// Unit of measurement (e.g., "viên", "mg", "ml").
  final String unit;

  /// Creates a [PrescriptionItem].
  const PrescriptionItem({
    required this.drugId,
    required this.drugName,
    required this.dosage,
    required this.quantity,
    required this.unit,
  });

  /// Deserializes a [PrescriptionItem] from a JSON map.
  factory PrescriptionItem.fromJson(Map<String, dynamic> json) {
    return PrescriptionItem(
      drugId: json['drugId']?.toString() ?? '',
      drugName: json['drugName']?.toString() ?? '',
      dosage: json['dosage']?.toString() ?? '',
      quantity: json['quantity'] is int ? json['quantity'] : 0,
      unit: json['unit']?.toString() ?? '',
    );
  }

  /// Serializes this item to a JSON map.
  Map<String, dynamic> toJson() => {
        'drugId': drugId,
        'drugName': drugName,
        'dosage': dosage,
        'quantity': quantity,
        'unit': unit,
      };
}

/// Possible statuses of a prescription in its lifecycle.
/// Defined as an Enum in the ERD: `Enum(Pending, Paid, Dispensed)`.
enum PrescriptionStatus {
  /// Prescription has been issued by the doctor but not yet filled.
  pending,

  /// Payment for the prescription has been processed by the cashier.
  paid,

  /// Drugs have been dispensed by the pharmacy.
  dispensed;

  /// Converts a raw API string to [PrescriptionStatus].
  static PrescriptionStatus fromString(String? value) {
    switch (value?.toLowerCase()) {
      case 'paid':
        return PrescriptionStatus.paid;
      case 'dispensed':
        return PrescriptionStatus.dispensed;
      case 'pending':
      default:
        return PrescriptionStatus.pending;
    }
  }

  /// Returns the raw string value stored in the database.
  String get value {
    switch (this) {
      case PrescriptionStatus.pending:
        return 'Pending';
      case PrescriptionStatus.paid:
        return 'Paid';
      case PrescriptionStatus.dispensed:
        return 'Dispensed';
    }
  }

  /// Vietnamese display label for UI.
  String get displayName {
    switch (this) {
      case PrescriptionStatus.pending:
        return 'Chờ thanh toán';
      case PrescriptionStatus.paid:
        return 'Đã thanh toán';
      case PrescriptionStatus.dispensed:
        return 'Đã cấp thuốc';
    }
  }
}

/// The canonical Flutter model for a Prescription document.
///
/// A [Prescription] is created by a doctor during medical examination and
/// goes through a workflow: Pending → Paid (cashier) → Dispensed (pharmacy).
class Prescription {
  // ── Identity ───────────────────────────────────────────────────────────────

  /// MongoDB ObjectId string. Maps to `_id`.
  final String id;

  /// Reference to the parent [MedicalRecord]. Maps to `recordId`.
  final String recordId;

  // ── Clinical Content ───────────────────────────────────────────────────────

  /// List of prescribed drug items with dosage and quantity.
  /// Maps to `items: Array[Object]` (embedded).
  final List<PrescriptionItem> items;

  // ── Workflow Status ────────────────────────────────────────────────────────

  /// Current status in the Pending → Paid → Dispensed workflow.
  /// Maps to `status: Enum(Pending, Paid, Dispensed)`.
  final PrescriptionStatus status;

  // ── Blockchain Anchor ──────────────────────────────────────────────────────

  /// SHA-256 hash of the prescription data anchored on the Ethereum chain.
  ///
  /// Computed by hashing the serialized prescription and submitting it to
  /// the Smart Contract. Provides tamper-proof proof of the original order.
  /// Maps to `prescriptionHash: String (Blockchain Anchor)` in the ERD.
  final String? prescriptionHash;

  // ── Metadata ───────────────────────────────────────────────────────────────

  /// Timestamp when this prescription was created.
  final DateTime? createdAt;

  /// Optional patient name for display purposes.
  final String? patientName;

  /// Optional doctor name for display purposes.
  final String? doctorName;

  /// Creates a [Prescription].
  const Prescription({
    required this.id,
    required this.recordId,
    required this.items,
    required this.status,
    this.prescriptionHash,
    this.createdAt,
    this.patientName,
    this.doctorName,
  });

  /// Deserializes a [Prescription] from a backend API JSON payload.
  factory Prescription.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'];
    final List<PrescriptionItem> itemsList = rawItems is List
        ? rawItems
            .map((e) => PrescriptionItem.fromJson(e as Map<String, dynamic>))
            .toList()
        : [];

    return Prescription(
      id: json['_id']?.toString() ?? '',
      recordId: json['recordId']?.toString() ?? '',
      items: itemsList,
      status: PrescriptionStatus.fromString(json['status']?.toString()),
      prescriptionHash: json['prescriptionHash']?.toString(),
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
      patientName: json['patientName']?.toString(),
      doctorName: json['doctorName']?.toString(),
    );
  }

  /// Serializes this [Prescription] to a JSON map for API requests.
  Map<String, dynamic> toJson() => {
        'recordId': recordId,
        'items': items.map((e) => e.toJson()).toList(),
        'status': status.value,
      };

  /// Returns the total number of drug line items in this prescription.
  int get totalItems => items.length;

  /// Returns true if this prescription has been anchored on the blockchain.
  bool get isAnchored =>
      prescriptionHash != null && prescriptionHash!.isNotEmpty;

  /// Creates a copy with optionally updated fields.
  Prescription copyWith({
    String? id,
    String? recordId,
    List<PrescriptionItem>? items,
    PrescriptionStatus? status,
    String? prescriptionHash,
    DateTime? createdAt,
    String? patientName,
    String? doctorName,
  }) {
    return Prescription(
      id: id ?? this.id,
      recordId: recordId ?? this.recordId,
      items: items ?? this.items,
      status: status ?? this.status,
      prescriptionHash: prescriptionHash ?? this.prescriptionHash,
      createdAt: createdAt ?? this.createdAt,
      patientName: patientName ?? this.patientName,
      doctorName: doctorName ?? this.doctorName,
    );
  }
}
