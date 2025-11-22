; Huffman Decoder (Member 4)
; Main tasks: Read .huff file, reconstruct Huffman tree, and restore original data
; Interface: DecompressHuffmanFile PROTO, pszInputFile:PTR BYTE, pszOutputFile:PTR BYTE

INCLUDE Irvine32.inc

.data
; Buffer for serialized tree (max 16KB to be safe)
TreeBuf BYTE 16384 DUP(?)
TreeBufIndex DWORD 0
TreeBytes DWORD 0
OriginalSize DWORD 0

; Node allocation buffer for decoder
NODE_BUFFER_SIZE_DEC = 512 * 16
NodeBufferDec BYTE NODE_BUFFER_SIZE_DEC DUP(?)
NextNodePtrDec DWORD OFFSET NodeBufferDec
OutWrittenCount DWORD 0
.code

; Huffman tree node structure
HuffNode STRUCT
    freq  DWORD ?
    char  BYTE  ?
    left  DWORD ?
    right DWORD ?
HuffNode ENDS

; Main decompression procedure

DecompressHuffmanFile PROC USES esi edi ebx,
    pszInputFile:PTR BYTE,
    pszOutputFile:PTR BYTE
    LOCAL hIn:DWORD
    LOCAL hOut:DWORD
    LOCAL rootNode:DWORD
    LOCAL bitBuffer:BYTE
    LOCAL bitCount:DWORD
    ; 1. Open input and output files
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

    ; 2. Read header and reconstruct Huffman tree (must match encoder format)
    ; Read treeBytes (DWORD, little-endian)
    xor eax, eax
    INVOKE ReadFileByte, hIn
    cmp eax, -1
    je .file_error
    movzx ebx, al
    or eax, ebx

    INVOKE ReadFileByte, hIn
    cmp eax, -1
    je .file_error
    movzx ebx, al
    shl ebx, 8
    or eax, ebx

    INVOKE ReadFileByte, hIn
    cmp eax, -1
    je .file_error
    movzx ebx, al
    shl ebx, 16
    or eax, ebx

    INVOKE ReadFileByte, hIn
    cmp eax, -1
    je .file_error
    movzx ebx, al
    shl ebx, 24
    or eax, ebx

    mov TreeBytes, eax

    ; sanity check TreeBytes
    mov ecx, TreeBytes
    cmp ecx, 16384
    jbe .tree_ok
    jmp .file_error
.tree_ok:

    ; Read serialized tree bytes into TreeBuf
    mov ecx, TreeBytes
    xor edi, edi
.read_tree_bytes_loop:
    cmp ecx, 0
    je .tree_bytes_done
    INVOKE ReadFileByte, hIn
    cmp eax, -1
    je .file_error
    mov TreeBuf[edi], al
    inc edi
    dec ecx
    jmp .read_tree_bytes_loop
.tree_bytes_done:

    ; Read originalFileSize (DWORD little-endian)
    xor eax, eax
    INVOKE ReadFileByte, hIn
    cmp eax, -1
    je .file_error
    movzx ebx, al
    or eax, ebx

    INVOKE ReadFileByte, hIn
    cmp eax, -1
    je .file_error
    movzx ebx, al
    shl ebx, 8
    or eax, ebx

    INVOKE ReadFileByte, hIn
    cmp eax, -1
    je .file_error
    movzx ebx, al
    shl ebx, 16
    or eax, ebx

    INVOKE ReadFileByte, hIn
    cmp eax, -1
    je .file_error
    movzx ebx, al
    shl ebx, 24
    or eax, ebx

    mov OriginalSize, eax

    ; Prepare to rebuild tree from TreeBuf
    mov TreeBufIndex, 0
    mov NextNodePtrDec, OFFSET NodeBufferDec
    ; call recursive builder
    call RebuildNodeFromBuffer
    mov rootNode, eax
    mov esi, rootNode
    mov OutWrittenCount, 0

    ; 3. Bit-level decoding main loop
    mov bitCount, 0

.decode_loop_start:
    ; stop when we've written OriginalSize bytes
    mov eax, OutWrittenCount
    cmp eax, OriginalSize
    jge .decode_end

    ; If bitCount == 0, read a new byte
    mov eax, bitCount
    cmp eax, 0
    jne .have_bits
    INVOKE ReadFileByte, hIn
    cmp eax, -1
    je .decode_end
    mov bitBuffer, al
    mov bitCount, 8
.have_bits:
    ; Extract MSB from bitBuffer -> bl = 0/1, consume MSB
    mov al, bitBuffer
    mov bl, al
    and bl, 80h
    shr bl, 7
    shl al, 1
    mov bitBuffer, al
    dec bitCount

    ; Traverse Huffman tree according to bit (bl)
    cmp esi, 0
    jne .has_node
    mov esi, rootNode
.has_node:
    mov edx, DWORD PTR [esi + HuffNode.left]
    mov ecx, DWORD PTR [esi + HuffNode.right]
    cmp bl, 0
    je .take_left
    mov esi, ecx
    jmp .after_move
.take_left:
    mov esi, edx
.after_move:
    cmp esi, 0
    je .decode_end

    ; Check if current node is a leaf: left==0 and right==0
    mov eax, DWORD PTR [esi + HuffNode.left]
    or eax, DWORD PTR [esi + HuffNode.right]
    jnz .not_leaf

    ; Leaf: output char
    mov al, BYTE PTR [esi + HuffNode.char]
    INVOKE WriteFileByte, hOut, al
    mov esi, rootNode
    mov eax, OutWrittenCount
    inc eax
    mov OutWrittenCount, eax
    jmp .decode_loop_start

.not_leaf:
    jmp .decode_loop_start

.decode_end:
    INVOKE CloseFileHandle, hIn
    INVOKE CloseFileHandle, hOut
    mov eax, 1
    ret

.file_error:
    INVOKE CloseFileHandle, hIn
    INVOKE CloseFileHandle, hOut
    mov eax, 0
    ret

DecompressHuffmanFile ENDP

; --------------------------------------------------------------------
; AllocNode - allocate space for a HuffNode from NodeBufferDec
; Returns: EAX = pointer to node
; --------------------------------------------------------------------
AllocNode PROC
    push ebp
    mov ebp, esp
    push ebx

    mov eax, NextNodePtrDec
    add NextNodePtrDec, SIZEOF HuffNode
    mov ebx, eax

    ; initialize
    mov DWORD PTR [ebx + HuffNode.freq], 0
    mov BYTE PTR [ebx + HuffNode.char], 0
    mov DWORD PTR [ebx + HuffNode.left], 0
    mov DWORD PTR [ebx + HuffNode.right], 0

    mov eax, ebx
    pop ebx
    mov esp, ebp
    pop ebp
    ret
AllocNode ENDP


; --------------------------------------------------------------------
; RebuildNodeFromBuffer - recursively rebuild Huffman tree from TreeBuf
; Returns: EAX = pointer to rebuilt node
; --------------------------------------------------------------------
RebuildNodeFromBuffer PROC
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    ; load current marker
    mov ebx, TreeBufIndex
    mov al, TreeBuf[ebx]
    ; increment index
    add dword ptr TreeBufIndex, 1
    cmp al, 1
    je .leaf

    ; internal node (marker != 1)
    call AllocNode
    mov edx, eax ; edx = this node
    ; build left
    call RebuildNodeFromBuffer
    mov DWORD PTR [edx + HuffNode.left], eax
    ; build right
    call RebuildNodeFromBuffer
    mov DWORD PTR [edx + HuffNode.right], eax
    mov eax, edx
    jmp .done

.leaf:
    ; read character byte
    mov ebx, TreeBufIndex
    mov al, TreeBuf[ebx]
    add dword ptr TreeBufIndex, 1
    call AllocNode
    mov BYTE PTR [eax + HuffNode.char], al
    mov DWORD PTR [eax + HuffNode.left], 0
    mov DWORD PTR [eax + HuffNode.right], 0

.done:
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret
RebuildNodeFromBuffer ENDP

END
