import 'package:flutter_test/flutter_test.dart';
import 'package:zola/domain/models/todo_item.dart';

void main() {
  group('TodoItem', () {
    test('stores all provided values', () {
      const item = TodoItem(userId: 1, id: 2, title: 'Todo', completed: false);

      expect(item.userId, 1);
      expect(item.id, 2);
      expect(item.title, 'Todo');
      expect(item.completed, isFalse);
    });
  });
}
