# Huffman File Compressor - 人員一模組說明 (Enhanced Version)

## ?? 模組概述
此模組負責：
1. ? Windows GUI 介面（對話框）
2. ? 檔案選擇對話框（開啟/儲存）
3. ? 基礎檔案 I/O 函式（供其他組員使用）
4. ? **NEW!** 檔案驗證與錯誤處理
5. ? **NEW!** 壓縮率計算與統計顯示
6. ? **NEW!** 額外的工具函式

## ?? 完成項目
- [x] 主視窗對話框
- [x] "Compress File" 按鈕
- [x] "Decompress File" 按鈕
- [x] 狀態顯示區
- [x] 檔案開啟對話框
- [x] 檔案儲存對話框
- [x] 所有基礎 I/O 函式
- [x] **檔案大小驗證（限制 10MB）**
- [x] **空檔案檢測**
- [x] **壓縮率計算與顯示**
- [x] **自動產生輸出檔名**
- [x] **檔案複製功能**
- [x] **檔案比對功能**

## ?? 編譯方式

### 方法一：使用 Visual Studio
1. 將 `HuffmanGUI.asm`, `HuffmanGUI.rc`, `resource.h` 加入專案
2. 專案屬性 → Linker → Input → Additional Dependencies 加入：
   - `user32.lib`
   - `kernel32.lib`
   - `comdlg32.lib`
3. 按下 F5 執行

### 方法二：使用 MASM 命令列
```batch
ml /c /coff HuffmanGUI.asm
rc HuffmanGUI.rc
link /SUBSYSTEM:WINDOWS HuffmanGUI.obj HuffmanGUI.res kernel32.lib user32.lib comdlg32.lib irvine32.lib
```

## ?? 公用 I/O 函式 API（供其他組員使用）

### 基本 I/O 函式

### 1. OpenFileForRead
```asm
; 功能：開啟檔案進行讀取
; 參數：pszFilePath - 檔案路徑字串指標
; 傳回：EAX = 檔案 handle (失敗時為 INVALID_HANDLE_VALUE = -1)
; 範例：
INVOKE OpenFileForRead, ADDR szInputFile
.IF eax == INVALID_HANDLE_VALUE
  ; 錯誤處理
.ELSE
  mov hFile, eax  ; 儲存 handle
.ENDIF
```

### 2. OpenFileForWrite
```asm
; 功能：開啟檔案進行寫入（會覆蓋現有檔案）
; 參數：pszFilePath - 檔案路徑字串指標
; 傳回：EAX = 檔案 handle (失敗時為 INVALID_HANDLE_VALUE = -1)
; 範例：
INVOKE OpenFileForWrite, ADDR szOutputFile
mov hFile, eax
```

### 3. ReadFileByte
```asm
; 功能：從檔案讀取一個位元組
; 參數：hFile - 檔案 handle
; 傳回：EAX = 讀取的位元組值 (0-255)，若 EOF 或失敗則為 -1
; 範例：
read_loop:
    INVOKE ReadFileByte, hFile
    cmp eax, -1
    je end_of_file
    ; 處理讀取到的位元組（在 AL 中）
    movzx ecx, al
 ; ...處理...
    jmp read_loop
end_of_file:
```

### 4. WriteFileByte
```asm
; 功能：寫入一個位元組到檔案
; 參數：hFile - 檔案 handle
;       byteVal - 要寫入的位元組 (BYTE)
; 傳回：EAX = 1 (成功) 或 0 (失敗)
; 範例：
mov al, 65  ; 'A'
INVOKE WriteFileByte, hFile, al
```

### 5. ReadFileBuffer
```asm
; 功能：從檔案讀取多個位元組
; 參數：hFile - 檔案 handle
;       pBuffer - 緩衝區指標
;       nBytes - 要讀取的位元組數
; 傳回：EAX = 實際讀取的位元組數
; 範例：
.data
    buffer BYTE 1024 DUP(?)
.code
    INVOKE ReadFileBuffer, hFile, ADDR buffer, 1024
    mov bytesRead, eax
```

### 6. WriteFileBuffer
```asm
; 功能：寫入多個位元組到檔案
; 參數：hFile - 檔案 handle
;  pBuffer - 緩衝區指標
;       nBytes - 要寫入的位元組數
; 傳回：EAX = 實際寫入的位元組數
; 範例：
INVOKE WriteFileBuffer, hFile, ADDR buffer, 1024
```

### 7. CloseFileHandle
```asm
; 功能：關閉檔案
; 參數：hFile - 檔案 handle
; 傳回：EAX = 1 (成功) 或 0 (失敗)
; 範例：
INVOKE CloseFileHandle, hFile
```

### 8. GetFileSizeEx
```asm
; 功能：取得檔案大小
; 參數：hFile - 檔案 handle
; 傳回：EAX = 檔案大小（bytes）
; 範例：
INVOKE GetFileSizeEx, hFile
mov fileSize, eax
```

### 9. SeekFile
```asm
; 功能：移動檔案讀寫指標
; 參數：hFile - 檔案 handle
;       offset - 偏移量
;       method - 秀尾錄方法
;           FILE_BEGIN (0) - 從檔案開頭
;      FILE_CURRENT (1) - 從目前位置
;           FILE_END (2) - 從檔案結尾
; 傳回：EAX = 新的檔案指標位置
; 範例：
INVOKE SeekFile, hFile, 0, FILE_BEGIN  ; 秮至檔案開頭
```

## ?? 新增的工具函式

### 10. ValidateInputFile
```asm
; 功能：驗證輸入檔案（檢查存在性、大小、是否為空）
; 參數：pszFilePath - 檔案路徑
; 傳回：EAX = 檔案大小（成功）或 0（失敗）
; 說明：自動顯示錯誤訊息
; 範例：
INVOKE ValidateInputFile, ADDR szInputFile
.IF eax == 0
    ; 檔案驗證失敗
    ret
.ENDIF
mov fileSize, eax  ; 儲存檔案大小
```

### 11. GetCompressedFileSize
```asm
; 功能：取得壓縮檔案的大小（包含開啟和關閉）
; 參數：pszFilePath - 檔案路徑
; 傳回：EAX = 檔案大小或 0（失敗）
; 範例：
INVOKE GetCompressedFileSize, ADDR szOutputFile
mov compressedSize, eax
```

### 12. CopyFileData
```asm
; 功能：複製整個檔案
; 參數：pszSource - 來源檔案路徑
;    pszDest - 目的檔案路徑
; 傳回：EAX = 1 (成功) 或 0 (失敗)
; 範例：
INVOKE CopyFileData, ADDR srcFile, ADDR destFile
.IF eax == 1
    ; 複製成功
.ENDIF
```

### 13. CompareFiles
```asm
; 功能：比較兩個檔案是否完全相同（用於驗證壓縮/解壓縮）
; 參數：pszFile1 - 第一個檔案路徑
;       pszFile2 - 第二個檔案路徑
; 傳回：EAX = 1 (相同) 或 0 (不同/錯誤)
; 範例：
INVOKE CompareFiles, ADDR original, ADDR recovered
.IF eax == 1
    ; 檔案相同，解壓縮成功！
.ELSE
    ; 檔案不同，有問題
.ENDIF
```

### 14. ClearBuffer
```asm
; 功能：清空緩衝區（填入 0）
; 參數：pBuffer - 緩衝區指標
;   size - 緩衝區大小
; 傳回：無
; 範例：
INVOKE ClearBuffer, ADDR myBuffer, 256
```

### 15. GenerateOutputFilename
```asm
; 功能：根據輸入檔名自動產生輸出檔名
; 參數：pszInput - 輸入檔案路徑
;       pszOutput - 輸出緩衝區
;       pszExtension - 新副檔名（例如 ".huf"）
; 傳回：無
; 範例：
INVOKE GenerateOutputFilename, ADDR szInput, ADDR szOutput, ADDR hufExt
; input.txt -> input.huf
```

## ?? 與其他組員的整合介面

### 人員二（霍夫曼樹建立）需要實作的函式：
```asm
BuildHuffmanTree PROC, pszFilePath:PTR BYTE
    ; 輸入：檔案路徑
    ; 輸出：EAX = 霍夫曼樹根節點指標（失敗時為 NULL）
    ; 
    ; 使用方式：
    ; INVOKE OpenFileForRead, pszFilePath
    ; mov hFile, eax
    ; ; ...統計頻率...
    ; INVOKE ReadFileByte, hFile  ; 逐 byte 讀取
    ; ; ...建立樹...
    ; INVOKE CloseFileHandle, hFile
    ; mov eax, pTreeRoot
    ret
BuildHuffmanTree ENDP
```

### 人員三（壓縮）需要實作的函式：
```asm
CompressWithHuffman PROC, pTreeRoot:DWORD, pszInputFile:PTR BYTE, pszOutputFile:PTR BYTE
    ; 輸入：樹根指標、輸入檔路徑、輸出檔路徑
    ; 輸出：EAX = 1 (成功) 或 0 (失敗)
    ;
    ; 使用方式：
    ; INVOKE OpenFileForRead, pszInputFile
    ; mov hFileIn, eax
    ; INVOKE OpenFileForWrite, pszOutputFile
    ; mov hFileOut, eax
    ; ; ...壓縮...
  ; INVOKE CloseFileHandle, hFileIn
    ; INVOKE CloseFileHandle, hFileOut
    ; mov eax, 1  ; 成功
    ret
CompressWithHuffman ENDP
```

### 人員四（解壓縮）需要實作的函式：
```asm
DecompressHuffmanFile PROC, pszInputFile:PTR BYTE, pszOutputFile:PTR BYTE
    ; 輸入：壓縮檔路徑、輸出檔路徑
    ; 輸出：EAX = 1 (成功) 或 0 (失敗)
    ;
    ; 使用方式：
    ; INVOKE OpenFileForRead, pszInputFile
    ; mov hFileIn, eax
    ; INVOKE OpenFileForWrite, pszOutputFile
 ; mov hFileOut, eax
    ; ; ...解壓縮...
  ; INVOKE CloseFileHandle, hFileIn
    ; INVOKE CloseFileHandle, hFileOut
    ; mov eax, 1  ; 成功
    ret
DecompressHuffmanFile ENDP
```

## ?? 整合步驟

### 階段一：測試 GUI（目前已完成）?
```asm
; 在 HuffmanGUI.asm 中的 CompressFile 和 DecompressFile
; 目前會顯示對話框並選擇檔案
; 模擬顯示壓縮統計資訊
```

### 階段二：整合人員二
在 `HuffmanGUI.asm` 的 `CompressFile` 函式中，找到：
```asm
; TODO: 在這裡呼叫人員二、三的函式
; INVOKE BuildHuffmanTree, ADDR szInputFile
```
改為：
```asm
INVOKE BuildHuffmanTree, ADDR szInputFile
.IF eax == NULL
    INVOKE MessageBoxA, hMainDialog, ADDR szError, ADDR szAppTitle, MB_OK OR MB_ICONERROR
    ret
.ENDIF
mov pTreeRoot, eax  ; 儲存樹根指標
```

### 階段三：整合人員三
繼續在 `CompressFile` 中：
```asm
; INVOKE CompressWithHuffman, ADDR szInputFile, ADDR szOutputFile
```
改為：
```asm
INVOKE CompressWithHuffman, pTreeRoot, ADDR szInputFile, ADDR szOutputFile
.IF eax == 0
    INVOKE MessageBoxA, hMainDialog, ADDR szError, ADDR szAppTitle, MB_OK OR MB_ICONERROR
    ret
.ENDIF

; 取得實際壓縮後的檔案大小
INVOKE GetCompressedFileSize, ADDR szOutputFile
mov outputFileSize, eax

; 顯示統計（這個會自動計算壓縮率）
call DisplayCompressionStats
```

### 階段四：整合人員四
在 `DecompressFile` 函式中：
```asm
; INVOKE DecompressHuffmanFile, ADDR szInputFile, ADDR szOutputFile
```
改為：
```asm
INVOKE DecompressHuffmanFile, ADDR szInputFile, ADDR szOutputFile
.IF eax == 0
    INVOKE MessageBoxA, hMainDialog, ADDR szError, ADDR szAppTitle, MB_OK OR MB_ICONERROR
    ret
.ENDIF

; 取得解壓後的檔案大小
INVOKE GetCompressedFileSize, ADDR szOutputFile
mov outputFileSize, eax

; 顯示統計
call DisplayDecompressionStats
```

## ?? GUI 畫面說明
```
┌─────────────────────────────────────┐
│   Huffman File Compressor v1.0  [X] │
├─────────────────────────────────────┤
│  Huffman Coding File Compression    │
│           Tool           │
│             │
│  Select an operation:    │
│             │
│  ┌───────────────────────────────┐  │
│  │      Compress File     │  │
│  └───────────────────────────────┘  │
│               │
│  ┌───────────────────────────────┐  │
│  │    Decompress File      │  │
│  └───────────────────────────────┘  │
│   │
│  Status:   │
│  [Input: 1024 bytes | Output: 512   │
│   bytes | Compression: 50%]          │
│         │
│            ┌──────┐                  │
│       │ Exit │   │
│     └──────┘        │
└─────────────────────────────────────┘
```

## ?? 注意事項

1. **檔案路徑**：`szInputFile` 和 `szOutputFile` 是全域變數，已經在 GUI 選擇時填入。

2. **錯誤處理**：所有 I/O 函式都有傳回值，請務必檢查：
   ```asm
   INVOKE OpenFileForRead, ADDR szFile
   cmp eax, INVALID_HANDLE_VALUE
   je error_handler
   ```

3. **檔案大小限制**：目前限制為 10MB，如需更大請修改 `ValidateInputFile` 中的檢查。

4. **記憶體管理**：人員二建立樹時需要動態配置記憶體。

5. **位元操作**（給人員三和四）：
   ```asm
   ; 寫入一個 bit 的範例
   shl bitBuffer, 1  ; 左移
   or bitBuffer, eax ; 加入新 bit
   inc bitCount
   .IF bitCount == 8
       INVOKE WriteFileByte, hFile, bitBuffer
       mov bitCount, 0
    mov bitBuffer, 0
   .ENDIF
   ```

## ?? 測試建議

### 測試案例一：基本功能
```asm
; 使用 CopyFileData 備份原始檔案
INVOKE CopyFileData, ADDR original, ADDR backup

; 壓縮
INVOKE BuildHuffmanTree, ADDR original
INVOKE CompressWithHuffman, eax, ADDR original, ADDR compressed

; 解壓縮
INVOKE DecompressHuffmanFile, ADDR compressed, ADDR recovered

; 驗證
INVOKE CompareFiles, ADDR original, ADDR recovered
; 應該傳回 1（相同）
```

### 測試案例二：空檔案
```asm
; ValidateInputFile 會自動拒絕空檔案
```

### 測試案例三：大檔案
```asm
; 10MB 以上的檔案會被拒絕
```

## ?? 壓縮率計算公式

程式會自動計算並顯示壓縮率：

```
壓縮率 = (1 - compressed_size / original_size) × 100%
```

例如：
- 原檔案：1000 bytes
- 壓縮後：600 bytes
- 壓縮率：(1 - 600/1000) × 100% = 40%

## ?? 聯絡與測試

當你們完成各自的模組後：
1. 將你們的 `.asm` 檔案提供給我
2. 我會在 `HuffmanGUI.asm` 中 include 你們的檔案
3. 取消註解相應的 `INVOKE` 呼叫
4. 進行整合測試
5. 使用 `CompareFiles` 函式驗證正確性

## ?? 目前狀態

- ? GUI 完成（增強版）
- ? 檔案對話框完成
- ? I/O 函式完成（9 個基本函式）
- ? **工具函式完成（6 個額外函式）**
- ? **檔案驗證完成**
- ? **壓縮率計算完成**
- ? **錯誤處理完成**
- ? 等待人員二、三、四的模組

## ?? 額外功能

### 自動產生檔名
- 壓縮：`input.txt` → 自動建議 `input.huf`
- 解壓縮：`data.huf` → 自動建議 `data.txt`

### 即時統計
- 顯示原始檔案大小
- 顯示壓縮後檔案大小
- 自動計算壓縮率

### 完整驗證
- 使用 `CompareFiles` 函式可以確認解壓縮後的檔案與原檔案完全相同

祝你們專案順利！??
