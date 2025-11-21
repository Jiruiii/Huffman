#  Huffman Coding File Compressor

霍夫曼編碼檔案壓縮工具 - 組合語言期末專案（人員一：GUI 與檔案 I/O 模組）

## 專案簡介

這是一個使用 **x86 組合語言 (MASM)** 實作的霍夫曼編碼檔案壓縮/解壓縮工具。

**本模組（人員一）** 負責提供完整的 GUI 介面和檔案 I/O 基礎設施，供其他組員使用。

##  人員一完成的功能

###  Windows GUI 介面

### 檔案 I/O 函式庫（15 個函式）
## 人員二完成的功能

### 檔案頻率分析與霍夫曼樹建構
- 讀取檔案並統計 256 字元的出現頻率（支援大檔案分段讀取）
- 建立霍夫曼樹資料結構（支援節點動態分配與陣列管理）
- 提供 `BuildHuffmanTree` 及 `BuildHuffmanTree_File` 介面，回傳樹根指標
- 支援樹結構序列化（供後續 header 寫入/解碼用）
- 單元測試：內建測試字串與自動化頻率驗證

## 人員三完成的功能

### 編碼表產生與壓縮流程
- 由霍夫曼樹產生 256 字元的編碼表（bit-level）
- 負責將樹序列化並寫入檔案 header（格式詳見下方）
- 將原始檔案依編碼表進行 bit-level 壓縮，並寫入壓縮檔
- 支援 header 回填、bitstream 尾端補 0
- 提供 `CompressFile` 介面，整合頻率分析、樹建構、編碼表產生與壓縮流程
- 單元測試：可用測試檔案驗證壓縮結果與 header 格式
#### 基礎檔案操作（9 個）
## 人員四完成的功能

### 解壓縮流程與樹重建
- 讀取壓縮檔 header，解析樹結構與原始檔案大小
- 依 header 內容重建霍夫曼樹（支援前序序列化格式）
- 逐 bit 讀取壓縮資料，依樹結構解碼還原原始檔案
- 支援解碼長度控制，避免 padding bits 產生多餘資料
- 提供 `DecompressHuffmanFile` 介面，整合 header 解析、樹重建與解碼流程
- 單元測試：可用壓縮檔驗證解壓縮正確性
```asm
OpenFileForRead(path)      ; 開啟檔案讀取
OpenFileForWrite(path)          ; 開啟檔案寫入
ReadFileByte(handle)            ; 讀取單一位元組
WriteFileByte(handle, byte)     ; 寫入單一位元組
ReadFileBuffer(h, buf, size)    ; 緩衝區讀取
WriteFileBuffer(h, buf, size)   ; 緩衝區寫入
CloseFileHandle(handle)         ; 關閉檔案
GetFileSizeEx(handle)      ; 獲得檔案大小
SeekFile(handle, offset, mode)  ; 移動檔案指標
```

#### 進階工具函式（6 個）
```asm
ValidateInputFile(path)         ; 驗證檔案（大小、存在性）
GetCompressedFileSize(path)          ; 獲得檔案大小
CopyFileData(src, dest)   ; 複製檔案
CompareFiles(file1, file2)           ; 比對兩個檔案是否相同
ClearBuffer(buffer, size)  ; 清除緩衝區
GenerateOutputFilename(in,out,ext)   ; 自動產生輸出檔名
```

### 錯誤處理
- 檔案不存在檢測
- 檔案太大檢測（限制 10MB）
- 空檔案檢測
- 權限錯誤處理
- 友善的錯誤訊息提示

## 檔案結構

```
Project32_VS2022/
├── HuffmanGUI.asm      # ? 主程式（本模組）
├── HuffmanGUI.rc       # ? GUI 資源檔
├── resource.h     # ? 資源定義
├── test_input.txt      # 測試用文字檔
├── Project.sln  # Visual Studio 方案
├── Project.vcxproj     # 專案設定檔
├── .gitignore     # Git 忽略檔案
└── README.md # 本文件
```

## 開發環境

- **作業系統**: Windows 10/11
- **開發工具**: Visual Studio 2022
- **組譯器**: Microsoft Macro Assembler (MASM)
- **函式庫**: Irvine32 Library
- **語言**: x86 Assembly Language

## 安裝與使用

### 前置需求

1. Visual Studio 2022（含 MASM）
2. Irvine32 Library
3. Windows SDK

### 編譯步驟

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

### 使用方法

1. 執行 `HuffmanGUI.exe`
2. 介面說明：
   - **Compress File** 按鈕：選擇要壓縮的文字檔
   - **Decompress File** 按鈕：選擇要解壓縮的 .huf 檔
   - **狀態顯示區**：顯示操作進度和壓縮統計
   - **Exit** 按鈕：結束程式

> **注意**：目前壓縮/解壓縮功能為模擬版本，實際演算法需要人員二、三、四實作。

## API 使用說明

### 給其他組員的整合指南

其他組員可以呼叫以下函式來完成檔案操作：

#### 範例 1：讀取檔案內容

```asm
; 開啟檔案
INVOKE OpenFileForRead, ADDR szFilePath
.IF eax == INVALID_HANDLE_VALUE
    ; 錯誤處理
    ret
.ENDIF
mov hFile, eax

; 讀取資料
read_loop:
    INVOKE ReadFileByte, hFile
    .IF eax == -1
        jmp read_done
    .ENDIF
    ; 處理讀取的位元組（EAX）
    jmp read_loop

read_done:
; 關閉檔案
INVOKE CloseFileHandle, hFile
```

#### 範例 2：寫入檔案

```asm
; 開啟檔案寫入
INVOKE OpenFileForWrite, ADDR szOutputPath
mov hFile, eax

; 寫入資料
mov al, 'A'  ; 要寫入的字元
INVOKE WriteFileByte, hFile, al

; 批次寫入
INVOKE WriteFileBuffer, hFile, ADDR buffer, 100

; 關閉檔案
INVOKE CloseFileHandle, hFile
```

#### 範例 3：檔案驗證

```asm
; 驗證輸入檔案
INVOKE ValidateInputFile, ADDR szFilePath
.IF eax == 0
    ; 檔案無效
    ret
.ENDIF
mov fileSize, eax  ; EAX = 檔案大小
```

## GUI 介面預覽

```
┌─────────────────────────────────────┐
│   Huffman File Compressor v1.0  [X] │
├─────────────────────────────────────┤
│  Huffman Coding File Compression    │
│     Tool           │
│                 │
│  Select an operation:           │
│        │
│  ┌───────────────────────────────┐  │
│  │      Compress File │  │
│  └───────────────────────────────┘  │
│           │
│  ┌───────────────────────────────┐  │
│  │    Decompress File   │  │
│  └───────────────────────────────┘  │
│  │
│  Status:          │
│  [Ready. Please select an operation.]│
│        │
│      ┌──────┐          │
│      │ Exit │      │
│      └──────┘   │
└─────────────────────────────────────┘
```

## 測試功能

### 已測試項目

- ? GUI 視窗正常顯示
- ? 檔案開啟對話框運作正常
- ? 檔案儲存對話框運作正常
- ? 檔案讀取功能正常
- ? 檔案寫入功能正常
- ? 檔案大小限制檢查
- ? 空檔案檢測
- ? 檔案不存在錯誤處理
- ? 狀態訊息更新
- ? 壓縮率計算顯示

### 測試方法

1. 選擇一個文字檔進行「壓縮」
2. 程式會模擬壓縮並顯示統計資訊
3. 選擇輸出位置
4. 檢查所有檔案操作是否正常

## 技術重點

### 使用的 Windows API
- `CreateFileA` - 檔案開啟/建立
- `ReadFile` - 檔案讀取
- `WriteFile` - 檔案寫入
- `GetFileSize` - 取得檔案大小
- `SetFilePointer` - 移動檔案指標
- `DialogBoxParamA` - 建立對話框
- `GetOpenFileNameA` - 檔案開啟對話框
- `GetSaveFileNameA` - 檔案儲存對話框
- `MessageBoxA` - 訊息視窗

### 組合語言技巧
- STRUCT 定義（OPENFILENAME）
- 區域變數（LOCAL）
- 記憶體操作（ADDR, OFFSET, PTR）
- 字串處理
- 錯誤處理流程

## 整合點說明

目前程式中預留了整合點，供其他組員加入壓縮/解壓縮演算法：

**在 `CompressFile` 程序中：**
```asm
; TODO: 在這裡呼叫人員二、三的函式
; INVOKE BuildHuffmanTree, ADDR szInputFile
; mov pTreeRoot, eax
; .IF eax != NULL
;     INVOKE CompressWithHuffman, pTreeRoot, ADDR szInputFile, ADDR szOutputFile
;     ...
; .ENDIF
```

**在 `DecompressFile` 程序中：**
```asm
; TODO: 在這裡呼叫人員四的函式
; INVOKE DecompressHuffmanFile, ADDR szInputFile, ADDR szOutputFile
; .IF eax != 0
;     ; 解壓縮成功
; ...
; .ENDIF
```

## 專案資訊

- **GitHub Repository**: https://github.com/Jiruiii/Huffman
- **開發者**: jiruiii
- **Email**: ray2017good@gmail.com
- **角色**: 人員一 - GUI 與檔案 I/O 總管

## 授權

本專案為學習專案，僅供學習參考使用。

---

**Made with ?? using x86 Assembly Language**


<!-- Additions from README_ADDITIONS.md -->

## 壓縮檔案格式（Header 規格）

為了讓「編碼器（人員三）」與「解碼器（人員四）」能互相正確溝通，建議採用以下簡單且明確的檔頭格式：

- DWORD (4 bytes, little-endian): `treeBytes` — 緊接著的序列化樹佔用的位元組數量
- 接著 `treeBytes` bytes: 樹的前序（pre-order）序列化：
  - `0x00` 表示內部節點（internal node）
  - `0x01` `<char>` 表示葉節點（leaf），後面緊接一個位元組表示該字元
- DWORD (4 bytes): `originalFileSize` — 解壓縮後應輸出的位元組數（方便解碼器知道何時結束）
- 接著為壓縮的 bitstream（以位元組為單位儲存，從 MSB 到 LSB 依序使用）

檔案整體結構：

```
[DWORD treeBytes][treeBytes bytes of serialized tree][DWORD originalFileSize][compressed data bytes]
```

說明：
- 序列化方式選用前序，內部節點只佔 1 byte 的標記（0x00），葉節點佔 2 bytes（0x01 + char），解碼端可用 stack 或遞迴來重建樹。
- `originalFileSize` 可用來在解碼時停止輸出，以避免因 padding bits 而產生多餘位元組。

此格式為建議，請人員三與人員四開會確認後再統一實作。

## 流程圖（文字版）

Compress:

Input.txt -> [頻率統計 (人員二)] -> Huffman Tree -> [產生編碼表 (人員三)] ->
Write Header (treeBytes + serialized tree + originalFileSize) -> Write compressed bitstream -> Output.huff

Decompress:

Output.huff -> Read Header (treeBytes + serialized tree + originalFileSize) -> Rebuild Huffman Tree (人員四) ->
Read compressed bitstream (bit-level) -> Traverse tree -> Output Restored.txt

## 四人分工摘要（快速檢視）

- **人員一（前端 GUI 與檔案 I/O）**：視窗介面、檔案選擇、提供 `OpenFileForRead/Write`、`ReadFileByte`、`WriteFileByte`、`CloseFileHandle` 等函式。
- **人員二（資料分析師）**：讀檔並統計頻率，建立 Huffman tree 資料結構，提供 `BuildHuffmanTree` 介面。
- **人員三（編碼器）**：從樹產生編碼表，寫入 header（使用上述格式），並以 bit-level I/O 寫出壓縮資料。
- **人員四（解碼器）**：讀 header、重建樹、逐位元解碼，並寫回原始檔案。

## 接下來的建議步驟（短期）

1. 人員三與人員四召開會議確認 header 格式與序列化細節（此 README 中的格式為建議）。
2. 人員一把 `ReadFileByte/WriteFileByte` 的測試範例交給其他人做單元測試。
3. 人員二 提供一個函式 `BuildHuffmanTree`，並包含一個小型測試輸入（例如 `AAAAABBBCC`），確認樹結構與節點序列化。
4. 人員三 實作寫 header 與 bit-level 寫入；人員四 同步實作讀 header 與 bit-level 讀取。

---
