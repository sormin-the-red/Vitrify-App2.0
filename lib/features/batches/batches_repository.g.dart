// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'batches_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$batchesRepositoryHash() =>
    r'a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2';

/// See also [batchesRepository].
@ProviderFor(batchesRepository)
final batchesRepositoryProvider = Provider<BatchesRepository>.internal(
  batchesRepository,
  name: r'batchesRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$batchesRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BatchesRepositoryRef = ProviderRef<BatchesRepository>;

String _$batchesListHash() =>
    r'b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3';

/// See also [batchesList].
@ProviderFor(batchesList)
final batchesListProvider =
    AutoDisposeFutureProvider<List<BatchSummary>>.internal(
  batchesList,
  name: r'batchesListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$batchesListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BatchesListRef = AutoDisposeFutureProviderRef<List<BatchSummary>>;

String _$batchDetailHash() =>
    r'c3d4e5f6a1b2c3d4e5f6a1b2c3d4e5f6a1b2c3d4';

/// See also [batchDetail].
@ProviderFor(batchDetail)
const batchDetailProvider = BatchDetailFamily();

/// @macro riverpod_annotation.riverpod_family
class BatchDetailFamily extends Family {
  /// @macro riverpod_annotation.riverpod_family
  const BatchDetailFamily();

  /// @macro
  BatchDetailProvider call(String id) => BatchDetailProvider(id);

  @override
  BatchDetailProvider getProviderOverride(
    covariant BatchDetailProvider provider,
  ) {
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
  String? get name => r'batchDetailProvider';
}

/// @macro
class BatchDetailProvider extends AutoDisposeFutureProvider<BatchDetail> {
  /// @macro
  BatchDetailProvider(String id)
      : this._internal(
          (ref) => batchDetail(ref as BatchDetailRef, id),
          from: batchDetailProvider,
          name: r'batchDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$batchDetailHash,
          dependencies: null,
          allTransitiveDependencies: null,
          id: id,
        );

  BatchDetailProvider._internal(
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
    FutureOr<BatchDetail> Function(BatchDetailRef ref) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: BatchDetailProvider._internal(
        (ref) => create(ref as BatchDetailRef),
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
  AutoDisposeFutureProviderElement<BatchDetail> createElement() {
    return _BatchDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is BatchDetailProvider && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// @macro riverpod_annotation.riverpod_element
mixin BatchDetailRef on AutoDisposeFutureProviderRef<BatchDetail> {
  /// The parameter `id` of this provider.
  String get id;
}

class _BatchDetailProviderElement
    extends AutoDisposeFutureProviderElement<BatchDetail>
    with BatchDetailRef {
  _BatchDetailProviderElement(super.provider);

  @override
  String get id => (origin as BatchDetailProvider).id;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
