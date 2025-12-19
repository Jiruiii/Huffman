; Huffman Decoder (Member 4)
; (Instrumented with code table rebuild for debugging)

.386
.model flat, stdcall
option casemap :none
INCLUDE Irvine32.inc

; File operations
OpenFileForRead PROTO, pszFilePath:PTR BYTE
OpenFileForWrite PROTO, pszFilePath:PTR BYTE
; ReadFileByte corresponds to ReadDecodedByte defined in pro2.asm
ReadDecodedByte PROTO, hFile:DWORD
; WriteFileByte corresponds to WriteDecodedByte defined in pro2.asm
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
    
    mov TreeBufIndex, 0
    mov NextNodePtrDec, OFFSET NodeBufferDec
    call RebuildNodeFromBuffer
    cmp eax, 0
    je file_error
    mov rootNode, eax
    mov esi, rootNode
    mov OutWrittenCount, 0
    mov bitCount, 0

; LSB-first decode (start from bit 0)
decode_loop_start:
    mov eax, OutWrittenCount
    cmp eax, OriginalSize
    jge decode_end
    
    mov eax, bitCount
    cmp eax, 0
    jne have_bits
    
    ; Read next byte using ReadDecodedByte
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
    ; Write the byte using WriteDecodedByte
    INVOKE WriteDecodedByte, hOut, al
    mov esi, rootNode
    mov eax, OutWrittenCount
    inc eax
    mov OutWrittenCount, eax
    jmp decode_loop_start
not_leaf:
    jmp decode_loop_start
decode_end:
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
; Decoder read function (returns 0 on failure)
; --------------------------------------------------------------------
ReadDecodedByte PROC USES ecx edx, hFile:DWORD
    LOCAL tempRead:DWORD
    LOCAL buf:BYTE

    ; 1. Use Windows API to read 1 byte
    lea edx, buf
    lea ecx, tempRead
    INVOKE ReadFile, hFile, edx, 1, ecx, 0

    ; 2. Check if successful
    cmp eax, 0          ; ReadFile returns 0 on error
    je read_fail
    cmp tempRead, 0     ; Read 0 bytes means EOF
    je read_fail

    ; 3. If successful, put byte in AL, return in EAX
    movzx eax, buf
    ret

read_fail:
    mov eax, -1         ; Return -1 to indicate EOF or error
    ret
ReadDecodedByte ENDP

; --------------------------------------------------------------------
; Decoder write function (returns success)
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