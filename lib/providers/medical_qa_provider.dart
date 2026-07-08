import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/medical_qa_service.dart';

// 1. Filter specialty state
final qaFilterProvider = StateProvider<String?>((ref) => null);

// 2. Search query state
final qaSearchQueryProvider = StateProvider<String>((ref) => '');

// 3. Approved posts list provider (watches filters and search queries to auto-update)
final qaPostsProvider = FutureProvider<List<MedicalPost>>((ref) async {
  final filter = ref.watch(qaFilterProvider);
  final query = ref.watch(qaSearchQueryProvider);

  // Fetch approved posts from Q&A service
  List<MedicalPost> posts =
      await MedicalQAService.getApprovedPosts(specialtyTag: filter);

  // Perform local search filtering if a search query is present
  if (query.isNotEmpty) {
    final lowerQuery = query.toLowerCase();
    posts = posts.where((p) {
      final titleMatch = p.title.toLowerCase().contains(lowerQuery);
      final contentMatch = p.content.toLowerCase().contains(lowerQuery);
      final tagMatch = p.tags.any((tag) => tag.toLowerCase().contains(lowerQuery));
      final doctorMatch =
          p.comments.any((c) => c.senderName.toLowerCase().contains(lowerQuery));
      return titleMatch || contentMatch || tagMatch || doctorMatch;
    }).toList();
  }

  return posts;
});
final pendingQuestionsProvider = Provider<List<MedicalPost>>((ref) {
  // Lắng nghe dữ liệu từ provider gốc
  final postsAsyncValue = ref.watch(qaPostsProvider);

  // Chỉ xử lý khi provider gốc đã lấy data thành công
  return postsAsyncValue.maybeWhen(
    data: (posts) {
      // 1. Lọc các câu chưa có bác sĩ nào trả lời (comments rỗng)
      final pending = posts.where((p) => p.comments.isEmpty).toList();

      // 2. Sắp xếp để câu mới nhất nằm trên cùng
      pending.sort((a, b) => b.createdAt.compareTo(a.createdAt));

      return pending;
    },
    // Nếu đang load hoặc lỗi thì trả về danh sách rỗng (ẩn Banner)
    orElse: () => [],
  );
});
// 4. Admin posts list provider
final adminPostsProvider = FutureProvider<List<MedicalPost>>((ref) async {
  // Requires token, will return empty list if not logged in
  return [];
});
// Định nghĩa một provider nhận vào String ID hồ sơ

