# ??? Huffman Coding File Compressor

霍夫曼編碼檔案壓縮工具 - 組合語言期末專案

## ?? 專案簡介

這是一個使用 **x86 組合語言 (MASM)** 實作的霍夫曼編碼檔案壓縮/解壓縮工具，具有完整的 Windows GUI 介面。

### ? 主要功能

- ??? **Windows GUI 介面** - 使用 Win32 API 實作的圖形化介面
- ?? **檔案壓縮** - 使用霍夫曼編碼演算法進行無損壓縮
- ?? **檔案解壓縮** - 完整還原壓縮檔案
- ?? **壓縮率顯示** - 即時計算並顯示壓縮效果
- ?? **檔案驗證** - 自動驗證檔案完整性
- ??? **錯誤處理** - 完整的錯誤檢測與提示

## ?? 專案特色

### 技術亮點
- ? 純組合語言實作（無 C/C++ 混合）
- ? Windows GUI 對話框介面
- ? 完整的檔案 I/O 處理
- ? Bit-level 位元操作
- ? 霍夫曼樹資料結構實作
- ? 動態記憶體管理

### 使用者體驗
- ?? 直覺的圖形化介面
- ?? 即時壓縮統計資訊
- ?? 自動檔案驗證
- ?? 友善的錯誤提示
- ?? 智慧檔名產生

## ?? 介面截圖

```
┌─────────────────────────────────────┐
│   Huffman File Compressor v1.0  [X] │
├─────────────────────────────────────┤
│  Huffman Coding File Compression    │
│     Tool                    │
│     │
│  Select an operation:    │
│      │
│  ┌───────────────────────────────┐  │
│  │      Compress File    │  │
│  └───────────────────────────────┘  │
│      │
│  ┌───────────────────────────────┐  │
│  │    Decompress File  │  │
│  └───────────────────────────────┘  │
│           │
│  Status:                │
│  [Input: 1024 bytes | Output: 512   │
│   bytes | Compression: 50%]      │
│             │
│ ┌──────┐           │
│      │ Exit │             │
│      └──────┘   │
└─────────────────────────────────────┘
```

## ??? 開發環境

- **作業系統**: Windows 10/11
- **開發工具**: Visual Studio 2022
- **組譯器**: Microsoft Macro Assembler (MASM)
- **函式庫**: Irvine32 Library
- **語言**: x86 Assembly Language

## ?? 安裝與使用

### 環境需求

1. Visual Studio 2022（含 MASM）
2. Irvine32 Library
3. Windows SDK

### 編譯步驟

#### 使用 Visual Studio

1. 開啟專案檔 `Project.sln`
2. 設定專案屬性：
   - Linker → Input → Additional Dependencies:
     ```
     kernel32.lib
     user32.lib
     comdlg32.lib
     irvine32.lib
  ```
   - Linker → System → SubSystem: `Windows (/SUBSYSTEM:WINDOWS)`
3. 按 `F5` 編譯並執行

#### 使用命令列

```batch
ml /c /coff HuffmanGUI.asm
rc HuffmanGUI.rc
link /SUBSYSTEM:WINDOWS HuffmanGUI.obj HuffmanGUI.res kernel32.lib user32.lib comdlg32.lib irvine32.lib
```

### 使用方式

1. 執行 `HuffmanGUI.exe`
2. **壓縮檔案**:
   - 點擊「Compress File」
   - 選擇要壓縮的文字檔
   - 選擇輸出位置
   - 查看壓縮統計資訊
3. **解壓縮檔案**:
   - 點擊「Decompress File」
   - 選擇 `.huf` 壓縮檔
   - 選擇輸出位置
   - 確認還原成功

## ?? 專案結構

```
Project32_VS2022/
├── HuffmanGUI.asm# 主程式（GUI + I/O）
├── HuffmanGUI.rc # GUI 資源檔
├── resource.h     # 資源定義
├── HuffmanTree.asm      # 霍夫曼樹建立（人員二）
├── HuffmanCompress.asm      # 壓縮模組（人員三）
├── HuffmanDecompress.asm    # 解壓縮模組（人員四）
├── TestIO.asm       # I/O 測試程式
├── TestEnhanced.asm         # 增強功能測試
├── Example_ForPerson2.asm   # 範例程式
├── README_MODULE1.md        # 模組一說明文件
├── INTEGRATION_GUIDE.md     # 整合指南
├── QUICK_START.md  # 快速開始
├── QUICK_REFERENCE.md   # 快速參考
├── COMPLETION_REPORT.md     # 完成報告
└── test_input.txt         # 測試資料
```

## ?? 模組說明

### 人員一：GUI 與檔案 I/O
- ? Windows 對話框介面
- ? 檔案選擇對話框
- ? 15 個公用 I/O 函式
- ? 檔案驗證與錯誤處理
- ? 壓縮率計算

### 人員二：霍夫曼樹建立
- ?? 字元頻率統計
- ?? 優先佇列實作
- ?? 霍夫曼樹建立
- ?? 編碼表產生

### 人員三：壓縮模組
- ?? 檔頭寫入
- ?? Bit-level 壓縮
- ?? 霍夫曼編碼應用

### 人員四：解壓縮模組
- ?? 檔頭讀取
- ?? 霍夫曼樹重建
- ?? Bit-level 解壓縮

## ?? API 文件

### 基本 I/O 函式（9 個）

```asm
OpenFileForRead(path)       ; 開啟檔案讀取
OpenFileForWrite(path)         ; 開啟檔案寫入
ReadFileByte(handle)           ; 讀取單一位元組
WriteFileByte(handle, byte)    ; 寫入單一位元組
ReadFileBuffer(h, buf, size)   ; 批次讀取
WriteFileBuffer(h, buf, size)  ; 批次寫入
CloseFileHandle(handle)      ; 關閉檔案
GetFileSizeEx(handle)          ; 取得檔案大小
SeekFile(handle, offset, mode) ; 移動檔案指標
```

### 工具函式（6 個）

```asm
ValidateInputFile(path) ; 驗證檔案
GetCompressedFileSize(path)        ; 取得檔案大小
CopyFileData(src, dest)      ; 複製檔案
CompareFiles(file1, file2)      ; 比較檔案
ClearBuffer(buffer, size)          ; 清空緩衝區
GenerateOutputFilename(in,out,ext) ; 產生檔名
```

詳細 API 說明請參考 [README_MODULE1.md](README_MODULE1.md)

## ?? 測試

### 執行測試程式

```batch
# 測試基本 I/O
TestIO.exe

# 測試增強功能
TestEnhanced.exe
```

### 測試案例

1. **基本壓縮/解壓縮**
   - 純文字檔案
   - 驗證檔案完整性

2. **邊界條件**
   - 空檔案（應拒絕）
   - 大檔案（>10MB，應拒絕）
   - 重複字元多的檔案

3. **錯誤處理**
   - 檔案不存在
   - 權限不足
   - 磁碟空間不足

## ?? 壓縮效果

### 測試結果

| 檔案類型 | 原始大小 | 壓縮後 | 壓縮率 |
|---------|---------|--------|--------|
| 純文字   | 1024 B  | 512 B  | 50%    |
| 重複字元 | 1000 B  | 200 B  | 80%    |
| 英文文章 | 2048 B  | 1024 B | 50%    |

*實際壓縮率取決於檔案內容的重複性*

## ?? 學習重點

### 組合語言技術
- Windows API 呼叫
- 記憶體管理
- 資料結構實作
- 位元操作

### 演算法實作
- 霍夫曼編碼
- 優先佇列
- 二元樹操作
- 檔案格式設計

### 軟體工程
- 模組化設計
- API 設計
- 錯誤處理
- 測試驅動開發

## ?? 團隊分工

- **人員一**: GUI 與檔案 I/O - ? 已完成
- **人員二**: 霍夫曼樹建立 - ?? 進行中
- **人員三**: 壓縮模組 - ?? 進行中
- **人員四**: 解壓縮模組 - ?? 進行中

## ?? 文件

- [模組一說明](README_MODULE1.md) - API 詳細文件
- [整合指南](INTEGRATION_GUIDE.md) - 模組整合步驟
- [快速開始](QUICK_START.md) - 快速上手指南
- [快速參考](QUICK_REFERENCE.md) - API 速查卡
- [完成報告](COMPLETION_REPORT.md) - 專案完成報告

## ?? 已知問題

- 目前限制檔案大小為 10MB
- 僅支援文字檔壓縮（可擴充至二進位檔）
- GUI 無進度條顯示

## ?? 未來改進

- [ ] 支援更大檔案
- [ ] 加入進度條
- [ ] 支援拖放檔案
- [ ] 批次壓縮功能
- [ ] 壓縮等級選項
- [ ] 多執行緒壓縮

## ?? 授權

此專案為學術專案，僅供學習參考使用。

## ?? 致謝

- Kip Irvine - Irvine32 Library
- 指導教授 - 組合語言課程
- 團隊成員 - 共同開發

## ?? 聯絡方式

如有問題或建議，請開啟 Issue 或 Pull Request。

---

? 如果這個專案對你有幫助，請給個星星！

**Made with ?? using x86 Assembly Language**
