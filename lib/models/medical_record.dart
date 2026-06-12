/// Canonical Flutter model for a Medical Record.
///
/// This model is the single source of truth that unifies:
/// 1. The Blockchain-anchored schema defined in `backend/models/medicalRecord.ts`
/// 2. The ERD definition: MedicalRecords with `pdfHash` (IPFS CID), `ipfsHash`,
///    and `blockchainTx` (Ethereum Transaction Hash anchor).
///
/// Architecture Note:
/// Each MedicalRecord is stored in MongoDB (off-chain) and its PDF hash
/// is anchored on the Ethereum private chain via a Smart Contract call.
/// The [blockchainTx] field stores the resulting transaction hash (Tx_Hash),
/// providing immutable proof of record integrity.
///
/// Relationship to ERD:
/// - MedicalRecords --[1..0]-- Appointments (via [appointmentId])
/// - MedicalRecords --[1..0.*]-- Prescriptions (prescriptions are sub-documents)
/// - MedicalRecords --[belongs_to]--> Users (patient via [patientId], doctor via [doctorId])
library;

/// Represents a single access log entry, recording who viewed this record and when.
///
/// Used for HIPAA-style audit trails and aligns with the `accessLogs` array
/// defined in `backend/models/medicalRecord.ts`.
class AccessLogEntry {
  /// The [ObjectId] string of the user who accessed this record.
  final String viewerId;

  /// The role of the viewer at the time of access (e.g., 'doctor', 'patient').
  final String role;

  /// ISO 8601 timestamp of the access event.
  final DateTime time;

  /// Creates an [AccessLogEntry].
  const AccessLogEntry({
    required this.viewerId,
    required this.role,
    required this.time,
  });

  /// Deserializes an [AccessLogEntry] from a JSON map.
  factory AccessLogEntry.fromJson(Map<String, dynamic> json) {
    return AccessLogEntry(
      viewerId: json['viewerId']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      time: json['time'] != null
          ? DateTime.tryParse(json['time'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }

  /// Serializes this entry to a JSON map for API submission.
  Map<String, dynamic> toJson() => {
        'viewerId': viewerId,
        'role': role,
        'time': time.toIso8601String(),
      };
}

/// The canonical Flutter data model for a Blockchain-anchored Medical Record.
///
/// This replaces the old lab-values-only model that was misaligned with the
/// active backend schema. All field names exactly mirror the MongoDB collection
/// defined in `backend/models/medicalRecord.ts`.
class MedicalRecord {
  // ══════════════════════════════════════════════════════════════════════════
  // IDENTITY & RELATIONSHIPS
  // ══════════════════════════════════════════════════════════════════════════

  /// MongoDB ObjectId string of this record. Maps to `_id`.
  final String id;

  /// ObjectId string of the patient this record belongs to.
  /// References the `Users` collection. Maps to `patientId`.
  final String patientId;

  /// ObjectId string of the doctor who created this record.
  /// References the `Users` collection. Maps to `doctorId`.
  final String doctorId;

  /// Snapshot of the patient's name at the time of record creation.
  /// Stored as a denormalized field for fast display without population.
  final String patientName;

  /// Optional reference to the [Appointment] that resulted in this record.
  /// Maps to `appointmentId` in the ERD.
  final String? appointmentId;

  // ══════════════════════════════════════════════════════════════════════════
  // CLINICAL DATA
  // ══════════════════════════════════════════════════════════════════════════

  /// The date of the medical visit. Maps to `visitDate`.
  final DateTime visitDate;

  /// Clinical symptoms reported by the patient. Maps to `symptoms`.
  final String symptoms;

  /// Doctor's diagnosis. Maps to `diagnosis`.
  final String diagnosis;

  /// Prescribed treatment plan. Maps to `treatment`.
  final String treatment;

  /// List of URLs pointing to uploaded attachments (X-rays, images, scans).
  /// Stored as Cloudinary CDN URLs. Maps to `attachments[]`.
  final List<String> attachments;

  // ══════════════════════════════════════════════════════════════════════════
  // STORAGE & BLOCKCHAIN ANCHORING
  // ══════════════════════════════════════════════════════════════════════════

  /// Cloudinary or storage URL of the generated PDF report. Maps to `pdfUrl`.
  final String? pdfUrl;

  /// SHA-256 hash of the generated PDF file.
  ///
  /// This hash is what gets anchored on the Ethereum chain via Smart Contract.
  /// Once anchored, any tampering with the PDF is detectable by re-computing
  /// this hash and comparing it against the on-chain value.
  /// Maps to `pdfHash` in the ERD and backend schema.
  final String? pdfHash;

  /// The IPFS Content Identifier (CID) of the uploaded PDF.
  ///
  /// Provides decentralized, content-addressed storage as a secondary
  /// integrity layer alongside blockchain anchoring. Maps to `ipfsHash`.
  final String? ipfsHash;

  // ── Ethereum Blockchain Anchor ────────────────────────────────────────────

  /// The Ethereum transaction hash returned after the Smart Contract call
  /// that anchored [pdfHash] on-chain.
  ///
  /// This is the "Tx_Hash" referenced in the ERD's Blockchain anchor notation.
  /// Can be verified on a blockchain explorer (e.g., Etherscan on Sepolia testnet).
  /// Maps to `blockchainTx`.
  final String? blockchainTx;

  /// The name of the Ethereum network used (e.g., 'sepolia', 'private').
  /// Maps to `blockchainNetwork`.
  final String? blockchainNetwork;

  /// The block number on the Ethereum chain where this transaction was mined.
  /// Maps to `blockNumber`.
  final int? blockNumber;

  /// Internal index within the anchoring transaction. Maps to `blockchainIndex`.
  final int? blockchainIndex;

  // ══════════════════════════════════════════════════════════════════════════
  // AUDIT & METADATA
  // ══════════════════════════════════════════════════════════════════════════

  /// Audit trail of all users who accessed this record.
  /// Maps to `accessLogs[]` in the backend schema.
  final List<AccessLogEntry> accessLogs;

  /// Timestamp when this record was first created in MongoDB.
  final DateTime? createdAt;

  // ══════════════════════════════════════════════════════════════════════════
  // CONSTRUCTOR
  // ══════════════════════════════════════════════════════════════════════════

  /// Creates a [MedicalRecord] with all required clinical and blockchain fields.
  const MedicalRecord({
    required this.id,
    required this.patientId,
    required this.doctorId,
    required this.patientName,
    this.appointmentId,
    required this.visitDate,
    required this.symptoms,
    required this.diagnosis,
    required this.treatment,
    this.attachments = const [],
    this.pdfUrl,
    this.pdfHash,
    this.ipfsHash,
    this.blockchainTx,
    this.blockchainNetwork,
    this.blockNumber,
    this.blockchainIndex,
    this.accessLogs = const [],
    this.createdAt,
  });

  // ══════════════════════════════════════════════════════════════════════════
  // SERIALIZATION
  // ══════════════════════════════════════════════════════════════════════════

  /// Deserializes a [MedicalRecord] from the JSON payload returned by the
  /// backend API endpoints (e.g., `GET /auth/api/medical-records/:id`).
  factory MedicalRecord.fromJson(Map<String, dynamic> json) {
    // Parse the attachments array safely, supporting both String lists
    // and potential null values from the API.
    final rawAttachments = json['attachments'];
    final List<String> attachmentsList = rawAttachments is List
        ? rawAttachments.map((e) => e?.toString() ?? '').toList()
        : [];

    // Parse the accessLogs array safely.
    final rawLogs = json['accessLogs'];
    final List<AccessLogEntry> logsList = rawLogs is List
        ? rawLogs
            .map((e) => AccessLogEntry.fromJson(e as Map<String, dynamic>))
            .toList()
        : [];

    return MedicalRecord(
      id: json['_id']?.toString() ?? '',
      patientId: json['patientId']?.toString() ?? '',
      doctorId: json['doctorId']?.toString() ?? '',
      patientName: json['patientName']?.toString() ?? '',
      appointmentId: json['appointmentId']?.toString(),
      visitDate: json['visitDate'] != null
          ? DateTime.tryParse(json['visitDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
      symptoms: json['symptoms']?.toString() ?? '',
      diagnosis: json['diagnosis']?.toString() ?? '',
      treatment: json['treatment']?.toString() ?? '',
      attachments: attachmentsList,
      pdfUrl: json['pdfUrl']?.toString(),
      pdfHash: json['pdfHash']?.toString(),
      ipfsHash: json['ipfsHash']?.toString(),
      blockchainTx: json['blockchainTx']?.toString(),
      blockchainNetwork: json['blockchainNetwork']?.toString(),
      blockNumber: json['blockNumber'] is int ? json['blockNumber'] : null,
      blockchainIndex:
          json['blockchainIndex'] is int ? json['blockchainIndex'] : null,
      accessLogs: logsList,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'].toString())
          : null,
    );
  }

  /// Serializes this [MedicalRecord] to a JSON map for API request bodies.
  /// Only includes the fields that the backend expects on creation/update.
  Map<String, dynamic> toJson() => {
        'patientId': patientId,
        'doctorId': doctorId,
        'patientName': patientName,
        if (appointmentId != null) 'appointmentId': appointmentId,
        'visitDate': visitDate.toIso8601String(),
        'symptoms': symptoms,
        'diagnosis': diagnosis,
        'treatment': treatment,
        'attachments': attachments,
      };

  /// Creates a copy of this [MedicalRecord] with optionally updated fields.
  /// Useful for state updates in UI layers.
  MedicalRecord copyWith({
    String? id,
    String? patientId,
    String? doctorId,
    String? patientName,
    String? appointmentId,
    DateTime? visitDate,
    String? symptoms,
    String? diagnosis,
    String? treatment,
    List<String>? attachments,
    String? pdfUrl,
    String? pdfHash,
    String? ipfsHash,
    String? blockchainTx,
    String? blockchainNetwork,
    int? blockNumber,
    int? blockchainIndex,
    List<AccessLogEntry>? accessLogs,
    DateTime? createdAt,
  }) {
    return MedicalRecord(
      id: id ?? this.id,
      patientId: patientId ?? this.patientId,
      doctorId: doctorId ?? this.doctorId,
      patientName: patientName ?? this.patientName,
      appointmentId: appointmentId ?? this.appointmentId,
      visitDate: visitDate ?? this.visitDate,
      symptoms: symptoms ?? this.symptoms,
      diagnosis: diagnosis ?? this.diagnosis,
      treatment: treatment ?? this.treatment,
      attachments: attachments ?? this.attachments,
      pdfUrl: pdfUrl ?? this.pdfUrl,
      pdfHash: pdfHash ?? this.pdfHash,
      ipfsHash: ipfsHash ?? this.ipfsHash,
      blockchainTx: blockchainTx ?? this.blockchainTx,
      blockchainNetwork: blockchainNetwork ?? this.blockchainNetwork,
      blockNumber: blockNumber ?? this.blockNumber,
      blockchainIndex: blockchainIndex ?? this.blockchainIndex,
      accessLogs: accessLogs ?? this.accessLogs,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// Returns true if this record has been successfully anchored on the
  /// Ethereum blockchain (i.e., [blockchainTx] is not null or empty).
  bool get isBlockchainAnchored =>
      blockchainTx != null && blockchainTx!.isNotEmpty;

  /// Returns true if this record's PDF has been pinned to IPFS.
  bool get isIpfsPinned => ipfsHash != null && ipfsHash!.isNotEmpty;

  @override
  String toString() =>
      'MedicalRecord(id: $id, patient: $patientName, diagnosis: $diagnosis, '
      'anchored: $isBlockchainAnchored)';
}