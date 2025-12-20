# Huffman File Compressor

使用 MASM x86 組合語言實作的 Huffman 壓縮程式，包含 GUI 介面、檔案壓縮與解壓縮功能。

![Huffman Coding](https://user-images.githubusercontent.com/67422037/147872768-ef7f8952-c688-49ab-88f9-838593145d4a.png)

## 功能說明

這個專案實作了完整的 Huffman 編碼流程：
- `HuffmanDataAnalyst.asm` 負責統計字元頻率並建立 Huffman 樹
- `pro2.asm` 處理編碼與壓縮
- `Decoder.asm` 處理解壓縮
- `HuffmanGUI.asm` 提供 Windows GUI 介面

### v2.0 新功能
- 支援拖曳檔案到視窗直接壓縮或解壓縮
- 可以一次處理多個檔案（批次處理）
- 加入進度條顯示目前處理狀態
- 壓縮檔包含 Magic Number (HUFF)，避免誤開其他格式的檔案

### 檔案 I/O
所有模組共用一套檔案 I/O 函式，封裝了 Windows API (CreateFile, ReadFile, WriteFile 等)。

### 編碼支援
程式以 byte 為單位處理資料，因此可以處理任何編碼的文字檔（UTF-8、UTF-16、ASCII），甚至是二進位檔案。壓縮後再解壓縮會保持原本的編碼格式。

## 環境需求

- Windows 10 或 Windows 11
- Visual Studio 2022 (需安裝 MASM 與 Windows SDK)
- Irvine32 Library

## 編譯方式

1. 用 Visual Studio 開啟 `Project32_VS2022/Project.sln`
2. 設定組態：Debug 或 Release，平台選 Win32
3. 確認 Linker 設定包含以下 libraries:
   - kernel32.lib
   - user32.lib
   - comdlg32.lib
   - irvine32.lib
4. 按 Ctrl+Shift+B 編譯，或按 F5 執行

## 使用方法

### 方法一：使用按鈕

1. 點選 "Compress File(s)" 選擇要壓縮的檔案（可按住 Ctrl 多選）
2. 程式會產生對應的 .huff 檔案並顯示壓縮率
3. 點選 "Decompress File(s)" 選擇 .huff 檔案進行解壓縮
4. 如果檔案有問題（不存在、太大、無法開啟等），狀態列會顯示錯誤訊息

### 方法二：拖曳檔案

1. 直接把檔案拖到程式視窗上
2. 程式會自動判斷：
   - .huff 檔案會執行解壓縮
   - 其他檔案會執行壓縮
3. 可以一次拖多個檔案，程式會依序處理
4. 進度條會顯示處理進度（例如：Processing file 3 of 5...）

## 檔案結構

```
Project32_VS2022/
├── Decoder.asm              解壓縮器
├── HuffmanDataAnalyst.asm   建立 Huffman Tree
├── pro2.asm                 編碼器與位元處理
├── HuffmanGUI.asm/.rc       GUI 介面與檔案操作
├── resource.h               資源定義
├── Project.sln / .vcxproj   Visual Studio 專案檔
├── .gitignore
└── README.md
```

## 模組說明

### HuffmanDataAnalyst.asm
- CountFrequencyFromFile: 以 4KB buffer 讀取檔案並統計每個 byte 出現次數
- BuildHuffmanTree: 建立 Huffman 樹（使用靜態 node pool 與指標陣列）
- FindMin: 找出頻率最小的節點

### pro2.asm
- BuildCodes: 遞迴產生每個符號的 Huffman 編碼（LSB-first）
- BitBufferWriteBit/BitBufferFlush: 位元緩衝處理，每 8 位元寫入一個 byte
- Pro2_SerializeTreePreorder: 前序序列化 Huffman 樹
- Pro2_EncodeHuffman: 寫入檔案標頭與壓縮資料

### Decoder.asm
- RebuildNodeFromBuffer: 從前序序列化資料重建 Huffman 樹
- DecompressHuffmanFile: 驗證 Magic Number 後逐位元讀取並解壓縮

### HuffmanGUI.asm
- 封裝檔案 I/O 函式供其他模組使用
- 處理視窗訊息、對話方塊、錯誤提示
- 實作拖放、批次處理、進度顯示功能

## 壓縮檔格式

```
[4 bytes] Magic Number "HUFF" (48 55 46 46h)
[4 bytes] 樹資料大小 (treeBytes)
[變動]    樹的序列化資料（前序走訪，內部節點 = 0，葉節點 = 1 + 符號）
[4 bytes] 原始檔案大小 (originalSize)
[變動]    壓縮後的位元流（LSB-first）
```

Magic Number 用來驗證檔案格式，避免開啟錯誤的檔案。

## 測試建議

1. 建立一個測試檔案（例如 test_input.txt），可以包含中英文或任何資料
2. 用程式壓縮後再解壓縮
3. 用 `fc /b` 指令比對原始檔案與解壓縮後的檔案
4. 測試不同編碼的檔案（UTF-8、UTF-16 等）

## 限制

- 單一檔案最大 10 MB
- 批次處理最多 10 個檔案
- 樹資料最大 16 KB

## 開發環境

- IDE: Visual Studio 2022
- 語言: MASM (Microsoft Macro Assembler)
- 平台: Win32
- 編譯器: ml.exe

## 版本記錄

### v2.0
- 支援批次處理多個檔案
- 支援拖放檔案
- 加入進度條
- 加入 Magic Number 驗證

### v1.0
- 基本壓縮與解壓縮功能
- GUI 介面
- 檔案 I/O 封裝

## 授權

本專案為課程作業，僅供學習參考使用。
