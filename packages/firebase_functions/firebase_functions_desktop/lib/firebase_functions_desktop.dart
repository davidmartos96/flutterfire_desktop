// Copyright 2021 Invertase Limited. All rights reserved.
// Use of this source code is governed by a BSD-style license
// that can be found in the LICENSE file.

library cloud_functions_desktop;

import 'package:cloud_functions_platform_interface/cloud_functions_platform_interface.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_functions_dart/firebase_functions_dart.dart'
    as functions_dart;

import 'desktop_utils.dart' as desktop_utils;

/// Desktop implementation of [FirebaseFunctionsPlatform] for managing FirebaseFunctions.
class FirebaseFunctionsDesktop extends FirebaseFunctionsPlatform {
  /// Constructs a FirebaseFunctionsDesktop.
  FirebaseFunctionsDesktop({
    required FirebaseApp? app,
    String region = functions_dart.FirebaseFunctions.defaultRegion,
  }) : super(app, region);

  FirebaseFunctionsDesktop._()
      : _dartFunctions = null,
        super(null, functions_dart.FirebaseFunctions.defaultRegion);

  /// Called by PluginRegistry to register this plugin as the implementation for Desktop.
  static void registerWith() {
    FirebaseFunctionsPlatform.instance = FirebaseFunctionsDesktop.instance;
  }

  /// Stub initializer to allow creating an instance without
  /// registering delegates or listeners.
  // ignore: prefer_constructors_over_static_methods
  static FirebaseFunctionsDesktop get instance {
    return FirebaseFunctionsDesktop._();
  }

  /// Instance of functions from the dart package.
  functions_dart.FirebaseFunctions? _dartFunctions;

  /// Lazily initialize [_dartFunctions] on first method call.
  functions_dart.FirebaseFunctions get _delegate {
    return _dartFunctions ??= functions_dart.FirebaseFunctions.instanceFor(
      app: desktop_utils.app(app?.name),
      region: region,
    );
  }

  @override
  FirebaseFunctionsPlatform delegateFor({
    FirebaseApp? app,
    required String region,
  }) =>
      FirebaseFunctionsDesktop(app: app, region: region);

  @override
  HttpsCallablePlatform httpsCallable(
    String? origin,
    String name,
    HttpsCallableOptions options,
  ) =>
      HttpsCallableDesktop(this, _delegate, origin, name, options, null);

  @override
  HttpsCallablePlatform httpsCallableWithUri(
    String? origin,
    Uri uri,
    HttpsCallableOptions options,
  ) =>
      HttpsCallableDesktop(this, _delegate, origin, null, options, uri);
}

/// Desktop implementation of HttpsCallablePlatform for managing HttpsCallable
/// instances.
class HttpsCallableDesktop extends HttpsCallablePlatform {
  /// Constructs a HttpsCallableDesktop
  HttpsCallableDesktop(
    FirebaseFunctionsDesktop functions,
    this._delegate,
    String? origin,
    String? name,
    HttpsCallableOptions options,
    Uri? uri,
  ) : super(functions, origin, name, options, uri);

  /// The dart functions instance for accessing the cloud functions API.
  final functions_dart.FirebaseFunctions _delegate;

  @override
  Future<dynamic> call([dynamic parameters]) async {
    if (origin != null) {
      final uri = Uri.parse(origin!);
      _delegate.useFunctionsEmulator(uri.host, uri.port);
    }

    if (options.limitedUseAppCheckToken) {
      // TODO: Implement limitedUseAppCheckToken
      throw UnimplementedError();
    }

    final callableOptions = functions_dart.HttpsCallableOptions(
      timeout: options.timeout,
      // limitedUseAppCheckToken: options.limitedUseAppCheckToken,
    );

    final functions_dart.HttpsCallable callable;
    if (name != null) {
      callable = _delegate.httpsCallable(
        name!,
        options: callableOptions,
      );
    } else if (uri != null) {
      callable = _delegate.httpsCallableWithUri(
        uri!,
        options: callableOptions,
      );
    } else {
      throw ArgumentError('Either name or uri must be provided');
    }

    functions_dart.HttpsCallableResult response;

    try {
      response = await callable.call(parameters);
    } on functions_dart.FirebaseFunctionsException catch (e, s) {
      throw desktop_utils.convertFirebaseFunctionsException(e, s);
    }

    return response.data;
  }
}
