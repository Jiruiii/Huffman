# 快速開始指南

## ?? 立即測試人員一的模組

### 步驟 1：確認環境
確保你已經安裝：
- Visual Studio 2022
- MASM (Microsoft Macro Assembler)
- Irvine32 函式庫

### 步驟 2：開啟專案
```
cd C:\Users\HOME\source\repos\Project32_VS2022\
```

### 步驟 3A：測試 GUI（目前可執行）

1. 將 `HuffmanGUI.rc` 加入專案的 Resource Files
2. 將 `HuffmanGUI.asm` 設為啟動檔案
3. 專案屬性設定：
   - Linker → Input → Additional Dependencies:
     ```
   kernel32.lib
     user32.lib
 comdlg32.lib
     irvine32.lib
     ```
   - Linker → System → SubSystem: **Windows (/SUBSYSTEM:WINDOWS)**
4. 按 F5 執行

**預期結果：**
- ? 視窗顯示
- ? 點擊 "Compress File" 會開啟檔案選擇對話框
- ? 選擇檔案後會開啟儲存對話框
- ? 顯示「Operation completed successfully!」訊息
- ?? 目前還不會真的壓縮（等其他組員的模組）

### 步驟 3B：測試 I/O 函式

如果你想先測試 I/O 函式（不需要 GUI）：

1. 使用 `TestIO.asm`
2. 專案屬性設定：
   - Linker → System → SubSystem: **Console (/SUBSYSTEM:CONSOLE)**
3. 按 F5 執行

**預期結果：**
```
Creating test file...

File size: 24 bytes

Reading test file...
Hello, Huffman Coding!

Writing output file...

All tests passed!
Press any key to continue...
```

### 步驟 4：給其他組員的檔案

**人員二需要：**
- `HuffmanGUI.asm` 中的以下函式：
  - `OpenFileForRead`
  - `ReadFileByte`
  - `CloseFileHandle`
  - `GetFileSizeEx`
- 參考 `Example_ForPerson2.asm` 來統計頻率

**人員三需要：**
- 所有的 I/O 函式
- 特別是 `WriteFileByte` 用於 bit-level 寫入

**人員四需要：**
- 所有的 I/O 函式
- 特別是 `ReadFileByte` 用於 bit-level 讀取

## ?? 檔案說明

| 檔案 | 用途 | 狀態 |
|------|------|------|
| `HuffmanGUI.asm` | 主程式（GUI + I/O） | ? 完成 |
| `HuffmanGUI.rc` | GUI 資源檔 | ? 完成 |
| `resource.h` | 資源定義 | ? 完成 |
| `TestIO.asm` | I/O 函式測試 | ? 完成 |
| `Example_ForPerson2.asm` | 範例程式 | ? 完成 |
| `test_input.txt` | 測試資料 | ? 完成 |
| `README_MODULE1.md` | API 文件 | ? 完成 |
| `INTEGRATION_GUIDE.md` | 整合指南 | ? 完成 |

## ?? 下一步

### 如果你是人員一（你）：
1. ? 測試 GUI 是否正常
2. ? 測試所有 I/O 函式
3. ? 等待其他組員完成模組
4. ? 整合所有模組
5. ? 最終測試

### 如果你是人員二：
1. 閱讀 `README_MODULE1.md`
2. 參考 `Example_ForPerson2.asm`
3. 實作 `BuildHuffmanTree` 函式
4. 測試你的模組

### 如果你是人員三：
1. 閱讀 `README_MODULE1.md`
2. 實作 `CompressWithHuffman` 函式
3. 特別注意 bit-level I/O 的實作

### 如果你是人員四：
1. 閱讀 `README_MODULE1.md`
2. 與人員三協商「檔頭格式」
3. 實作 `DecompressHuffmanFile` 函式

## ? 常見問題

### Q1: 如何切換 Console 和 Windows 模式？
**A:** 在專案屬性中：
- Linker → System → SubSystem
  - Console: 有命令列視窗
  - Windows: 純 GUI，沒有命令列視窗

### Q2: GUI 無法顯示？
**A:** 檢查：
1. `.rc` 檔案是否在專案中
2. SubSystem 是否設為 Windows
3. `comdlg32.lib` 和 `user32.lib` 是否有加入

### Q3: Link error: unresolved external symbol?
**A:** 
1. 確認所有需要的 `.lib` 都有加入
2. 確認 Irvine32 的路徑設定正確

### Q4: 如何debug？
**A:**
- 在 `.asm` 檔案中設中斷點（F9）
- 按 F5 開始偵錯
- 用 F10 (Step Over) 和 F11 (Step Into)
- 查看 Registers 和 Memory 視窗

## ?? 聯絡

如果有任何問題，請：
1. 先查閱 `README_MODULE1.md`
2. 查看 `INTEGRATION_GUIDE.md`
3. 檢查錯誤訊息
4. 與組員討論

祝專案順利！??
