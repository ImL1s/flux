# 安全指南 (Security Guide)

[English Documentation](security.md)

## 腳本簽名 (Script Signing)

Flux 支援 Ed25519 數位簽名，以確保指令碼的完整性。

### 為什麼要簽名腳本？

- **完整性 (Integrity)**：檢測腳本是否已被篡改。
- **身分驗證 (Authentication)**：驗證腳本是否來自可信來源。
- **生產安全性 (Production Safety)**：防止執行未經授權的代碼。

## 設定 (Setup)

### 生成金鑰對 (Generate Key Pair)

```bash
flux keygen --output ./keys
```

這將建立：
- `keys/private.pem` - 需保密，用於簽名。
- `keys/public.pem` - 隨 App 分發，用於驗證。

### 簽名腳本 (Sign a Script)

```bash
flux sign script.flux --key keys/private.pem --output script.signed.flux
```

### 驗證簽名 (Verify Signature)

```bash
flux verify script.signed.flux --key keys/public.pem
```

## Flutter 整合 (Flutter Integration)

### 嵌入公鑰 (Embed Public Key)

```dart
const publicKey = '''
-----BEGIN PUBLIC KEY-----
MCowBQYDK2VwAyEA...
-----END PUBLIC KEY-----
''';
```

### 執行前驗證 (Verify Before Execution)

```dart
import 'package:flux_vm/flux_vm.dart';

final verifier = FluxScriptVerifier(publicKey: publicKey);

void runSignedScript(String signedContent) {
  if (!verifier.verify(signedContent)) {
    throw SecurityException('指令碼簽名無效');
  }
  
  // 提取腳本內容（簽名之前的部分）
  final script = verifier.extractContent(signedContent);
  
  final vm = VM();
  vm.interpret(script);
}
```

## 已簽名腳本格式 (Signed Script Format)

```
// 原始腳本內容
var x = 1;
print(x);

// --- FLUX SIGNATURE ---
// ed25519:ABC123...XYZ789
```

## 最佳實踐 (Best Practices)

### 金鑰管理 (Key Management)

1. **切勿將私鑰提交**到版本控制系統。
2. **使用環境變數**或機密管理器 (Secrets Manager)。
3. **定期輪換金鑰**。
4. **開發與生產環境使用不同的金鑰**。

### 執行時安全 (Runtime Security)

```dart
// 建立沙箱化的虛擬機
final vm = VM();

// 不要註冊敏感模組
// vm.registerModule(fileSystemModule);  // ❌ 不要這樣做

// 限制腳本可以訪問的內容
vm.registerModule(safeModule);
```

### 輸入驗證 (Input Validation)

```dart
// 驗證從 Flux 返回的任何值
final result = vm.getGlobal('userInput');

if (result is! String || result.length > 100) {
  throw ValidationException('無效輸入');
}
```

## 威脅模型 (Threat Model)

| 威脅 | 緩解措施 |
|--------|------------|
| 惡意腳本執行 | 簽名驗證 |
| 腳本竄改 | Ed25519 數位簽名 |
| 資源耗盡 | 執行超時限制（計劃中） |
| 敏感數據訪問 | 模組沙箱化 |

## 偵錯 vs 生產 (Debugging vs Production)

| 特性 | 偵錯 (Debug) | 生產 (Production) |
|---------|-------|------------|
| 簽名檢查 | 選配 | 強制要求 |
| 源碼映射 (Source maps) | 包含 | 移除 |
| 偵錯符號 | 包含 | 移除 |
| .flx 格式 | 選配 | 推薦使用 |
