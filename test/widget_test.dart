// Smoke test: the app starts on the splash screen, then navigates to the
// connections list, with no pending timer left behind.

import 'dart:ffi';
import 'dart:io';

import 'package:drift/drift.dart' show driftRuntimeOptions;
import 'package:drift/native.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
// ignore: depend_on_referenced_packages
import 'package:sqlite3/open.dart';

import 'package:myglobaldc/app.dart';
import 'package:myglobaldc/application/providers/database_provider.dart';
import 'package:myglobaldc/data/database/app_database.dart';

void main() {
  setUpAll(() {
    // Linux hosts often only ship libsqlite3.so.0 (no dev symlink)
    if (Platform.isLinux) {
      open.overrideFor(OperatingSystem.linux, () {
        try {
          return DynamicLibrary.open('libsqlite3.so');
        } catch (_) {
          return DynamicLibrary.open('libsqlite3.so.0');
        }
      });
    }
    // Several AppDatabase instances may be created across tests
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
  });

  testWidgets('App starts on splash then shows the connections list', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final db = AppDatabase(NativeDatabase.memory());
    addTearDown(db.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [databaseProvider.overrideWithValue(db)],
        child: const MyGlobalDCApp(),
      ),
    );
    await tester.pump();

    // Splash screen
    expect(find.text('MyGlobalDC'), findsOneWidget);

    // Splash minimum delay (1 s) then navigation to the connections list
    await tester.pump(const Duration(milliseconds: 1500));
    for (var i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('MyGlobalDC'), findsNothing);
    expect(find.text('Aucune connexion enregistrée'), findsOneWidget);

    // Unmount so providers and stream queries are disposed, then let
    // pending timers (drift stream cleanup) fire before the test ends
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(seconds: 1));
  });
}
