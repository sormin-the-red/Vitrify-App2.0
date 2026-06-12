import 'package:flutter_test/flutter_test.dart';
import 'package:glazevault/features/community/community_models.dart';
import 'package:glazevault/features/recipes/recipe_models.dart';

void main() {
  group('RecipeIngredient.fromJson', () {
    test('parses new camelCase keys', () {
      final ing = RecipeIngredient.fromJson(
          {'name': 'Silica', 'percentage': 25.5, 'isAddition': true});
      expect(ing.name, 'Silica');
      expect(ing.percentage, 25.5);
      expect(ing.isAddition, isTrue);
    });

    test('parses legacy PascalCase keys from the old Angular app', () {
      final ing =
          RecipeIngredient.fromJson({'Name': 'EPK Kaolin', 'Percentage': 10});
      expect(ing.name, 'EPK Kaolin');
      expect(ing.percentage, 10.0);
      expect(ing.isAddition, isFalse);
    });

    test('integer percentages become doubles', () {
      final ing = RecipeIngredient.fromJson({'name': 'Whiting', 'percentage': 20});
      expect(ing.percentage, isA<double>());
    });

    test('toJson omits isAddition when false and keeps it when true', () {
      expect(
        const RecipeIngredient(name: 'Silica', percentage: 25).toJson(),
        {'name': 'Silica', 'percentage': 25.0},
      );
      expect(
        const RecipeIngredient(name: 'Rutile', percentage: 5, isAddition: true)
            .toJson(),
        {'name': 'Rutile', 'percentage': 5.0, 'isAddition': true},
      );
    });

    test('round-trips through toJson/fromJson', () {
      const original =
          RecipeIngredient(name: 'Custer Feldspar', percentage: 38.2);
      final parsed = RecipeIngredient.fromJson(original.toJson());
      expect(parsed.name, original.name);
      expect(parsed.percentage, original.percentage);
      expect(parsed.isAddition, original.isAddition);
    });
  });

  group('RecipeRevision.fromJson', () {
    test('applies defaults for missing fields', () {
      final rev = RecipeRevision.fromJson(const {});
      expect(rev.revisionNum, 1);
      expect(rev.materials, isEmpty);
      expect(rev.imageUrls, isEmpty);
      expect(rev.status, 'New');
    });

    test('parses nested materials', () {
      final rev = RecipeRevision.fromJson({
        'revisionNum': 3,
        'materials': [
          {'name': 'Silica', 'percentage': 30},
          {'Name': 'Whiting', 'Percentage': 20},
        ],
      });
      expect(rev.revisionNum, 3);
      expect(rev.materials, hasLength(2));
      expect(rev.materials[1].name, 'Whiting');
    });
  });

  group('FeedItem.fromJson', () {
    test('parses attribute chips fields', () {
      final item = FeedItem.fromJson({
        'id': 'abc',
        'name': 'Floating Blue',
        'itemType': 'recipe',
        'likeCount': 4,
        'color': ['Blue', 'Green'],
        'finish': 'Glossy',
        'surface': 'Variegated',
        'transparency': 'Semi-opaque',
        'dateModified': '2026-01-01',
        'dateCreated': '2026-01-01',
        'uid': 'u1',
        'description': '',
      });
      expect(item.isRecipe, isTrue);
      expect(item.color, ['Blue', 'Green']);
      expect(item.finish, 'Glossy');
      expect(item.likeCount, 4);
    });
  });

  group('FeedPage', () {
    test('hasMore reflects the cursor', () {
      expect(const FeedPage(items: []).hasMore, isFalse);
      expect(const FeedPage(items: [], nextCursor: '').hasMore, isFalse);
      expect(const FeedPage(items: [], nextCursor: 'abc').hasMore, isTrue);
    });
  });
}
