# 霍夫曼編碼專案整合指南

## ?? 檔案清單

### 人員一提供的檔案：
1. **HuffmanGUI.asm** - 主程式（GUI + I/O 函式）
2. **HuffmanGUI.rc** - 資源檔（對話框定義）
3. **resource.h** - 資源標頭檔
4. **README_MODULE1.md** - API 使用說明
5. **TestIO.asm** - I/O 函式測試程式

## ??? 專案結構

```
Project32_VS2022/
├── HuffmanGUI.asm          (主程式 - 人員一)
├── HuffmanGUI.rc           (GUI 資源)
├── resource.h      (資源定義)
├── HuffmanTree.asm         (霍夫曼樹 - 人員二)
├── HuffmanCompress.asm     (壓縮模組 - 人員三)
├── HuffmanDecompress.asm   (解壓縮模組 - 人員四)
└── README_MODULE1.md    (說明文件)
```

## ?? Visual Studio 2022 專案設定步驟

### 1. 建立新專案
1. 開啟 Visual Studio 2022
2. 建立新的空白專案或使用現有的 MASM 專案
3. 將所有 `.asm` 和 `.rc` 檔案加入專案

### 2. 設定專案屬性

#### MASM 設定：
1. 右鍵點擊專案 → Properties
2. Microsoft Macro Assembler → General
   - Additional Include Directories: 加入 Irvine32 的 include 路徑
3. Microsoft Macro Assembler → Listing File
   - Assembled Code Listing File: `$(ProjectName).lst`

#### Linker 設定：
1. Linker → General
   - Additional Library Directories: 加入 Irvine32 的 lib 路徑

2. Linker → Input → Additional Dependencies 加入：
   ```
   kernel32.lib
   user32.lib
   comdlg32.lib
   irvine32.lib
   ```

3. Linker → System
   - SubSystem: Windows (/SUBSYSTEM:WINDOWS)

#### Resource Compiler：
1. 確保 `.rc` 檔案有被加入專案
2. 會自動編譯成 `.res` 檔

### 3. 編譯順序
Visual Studio 會自動處理，但順序為：
1. `.rc` → `.res`
2. `.asm` → `.obj`
3. Link → `.exe`

## ?? 整合方式

### 方法一：INCLUDE 方式（建議）

在 `HuffmanGUI.asm` 的開頭加入：
```asm
INCLUDE Irvine32.inc
INCLUDE macros.inc

; 引入其他組員的模組
INCLUDE HuffmanTree.asm        ; 人員二
INCLUDE HuffmanCompress.asm    ; 人員三
INCLUDE HuffmanDecompress.asm  ; 人員四
```

### 方法二：PROTO 宣告方式

如果不想用 INCLUDE，可以在各模組中宣告 PROTO：

**HuffmanGUI.asm:**
```asm
; 外部函式宣告
BuildHuffmanTree PROTO, pszFilePath:PTR BYTE
CompressWithHuffman PROTO, pTreeRoot:DWORD, pszInputFile:PTR BYTE, pszOutputFile:PTR BYTE
DecompressHuffmanFile PROTO, pszInputFile:PTR BYTE, pszOutputFile:PTR BYTE
```

**HuffmanTree.asm (人員二):**
```asm
; 引入人員一的 I/O 函式
OpenFileForRead PROTO, pszFilePath:PTR BYTE
ReadFileByte PROTO, hFile:DWORD
CloseFileHandle PROTO, hFile:DWORD

PUBLIC BuildHuffmanTree

.code
BuildHuffmanTree PROC, pszFilePath:PTR BYTE
    ; 實作...
  ret
BuildHuffmanTree ENDP
```

## ?? 整合檢查清單

### 階段 0：人員一獨立測試 ?
- [ ] GUI 視窗能正常顯示
- [ ] 按鈕可以點擊
- [ ] 檔案對話框能開啟
- [ ] I/O 函式測試通過（使用 TestIO.asm）

### 階段 1：整合人員二
- [ ] `HuffmanTree.asm` 加入專案
- [ ] 在 `HuffmanGUI.asm` 的 `CompressFile` 中取消註解：
  ```asm
  INVOKE BuildHuffmanTree, ADDR szInputFile
  mov pTreeRoot, eax
  ```
- [ ] 測試：選擇檔案後，確認霍夫曼樹有成功建立
- [ ] 可以印出樹的結構或統計資訊來驗證

### 階段 2：整合人員三
- [ ] `HuffmanCompress.asm` 加入專案
- [ ] 取消註解：
  ```asm
  INVOKE CompressWithHuffman, pTreeRoot, ADDR szInputFile, ADDR szOutputFile
  ```
- [ ] 測試：能產生 `.huf` 壓縮檔
- [ ] 檢查：壓縮檔大小應該比原檔小（或相近）

### 階段 3：整合人員四
- [ ] `HuffmanDecompress.asm` 加入專案
- [ ] 取消註解：
  ```asm
  INVOKE DecompressHuffmanFile, ADDR szInputFile, ADDR szOutputFile
  ```
- [ ] 測試：能解壓縮 `.huf` 檔案

### 階段 4：完整測試
- [ ] 測試案例 1：純文字檔
  - input.txt → compress → output.huf → decompress → recovered.txt
  - 用檔案比對工具確認 input.txt 和 recovered.txt 完全相同
  
- [ ] 測試案例 2：重複字元多的檔案
  - "AAAAABBBBBCCCCCDDDDD..."
  - 確認壓縮率高
  
- [ ] 測試案例 3：隨機字元的檔案
  - 確認能正常處理
  
- [ ] 測試案例 4：空檔案/單字元檔案
  - 邊界條件測試

## ?? 常見問題與解決

### 1. Link Error: unresolved external symbol
**原因：** 找不到函式實作
**解決：** 
- 確認所有 `.asm` 檔案都加入專案
- 確認 PROTO 宣告和實際函式名稱一致
- 確認有 `PUBLIC` 匯出函式

### 2. GUI 視窗無法顯示
**原因：** Resource 檔案未正確編譯
**解決：**
- 確認 `.rc` 檔案在專案中
- 檢查 IDD_MAIN_DIALOG 的值是否一致

### 3. 檔案對話框顯示亂碼
**原因：** OPENFILENAME 結構未正確初始化
**解決：**
- 確認所有欄位都有設定
- 特別注意 `lStructSize` 必須是 `SIZEOF OPENFILENAME`

### 4. 讀取檔案失敗
**原因：** Handle 無效或檔案不存在
**解決：**
```asm
INVOKE OpenFileForRead, ADDR szFile
cmp eax, INVALID_HANDLE_VALUE
je error_handler
```

### 5. 位元寫入錯誤
**原因：** 人員三/四的 bit buffer 處理錯誤
**解決：**
- 確保最後一個 byte 有正確寫入（padding）
- 記錄檔案中有多少 valid bits

## ?? 測試資料建議

### test1.txt (簡單)
```
AAAAAABBBBBCCCCCDDDDEEF
```
預期：A, B, C, D 出現頻率高，編碼短

### test2.txt (英文文章)
```
The quick brown fox jumps over the lazy dog.
This is a test file for Huffman coding compression.
```

### test3.txt (中文測試)
```
霍夫曼編碼是一種無損資料壓縮演算法。
```
注意：中文是 UTF-8 或 Big5 編碼，每個字 2-3 bytes

## ?? 加分項目

1. **壓縮率顯示**
   - 在 GUI 顯示：原檔大小 → 壓縮後大小 → 壓縮率

2. **進度條**
   - 壓縮/解壓縮時顯示進度

3. **錯誤處理**
- 檔案損壞偵測
   - 格式驗證

4. **編碼表匯出**
   - 產生 `code_table.txt` 顯示每個字元的編碼

5. **統計資訊**
   - 字元頻率圖表
   - 樹的深度/節點數

## ?? 問題回報

如果遇到整合問題，請提供：
1. 錯誤訊息（完整的）
2. 相關的程式碼片段
3. 測試檔案
4. Visual Studio 的版本和設定

祝專案順利！??
