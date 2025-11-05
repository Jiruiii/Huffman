# ?? 人員一模組 - 快速參考卡

## ?? 我提供的 15 個函式

### 基本檔案 I/O (必用)
```asm
1. OpenFileForRead(path)    → handle
2. OpenFileForWrite(path)       → handle  
3. ReadFileByte(handle)            → byte value or -1
4. WriteFileByte(handle, byte)     → 1/0
5. ReadFileBuffer(h, buf, size)    → bytes read
6. WriteFileBuffer(h, buf, size)   → bytes written
7. CloseFileHandle(handle)   → 1/0
8. GetFileSizeEx(handle)           → size
9. SeekFile(handle, offset, mode)  → position
```

### 進階工具 (選用但建議)
```asm
10. ValidateInputFile(path)→ size or 0
11. GetCompressedFileSize(path)     → size
12. CopyFileData(src, dest)         → 1/0
13. CompareFiles(file1, file2) → 1/0
14. ClearBuffer(buffer, size)       → void
15. GenerateOutputFilename(in, out, ext) → void
```

## ?? 給人員二

### 你要做什麼
建立霍夫曼樹（從檔案統計頻率）

### 你要實作的函式
```asm
BuildHuffmanTree PROC, pszFilePath:PTR BYTE
    ; TODO: 統計頻率、建立樹
    mov eax, pTreeRoot  ; 傳回樹根指標
  ret
BuildHuffmanTree ENDP
```

### 你要用到的函式
- `OpenFileForRead` - 開啟檔案
- `ReadFileByte` - 統計每個 byte 的頻率
- `GetFileSizeEx` - 知道要讀多少
- `CloseFileHandle` - 關檔

### 快速範例
```asm
; 統計頻率
INVOKE OpenFileForRead, pszFilePath
mov hFile, eax
read_loop:
    INVOKE ReadFileByte, hFile
    cmp eax, -1
    je done
    ; frequency[eax]++
    jmp read_loop
done:
INVOKE CloseFileHandle, hFile
```

## ?? 給人員三

### 你要做什麼
壓縮檔案（使用霍夫曼編碼）

### 你要實作的函式
```asm
CompressWithHuffman PROC, pTreeRoot:DWORD, pszIn:PTR BYTE, pszOut:PTR BYTE
    ; TODO: 產生編碼表、壓縮
    mov eax, 1  ; 成功
    ret
CompressWithHuffman ENDP
```

### 你要用到的函式
- `OpenFileForRead/Write` - 開啟輸入/輸出
- `ReadFileByte` - 讀取原始資料
- `WriteFileByte` - 寫入壓縮資料（bit by bit）
- `WriteFileBuffer` - 寫入檔頭
- `CloseFileHandle` - 關檔

### Bit-level 寫入技巧
```asm
; 初始化
mov bitBuffer, 0
mov bitCount, 0

; 寫入一個 bit (假設 bit 在 AL 的最低位)
shl bitBuffer, 1    ; 左移緩衝區
and al, 1           ; 只取最低位
or bitBuffer, al; 加入新 bit
inc bitCount

; 緩衝區滿了？
.IF bitCount == 8
    INVOKE WriteFileByte, hFileOut, bitBuffer
    mov bitCount, 0
    mov bitBuffer, 0
.ENDIF

; 最後記得寫入剩餘的 bits
.IF bitCount > 0
    mov cl, 8
    sub cl, bitCount
    shl bitBuffer, cl  ; 補齊到 8 bits
  INVOKE WriteFileByte, hFileOut, bitBuffer
.ENDIF
```

## ?? 給人員四

### 你要做什麼
解壓縮檔案

### 你要實作的函式
```asm
DecompressHuffmanFile PROC, pszIn:PTR BYTE, pszOut:PTR BYTE
    ; TODO: 讀取檔頭、重建樹、解壓縮
  mov eax, 1  ; 成功
    ret
DecompressHuffmanFile ENDP
```

### 你要用到的函式
- `OpenFileForRead/Write` - 開啟輸入/輸出
- `ReadFileByte` - 讀取壓縮資料
- `WriteFileByte` - 寫入解壓後的字元
- `ReadFileBuffer` - 讀取檔頭
- `CloseFileHandle` - 關檔

### Bit-level 讀取技巧
```asm
; 初始化
mov bitBuffer, 0
mov bitCount, 0

; 讀取一個 bit
read_bit:
    .IF bitCount == 0
      ; 需要讀取新的 byte
        INVOKE ReadFileByte, hFileIn
  cmp eax, -1
        je eof
        mov bitBuffer, al
    mov bitCount, 8
    .ENDIF
    
    ; 取得最高位
    mov al, bitBuffer
shr al, 7   ; 移到最低位
 ; AL 現在是 0 或 1
    
    shl bitBuffer, 1   ; 移除已讀的 bit
    dec bitCount
```

## ?? 測試你的模組

### 人員二測試
```asm
; 測試霍夫曼樹建立
INVOKE BuildHuffmanTree, ADDR testFile
.IF eax != NULL
    ; 成功！印出樹的結構或統計資訊
.ENDIF
```

### 人員三測試
```asm
; 先建立樹
INVOKE BuildHuffmanTree, ADDR inputFile
mov pTree, eax

; 壓縮
INVOKE CompressWithHuffman, pTree, ADDR inputFile, ADDR compressedFile

; 檢查壓縮檔是否產生
INVOKE ValidateInputFile, ADDR compressedFile
```

### 人員四測試
```asm
; 使用人員三產生的壓縮檔
INVOKE DecompressHuffmanFile, ADDR compressedFile, ADDR recoveredFile

; 驗證是否相同
INVOKE CompareFiles, ADDR inputFile, ADDR recoveredFile
.IF eax == 1
    ; 成功！
.ENDIF
```

## ?? 完整流程

```
1. [人員二] 原始檔 → 建立霍夫曼樹 → 樹根指標
2. [人員三] 原始檔 + 樹 → 壓縮 → .huf 檔
3. [人員四] .huf 檔 → 解壓縮 → 還原檔
4. [驗證] 原始檔 == 還原檔？
```

## ?? 重要常數

```asm
INVALID_HANDLE_VALUE EQU -1
FILE_BEGIN           EQU 0
FILE_CURRENT         EQU 1
FILE_END  EQU 2
```

## ?? 常見錯誤

### ? 錯誤：忘記檢查 handle
```asm
INVOKE OpenFileForRead, ADDR file
mov hFile, eax  ; 直接使用！
```

### ? 正確：
```asm
INVOKE OpenFileForRead, ADDR file
.IF eax == INVALID_HANDLE_VALUE
    ; 錯誤處理
    ret
.ENDIF
mov hFile, eax
```

### ? 錯誤：忘記關閉檔案
```asm
INVOKE OpenFileForRead, ADDR file
; ... 處理 ...
ret  ; 忘記 CloseFileHandle！
```

### ? 正確：
```asm
INVOKE OpenFileForRead, ADDR file
mov hFile, eax
; ... 處理 ...
INVOKE CloseFileHandle, hFile
ret
```

## ?? 需要幫助？

查閱：
1. `README_MODULE1.md` - 完整 API 文件
2. `Example_ForPerson2.asm` - 完整範例
3. `INTEGRATION_GUIDE.md` - 整合步驟

## ?? 記住

- ? 所有函式都有 PROTO 宣告
- ? 所有函式都有錯誤處理
- ? 全域變數 `szInputFile` 和 `szOutputFile` 可以直接用
- ? 檔案路徑已經由 GUI 填好

**專注在你的演算法實作，檔案 I/O 我都處理好了！** ??
