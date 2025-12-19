# Huffman Coding File Compressor

一個以 **MASM x86 組合語言** 實作的霍夫曼壓縮器，整合 GUI、檔案 I/O、Huffman Tree 建構、位元壓縮與解壓。所有程式碼都可在 Windows 10/11 + Visual Studio 2022 上直接編譯。

![Huffman Coding](https://user-images.githubusercontent.com/67422037/147872768-ef7f8952-c688-49ab-88f9-838593145d4a.png)

## 專案特色

- **完整 Huffman 流程**：`HuffmanDataAnalyst.asm` 建頻率表與樹、`pro2.asm` 實作編碼器、`Decoder.asm` 執行解碼器。
- **Win32 GUI**：`HuffmanGUI.asm` 提供壓縮/解壓按鈕、檔案對話盒與狀態欄。
- **🆕 檔案拖放功能**：直接拖曳檔案（或多個檔案）到視窗即可開始壓縮/解壓縮，自動識別檔案類型。
- **🆕 批次處理**：支援一次選擇/拖放多個檔案，自動依序處理所有檔案。
- **🆕 即時進度條**：顯示處理進度（單檔模式或批次模式），提供視覺化回饋。
- **🆕 Magic Number 驗證**：壓縮檔含 `HUFF` 簽章，解壓縮時會驗證檔案格式，防止錯誤操作。
- **共用 I/O 函式庫**：封裝 `CreateFile`, `ReadFile`, `WriteFile` 等 WinAPI，供其他模組與測試程式呼叫。
- **任意編碼支援**：演算法逐 byte 運作，可處理 UTF-8、UTF-16、ASCII 甚至二進位資料；壓縮後的檔案還原時會保留原本的 encoding。

## 建置需求

- **作業系統**：Windows 10/11
- **開發工具**：Visual Studio 2022（含 MASM 支援、Windows SDK）
- **相依套件**：Irvine32 Library（用於組合語言開發輔助函式）

## 編譯與執行

### 使用 Visual Studio

1. 以 Visual Studio 開啟 `Project32_VS2022/Project.sln`
2. 確認組態為 `Debug` 或 `Release`、平台 `Win32`
3. 檢查 Linker → Input → Additional Dependencies 包含：
   - `kernel32.lib`
   - `user32.lib`
   - `comdlg32.lib`
   - `irvine32.lib`
4. 按 `Ctrl+Shift+B` 建置，或按 `F5` 執行偵錯

### GUI 操作指南

**方式一：使用按鈕**
1. **Compress File(s)**：選擇單個或多個檔案（按住 Ctrl 多選），程式會建立 Huffman 樹、輸出 `.huff` 檔並顯示壓縮率
2. **Decompress File(s)**：選擇單個或多個 `.huff` 檔，程式會自動解壓縮
3. 狀態欄會提示錯誤（檔案不存在、超過 10 MB、無法開啟等）
4. 進度條會顯示當前處理進度

**方式二：拖放檔案 🆕（支援批次）**
1. 直接將單個或多個檔案拖曳到程式視窗上
2. 程式會自動判斷：
   - `.huff` 檔案 → 批次解壓縮
   - 其他檔案 → 批次壓縮
3. 進度條顯示：「Processing file X of Y...」
4. 完成後顯示：「Batch processing completed! N files processed.」

**進度條說明：**
- **單檔**：顯示 0% → 處理中 → 100%
- **批次**：顯示實際進度（例如：3/5 = 60%）

## 專案結構

```
Project32_VS2022/
├── Decoder.asm              # 解壓縮器（建樹 + 逐位元讀取）
├── HuffmanDataAnalyst.asm   # 建頻率表、節點配置、Huffman Tree
├── pro2.asm                 # Huffman 編碼器、位元緩衝器
├── HuffmanGUI.asm/.rc       # Win32 GUI 與檔案 I/O API 包裝
├── resource.h               # GUI 資源 ID
├── Project.sln / .vcxproj   # Visual Studio 解決方案與專案檔
├── .gitignore               # Git 忽略清單
└── README.md                # 專案說明文件
```

## 主要模組說明

### HuffmanDataAnalyst.asm
- `CountFrequencyFromFile` - 以 4 KB buffer 掃描檔案
- `BuildHuffmanTree` - 透過指標陣列與靜態 node pool 建立樹
- `FindMin` - 找出最小頻率節點

### pro2.asm
- `BuildCodes` - 以遞迴方式產生每個符號的 bit pattern
- `BitBufferWriteBit` / `BitBufferFlush` - 實作 LSB-first 位元緩衝
- `Pro2_EncodeHuffman` - 寫出檔頭（樹大小 + 樹結構 + 原始檔大小）與壓縮資料

### Decoder.asm
- `RebuildNodeFromBuffer` - 依前序序列還原樹
- 逐 bit 走樹寫回原始位元組，確保輸出大小等於檔頭紀錄

### HuffmanGUI.asm
- 封裝 15 個共用 I/O 函式（`OpenFileForRead`, `OpenFileForWrite` 等）
- 管理對話盒、訊息迴圈與錯誤提示
- 支援拖放、批次處理、進度顯示

## 技術特點

### 壓縮檔格式（v2.0）
```
[4 bytes MAGIC "HUFF"]
[4 bytes treeBytes]
[preorder tree bytes]
[4 bytes originalSize]
[bitstream...]
```

### 特色功能
- ✅ **Magic Number 驗證**：只能解壓縮本程式產生的 `.huff` 檔案
- ✅ **任意編碼支援**：UTF-8、UTF-16、二進位資料均可正確處理
- ✅ **批次處理**：一次處理多個檔案，自動產生輸出檔名
- ✅ **拖放支援**：便捷的使用者介面
- ✅ **進度顯示**：即時回饋處理狀態

## 測試建議

1. 以 UTF-8 建立 `test_input.txt`，內容可含英文、中文、符號或二進位資料
2. 執行 GUI 壓縮並解壓
3. 使用 `fc /b original decompressed` 驗證輸出
4. 若要測 UTF-16 或其他編碼，只要輸入檔本身使用該編碼，流程會如實保留

## 注意事項

- 🔒 檔案大小限制：最大 10 MB
- 🔒 批次處理限制：最多 10 個檔案
- ⚠️ `test_input.txt` 採 UTF-8 儲存，以避免某些編輯器將 UTF-16 BOM 顯示為方塊字符
- ⚠️ Debug/.vs/臨時輸出都已在 `.gitignore` 中排除

## 開發環境

- **IDE**：Visual Studio 2022
- **語言**：MASM (Microsoft Macro Assembler)
- **平台**：Win32
- **編譯器**：ml.exe (MASM assembler)

## 授權與貢獻

此專案為教學/課程使用，歡迎在非商業情境下參考與修改。

- 如需引用請標註來源
- 歡迎提交 Issues 或 Pull Requests 改進專案
- 建議改進方向：
  - 支援更大檔案（分段處理）
  - 加入壓縮率統計圖表
  - 支援更多檔案格式驗證

## 版本歷史

### v2.0 (Current)
- ✨ 新增批次處理功能
- ✨ 新增拖放支援
- ✨ 新增進度條顯示
- ✨ 新增 Magic Number 驗證
- 🐛 修正多檔案選擇問題

### v1.0
- ✅ 基本 Huffman 壓縮/解壓功能
- ✅ GUI 介面
- ✅ 檔案 I/O 封裝

---

**Made with ❤️ using MASM x86 Assembly**
