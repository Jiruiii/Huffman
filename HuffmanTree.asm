; ===============================================
; 霍夫曼樹建立模組 (人員二)
; Huffman Tree Builder Module
; ===============================================
INCLUDE Irvine32.inc

; 外部函式宣告（人員一提供）
OpenFileForRead PROTO, pszFilePath:PTR BYTE
ReadFileByte PROTO, hFile:DWORD
CloseFileHandle PROTO, hFile:DWORD
GetFileSizeEx PROTO, hFile:DWORD

; 本模組提供的函式
PUBLIC BuildHuffmanTree

; 常數定義
.const
MAX_CHARS EQU 256       ; ASCII 字元數量
INVALID_HANDLE_VALUE EQU -1

; 霍夫曼樹節點結構
HuffNode STRUCT
    freq    DWORD ?     ; 字元出現頻率
    char    BYTE  ?     ; 字元值（葉節點使用）
    left    DWORD ?     ; 左子節點指標
    right   DWORD ?     ; 右子節點指標
HuffNode ENDS

.data
; 字元頻率統計陣列
charFrequency DWORD MAX_CHARS DUP(0)

; 測試訊息
szDebugMsg BYTE "Building Huffman Tree...",0

.code

;-----------------------------------------------
; BuildHuffmanTree
; 功能：讀取檔案，統計字元頻率，建立霍夫曼樹
; 輸入：pszFilePath - 檔案路徑指標
; 輸出：EAX = 樹根節點指標（成功）或 NULL（失敗）
;-----------------------------------------------
BuildHuffmanTree PROC USES ebx ecx edx esi edi, pszFilePath:PTR BYTE
    LOCAL hFile:DWORD
    LOCAL byteVal:DWORD
    LOCAL pTreeRoot:DWORD
    
    ; TODO: 步驟 1 - 開啟檔案
    ; INVOKE OpenFileForRead, pszFilePath
    ; .IF eax == INVALID_HANDLE_VALUE
    ;     mov eax, NULL
    ;     ret
    ; .ENDIF
    ; mov hFile, eax
    
    ; TODO: 步驟 2 - 統計字元頻率
    ; call CountCharFrequencies, hFile
    
    ; TODO: 步驟 3 - 建立優先佇列
    ; call BuildPriorityQueue
    
    ; TODO: 步驟 4 - 建立霍夫曼樹
    ; call BuildTreeFromQueue
    ; mov pTreeRoot, eax
    
    ; TODO: 步驟 5 - 關閉檔案
    ; INVOKE CloseFileHandle, hFile
    
    ; 暫時回傳 NULL（待實作）
    mov eax, NULL
    ret
BuildHuffmanTree ENDP

;-----------------------------------------------
; CountCharFrequencies
; 功能：統計檔案中每個字元的出現次數
; 輸入：hFile - 檔案控制代碼
; 輸出：更新 charFrequency 陣列
;-----------------------------------------------
CountCharFrequencies PROC USES ebx ecx edx esi, hFile:DWORD
    ; TODO: 實作字元頻率統計
    ; 1. 清空 charFrequency 陣列
    ; 2. 逐位元組讀取檔案
    ; 3. 累加對應字元的頻率
    
    ret
CountCharFrequencies ENDP

;-----------------------------------------------
; BuildPriorityQueue
; 功能：根據字元頻率建立優先佇列
; 輸出：優先佇列的頭指標
;-----------------------------------------------
BuildPriorityQueue PROC
    ; TODO: 實作優先佇列
    ; 1. 為每個出現的字元建立葉節點
    ; 2. 按頻率排序（最小堆積）
    
    ret
BuildPriorityQueue ENDP

;-----------------------------------------------
; BuildTreeFromQueue
; 功能：從優先佇列建立霍夫曼樹
; 輸出：EAX = 樹根節點指標
;-----------------------------------------------
BuildTreeFromQueue PROC
    ; TODO: 實作霍夫曼樹建立演算法
 ; 1. 取出兩個頻率最小的節點
    ; 2. 建立新的父節點，頻率為兩節點之和
    ; 3. 將父節點放回佇列
    ; 4. 重複直到只剩一個節點（樹根）
    
    mov eax, NULL
 ret
BuildTreeFromQueue ENDP

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
; InsertQueue
; 功能：將節點插入優先佇列（保持排序）
; 輸入：pNode - 要插入的節點指標
;-----------------------------------------------
InsertQueue PROC, pNode:DWORD
    ; TODO: 實作插入排序
    
    ret
InsertQueue ENDP

;-----------------------------------------------
; ExtractMin
; 功能：從優先佇列中取出最小頻率節點
; 輸出：EAX = 節點指標
;-----------------------------------------------
ExtractMin PROC
    ; TODO: 實作取出最小值
    
  mov eax, NULL
    ret
ExtractMin ENDP

END
