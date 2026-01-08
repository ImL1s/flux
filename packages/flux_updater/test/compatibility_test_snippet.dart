
    test('checkCompatibility rejects incompatible version', () async {
      final release = FluxRelease(
        appId: appId,
        version: '1.0.3',
        buildNumber: 4,
        chunk: Uint8List(0),
        signature: 'sig',
        createdAt: DateTime.now(),
        minVmVersion: '4.0.0', // Higher than 3.0.0
      );

      final result = await manager.checkCompatibility(release);
      expect(result, false);
    });

    test('checkCompatibility accepts compatible version', () async {
      final release = FluxRelease(
        appId: appId,
        version: '1.0.3',
        buildNumber: 4,
        chunk: Uint8List(0),
        signature: 'sig',
        createdAt: DateTime.now(),
        minVmVersion: '2.0.0', // Lower than 3.0.0
      );

      final result = await manager.checkCompatibility(release);
      expect(result, true);
    });
