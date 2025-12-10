# Huffman Coding File Compressor

一個以 **MASM x86 組合語言** 實作的霍夫曼壓縮器，整合 GUI、檔案 I/O、Huffman Tree 建構、位元壓縮與解壓。所有程式碼都可在 Windows 10/11 + Visual Studio 2022 上直接編譯。

## 專案特色

- **完整 Huffman 流程**：`HuffmanDataAnalyst.asm` 建頻率表與樹、`pro2.asm` 實作編碼器、`Decoder.asm` 執行解碼器。
- **Win32 GUI**：`HuffmanGUI.asm` 提供壓縮/解壓按鈕、檔案對話盒與狀態欄。
- **🆕 檔案拖放功能**：直接拖曳檔案（或多個檔案）到視窗即可開始壓縮/解壓縮，自動識別檔案類型。
- **🆕 批次處理**：支援一次選擇/拖放多個檔案，自動依序處理所有檔案。
- **🆕 即時進度條**：顯示處理進度（單檔模式或批次模式），提供視覺化回饋。
- **🆕 Magic Number 驗證**：壓縮檔含 `HUFF` 簽章，解壓縮時會驗證檔案格式，防止錯誤操作。
- **共用 I/O 函式庫**：封裝 `CreateFile`, `ReadFile`, `WriteFile` 等 WinAPI，供其他模組與測試程式呼叫。
- **測試腳本**：`test_runner.asm` 可批次壓縮→解壓→比對，確保輸出內容與輸入完全相同。
- **任意編碼支援**：演算法逐 byte 運作，可處理 UTF-8、UTF-16、ASCII 甚至二進位資料；壓縮後的檔案還原時會保留原本的 encoding。

## 建置需求

- Windows 10/11
- Visual Studio 2022（含 MASM、Windows SDK）
- Irvine32 Library（已在專案中 reference）

## 編譯與執行

1. 以 Visual Studio 開啟 `Project32_VS2022/Project.sln`。
2. 確認組態為 `Debug` 或 `Release`、平台 `Win32`。
3. （若自訂工具鏈）再次檢查 Linker → Input → Additional Dependencies 包含 `kernel32.lib user32.lib comdlg32.lib irvine32.lib`。
4. 按 `Ctrl+Shift+B` 或 `F5` 進行建置/偵錯，會產生 GUI 可執行檔。

### GUI 操作

**方式一：使用按鈕**
1. `Compress File(s)`：選擇單個或多個檔案（按住 Ctrl 多選），程式會建立 Huffman 樹、輸出 `.huff` 檔並顯示壓縮率。
2. `Decompress File(s)`：選擇單個或多個 `.huff` 檔，程式會自動解壓縮。
3. 狀態欄會提示錯誤（檔案不存在、超過 10 MB、無法開啟等）。
4. 進度條會顯示當前處理進度。

**方式二：拖放檔案 🆕（支援批次）**
1. 直接將單個或多個檔案拖曳到程式視窗上
2. 程式會自動判斷：
   - `.huff` 檔案 → 批次解壓縮
   - 其他檔案 → 批次壓縮
3. 進度條顯示：「Processing file X of Y...」
4. 完成後顯示：「Batch processing completed! N files processed.」

**進度條說明：**
- 單檔：顯示 0% → 處理中 → 100%
- 批次：顯示實際進度（例如：3/5 = 60%）

### 測試 Runner（可選）

`test_runner.asm` 會呼叫 `Pro2_CompressFile` 與 `DecompressHuffmanFile`，最後用 `CompareFiles` 驗證原始檔與還原檔是否 byte-by-byte 相同：

```
INVOKE Pro2_CompressFile, ADDR srcFile, ADDR compressed
INVOKE DecompressHuffmanFile, ADDR compressed, ADDR restored
INVOKE CompareFiles, ADDR srcFile, ADDR restored ; EAX = 1 代表一致
```

自訂測試時可替換 `srcFile` 為 UTF-8 或 UTF-16 檔案，演算法會保持原始編碼。

## 專案結構

```
Project32_VS2022/
├── Decoder.asm              # 解壓縮器（建樹 + 逐位元讀取）
├── HuffmanDataAnalyst.asm   # 建頻率表、節點配置、Huffman Tree
├── pro2.asm                 # Huffman 編碼器、位元緩衝器
├── HuffmanGUI.asm/.rc       # Win32 GUI 與檔案 I/O API 包裝
├── resource.h               # GUI 資源 ID
├── test_runner.asm          # 自動化壓縮/解壓測試
├── test_input.txt           # 預設 UTF-8 測試檔（可自行替換）
├── Project.sln / .vcxproj   # Visual Studio 解決方案與專案檔
└── README.md                # 目前文件
```

## 主要模組說明

- **HuffmanDataAnalyst.asm**：
    - `CountFrequencyFromFile` 以 4 KB buffer 掃描檔案。
    - `BuildHuffmanTree`/`FindMin` 透過指標陣列與靜態 node pool 建立樹。
- **pro2.asm**：
    - `BuildCodes` 以遞迴方式產生每個符號的 bit pattern。
    - `BitBufferWriteBit`/`BitBufferFlush` 實作 LSB-first 位元緩衝。
    - `Pro2_EncodeHuffman` 寫出檔頭（樹大小 + 樹結構 + 原始檔大小）與壓縮資料。
- **Decoder.asm**：
    - `RebuildNodeFromBuffer` 依前序序列還原樹。
    - 逐 bit 走樹寫回原始位元組，確保輸出大小等於檔頭紀錄。
- **HuffmanGUI.asm**：
    - 封裝 `OpenFileForRead/OpenFileForWrite/...` 等 15 個共用 I/O 函式。
    - 管理對話盒、訊息迴圈與錯誤提示。

## 測試建議

1. 以 UTF-8 建立 `test_input.txt`，內容可含英文、中文、符號或二進位資料。
2. 執行 GUI 或 `test_runner.exe` 壓縮並解壓。
3. 使用 `CompareFiles` 或 `fc /b original restored` 驗證輸出。
4. 若要測 UTF-16 或其他編碼，只要輸入檔本身使用該編碼，流程會如實保留。

## 注意事項

- 壓縮檔檔頭格式（v2.0）：`[4 bytes MAGIC "HUFF"][4 bytes treeBytes][preorder tree bytes][4 bytes originalSize][bitstream...]`。
- 🆕 加入 Magic Number 驗證，只能解壓縮本程式產生的 `.huff` 檔案。
- `test_input.txt` 採 UTF-8 儲存，以避免某些編輯器將 UTF-16 BOM 顯示為方塊字符。
- 清單中的 Debug/.vs/臨時輸出都已移除，若重新建置請將生成的資料夾加入 `.gitignore`。

## 授權

此專案為教學/課程使用，歡迎在非商業情境下參考與修改，如需引用請標註來源。歡迎 Issues/PR 一起改進！
