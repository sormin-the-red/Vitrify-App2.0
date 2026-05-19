// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipes_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$recipesRepositoryHash() =>
    r'd1e2f3a4b5c6d1e2f3a4b5c6d1e2f3a4b5c6d1e2';

/// See also [recipesRepository].
@ProviderFor(recipesRepository)
final recipesRepositoryProvider = Provider<RecipesRepository>.internal(
  recipesRepository,
  name: r'recipesRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$recipesRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecipesRepositoryRef = ProviderRef<RecipesRepository>;

String _$recipesListHash() =>
    r'e2f3a4b5c6d1e2f3a4b5c6d1e2f3a4b5c6d1e2f3';

/// See also [recipesList].
@ProviderFor(recipesList)
final recipesListProvider =
    AutoDisposeFutureProvider<List<RecipeSummary>>.internal(
  recipesList,
  name: r'recipesListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$recipesListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef RecipesListRef = AutoDisposeFutureProviderRef<List<RecipeSummary>>;

String _$recipeDetailHash() =>
    r'f3a4b5c6d1e2f3a4b5c6d1e2f3a4b5c6d1e2f3a4';

/// See also [recipeDetail].
@ProviderFor(recipeDetail)
const recipeDetailProvider = RecipeDetailFamily();

/// @macro riverpod_annotation.riverpod_family
class RecipeDetailFamily extends Family {
  const RecipeDetailFamily();

  RecipeDetailProvider call(String id) => RecipeDetailProvider(id);

  @override
  RecipeDetailProvider getProviderOverride(
      covariant RecipeDetailProvider provider) {
    return call(provider.id);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'recipeDetailProvider';
}

class RecipeDetailProvider extends AutoDisposeFutureProvider<RecipeDetail> {
  RecipeDetailProvider(String id)
      : this._internal(
          (ref) => recipeDetail(ref as RecipeDetailRef, id),
          from: recipeDetailProvider,
          name: r'recipeDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$recipeDetailHash,
          dependencies: null,
          allTransitiveDependencies: null,
          id: id,
        );

  RecipeDetailProvider._internal(
    super.create, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.id,
  }) : super.internal();

  final String id;

  @override
  Override overrideWith(
    FutureOr<RecipeDetail> Function(RecipeDetailRef ref) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RecipeDetailProvider._internal(
        (ref) => create(ref as RecipeDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        id: id,
      ),
    );
  }

  @override
  (String,) get argument => (id,);

  @override
  AutoDisposeFutureProviderElement<RecipeDetail> createElement() {
    return _RecipeDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RecipeDetailProvider && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

mixin RecipeDetailRef on AutoDisposeFutureProviderRef<RecipeDetail> {
  String get id;
}

class _RecipeDetailProviderElement
    extends AutoDisposeFutureProviderElement<RecipeDetail>
    with RecipeDetailRef {
  _RecipeDetailProviderElement(super.provider);

  @override
  String get id => (origin as RecipeDetailProvider).id;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
