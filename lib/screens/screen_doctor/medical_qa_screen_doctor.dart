import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../models/app_role.dart';
import '../../providers/auth_provider.dart';
import '../../providers/medical_qa_provider.dart';
import '../../services/medical_qa_service.dart';

// Đảm bảo bạn đã khai báo doctorSpecialtyProvider ở đâu đó trong app của bạn.
// Ví dụ: final doctorSpecialtyProvider = Provider<String>((ref) => 'Nha khoa');

// Premium Medical Theme Colors aligned with Saas Clinic
const Color _kPrimary = Color(0xFF2563EB);
const Color _kBackground = Color(0xFFF8FAFC);
const Color _kTextPrimary = Color(0xFF0F172A);
const Color _kTextSecondary = Color(0xFF64748B);
const Color _kSuccess = Color(0xFF10B981);
const Color _kBorder = Color(0xFFE2E8F0);

class MedicalQADoctorScreen extends ConsumerStatefulWidget {
  const MedicalQADoctorScreen({super.key});

  @override
  ConsumerState<MedicalQADoctorScreen> createState() =>
      _MedicalQADoctorScreenState();
}

class _MedicalQADoctorScreenState extends ConsumerState<MedicalQADoctorScreen> {
  final TextEditingController _searchController = TextEditingController();

  // Thay vì list chuyên khoa, ta chỉ dùng 2 tab trạng thái.
  // Mặc định gán là "Chưa trả lời" để khi bay từ trang khác sang là lọc sẵn.
  final List<String> _statusTabs = ["Chưa trả lời", "Tất cả"];
  String _selectedTab = "Chưa trả lời";
  String _currentSpecialty = '';
  bool _isLoadingSpecialty = true;
  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void initState() {
    super.initState();
    // 2. Gọi hàm tải dữ liệu ngay khi màn hình khởi tạo
    _loadSpecialty();
  }

  Future<void> _loadSpecialty() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _currentSpecialty = prefs.getString("specialty") ?? '';
        _isLoadingSpecialty = false; // Đã tải xong
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoadingSpecialty) {
      return const Scaffold(
        backgroundColor: _kBackground,
        body: Center(child: CircularProgressIndicator(color: _kPrimary)),
      );
    }

    final postsAsync = ref.watch(qaPostsProvider);
    final authState = ref.watch(authProvider);
    final searchQuery = ref.watch(qaSearchQueryProvider);
    final currentSpecialty = _currentSpecialty; // Lấy chuyên khoa của BS

    return Scaffold(
      backgroundColor: _kBackground,
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              'Góc Tư vấn Sức khỏe Q&A',
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: Colors.white),
            ),
            if (currentSpecialty.isNotEmpty)
              Text(
                'Chuyên khoa: $currentSpecialty',
                style: const TextStyle(fontSize: 12, color: Colors.white70),
              )
          ],
        ),
        centerTitle: true,
        backgroundColor: _kPrimary,
        elevation: 0,
        leading: IconButton(
          icon:
              const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SelectionArea(
        child: Column(
          children: [
            // ── TOP SECTION: Search Bar & Status Filter Chips ────────────
            Container(
              color: Colors.white,
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  // Premium Search Bar
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: _kBorder),
                    ),
                    child: TextField(
                      controller: _searchController,
                      onChanged: (val) {
                        ref.read(qaSearchQueryProvider.notifier).state =
                            val.trim();
                      },
                      style:
                          const TextStyle(fontSize: 14, color: _kTextPrimary),
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm câu hỏi, triệu chứng...',
                        hintStyle: const TextStyle(
                            color: _kTextSecondary, fontSize: 13),
                        prefixIcon:
                            const Icon(Icons.search_rounded, color: _kPrimary),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear_rounded,
                                    color: _kTextSecondary, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  ref
                                      .read(qaSearchQueryProvider.notifier)
                                      .state = '';
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        contentPadding:
                            const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Trạng thái List Row (Chưa trả lời / Tất cả)
                  SizedBox(
                    height: 40,
                    child: Row(
                      children: _statusTabs.map((tab) {
                        final isSelected = _selectedTab == tab;
                        return Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: ChoiceChip(
                            label: Text(
                              tab,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color:
                                    isSelected ? Colors.white : _kTextSecondary,
                              ),
                            ),
                            selected: isSelected,
                            onSelected: (selected) {
                              if (selected) {
                                setState(() {
                                  _selectedTab = tab;
                                });
                              }
                            },
                            selectedColor: _kPrimary,
                            backgroundColor: const Color(0xFFF1F5F9),
                            checkmarkColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                              side: const BorderSide(color: Colors.transparent),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ),

            // ── FEED LIST (ĐÃ TÍCH HỢP LOGIC LỌC TỔNG HỢP) ─────────────────
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async {
                  ref.invalidate(qaPostsProvider);
                },
                child: postsAsync.when(
                  data: (allPosts) {
                    // 1. Logic lọc mượt mà tại đây
                    final filteredPosts = allPosts.where((p) {
                      // Lọc theo Chuyên khoa của Bác sĩ (So khớp Tags)
                      final isMatchingSpecialty = currentSpecialty.isEmpty ||
                          p.tags.any((tag) => tag
                              .toLowerCase()
                              .contains(currentSpecialty.toLowerCase()));

                      if (!isMatchingSpecialty) return false;

                      // Lọc theo Tab (Chưa trả lời vs Tất cả)
                      if (_selectedTab == "Chưa trả lời") {
                        if (p.comments.isNotEmpty) return false;
                      }

                      // Lọc theo Tìm kiếm (Search Query)
                      if (searchQuery != null && searchQuery.isNotEmpty) {
                        final query = searchQuery.toLowerCase();
                        final matchSearch =
                            p.title.toLowerCase().contains(query) ||
                                p.content.toLowerCase().contains(query);
                        if (!matchSearch) return false;
                      }

                      return true; // Pass qua tất cả điều kiện thì giữ lại
                    }).toList();

                    // 2. Hiển thị UI sau khi lọc
                    if (filteredPosts.isEmpty) {
                      return ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: [
                          SizedBox(
                              height: MediaQuery.of(context).size.height * 0.2),
                          Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check_circle_outline_rounded,
                                    size: 64, color: _kSuccess),
                                const SizedBox(height: 16),
                                Text(
                                  _selectedTab == "Chưa trả lời"
                                      ? "Tuyệt vời! Không có câu hỏi nào đang chờ."
                                      : "Chưa có dữ liệu câu hỏi phù hợp.",
                                  style: const TextStyle(
                                      color: _kTextSecondary,
                                      fontSize: 14,
                                      fontWeight: FontWeight.w500),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filteredPosts.length,
                      itemBuilder: (context, index) {
                        return _PostCard(post: filteredPosts[index]);
                      },
                    );
                  },
                  loading: () => const Center(
                    child: CircularProgressIndicator(color: _kPrimary),
                  ),
                  error: (err, stack) => Center(
                    child: Text(
                      "Lỗi tải dữ liệu: $err",
                      style: const TextStyle(color: Colors.redAccent),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      // Giữ nguyên FAB cho role Patient (mặc dù đây là màn Bác Sĩ, tuỳ logic app của bạn)
      floatingActionButton: authState.isAuthenticated &&
              authState.role == AppRole.patient
          ? FloatingActionButton.extended(
              onPressed: () => _showAskQuestionBottomSheet(context),
              backgroundColor: _kPrimary,
              icon: const Icon(Icons.add_comment_rounded, color: Colors.white),
              label: const Text(
                "Đặt câu hỏi ẩn danh",
                style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            )
          : null,
    );
  }

  // Open BottomSheet Form to Ask Question
  void _showAskQuestionBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AskQuestionBottomSheet(),
    );
  }
}

// ── ASK QUESTION BOTTOM SHEET FORM ──────────────────────────────────────────
class _AskQuestionBottomSheet extends ConsumerStatefulWidget {
  const _AskQuestionBottomSheet();

  @override
  ConsumerState<_AskQuestionBottomSheet> createState() =>
      _AskQuestionBottomSheetState();
}

class _AskQuestionBottomSheetState
    extends ConsumerState<_AskQuestionBottomSheet> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  bool _isAnonymous = true; // default true
  String? _selectedSpecialty;
  bool _isSubmitting = false;

  final List<String> _specialties = [
    "Da liễu",
    "Nội tiết",
    "Nha khoa",
    "Tim mạch",
    "Cơ xương khớp",
    "Nhi khoa",
    "Tai Mũi Họng",
    "Mắt",
    "Tiêu hóa",
    "Tổng quát"
  ];

  @override
  void initState() {
    super.initState();
    _titleController.addListener(_onTextChanged);
    _contentController.addListener(_onTextChanged);
  }

  void _onTextChanged() {
    setState(() {});
  }

  @override
  void dispose() {
    _titleController.removeListener(_onTextChanged);
    _contentController.removeListener(_onTextChanged);
    _titleController.dispose();
    _contentController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
    });

    final token = ref.read(authProvider).token ?? '';
    final errorMsg = await MedicalQAService.createQuestion(
      token: token,
      title: _titleController.text.trim(),
      content: _contentController.text.trim(),
      isAnonymous: _isAnonymous,
      specialtyTag: _selectedSpecialty,
    );

    if (mounted) {
      setState(() {
        _isSubmitting = false;
      });

      if (errorMsg == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content:
                Text('Câu hỏi của bạn đã được gửi và phê duyệt thành công.'),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.invalidate(qaPostsProvider);
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMsg)),
              ],
            ),
            backgroundColor: const Color(0xFFC62828),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final bool canSubmit = _titleController.text.trim().length >= 15 &&
        _contentController.text.trim().length >= 50;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        top: 20,
        left: 20,
        right: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                "Hỏi Đáp Bác Sĩ Tư Vấn",
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _kTextPrimary),
              ),
              const SizedBox(height: 4),
              const Text(
                "Câu hỏi sẽ được chuyển đến bác sĩ có chuyên môn phù hợp.",
                style: TextStyle(fontSize: 12, color: _kTextSecondary),
              ),
              const SizedBox(height: 20),
              // Title Field
              TextFormField(
                controller: _titleController,
                maxLength: 100,
                style: const TextStyle(fontSize: 14, color: _kTextPrimary),
                decoration: InputDecoration(
                  labelText: "Tiêu đề câu hỏi *",
                  labelStyle:
                      const TextStyle(fontSize: 13, color: _kTextSecondary),
                  hintText: "Ví dụ: Hỏi về bệnh chàm da cơ địa trẻ em...",
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                  counterText: "",
                  helperText:
                      "Tối thiểu 15 ký tự (${_titleController.text.length}/100)",
                  helperStyle: TextStyle(
                    fontSize: 11,
                    color: _titleController.text.length < 15
                        ? Colors.redAccent
                        : Colors.grey,
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kPrimary, width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Vui lòng nhập tiêu đề';
                  if (val.trim().length < 15)
                    return 'Tiêu đề quá ngắn (tối thiểu 15 ký tự)';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Content Field
              TextFormField(
                controller: _contentController,
                maxLines: 4,
                style: const TextStyle(fontSize: 14, color: _kTextPrimary),
                decoration: InputDecoration(
                  labelText: "Chi tiết triệu chứng & câu hỏi *",
                  labelStyle:
                      const TextStyle(fontSize: 13, color: _kTextSecondary),
                  hintText:
                      "Mô tả cụ thể triệu chứng, thời gian mắc phải, tình trạng hiện tại...",
                  hintStyle: const TextStyle(fontSize: 13, color: Colors.grey),
                  helperText:
                      "Tối thiểu 50 ký tự (${_contentController.text.length}/50 min)",
                  helperStyle: TextStyle(
                    fontSize: 11,
                    color: _contentController.text.length < 50
                        ? Colors.redAccent
                        : Colors.grey,
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: _kPrimary, width: 1.5),
                  ),
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty)
                    return 'Vui lòng mô tả chi tiết triệu chứng';
                  if (val.trim().length < 50)
                    return 'Vui lòng mô tả chi tiết hơn (tối thiểu 50 ký tự)';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              // Specialty Dropdown (Optional, AI will auto assign if empty)
              DropdownButtonFormField<String>(
                value: _selectedSpecialty,
                style: const TextStyle(fontSize: 14, color: _kTextPrimary),
                decoration: InputDecoration(
                  labelText: "Chọn Chuyên khoa (Không bắt buộc)",
                  labelStyle:
                      const TextStyle(fontSize: 13, color: _kTextSecondary),
                  helperText:
                      "Hệ thống AI sẽ tự động phân loại chuyên khoa nếu để trống.",
                  helperStyle: const TextStyle(
                      fontSize: 10,
                      color: _kPrimary,
                      fontWeight: FontWeight.w500),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: _specialties.map((s) {
                  return DropdownMenuItem(
                    value: s,
                    child: Text(s),
                  );
                }).toList(),
                onChanged: (val) {
                  setState(() {
                    _selectedSpecialty = val;
                  });
                },
              ),
              const SizedBox(height: 12),
              // Anonymous Checkbox
              CheckboxListTile(
                contentPadding: EdgeInsets.zero,
                value: _isAnonymous,
                onChanged: (val) {
                  setState(() {
                    _isAnonymous = val ?? true;
                  });
                },
                title: const Text(
                  "Đăng ẩn danh (Ẩn tên và ảnh đại diện của bạn với các bệnh nhân khác)",
                  style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: _kTextPrimary),
                ),
                controlAffinity: ListTileControlAffinity.leading,
                activeColor: _kPrimary,
              ),
              const SizedBox(height: 24),
              // Submit Button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  onPressed: (_isSubmitting || !canSubmit) ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _kPrimary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text(
                          "Gửi câu hỏi cho Bác sĩ",
                          style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 14),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── INDIVIDUAL Q&A POST CARD ────────────────────────────────────────────────
class _PostCard extends ConsumerStatefulWidget {
  final MedicalPost post;
  const _PostCard({required this.post});

  @override
  ConsumerState<_PostCard> createState() => _PostCardState();
}

class _PostCardState extends ConsumerState<_PostCard> {
  bool _isExpanded = false;
  final TextEditingController _answerController = TextEditingController();
  bool _isSubmittingAnswer = false;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _submitDoctorAnswer() async {
    final text = _answerController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _isSubmittingAnswer = true;
    });

    final token = ref.read(authProvider).token ?? '';
    final errorMsg = await MedicalQAService.submitAnswer(
      token: token,
      postId: widget.post.id,
      responseText: text,
    );

    if (mounted) {
      setState(() {
        _isSubmittingAnswer = false;
      });

      if (errorMsg == null) {
        _answerController.clear();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Gửi bình luận thành công.'),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
          ),
        );
        ref.invalidate(qaPostsProvider);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.error_outline, color: Colors.white),
                const SizedBox(width: 8),
                Expanded(child: Text(errorMsg)),
              ],
            ),
            backgroundColor: const Color(0xFFC62828),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final currentUserId = authState.userId;
    final currentUserRole = authState.role;

    final isOwnerPatient = authState.isAuthenticated &&
        currentUserRole == AppRole.patient &&
        widget.post.patientId == currentUserId;

    final isAssignedDoctor = authState.isAuthenticated &&
        currentUserRole == AppRole.doctor &&
        (widget.post.doctorId == null || widget.post.doctorId == currentUserId);

    final canComment = isOwnerPatient || isAssignedDoctor;
    final hasAnswers = widget.post.comments.isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: _kBorder),
      ),
      color: Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row with Specialty Badge and Created Date
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _kPrimary.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "# ${widget.post.tags}",
                    style: const TextStyle(
                      color: _kPrimary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
                Text(
                  DateFormat('dd/MM/yyyy • HH:mm')
                      .format(widget.post.createdAt),
                  style: const TextStyle(color: _kTextSecondary, fontSize: 11),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Title Question
            Text(
              widget.post.title,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.bold,
                color: _kTextPrimary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 8),
            // Question Content (collapsible)
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.post.content,
                    maxLines: _isExpanded ? 100 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                        fontSize: 13, color: _kTextPrimary, height: 1.45),
                  ),
                  if (widget.post.content.length > 120) ...[
                    const SizedBox(height: 4),
                    Text(
                      _isExpanded ? "Thu gọn" : "Xem thêm chi tiết",
                      style: const TextStyle(
                        color: _kPrimary,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            // Patient details row
            Row(
              children: [
                CircleAvatar(
                  radius: 12,
                  backgroundColor: _kPrimary.withOpacity(0.1),
                  backgroundImage: (!widget.post.isAnonymous &&
                          widget.post.patientAvatar != null)
                      ? NetworkImage(widget.post.patientAvatar!)
                      : null,
                  child: (widget.post.isAnonymous ||
                          widget.post.patientAvatar == null)
                      ? const Icon(Icons.person, size: 14, color: _kPrimary)
                      : null,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      children: [
                        TextSpan(
                          text: widget.post.isAnonymous
                              ? "Bệnh nhân ẩn danh"
                              : (widget.post.patientName ??
                                  "Bệnh nhân hệ thống"),
                          style: const TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: _kTextPrimary, // Tên người dùng màu đậm
                          ),
                        ),
                        const TextSpan(
                          text: " • Người hỏi", // Thêm role ở đây
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: _kTextSecondary, // Role màu xám nhạt hơn
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            const Divider(height: 1, color: _kBorder),
            const SizedBox(height: 16),
            // ── DISCUSSION / COMMENTS BLOCK ─────────────────────────────────
            if (hasAnswers) ...[
              const Text(
                "THẢO LUẬN Y KHOA:",
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 0.5,
                  color: _kPrimary,
                ),
              ),
              const SizedBox(height: 10),
              Column(
                children: widget.post.comments.map((comment) {
                  final isCommentDoctor = comment.senderTitle == 'Bác sĩ';
                  final bool canShowInfo =
                      isCommentDoctor || !widget.post.isAnonymous;
                  final String? displayAvatar =
                      canShowInfo ? comment.senderAvatar : null;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isCommentDoctor
                          ? const Color(0xFFEFF6FF)
                          : const Color(0xFFF8FAFC),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isCommentDoctor
                            ? const Color(0xFFDBEAFE)
                            : const Color(0xFFE2E8F0),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: CircleAvatar(
                                radius: 12,
                                backgroundColor: _kPrimary.withOpacity(0.1),
                                // Thêm dòng này để tải ảnh từ URL
                                backgroundImage: displayAvatar != null
                                    ? NetworkImage(displayAvatar)
                                    : null,
                                // Chỉ hiện Icon nếu displayAvatar bị null
                                child: displayAvatar == null
                                    ? Icon(
                                        isCommentDoctor
                                            ? Icons.verified_rounded
                                            : Icons.person_outline_rounded,
                                        color: isCommentDoctor
                                            ? Colors.blue
                                            : Colors.grey,
                                        size: 16,
                                      )
                                    : null, // Xóa child (Icon) nếu đã có ảnh
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  children: [
                                    TextSpan(
                                      text: isCommentDoctor
                                          ? "${comment.senderTitle} ${comment.senderName}"
                                          : comment.senderName,
                                      style: const TextStyle(
                                        color: _kTextPrimary,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                    TextSpan(
                                      text: isCommentDoctor
                                          ? " • Bác sĩ chuyên khoa"
                                          : " • Người hỏi",
                                      style: TextStyle(
                                        color: isCommentDoctor
                                            ? _kPrimary
                                            : _kTextSecondary,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          comment.content,
                          style: const TextStyle(
                              fontSize: 13, color: _kTextPrimary, height: 1.45),
                        ),
                        const SizedBox(height: 6),
                        Align(
                          alignment: Alignment.bottomRight,
                          child: Text(
                            DateFormat('dd/MM/yyyy HH:mm')
                                .format(comment.createdAt),
                            style: TextStyle(
                                color: Colors.grey.shade400, fontSize: 9),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              // If NO replies yet
              Row(
                children: [
                  Icon(Icons.hourglass_empty_rounded,
                      size: 16, color: Colors.amber.shade700),
                  const SizedBox(width: 6),
                  Text(
                    "Đang chờ ý kiến tư vấn từ bác sĩ chuyên khoa...",
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.amber.shade800,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ],
            // ── COMMENT / DISCUSSION BOX ───────────────────────────────────
            if (canComment) ...[
              const SizedBox(height: 16),
              const Text(
                "Tham gia thảo luận:",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: _kTextPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8FAFC),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _kBorder),
                      ),
                      child: TextField(
                        controller: _answerController,
                        maxLines: null,
                        style:
                            const TextStyle(fontSize: 13, color: _kTextPrimary),
                        decoration: const InputDecoration(
                          hintText: "Nhập lời khuyên hoặc ý kiến của bạn...",
                          hintStyle:
                              TextStyle(fontSize: 12, color: _kTextSecondary),
                          border: InputBorder.none,
                          contentPadding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 38,
                    child: ElevatedButton(
                      onPressed:
                          _isSubmittingAnswer ? null : _submitDoctorAnswer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kPrimary,
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: _isSubmittingAnswer
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : const Text(
                              "Gửi",
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                    ),
                  ),
                ],
              ),
            ] else ...[
              const SizedBox(height: 16),
              Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.lock_outline_rounded,
                        size: 16, color: _kTextSecondary),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        "Chỉ bác sĩ phụ trách và người hỏi được quyền thảo luận tại đây.",
                        style: TextStyle(
                          fontSize: 12,
                          color: _kTextSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
