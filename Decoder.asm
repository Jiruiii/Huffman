; Huffman Decoder (Member 4)
; (Instrumented with code table rebuild for debugging)

.386
.model flat, stdcall
option casemap :none
INCLUDE Irvine32.inc

; 宣告函式原型
OpenFileForRead PROTO, pszFilePath:PTR BYTE
OpenFileForWrite PROTO, pszFilePath:PTR BYTE
; ReadFileByte 改名為 ReadDecodedByte 以避免與 pro2.asm 衝突
ReadDecodedByte PROTO, hFile:DWORD
; WriteFileByte 改名為 WriteDecodedByte 以避免與 pro2.asm 衝突
WriteDecodedByte PROTO, hFile:DWORD, byteVal:BYTE
CloseFileHandle PROTO, hFile:DWORD

PUBLIC DecompressHuffmanFile

INVALID_HANDLE_VALUE EQU -1

.data
TreeBuf BYTE 16384 DUP(?)
TreeBufIndex DWORD 0
TreeBytes DWORD 0
OriginalSize DWORD 0
MagicNumberExpected DWORD 48554648h  ; "HUFF" in little-endian
MagicNumberRead DWORD 0
NODE_BUFFER_SIZE_DEC = 1024 * 16
NodeBufferDec BYTE NODE_BUFFER_SIZE_DEC DUP(?)
NextNodePtrDec DWORD OFFSET NodeBufferDec
NodeBufferEndDec DWORD OFFSET NodeBufferDec + NODE_BUFFER_SIZE_DEC
OutWrittenCount DWORD 0

; Code tables (debug)
DecCodeBits DWORD 256 DUP(0)
DecCodeLen  BYTE 256 DUP(0)

msg_dec_start BYTE "=== Decompression Start ===",0dh,0ah,0
msg_tree_bytes BYTE "TreeBytes: ",0
msg_original_size BYTE "OriginalSize: ",0
msg_rebuild_start BYTE "Rebuilding tree...",0dh,0ah,0
msg_rebuild_done BYTE "Tree rebuilt successfully",0dh,0ah,0
msg_decode_start BYTE "Starting decode loop...",0dh,0ah,0
msg_bytes_written BYTE "Bytes written: ",0
msg_codes_header BYTE "--- Rebuilt Code Lengths (sym:len) ---",0dh,0ah,0
msg_magic_error BYTE "Invalid file format! Not a HUFF compressed file.",0dh,0ah,0
.code

HuffNode STRUCT
    freq  DWORD ?
    char  BYTE  ?
    _pad  BYTE  3 DUP(?)
    left  DWORD ?
    right DWORD ?
HuffNode ENDS

; Allocator
AllocNodeDec PROC
    push ebp
    mov ebp, esp
    push ebx
    mov eax, NextNodePtrDec
    mov ebx, eax
    add ebx, SIZEOF HuffNode
    cmp ebx, NodeBufferEndDec
    ja alloc_overflow
    mov NextNodePtrDec, ebx
    mov ebx, eax
    mov DWORD PTR [ebx + HuffNode.freq], 0
    mov BYTE PTR [ebx + HuffNode.char], 0
    mov DWORD PTR [ebx + HuffNode.left], 0
    mov DWORD PTR [ebx + HuffNode.right], 0
    mov eax, ebx
    pop ebx
    mov esp, ebp
    pop ebp
    ret
alloc_overflow:
    xor eax, eax
    pop ebx
    mov esp, ebp
    pop ebp
    ret
AllocNodeDec ENDP

; Tree rebuild
RebuildNodeFromBuffer PROC
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    ; load current marker index
    mov ebx, TreeBufIndex
    cmp ebx, TreeBytes
    jge rebuild_error
    mov al, TreeBuf[ebx]
    add dword ptr TreeBufIndex, 1
    cmp al, 1
    je leaf_node
    ; internal node: allocate and keep parent in EBX (preserved)
    call AllocNodeDec
    cmp eax, 0
    je rebuild_error
    mov ebx, eax            ; EBX = parent node (stable across recursion)
    ; build left child
    call RebuildNodeFromBuffer
    cmp eax, 0
    je rebuild_error
    mov [ebx + HuffNode.left], eax
    ; build right child
    call RebuildNodeFromBuffer
    cmp eax, 0
    je rebuild_error
    mov [ebx + HuffNode.right], eax
    mov eax, ebx            ; return parent
    jmp done_rebuild
leaf_node:
    mov ebx, TreeBufIndex
    cmp ebx, TreeBytes
    jge rebuild_error
    movzx ecx, BYTE PTR TreeBuf[ebx]
    add dword ptr TreeBufIndex, 1
    call AllocNodeDec
    cmp eax, 0
    je rebuild_error
    mov BYTE PTR [eax + HuffNode.char], cl
    mov DWORD PTR [eax + HuffNode.left], 0
    mov DWORD PTR [eax + HuffNode.right], 0
    jmp done_rebuild
rebuild_error:
    xor eax, eax
done_rebuild:
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret
RebuildNodeFromBuffer ENDP

; BuildCodesRec (debug)
BuildCodesRecDec PROC
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    mov esi, [ebp+8]    ; nodePtr
    mov ebx, [ebp+12]   ; curBits
    mov edi, [ebp+16]   ; curLen
    cmp esi, 0
    je bcr_done
    mov eax, (HuffNode PTR [esi]).left
    mov edx, (HuffNode PTR [esi]).right
    cmp eax, 0
    jne bcr_notleaf
    cmp edx, 0
    jne bcr_notleaf
    mov al, (HuffNode PTR [esi]).char
    movzx ecx, al
    lea esi, DecCodeBits
    mov edx, ecx
    shl edx, 2
    add esi, edx
    mov [esi], ebx
    lea esi, DecCodeLen
    add esi, ecx
    mov eax, edi
    mov [esi], al
    jmp bcr_done
bcr_notleaf:
    ; left
    mov eax, (HuffNode PTR [esi]).left
    cmp eax, 0
    je skip_left
    mov ecx, edi
    inc ecx
    push ecx
    push ebx
    push eax
    call BuildCodesRecDec
skip_left:
    ; right
    mov eax, (HuffNode PTR [esi]).right
    cmp eax, 0
    je skip_right
    mov ecx, edi
    mov eax, 1
    cmp cl, 32
    jge skip_right
    shl eax, cl
    mov edx, ebx
    or edx, eax
    mov ecx, edi
    inc ecx
    push ecx
    push edx
    mov eax, (HuffNode PTR [esi]).right
    push eax
    call BuildCodesRecDec
skip_right:
    ; fallthrough
bcr_done:
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 12
BuildCodesRecDec ENDP

BuildCodesDec PROC
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi
    mov esi, [ebp+8] ; root
    ; clear tables
    mov ecx, 256
    lea edi, DecCodeBits
    xor eax, eax
clr_bits:
    mov [edi], eax
    add edi, 4
    loop clr_bits
    mov ecx, 256
    lea edi, DecCodeLen
    mov al, 0
clr_len:
    mov [edi], al
    inc edi
    loop clr_len
    push 0
    push 0
    push esi
    call BuildCodesRecDec
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 4
BuildCodesDec ENDP

DecompressHuffmanFile PROC USES esi edi ebx,
    pszInputFile:PTR BYTE,
    pszOutputFile:PTR BYTE
    LOCAL hIn:DWORD
    LOCAL hOut:DWORD
    LOCAL rootNode:DWORD
    LOCAL bitBuffer:BYTE
    LOCAL bitCount:DWORD
    INVOKE OpenFileForRead, pszInputFile
    mov hIn, eax
    .IF eax == INVALID_HANDLE_VALUE
        mov eax, 0
        ret
    .ENDIF
    INVOKE OpenFileForWrite, pszOutputFile
    mov hOut, eax
    .IF eax == INVALID_HANDLE_VALUE
        INVOKE CloseFileHandle, hIn
        mov eax, 0
        ret
    .ENDIF
    
    ; Read and validate Magic Number (4 bytes)
    INVOKE ReadDecodedByte, hIn
    cmp eax, -1
    je file_error
    movzx ebx, al
    INVOKE ReadDecodedByte, hIn
    cmp eax, -1
    je file_error
    movzx eax, al
    shl eax, 8
    or ebx, eax
    INVOKE ReadDecodedByte, hIn
    cmp eax, -1
    je file_error
    movzx eax, al
    shl eax, 16
    or ebx, eax
    INVOKE ReadDecodedByte, hIn
    cmp eax, -1
    je file_error
    movzx eax, al
    shl eax, 24
    or ebx, eax
    mov MagicNumberRead, ebx
    
    ; Validate Magic Number
    mov eax, MagicNumberRead
    cmp eax, MagicNumberExpected
    jne magic_error
    
    ; Read treeBytes (4 bytes)
    INVOKE ReadDecodedByte, hIn
    cmp eax, -1
    je file_error
    movzx ebx, al
    INVOKE ReadDecodedByte, hIn
    cmp eax, -1
    je file_error
    movzx eax, al
    shl eax, 8
    or ebx, eax
    INVOKE ReadDecodedByte, hIn
    cmp eax, -1
    je file_error
    movzx eax, al
    shl eax, 16
    or ebx, eax
    INVOKE ReadDecodedByte, hIn
    cmp eax, -1
    je file_error
    movzx eax, al
    shl eax, 24
    or ebx, eax
    mov TreeBytes, ebx
    mov ecx, TreeBytes
    cmp ecx, 16384
    jbe tree_ok
    jmp file_error
tree_ok:
    mov ecx, TreeBytes
    xor edi, edi
rt_loop:
    cmp ecx, 0
    je rt_done
    INVOKE ReadDecodedByte, hIn
    cmp eax, -1
    je file_error
    mov TreeBuf[edi], al
    inc edi
    dec ecx
    jmp rt_loop
rt_done:
    ; read original size
    INVOKE ReadDecodedByte, hIn
    cmp eax, -1
    je file_error
    movzx ebx, al
    INVOKE ReadDecodedByte, hIn
    cmp eax, -1
    je file_error
    movzx eax, al
    shl eax, 8
    or ebx, eax
    INVOKE ReadDecodedByte, hIn
    cmp eax, -1
    je file_error
    movzx eax, al
    shl eax, 16
    or ebx, eax
    INVOKE ReadDecodedByte, hIn
    cmp eax, -1
    je file_error
    movzx eax, al
    shl eax, 24
    or ebx, eax
    mov OriginalSize, ebx
    
    ; messages
    mov edx, OFFSET msg_dec_start
    call WriteString
    mov edx, OFFSET msg_tree_bytes
    call WriteString
    mov eax, TreeBytes
    call WriteDec
    call Crlf
    mov edx, OFFSET msg_original_size
    call WriteString
    mov eax, OriginalSize
    call WriteDec
    call Crlf
    mov edx, OFFSET msg_rebuild_start
    call WriteString
    mov TreeBufIndex, 0
    mov NextNodePtrDec, OFFSET NodeBufferDec
    call RebuildNodeFromBuffer
    cmp eax, 0
    je file_error
    mov edx, OFFSET msg_rebuild_done
    call WriteString
    mov rootNode, eax
    ; build codes for debug
    push rootNode
    call BuildCodesDec
    mov edx, OFFSET msg_codes_header
    call WriteString
    mov ecx, 256
    xor ebx, ebx
print_codes_loop:
    mov al, DecCodeLen[ebx]
    cmp al, 0
    je pc_next
    mov eax, ebx
    call WriteDec
    mov al, ':'
    call WriteChar
    movzx eax, DecCodeLen[ebx]
    call WriteDec
    call Crlf
pc_next:
    inc ebx
    loop print_codes_loop
    mov esi, rootNode
    mov OutWrittenCount, 0
    mov edx, OFFSET msg_decode_start
    call WriteString
    mov eax, rootNode
    call WriteHex
    call Crlf
    mov bitCount, 0

; LSB-first decode (start from bit 0)
decode_loop_start:
    mov eax, OutWrittenCount
    cmp eax, OriginalSize
    jge decode_end
    
    mov eax, bitCount
    cmp eax, 0
    jne have_bits
    
    ; 讀取壓縮資料改用 ReadDecodedByte
    INVOKE ReadDecodedByte, hIn
    cmp eax, -1
    je decode_end
    mov bitBuffer, al
    mov bitCount, 8
    
have_bits:  
    mov al, bitBuffer
    mov bl, al
    and bl, 1          ; bl = LSB (bit 0)
    shr al, 1          ; shift right to consume LSB
    mov bitBuffer, al
    dec bitCount
    
    cmp esi, 0
    jne has_node
    mov esi, rootNode
has_node:
    mov edx, [esi + HuffNode.left]
    mov ecx, [esi + HuffNode.right]
    cmp bl, 0
    je take_left
    mov esi, ecx
    jmp after_move
take_left:
    mov esi, edx
after_move:
    cmp esi, 0
    je decode_end
    mov eax, [esi + HuffNode.left]
    or eax, [esi + HuffNode.right]
    jnz not_leaf
    mov al, BYTE PTR [esi + HuffNode.char]
    ; 寫入改用 WriteDecodedByte
    INVOKE WriteDecodedByte, hOut, al
    mov esi, rootNode
    mov eax, OutWrittenCount
    inc eax
    mov OutWrittenCount, eax
    jmp decode_loop_start
not_leaf:
    jmp decode_loop_start
decode_end:
    mov edx, OFFSET msg_bytes_written
    call WriteString
    mov eax, OutWrittenCount
    call WriteDec
    call Crlf
    INVOKE CloseFileHandle, hIn
    INVOKE CloseFileHandle, hOut
    mov eax, 1
    ret
    
magic_error:
    mov edx, OFFSET msg_magic_error
    call WriteString
    INVOKE CloseFileHandle, hIn
    INVOKE CloseFileHandle, hOut
    mov eax, 0
    ret
    
file_error:
    INVOKE CloseFileHandle, hIn
    INVOKE CloseFileHandle, hOut
    mov eax, 0
    ret
DecompressHuffmanFile ENDP

; --------------------------------------------------------------------
; 專屬於 Decoder 的讀取函式 (修復讀取到 0 變空格的問題)
; --------------------------------------------------------------------
ReadDecodedByte PROC USES ecx edx, hFile:DWORD
    LOCAL tempRead:DWORD
    LOCAL buf:BYTE

    ; 1. 呼叫 Windows API 讀取 1 byte
    lea edx, buf
    lea ecx, tempRead
    INVOKE ReadFile, hFile, edx, 1, ecx, 0

    ; 2. 檢查是否成功
    cmp eax, 0          ; ReadFile 回傳 0 表示失敗
    je read_fail
    cmp tempRead, 0     ; 讀取位元組數為 0 表示 EOF
    je read_fail

    ; 3. 成功讀取，將 byte 放入 AL，並清空 EAX 高位
    movzx eax, buf      
    ret

read_fail:
    mov eax, -1         ; 回傳 -1 表示 EOF 或錯誤
    ret
ReadDecodedByte ENDP

; --------------------------------------------------------------------
; 專屬於 Decoder 的寫入函式 (修復寫入失敗的問題)
; --------------------------------------------------------------------
WriteDecodedByte PROC USES eax edx ecx, hFile:DWORD, byteVal:BYTE
    LOCAL tempWritten:DWORD
    LOCAL buf:BYTE

    mov al, byteVal
    mov buf, al

    lea edx, buf
    lea ecx, tempWritten
    INVOKE WriteFile, hFile, edx, 1, ecx, 0

    ret
WriteDecodedByte ENDP

END