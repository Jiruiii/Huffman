; ===============================================
; 霍夫曼壓縮模組 (人員三)
; Huffman Compression Module
; ===============================================
INCLUDE Irvine32.inc

; 外部函式宣告（人員一提供）
OpenFileForRead PROTO, pszFilePath:PTR BYTE
OpenFileForWrite PROTO, pszFilePath:PTR BYTE
ReadFileByte PROTO, hFile:DWORD
WriteFileByte PROTO, hFile:DWORD, byteVal:BYTE
WriteFileBuffer PROTO, hFile:DWORD, pBuffer:PTR BYTE, nBytes:DWORD
CloseFileHandle PROTO, hFile:DWORD

; 霍夫曼樹節點結構（必須與人員二一致）
HuffNode STRUCT
  freq    DWORD ?
    char    BYTE  ?
    left    DWORD ?
    right   DWORD ?
HuffNode ENDS

; 本模組提供的函式
PUBLIC CompressWithHuffman

.const
MAX_CODE_LENGTH EQU 256     ; 最大編碼長度
MAX_CHARS EQU 256           ; ASCII 字元數量
INVALID_HANDLE_VALUE EQU -1

.data
; 編碼表：儲存每個字元的霍夫曼編碼
codeTable BYTE MAX_CHARS * MAX_CODE_LENGTH DUP(0)
codeLengths BYTE MAX_CHARS DUP(0)

; 位元緩衝區
bitBuffer BYTE 0
bitCount BYTE 0

; 測試訊息
szCompressMsg BYTE "Compressing file...",0

.code

;-----------------------------------------------
; CompressWithHuffman
; 功能：使用霍夫曼樹壓縮檔案
; 輸入：pTreeRoot - 霍夫曼樹根節點指標
;  pszInput - 輸入檔案路徑
;       pszOutput - 輸出檔案路徑
; 輸出：EAX = 1（成功）或 0（失敗）
;-----------------------------------------------
CompressWithHuffman PROC USES ebx ecx edx esi edi, pTreeRoot:DWORD, pszInput:PTR BYTE, pszOutput:PTR BYTE
 LOCAL hFileIn:DWORD
    LOCAL hFileOut:DWORD
    LOCAL byteVal:DWORD
    
    ; TODO: 步驟 1 - 產生編碼表
    ; call GenerateCodeTable, pTreeRoot
    
    ; TODO: 步驟 2 - 開啟輸入和輸出檔案
    ; INVOKE OpenFileForRead, pszInput
    ; mov hFileIn, eax
    ; INVOKE OpenFileForWrite, pszOutput
    ; mov hFileOut, eax
    
    ; TODO: 步驟 3 - 寫入檔頭
    ; call WriteHeader, hFileOut, pTreeRoot
  
    ; TODO: 步驟 4 - 壓縮資料
    ; call CompressData, hFileIn, hFileOut
    
    ; TODO: 步驟 5 - 寫入剩餘位元
    ; call FlushBitBuffer, hFileOut
    
    ; TODO: 步驟 6 - 關閉檔案
    ; INVOKE CloseFileHandle, hFileIn
    ; INVOKE CloseFileHandle, hFileOut
    
    ; 暫時回傳失敗（待實作）
    xor eax, eax
    ret
CompressWithHuffman ENDP

;-----------------------------------------------
; GenerateCodeTable
; 功能：遍歷霍夫曼樹，產生每個字元的編碼
; 輸入：pTreeRoot - 樹根節點指標
;-----------------------------------------------
GenerateCodeTable PROC, pTreeRoot:DWORD
    LOCAL currentCode[MAX_CODE_LENGTH]:BYTE
    LOCAL codeLength:DWORD
    
    ; TODO: 實作遞迴遍歷
    ; 1. 走到左子節點時，在當前編碼後加 '0'
    ; 2. 走到右子節點時，在當前編碼後加 '1'
    ; 3. 到達葉節點時，儲存該字元的編碼
    
    ; 提示：可以呼叫輔助函式 GenerateCodeRecursive
    
    ret
GenerateCodeTable ENDP

;-----------------------------------------------
; GenerateCodeRecursive
; 功能：遞迴產生編碼表
; 輸入：pNode - 當前節點
;       pCurrentCode - 當前編碼
;       codeLength - 當前編碼長度
;-----------------------------------------------
GenerateCodeRecursive PROC, pNode:DWORD, pCurrentCode:PTR BYTE, codeLength:DWORD
    ; TODO: 實作遞迴邏輯
    
    ret
GenerateCodeRecursive ENDP

;-----------------------------------------------
; WriteHeader
; 功能：寫入壓縮檔案的檔頭
; 輸入：hFile - 輸出檔案控制代碼
;       pTreeRoot - 霍夫曼樹根節點
;-----------------------------------------------
WriteHeader PROC, hFile:DWORD, pTreeRoot:DWORD
    ; TODO: 實作檔頭寫入
    ; 建議格式：
    ; [4 bytes] 魔術數字: "HUFF"
    ; [4 bytes] 原始檔案大小
    ; [4 bytes] 樹節點數量
    ; [N bytes] 霍夫曼樹序列化資料
    
    ; 重要：必須與人員四約定相同格式！
    
    ret
WriteHeader ENDP

;-----------------------------------------------
; SerializeTree
; 功能：序列化霍夫曼樹（前序遍歷）
; 輸入：hFile - 輸出檔案
;       pNode - 當前節點
;-----------------------------------------------
SerializeTree PROC, hFile:DWORD, pNode:DWORD
    ; TODO: 實作樹的序列化
    ; 提示：
    ; - 內部節點寫入標記 '0'
    ; - 葉節點寫入標記 '1' + 字元值
    
    ret
SerializeTree ENDP

;-----------------------------------------------
; CompressData
; 功能：讀取輸入檔案並壓縮寫入
; 輸入：hFileIn - 輸入檔案
;       hFileOut - 輸出檔案
;-----------------------------------------------
CompressData PROC, hFileIn:DWORD, hFileOut:DWORD
    ; TODO: 實作資料壓縮
    ; 1. 逐位元組讀取輸入檔
    ; 2. 查表取得該字元的霍夫曼編碼
    ; 3. 將編碼寫入位元緩衝區
    ; 4. 當緩衝區滿 8 bits 時，寫入一個 byte
  
    ret
CompressData ENDP

;-----------------------------------------------
; WriteBit
; 功能：寫入一個位元到緩衝區
; 輸入：hFile - 輸出檔案
;       bit - 要寫入的位元（0 或 1）
;-----------------------------------------------
WriteBit PROC, hFile:DWORD, bit:BYTE
    ; TODO: 實作位元寫入
    ; 1. 將 bit 加入 bitBuffer
    ; 2. bitCount++
    ; 3. 如果 bitCount == 8，寫出 bitBuffer 並清空
    
 ret
WriteBit ENDP

;-----------------------------------------------
; FlushBitBuffer
; 功能：寫出緩衝區中剩餘的位元
; 輸入：hFile - 輸出檔案
;-----------------------------------------------
FlushBitBuffer PROC, hFile:DWORD
    ; TODO: 實作緩衝區清空
    ; 如果 bitCount > 0，用 0 補滿後寫出
    
 ret
FlushBitBuffer ENDP

END
