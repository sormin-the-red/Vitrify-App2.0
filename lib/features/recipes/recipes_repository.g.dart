// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'recipes_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$recipesRepositoryHash() =>
    r'e1f2a3b4c5d6e1f2a3b4c5d6e1f2a3b4c5d6e1f2';

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
    r'f2a3b4c5d6e1f2a3b4c5d6e1f2a3b4c5d6e1f2a3';

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
    r'a3b4c5d6e1f2a3b4c5d6e1f2a3b4c5d6e1f2a3b4';

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

String _$recipeRevisionsHash() =>
    r'b4c5d6e1f2a3b4c5d6e1f2a3b4c5d6e1f2a3b4c5';

/// See also [recipeRevisions].
@ProviderFor(recipeRevisions)
const recipeRevisionsProvider = RecipeRevisionsFamily();

/// @macro riverpod_annotation.riverpod_family
class RecipeRevisionsFamily extends Family {
  const RecipeRevisionsFamily();

  RecipeRevisionsProvider call(String id) => RecipeRevisionsProvider(id);

  @override
  RecipeRevisionsProvider getProviderOverride(
      covariant RecipeRevisionsProvider provider) {
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
  String? get name => r'recipeRevisionsProvider';
}

class RecipeRevisionsProvider
    extends AutoDisposeFutureProvider<List<RecipeRevision>> {
  RecipeRevisionsProvider(String id)
      : this._internal(
          (ref) => recipeRevisions(ref as RecipeRevisionsRef, id),
          from: recipeRevisionsProvider,
          name: r'recipeRevisionsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$recipeRevisionsHash,
          dependencies: null,
          allTransitiveDependencies: null,
          id: id,
        );

  RecipeRevisionsProvider._internal(
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
    FutureOr<List<RecipeRevision>> Function(RecipeRevisionsRef ref) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: RecipeRevisionsProvider._internal(
        (ref) => create(ref as RecipeRevisionsRef),
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
  AutoDisposeFutureProviderElement<List<RecipeRevision>> createElement() {
    return _RecipeRevisionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is RecipeRevisionsProvider && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

mixin RecipeRevisionsRef
    on AutoDisposeFutureProviderRef<List<RecipeRevision>> {
  String get id;
}

class _RecipeRevisionsProviderElement
    extends AutoDisposeFutureProviderElement<List<RecipeRevision>>
    with RecipeRevisionsRef {
  _RecipeRevisionsProviderElement(super.provider);

  @override
  String get id => (origin as RecipeRevisionsProvider).id;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
