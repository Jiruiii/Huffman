; ===============================================
; 霍夫曼解壓縮模組 (人員四)
; Huffman Decompression Module
; ===============================================
INCLUDE Irvine32.inc

; 外部函式宣告（人員一提供）
OpenFileForRead PROTO, pszFilePath:PTR BYTE
OpenFileForWrite PROTO, pszFilePath:PTR BYTE
ReadFileByte PROTO, hFile:DWORD
WriteFileByte PROTO, hFile:DWORD, byteVal:BYTE
ReadFileBuffer PROTO, hFile:DWORD, pBuffer:PTR BYTE, nBytes:DWORD
WriteFileBuffer PROTO, hFile:DWORD, pBuffer:PTR BYTE, nBytes:DWORD
CloseFileHandle PROTO, hFile:DWORD

; 霍夫曼樹節點結構（必須與人員二、三一致）
HuffNode STRUCT
    freq    DWORD ?
  charBYTE  ?
    left    DWORD ?
    right   DWORD ?
HuffNode ENDS

; 本模組提供的函式
PUBLIC DecompressHuffmanFile

.const
INVALID_HANDLE_VALUE EQU -1

.data
; 位元緩衝區
bitBuffer BYTE 0
bitPosition BYTE 0

; 測試訊息
szDecompressMsg BYTE "Decompressing file...",0

.code

;-----------------------------------------------
; DecompressHuffmanFile
; 功能：解壓縮霍夫曼編碼檔案
; 輸入：pszInput - 壓縮檔路徑
;       pszOutput - 輸出檔路徑
; 輸出：EAX = 1（成功）或 0（失敗）
;-----------------------------------------------
DecompressHuffmanFile PROC USES ebx ecx edx esi edi, pszInput:PTR BYTE, pszOutput:PTR BYTE
LOCAL hFileIn:DWORD
    LOCAL hFileOut:DWORD
    LOCAL pTreeRoot:DWORD
    LOCAL originalSize:DWORD
    
    ; TODO: 步驟 1 - 開啟檔案
    ; INVOKE OpenFileForRead, pszInput
    ; mov hFileIn, eax
  ; INVOKE OpenFileForWrite, pszOutput
    ; mov hFileOut, eax
    
    ; TODO: 步驟 2 - 讀取並驗證檔頭
    ; call ReadAndVerifyHeader, hFileIn
    ; mov originalSize, eax
    
    ; TODO: 步驟 3 - 重建霍夫曼樹
    ; call DeserializeTree, hFileIn
    ; mov pTreeRoot, eax
    
    ; TODO: 步驟 4 - 解壓縮資料
 ; call DecompressData, hFileIn, hFileOut, pTreeRoot, originalSize
    
    ; TODO: 步驟 5 - 關閉檔案
    ; INVOKE CloseFileHandle, hFileIn
    ; INVOKE CloseFileHandle, hFileOut
    
    ; 暫時回傳失敗（待實作）
    xor eax, eax
    ret
DecompressHuffmanFile ENDP

;-----------------------------------------------
; ReadAndVerifyHeader
; 功能：讀取並驗證壓縮檔案的檔頭
; 輸入：hFile - 輸入檔案控制代碼
; 輸出：EAX = 原始檔案大小（成功）或 0（失敗）
;-----------------------------------------------
ReadAndVerifyHeader PROC, hFile:DWORD
    LOCAL magicNumber[4]:BYTE
    LOCAL fileSize:DWORD
    
    ; TODO: 實作檔頭讀取
  ; 1. 讀取魔術數字 "HUFF"
    ; 2. 驗證魔術數字是否正確
    ; 3. 讀取原始檔案大小
    ; 4. 讀取樹節點數量
    
    ; 重要：格式必須與人員三一致！
    
    xor eax, eax
    ret
ReadAndVerifyHeader ENDP

;-----------------------------------------------
; DeserializeTree
; 功能：從檔案重建霍夫曼樹
; 輸入：hFile - 輸入檔案
; 輸出：EAX = 樹根節點指標（成功）或 NULL（失敗）
;-----------------------------------------------
DeserializeTree PROC, hFile:DWORD
    ; TODO: 實作樹的反序列化
    ; 提示：
    ; - 讀到標記 '0' = 內部節點，遞迴讀取左右子樹
    ; - 讀到標記 '1' = 葉節點，讀取字元值
    
    ; 可以使用輔助函式 DeserializeTreeRecursive
    
    mov eax, NULL
    ret
DeserializeTree ENDP

;-----------------------------------------------
; DeserializeTreeRecursive
; 功能：遞迴重建霍夫曼樹
; 輸入：hFile - 輸入檔案
; 輸出：EAX = 當前節點指標
;-----------------------------------------------
DeserializeTreeRecursive PROC, hFile:DWORD
    LOCAL marker:BYTE
    LOCAL pNode:DWORD
    
  ; TODO: 實作遞迴反序列化
    ; 1. 讀取標記位元
    ; 2. 如果是內部節點（0），建立節點並遞迴讀取子樹
    ; 3. 如果是葉節點（1），讀取字元值並建立葉節點
    
    mov eax, NULL
    ret
DeserializeTreeRecursive ENDP

;-----------------------------------------------
; DecompressData
; 功能：使用霍夫曼樹解壓縮資料
; 輸入：hFileIn - 輸入檔案
;       hFileOut - 輸出檔案
;       pTreeRoot - 霍夫曼樹根節點
;       originalSize - 原始檔案大小
;-----------------------------------------------
DecompressData PROC, hFileIn:DWORD, hFileOut:DWORD, pTreeRoot:DWORD, originalSize:DWORD
    LOCAL pCurrentNode:DWORD
    LOCAL bytesWritten:DWORD
    LOCAL bit:BYTE
    
    ; TODO: 實作資料解壓縮
    ; 1. 從樹根開始
    ; 2. 逐位元讀取壓縮資料
    ; 3. bit = 0 往左走，bit = 1 往右走
    ; 4. 到達葉節點時，寫出字元並回到樹根
    ; 5. 重複直到寫出 originalSize 個位元組
    
    ret
DecompressData ENDP

;-----------------------------------------------
; ReadBit
; 功能：從檔案讀取一個位元
; 輸入：hFile - 輸入檔案
; 輸出：AL = 讀取的位元（0 或 1）
;    EAX = -1 表示檔案結束
;-----------------------------------------------
ReadBit PROC, hFile:DWORD
    ; TODO: 實作位元讀取
    ; 1. 如果 bitPosition == 0，讀取新的 byte 到 bitBuffer
    ; 2. 從 bitBuffer 提取當前位元
  ; 3. bitPosition++
    ; 4. 如果 bitPosition == 8，重設為 0
    
    mov eax, -1
    ret
ReadBit ENDP

;-----------------------------------------------
; AllocateNode
; 功能：配置一個霍夫曼樹節點
; 輸出：EAX = 新節點指標
;-----------------------------------------------
AllocateNode PROC
    ; TODO: 實作記憶體配置
    ; 提示：可使用 malloc 或自行管理記憶體池
    
    mov eax, NULL
    ret
AllocateNode ENDP

;-----------------------------------------------
; FreeTree
; 功能：釋放霍夫曼樹的記憶體
; 輸入：pTreeRoot - 樹根節點指標
;-----------------------------------------------
FreeTree PROC, pTreeRoot:DWORD
    ; TODO: 實作記憶體釋放
    ; 提示：需要遞迴釋放所有節點
    
    ret
FreeTree ENDP

END
