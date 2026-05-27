// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'feature_id.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$FeatureId {

 int get value;
/// Create a copy of FeatureId
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$FeatureIdCopyWith<FeatureId> get copyWith => _$FeatureIdCopyWithImpl<FeatureId>(this as FeatureId, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is FeatureId&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'FeatureId(value: $value)';
}


}

/// @nodoc
abstract mixin class $FeatureIdCopyWith<$Res>  {
  factory $FeatureIdCopyWith(FeatureId value, $Res Function(FeatureId) _then) = _$FeatureIdCopyWithImpl;
@useResult
$Res call({
 int value
});




}
/// @nodoc
class _$FeatureIdCopyWithImpl<$Res>
    implements $FeatureIdCopyWith<$Res> {
  _$FeatureIdCopyWithImpl(this._self, this._then);

  final FeatureId _self;
  final $Res Function(FeatureId) _then;

/// Create a copy of FeatureId
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? value = null,}) {
  return _then(_self.copyWith(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [FeatureId].
extension FeatureIdPatterns on FeatureId {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _FeatureId value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _FeatureId() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _FeatureId value)  $default,){
final _that = this;
switch (_that) {
case _FeatureId():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _FeatureId value)?  $default,){
final _that = this;
switch (_that) {
case _FeatureId() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int value)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _FeatureId() when $default != null:
return $default(_that.value);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int value)  $default,) {final _that = this;
switch (_that) {
case _FeatureId():
return $default(_that.value);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int value)?  $default,) {final _that = this;
switch (_that) {
case _FeatureId() when $default != null:
return $default(_that.value);case _:
  return null;

}
}

}

/// @nodoc


class _FeatureId implements FeatureId {
  const _FeatureId({required this.value});
  

@override final  int value;

/// Create a copy of FeatureId
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$FeatureIdCopyWith<_FeatureId> get copyWith => __$FeatureIdCopyWithImpl<_FeatureId>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _FeatureId&&(identical(other.value, value) || other.value == value));
}


@override
int get hashCode => Object.hash(runtimeType,value);

@override
String toString() {
  return 'FeatureId(value: $value)';
}


}

/// @nodoc
abstract mixin class _$FeatureIdCopyWith<$Res> implements $FeatureIdCopyWith<$Res> {
  factory _$FeatureIdCopyWith(_FeatureId value, $Res Function(_FeatureId) _then) = __$FeatureIdCopyWithImpl;
@override @useResult
$Res call({
 int value
});




}
/// @nodoc
class __$FeatureIdCopyWithImpl<$Res>
    implements _$FeatureIdCopyWith<$Res> {
  __$FeatureIdCopyWithImpl(this._self, this._then);

  final _FeatureId _self;
  final $Res Function(_FeatureId) _then;

/// Create a copy of FeatureId
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? value = null,}) {
  return _then(_FeatureId(
value: null == value ? _self.value : value // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
