import 'package:flutter_test/flutter_test.dart';
import 'package:zola/data/models/todo_api_model.dart';

void main() {
  group('TodoApiModel', () {
    test('fromJson maps all fields', () {
      final model = TodoApiModel.fromJson(<String, dynamic>{
        'userId': 2,
        'id': 10,
        'title': 'Todo title',
        'completed': true,
      });

      expect(model.userId, 2);
      expect(model.id, 10);
      expect(model.title, 'Todo title');
      expect(model.completed, isTrue);
    });
  });
}
