// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'upload_queue_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

/// @nodoc
mixin _$UploadQueueState {
  /// Raw guest name as entered; empty when the guest stayed anonymous.
  String get guestName => throw _privateConstructorUsedError;

  /// UUID4 generated once per guest upload batch and reused for the
  /// object keys of every file in the batch.
  String get batchId => throw _privateConstructorUsedError;

  /// Queued files with per-file status, progress, and error state.
  List<UploadItem> get items => throw _privateConstructorUsedError;

  /// True while uploads are being transmitted.
  bool get isUploading => throw _privateConstructorUsedError;

  /// Create a copy of UploadQueueState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UploadQueueStateCopyWith<UploadQueueState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UploadQueueStateCopyWith<$Res> {
  factory $UploadQueueStateCopyWith(
    UploadQueueState value,
    $Res Function(UploadQueueState) then,
  ) = _$UploadQueueStateCopyWithImpl<$Res, UploadQueueState>;
  @useResult
  $Res call({
    String guestName,
    String batchId,
    List<UploadItem> items,
    bool isUploading,
  });
}

/// @nodoc
class _$UploadQueueStateCopyWithImpl<$Res, $Val extends UploadQueueState>
    implements $UploadQueueStateCopyWith<$Res> {
  _$UploadQueueStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UploadQueueState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? guestName = null,
    Object? batchId = null,
    Object? items = null,
    Object? isUploading = null,
  }) {
    return _then(
      _value.copyWith(
            guestName: null == guestName
                ? _value.guestName
                : guestName // ignore: cast_nullable_to_non_nullable
                      as String,
            batchId: null == batchId
                ? _value.batchId
                : batchId // ignore: cast_nullable_to_non_nullable
                      as String,
            items: null == items
                ? _value.items
                : items // ignore: cast_nullable_to_non_nullable
                      as List<UploadItem>,
            isUploading: null == isUploading
                ? _value.isUploading
                : isUploading // ignore: cast_nullable_to_non_nullable
                      as bool,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$UploadQueueStateImplCopyWith<$Res>
    implements $UploadQueueStateCopyWith<$Res> {
  factory _$$UploadQueueStateImplCopyWith(
    _$UploadQueueStateImpl value,
    $Res Function(_$UploadQueueStateImpl) then,
  ) = __$$UploadQueueStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String guestName,
    String batchId,
    List<UploadItem> items,
    bool isUploading,
  });
}

/// @nodoc
class __$$UploadQueueStateImplCopyWithImpl<$Res>
    extends _$UploadQueueStateCopyWithImpl<$Res, _$UploadQueueStateImpl>
    implements _$$UploadQueueStateImplCopyWith<$Res> {
  __$$UploadQueueStateImplCopyWithImpl(
    _$UploadQueueStateImpl _value,
    $Res Function(_$UploadQueueStateImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of UploadQueueState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? guestName = null,
    Object? batchId = null,
    Object? items = null,
    Object? isUploading = null,
  }) {
    return _then(
      _$UploadQueueStateImpl(
        guestName: null == guestName
            ? _value.guestName
            : guestName // ignore: cast_nullable_to_non_nullable
                  as String,
        batchId: null == batchId
            ? _value.batchId
            : batchId // ignore: cast_nullable_to_non_nullable
                  as String,
        items: null == items
            ? _value._items
            : items // ignore: cast_nullable_to_non_nullable
                  as List<UploadItem>,
        isUploading: null == isUploading
            ? _value.isUploading
            : isUploading // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// @nodoc

class _$UploadQueueStateImpl extends _UploadQueueState {
  const _$UploadQueueStateImpl({
    this.guestName = '',
    this.batchId = '',
    final List<UploadItem> items = const <UploadItem>[],
    this.isUploading = false,
  }) : _items = items,
       super._();

  /// Raw guest name as entered; empty when the guest stayed anonymous.
  @override
  @JsonKey()
  final String guestName;

  /// UUID4 generated once per guest upload batch and reused for the
  /// object keys of every file in the batch.
  @override
  @JsonKey()
  final String batchId;

  /// Queued files with per-file status, progress, and error state.
  final List<UploadItem> _items;

  /// Queued files with per-file status, progress, and error state.
  @override
  @JsonKey()
  List<UploadItem> get items {
    if (_items is EqualUnmodifiableListView) return _items;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_items);
  }

  /// True while uploads are being transmitted.
  @override
  @JsonKey()
  final bool isUploading;

  @override
  String toString() {
    return 'UploadQueueState(guestName: $guestName, batchId: $batchId, items: $items, isUploading: $isUploading)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UploadQueueStateImpl &&
            (identical(other.guestName, guestName) ||
                other.guestName == guestName) &&
            (identical(other.batchId, batchId) || other.batchId == batchId) &&
            const DeepCollectionEquality().equals(other._items, _items) &&
            (identical(other.isUploading, isUploading) ||
                other.isUploading == isUploading));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    guestName,
    batchId,
    const DeepCollectionEquality().hash(_items),
    isUploading,
  );

  /// Create a copy of UploadQueueState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UploadQueueStateImplCopyWith<_$UploadQueueStateImpl> get copyWith =>
      __$$UploadQueueStateImplCopyWithImpl<_$UploadQueueStateImpl>(
        this,
        _$identity,
      );
}

abstract class _UploadQueueState extends UploadQueueState {
  const factory _UploadQueueState({
    final String guestName,
    final String batchId,
    final List<UploadItem> items,
    final bool isUploading,
  }) = _$UploadQueueStateImpl;
  const _UploadQueueState._() : super._();

  /// Raw guest name as entered; empty when the guest stayed anonymous.
  @override
  String get guestName;

  /// UUID4 generated once per guest upload batch and reused for the
  /// object keys of every file in the batch.
  @override
  String get batchId;

  /// Queued files with per-file status, progress, and error state.
  @override
  List<UploadItem> get items;

  /// True while uploads are being transmitted.
  @override
  bool get isUploading;

  /// Create a copy of UploadQueueState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UploadQueueStateImplCopyWith<_$UploadQueueStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
