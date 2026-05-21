// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'schedules_repository.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$schedulesRepositoryHash() =>
    r'a4b5c6d1e2f3a4b5c6d1e2f3a4b5c6d1e2f3a4b5';

/// See also [schedulesRepository].
@ProviderFor(schedulesRepository)
final schedulesRepositoryProvider = Provider<SchedulesRepository>.internal(
  schedulesRepository,
  name: r'schedulesRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$schedulesRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SchedulesRepositoryRef = ProviderRef<SchedulesRepository>;

String _$schedulesListHash() =>
    r'b5c6d1e2f3a4b5c6d1e2f3a4b5c6d1e2f3a4b5c6';

/// See also [schedulesList].
@ProviderFor(schedulesList)
final schedulesListProvider =
    AutoDisposeFutureProvider<List<ScheduleSummary>>.internal(
  schedulesList,
  name: r'schedulesListProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$schedulesListHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SchedulesListRef = AutoDisposeFutureProviderRef<List<ScheduleSummary>>;

String _$scheduleDetailHash() =>
    r'c6d1e2f3a4b5c6d1e2f3a4b5c6d1e2f3a4b5c6d1';

/// See also [scheduleDetail].
@ProviderFor(scheduleDetail)
const scheduleDetailProvider = ScheduleDetailFamily();

/// @macro riverpod_annotation.riverpod_family
class ScheduleDetailFamily extends Family {
  const ScheduleDetailFamily();

  ScheduleDetailProvider call(String id) => ScheduleDetailProvider(id);

  @override
  ScheduleDetailProvider getProviderOverride(
      covariant ScheduleDetailProvider provider) {
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
  String? get name => r'scheduleDetailProvider';
}

class ScheduleDetailProvider extends AutoDisposeFutureProvider<ScheduleDetail> {
  ScheduleDetailProvider(String id)
      : this._internal(
          (ref) => scheduleDetail(ref as ScheduleDetailRef, id),
          from: scheduleDetailProvider,
          name: r'scheduleDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$scheduleDetailHash,
          dependencies: null,
          allTransitiveDependencies: null,
          id: id,
        );

  ScheduleDetailProvider._internal(
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
    FutureOr<ScheduleDetail> Function(ScheduleDetailRef ref) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ScheduleDetailProvider._internal(
        (ref) => create(ref as ScheduleDetailRef),
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
  AutoDisposeFutureProviderElement<ScheduleDetail> createElement() {
    return _ScheduleDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ScheduleDetailProvider && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

mixin ScheduleDetailRef on AutoDisposeFutureProviderRef<ScheduleDetail> {
  String get id;
}

class _ScheduleDetailProviderElement
    extends AutoDisposeFutureProviderElement<ScheduleDetail>
    with ScheduleDetailRef {
  _ScheduleDetailProviderElement(super.provider);

  @override
  String get id => (origin as ScheduleDetailProvider).id;
}

String _$scheduleRevisionsHash() =>
    r'd7e8f9a0b1c2d3e4f5a6b7c8d9e0f1a2b3c4d5e6';

/// See also [scheduleRevisions].
@ProviderFor(scheduleRevisions)
const scheduleRevisionsProvider = ScheduleRevisionsFamily();

/// @macro riverpod_annotation.riverpod_family
class ScheduleRevisionsFamily extends Family {
  const ScheduleRevisionsFamily();

  ScheduleRevisionsProvider call(String id) => ScheduleRevisionsProvider(id);

  @override
  ScheduleRevisionsProvider getProviderOverride(
      covariant ScheduleRevisionsProvider provider) {
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
  String? get name => r'scheduleRevisionsProvider';
}

class ScheduleRevisionsProvider
    extends AutoDisposeFutureProvider<List<ScheduleRevision>> {
  ScheduleRevisionsProvider(String id)
      : this._internal(
          (ref) => scheduleRevisions(ref as ScheduleRevisionsRef, id),
          from: scheduleRevisionsProvider,
          name: r'scheduleRevisionsProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$scheduleRevisionsHash,
          dependencies: null,
          allTransitiveDependencies: null,
          id: id,
        );

  ScheduleRevisionsProvider._internal(
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
    FutureOr<List<ScheduleRevision>> Function(ScheduleRevisionsRef ref) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ScheduleRevisionsProvider._internal(
        (ref) => create(ref as ScheduleRevisionsRef),
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
  AutoDisposeFutureProviderElement<List<ScheduleRevision>> createElement() {
    return _ScheduleRevisionsProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ScheduleRevisionsProvider && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

mixin ScheduleRevisionsRef
    on AutoDisposeFutureProviderRef<List<ScheduleRevision>> {
  String get id;
}

class _ScheduleRevisionsProviderElement
    extends AutoDisposeFutureProviderElement<List<ScheduleRevision>>
    with ScheduleRevisionsRef {
  _ScheduleRevisionsProviderElement(super.provider);

  @override
  String get id => (origin as ScheduleRevisionsProvider).id;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
