# ??? Huffman Coding File Compressor

霍夫曼編碼檔案壓縮工具 - 組合語言期末專案

## ?? 專案簡介

這是一個使用 **x86 組合語言 (MASM)** 實作的霍夫曼編碼檔案壓縮/解壓縮工具，具有完整的 Windows GUI 介面。

### ?? 主要功能

- **壓縮檔案** - 使用霍夫曼編碼壓縮文字檔
- **解壓縮檔案** - 完整還原壓縮檔
- **壓縮率顯示** - 即時計算並顯示壓縮效果
- **檔案驗證** - 自動檢查檔案完整性
- **錯誤處理** - 完整的錯誤檢測與提示

## ??? 專案架構

### 四人分工模式

**人員一：GUI 與檔案 I/O 總管**
- ? Windows 視窗介面
- ? 檔案對話框
- ? 基礎檔案讀寫函式（15 個 I/O 函式）
- ?? 負責檔案：`HuffmanGUI.asm`

**人員二：資料分析師**
- ?? 字元頻率統計
- ?? 優先佇列實作
- ?? 霍夫曼樹建立
- ?? 負責檔案：`HuffmanTree.asm` (待實作)

**人員三：編碼器**
- ?? 產生編碼表
- ?? 撰寫檔頭
- ?? Bit-level 壓縮
- ?? 負責檔案：`HuffmanCompress.asm` (待實作)

**人員四：解碼器**
- ?? 讀取檔頭
- ?? 霍夫曼樹重建
- ?? Bit-level 解壓縮
- ?? 負責檔案：`HuffmanDecompress.asm` (待實作)

## ?? 檔案結構

```
Project32_VS2022/
├── HuffmanGUI.asm     # ? 主程式 (GUI + I/O) - 人員一
├── HuffmanGUI.rc           # ? GUI 資源檔
├── resource.h        # ? 資源定義
├── HuffmanTree.asm         # ?? 霍夫曼樹建立 - 人員二
├── HuffmanCompress.asm     # ?? 壓縮模組 - 人員三
├── HuffmanDecompress.asm   # ?? 解壓縮模組 - 人員四
├── test_input.txt          # 測試檔案
├── Project.sln             # Visual Studio 方案
├── Project.vcxproj         # 專案設定檔
└── README.md       # 本文件
```

**圖示說明：**
- ? 已完成
- ?? 進行中
- ? 待開始

## ??? 開發環境

- **作業系統**: Windows 10/11
- **開發工具**: Visual Studio 2022
- **組譯器**: Microsoft Macro Assembler (MASM)
- **函式庫**: Irvine32 Library
- **語言**: x86 Assembly Language

## ?? 安裝與使用

### 前置需求

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

### 使用方法

1. 執行 `HuffmanGUI.exe`
2. **壓縮檔案**:
   - 點擊「Compress File」
   - 選擇要壓縮的文字檔
   - 選擇輸出位置
   - 查看壓縮率統計資訊
3. **解壓縮檔案**:
   - 點擊「Decompress File」
   - 選擇 `.huf` 壓縮檔
   - 選擇輸出位置
   - 確認還原成功

## ?? API 介面

### 檔案 I/O 函式（9 個）

```asm
OpenFileForRead(path)       ; 開啟檔案讀取
OpenFileForWrite(path)          ; 開啟檔案寫入
ReadFileByte(handle)      ; 讀取單一位元組
WriteFileByte(handle, byte)     ; 寫入單一位元組
ReadFileBuffer(h, buf, size)    ; 緩衝區讀取
WriteFileBuffer(h, buf, size)   ; 緩衝區寫入
CloseFileHandle(handle)     ; 關閉檔案
GetFileSizeEx(handle)           ; 獲得檔案大小
SeekFile(handle, offset, mode)  ; 移動檔案指標
```

### 工具函式（6 個）

```asm
ValidateInputFile(path)        ; 驗證檔案
GetCompressedFileSize(path)         ; 獲得檔案大小
CopyFileData(src, dest)             ; 複製檔案
CompareFiles(file1, file2)          ; 比對檔案
ClearBuffer(buffer, size)     ; 清除緩衝區
GenerateOutputFilename(in,out,ext)  ; 產生檔名
```

## ?? 整合指南

### 人員二（樹建立）需提供：

```asm
; 函式原型
BuildHuffmanTree PROTO, pszFilePath:PTR BYTE
; 輸入：檔案路徑
; 輸出：EAX = 樹根節點指標（NULL 表示失敗）

; 節點結構
HuffNode STRUCT
    freq    DWORD ?     ; 頻率
    char BYTE  ?   ; 字元（葉節點）
    left    DWORD ?     ; 左子節點指標
    right   DWORD ?     ; 右子節點指標
HuffNode ENDS
```

**使用方式：**
```asm
; 在 HuffmanGUI.asm 的 CompressFile 中呼叫
INVOKE BuildHuffmanTree, ADDR szInputFile
mov pTreeRoot, eax
.IF eax != NULL
    ; 繼續壓縮流程
.ENDIF
```

### 人員三（壓縮）需提供：

```asm
; 函式原型
CompressWithHuffman PROTO, pTreeRoot:DWORD, pszInput:PTR BYTE, pszOutput:PTR BYTE
; 輸入：樹根、輸入檔路徑、輸出檔路徑
; 輸出：EAX = 1（成功）或 0（失敗）
```

**使用方式：**
```asm
; 在 HuffmanGUI.asm 的 CompressFile 中呼叫
INVOKE CompressWithHuffman, pTreeRoot, ADDR szInputFile, ADDR szOutputFile
.IF eax != 0
    ; 壓縮成功
    INVOKE GetCompressedFileSize, ADDR szOutputFile
    mov outputFileSize, eax
    INVOKE DisplayCompressionStats
.ENDIF
```

### 人員四（解壓縮）需提供：

```asm
; 函式原型
DecompressHuffmanFile PROTO, pszInput:PTR BYTE, pszOutput:PTR BYTE
; 輸入：壓縮檔路徑、輸出檔路徑
; 輸出：EAX = 1（成功）或 0（失敗）
```

**使用方式：**
```asm
; 在 HuffmanGUI.asm 的 DecompressFile 中呼叫
INVOKE DecompressHuffmanFile, ADDR szInputFile, ADDR szOutputFile
.IF eax != 0
    ; 解壓縮成功
    INVOKE GetCompressedFileSize, ADDR szOutputFile
    mov outputFileSize, eax
    INVOKE DisplayDecompressionStats
.ENDIF
```

## ?? 檔頭格式規範

**重要：人員三和人員四必須遵守相同的格式！**

建議的檔頭格式：
```
[4 bytes] 魔術數字: "HUFF"
[4 bytes] 原始檔案大小
[4 bytes] 樹節點數量
[N bytes] 霍夫曼樹序列化資料（前序遍歷）
[M bytes] 壓縮資料
```

## ?? 測試計畫

### 單元測試

1. **人員一測試**
   - GUI 介面顯示
   - 檔案選擇對話框
   - 檔案讀寫功能

2. **人員二測試**
   - 頻率統計正確性
   - 霍夫曼樹建立
   - 使用簡單字串測試（如 "AAAAABBBCC"）

3. **人員三測試**
   - 編碼表生成
   - 位元寫入正確性
   - 檔頭寫入完整性

4. **人員四測試**
   - 檔頭讀取正確性
   - 位元讀取
   - 樹重建與遍歷

### 整合測試

1. **階段一**：人員一 + 人員二
   - 測試：選檔案 → 成功建立霍夫曼樹

2. **階段二**：加入人員三
   - 測試：選檔案 → 成功產生壓縮檔

3. **階段三**：加入人員四
   - 測試：選壓縮檔 → 成功還原檔案

4. **最終測試**
   - 壓縮 A 檔案得到 B 檔案
   - 解壓縮 B 檔案得到 C 檔案
   - 驗證：A 和 C 檔案完全相同

## ?? 當前狀態

### 已實作功能（人員一）

- ? Windows GUI 介面
- ? 檔案開啟對話框
- ? 檔案儲存對話框
- ? 15 個完整的 I/O 函式
- ? 檔案驗證與錯誤處理
- ? 壓縮率計算與顯示
- ? 狀態訊息更新

### 待實作功能

- ? 霍夫曼樹建立（人員二）
- ? 壓縮模組（人員三）
- ? 解壓縮模組（人員四）

### 整合點說明

目前 `HuffmanGUI.asm` 中的 TODO 標記處是預留的整合點：

```asm
; TODO: 在這裡呼叫人員二、三的函式
; INVOKE BuildHuffmanTree, ADDR szInputFile
; mov pTreeRoot, eax
; .IF eax != NULL
;   INVOKE CompressWithHuffman, pTreeRoot, ADDR szInputFile, ADDR szOutputFile
;     ...
; .ENDIF
```

## ?? 學習重點

### 組合語言技術
- Windows API 呼叫
- 記憶體管理
- 資料結構實作
- 位元運算

### 演算法實作
- 霍夫曼編碼
- 優先佇列
- 二元樹遍歷
- 檔案格式設計

### 軟體工程
- 模組化設計
- API 設計
- 錯誤處理
- 團隊協作開發

## ?? 相關資源

- **Irvine32 Library**: http://www.asmirvine.com/
- **MASM 文件**: Microsoft Macro Assembler Reference
- **霍夫曼編碼**: https://en.wikipedia.org/wiki/Huffman_coding

## ?? 聯絡方式

- **GitHub Repository**: https://github.com/Jiruiii/Huffman
- **開發者**: jiruiii
- **Email**: ray2017good@gmail.com

## ?? 授權

本專案為學習專案，僅供學習參考使用。

---

? 如果這個專案對你有幫助，請給個 Star！

**Made with ?? using x86 Assembly Language**
