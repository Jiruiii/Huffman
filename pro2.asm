.386
.model flat, stdcall
option casemap :none

INCLUDE Irvine32.inc
; WinAPI constants
GENERIC_READ      EQU 80000000h
GENERIC_WRITE     EQU 40000000h
FILE_SHARE_READ   EQU 00000001h
OPEN_EXISTING     EQU 3
CREATE_ALWAYS     EQU 2
FILE_ATTRIBUTE_NORMAL EQU 80h
INVALID_HANDLE_VALUE EQU -1
FILE_BEGIN        EQU 0
FILE_CURRENT      EQU 1
FILE_END          EQU 2

includelib kernel32.lib

BuildHuffmanTree PROTO
BuildHuffmanTree_File PROTO, inputPathPtr:PTR BYTE

; Re-declare HuffNode structure to match pro.asm
HuffNode STRUCT
    freq  DWORD ?
    char  BYTE  ?
    _pad  BYTE  3 DUP(?)
    left  DWORD ?
    right DWORD ?
HuffNode ENDS

.data
; Code table: for each byte store bit pattern (LSB-first) and length
CodeBits DWORD 256 DUP(0)
CodeLen  BYTE  256 DUP(0)

; Bit output buffer
OutByte   BYTE 0
OutBitCnt DWORD 0

; File I/O
InFileHandle  DWORD 0
OutFileHandle DWORD 0
BytesWritten  DWORD 0
ReadCount     DWORD 0
WriteBuf      BYTE 1 DUP(0)
ReadBuf       BYTE 4096 DUP(?)
out_filename  BYTE 260 DUP(0)
TreeBytes     DWORD 0
OriginalSize  DWORD 0
HeaderZero    DWORD 0
MagicNumber   DWORD 48554648h  ; "HUFF" in little-endian (0x48 0x55 0x46 0x46)
TempBytesWritten DWORD 0
DebugErrorCode DWORD 0

; Simple message
msg_header   BYTE "--- Huffman Header (symbol:len) ---",0dh,0ah,0
msg_compress BYTE "--- Compressed bytes (raw) ---",0dh,0ah,0
msg_done     BYTE "--- Done ---",0dh,0ah,0

; Messages
msg_out_open_err BYTE "Failed to open/create output file",0dh,0ah,0
msg_in_open_err  BYTE "Failed to open input file",0dh,0ah,0
msg_colon BYTE ": ",0
msg_debug_path BYTE "Trying to open file: ",0
msg_debug_error BYTE "Error code: ",0

.code
; Exports
public BuildCodes
public Pro2_EncodeHuffman
public WriteFileByte
public Pro2_SerializeTreePreorder
public Pro2_CompressFile

; ------------------------------------------------------------
; Bit buffer routines (stdcall):
;   push bit ; call BitBufferWriteBit
; callee cleans stack
; ------------------------------------------------------------
BitBufferInit PROC
    mov byte ptr OutByte, 0
 mov dword ptr OutBitCnt, 0
  ret
BitBufferInit ENDP

; stdcall: [ebp+8] = bit (DWORD)
BitBufferWriteBit PROC
    push ebp
    mov ebp, esp
    push ebx
    push ecx
    push edx

    mov eax, dword ptr [ebp+8]    ; bit value
    mov ecx, dword ptr OutBitCnt  ; current bit index
    cmp eax, 0
    je no_set
    ; set bit in OutByte: OutByte |= (1 << OutBitCnt)
    mov edx, 1
    mov ebx, ecx
    mov cl, bl
  shl edx, cl
    movzx eax, byte ptr OutByte
    or al, dl
    mov byte ptr OutByte, al
no_set:
    ; increment OutBitCnt
    inc dword ptr OutBitCnt
    ; if OutBitCnt == 8 -> flush
    mov eax, dword ptr OutBitCnt
    cmp eax, 8
    jne bb_done

    ; flush byte: write to output file (WriteFileByte is stdcall and removes param)
    mov al, byte ptr OutByte
    push eax
    call WriteFileByte
    ; reset
    mov byte ptr OutByte, 0
    mov dword ptr OutBitCnt, 0

bb_done:
    pop edx
    pop ecx
 pop ebx
    mov esp, ebp
    pop ebp
    ret 4
BitBufferWriteBit ENDP

BitBufferFlush PROC
  push ebp
    mov ebp, esp
    push eax
    mov eax, dword ptr OutBitCnt
    cmp eax, 0
    je bf_ret
    mov al, byte ptr OutByte
    push eax
    call WriteFileByte
    mov byte ptr OutByte, 0
    mov dword ptr OutBitCnt, 0
bf_ret:
    pop eax
 mov esp, ebp
    pop ebp
    ret
BitBufferFlush ENDP

; ------------------------------------------------------------
; WriteFileByte(AL) - write one byte (in AL) to OutFileHandle using WriteFile
; stdcall: push byte (in eax), call WriteFileByte
; callee cleans stack
; ------------------------------------------------------------
WriteFileByte PROC
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    mov eax, dword ptr [ebp+8]
 mov bl, al
    ; prepare buffer
    lea esi, WriteBuf
    mov byte ptr [esi], bl
    ; call WriteFile: WriteFile(hFile, lpBuffer, nNumberOfBytesToWrite, lpNumberOfBytesWritten, lpOverlapped)
    INVOKE WriteFile, dword ptr OutFileHandle, ADDR WriteBuf, 1, ADDR BytesWritten, 0

    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 4
WriteFileByte ENDP

; ------------------------------------------------------------
; SerializeTreePreorder(nodePtr)
; Writes tree to output file in preorder. Format:
; - For leaf: write byte 1 followed by symbol byte
; - For internal: write byte 0
; ------------------------------------------------------------
Pro2_SerializeTreePreorder PROC
    push ebp
    mov ebp, esp
    push ebx
    push esi

    mov esi, dword ptr [ebp+8] ; nodePtr
    cmp esi, 0
    je stp_ret

    ; check leaf
mov eax, (HuffNode PTR [esi]).left
    mov edx, (HuffNode PTR [esi]).right
    cmp eax, 0
jne stp_internal
    cmp edx, 0
 jne stp_internal
    ; leaf: write 1 then symbol
    push 1
    call WriteFileByte
    ; write symbol
  mov al, (HuffNode PTR [esi]).char
    push eax
    call WriteFileByte
jmp stp_ret

stp_internal:
    push 0
    call WriteFileByte
 ; recurse left then right
    ; left
    mov eax, (HuffNode PTR [esi]).left
    cmp eax, 0
    je skip_left_rec
    push eax
    call Pro2_SerializeTreePreorder
skip_left_rec:
    ; right
    mov eax, (HuffNode PTR [esi]).right
    cmp eax, 0
    je skip_right_rec
    push eax
    call Pro2_SerializeTreePreorder
skip_right_rec:

stp_ret:
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
ret 4
Pro2_SerializeTreePreorder ENDP

; ------------------------------------------------------------
; Recursive BuildCodes: BuildCodesRec(nodePtr, curBits, curLen)
; params (stdcall): nodePtr (DWORD), curBits (DWORD), curLen (DWORD)
; stores CodeBits[char] and CodeLen[char]
; ------------------------------------------------------------
BuildCodesRec PROC
    push ebp
    mov ebp, esp
 push ebx
    push esi
    push edi

    mov esi, dword ptr [ebp+8]   ; nodePtr
  mov ebx, dword ptr [ebp+12]  ; curBits
    mov edi, dword ptr [ebp+16]  ; curLen

    cmp esi, 0
    je bcr_done

    ; load children
    mov eax, (HuffNode PTR [esi]).left
    mov edx, (HuffNode PTR [esi]).right

    cmp eax, 0
    jne bcr_notleaf
    cmp edx, 0
    jne bcr_notleaf
    ; leaf: store code
    mov al, (HuffNode PTR [esi]).char
    movzx ecx, al       ; ecx = symbol
; store bits (4 bytes)
    lea esi, CodeBits
    mov edx, ecx
    shl edx, 2
    add esi, edx
    mov [esi], ebx
; store len (byte)
  lea esi, CodeLen
    add esi, ecx
    mov eax, edi
    mov byte ptr [esi], al
    jmp bcr_done

bcr_notleaf:
    ; recurse left with curBits, curLen+1
    mov eax, (HuffNode PTR [esi]).left
    cmp eax, 0
    je bcr_skip_left
    mov ecx, edi
    inc ecx
    push ecx         ; curLen+1
    push ebx       ; curBits
    push eax       ; nodePtr
    call BuildCodesRec
    
bcr_skip_left:
    ; Call right
    mov eax, (HuffNode PTR [esi]).right
    cmp eax, 0
    je bcr_skip_right
    
    ; compute newBits = ebx | (1<<edi)
mov ecx, edi
    mov eax, 1
    cmp cl, 32  
    jge bcr_skip_right
    shl eax, cl
    mov edx, ebx
    or edx, eax
    mov ecx, edi
    inc ecx
    push ecx         ; curLen+1
    push edx   ; newBits
    mov eax, (HuffNode PTR [esi]).right
    push eax     ; nodePtr
  call BuildCodesRec
    
bcr_skip_right:

bcr_done:
    pop edi
    pop esi
  pop ebx
    mov esp, ebp
    pop ebp
    ret 12
BuildCodesRec ENDP

; ------------------------------------------------------------
; Wrapper BuildCodes(rootPtr)
; ------------------------------------------------------------
BuildCodes PROC
    push ebp
 mov ebp, esp
    push ebx
    push esi
    push edi

  mov esi, dword ptr [ebp+8] ; root pointer
    ; clear CodeBits
    mov ecx, 256
    lea edi, CodeBits
    xor eax, eax
ClearBitsLoop:
    mov [edi], eax
    add edi, 4
    loop ClearBitsLoop
    ; clear CodeLen
mov ecx, 256
 lea edi, CodeLen
    mov al, 0
ClearLensLoop:
    mov [edi], al
    inc edi
    loop ClearLensLoop

    ; call recursive with curBits=0, curLen=0 (stdcall: callee cleans args)
    push 0
  push 0
 push esi
    call BuildCodesRec

    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 4
BuildCodes ENDP

; ------------------------------------------------------------
; EncodeHuffman(rootPtr, inputPtr, outputPtr)
; rootPtr at [ebp+8], inputPtr at [ebp+12], outputPtr at [ebp+16]
; ------------------------------------------------------------
Pro2_EncodeHuffman PROC
    push ebp
    mov ebp, esp
    push ebx
    push esi
    push edi

    mov esi, dword ptr [ebp+8] ; rootPtr
    mov edi, dword ptr [ebp+12] ; inputPathPtr
    mov edx, OFFSET msg_debug_path
    call WriteString
    mov edx, edi
    call WriteString
 call Crlf

    ; Open input file using CreateFileA
    INVOKE CreateFileA, edi, GENERIC_READ, FILE_SHARE_READ, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0
 mov dword ptr InFileHandle, eax
    cmp eax, INVALID_HANDLE_VALUE
    jne open_success
    INVOKE GetLastError
    mov DebugErrorCode, eax

    mov edx, OFFSET msg_debug_error
    call WriteString
    mov eax, DebugErrorCode
    call WriteDec
    call Crlf

    jmp open_in_err

open_success:
    mov eax, dword ptr [ebp+16] ; outputPathPtr
    cmp eax, 0
    je auto_generate_name
    
    mov esi, eax
  lea edi, out_filename
CopyOutputLoop:
    mov al, [esi]
    mov [edi], al
    cmp al, 0
    je output_name_done
    inc esi
    inc edi
    jmp CopyOutputLoop
    
auto_generate_name:
    ; Create output filename by copying input path into out_filename and appending ".huff"
    mov esi, dword ptr [ebp+12] ; src inputPathPtr
 lea edi, out_filename
CopyNameLoop:
    mov al, [esi]
    mov [edi], al
cmp al, 0
  je CopyDone
    inc esi
    inc edi
    jmp CopyNameLoop
CopyDone:
    ; edi points at trailing NUL; append .huff
    mov byte ptr [edi], '.'
    inc edi
  mov byte ptr [edi], 'h'
  inc edi
    mov byte ptr [edi], 'u'
  inc edi
    mov byte ptr [edi], 'f'
    inc edi
    mov byte ptr [edi], 'f'
  inc edi
    mov byte ptr [edi], 0

output_name_done:
    ; init bit buffer and build codes
    mov esi, dword ptr [ebp+8] ; restore rootPtr
    
    mov edx, OFFSET msg_debug_path
    call WriteString
    mov eax, esi
  call WriteHex
    call Crlf
    
    call BitBufferInit
    push esi
    call BuildCodes

 ; Open output file with CreateFileA using inputPath + ".huff"
    INVOKE CreateFileA, ADDR out_filename, GENERIC_WRITE, 0, 0, CREATE_ALWAYS, FILE_ATTRIBUTE_NORMAL, 0
    mov dword ptr OutFileHandle, eax
    cmp eax, INVALID_HANDLE_VALUE
    je open_out_err

    ; --- Write header: Magic Number + placeholder for treeBytes, serialize tree, then backpatch treeBytes ---
    ; write 4-byte Magic Number "HUFF"
    INVOKE WriteFile, dword ptr OutFileHandle, ADDR MagicNumber, 4, ADDR BytesWritten, 0
    
    ; write 4-byte placeholder for treeBytes
    INVOKE WriteFile, dword ptr OutFileHandle, ADDR HeaderZero, 4, ADDR BytesWritten, 0

    ; serialize the Huffman tree directly to the output (preorder)
    push esi
    call Pro2_SerializeTreePreorder

    ; get current file pointer (end of serialized tree)
    INVOKE SetFilePointer, dword ptr OutFileHandle, 0, 0, FILE_CURRENT
    mov TreeBytes, eax
    ; subtract the 8-byte header (Magic + TreeBytes placeholder) at file start
    sub TreeBytes, 8

  ; compute original input file size by seeking to end of input file
    INVOKE SetFilePointer, dword ptr InFileHandle, 0, 0, FILE_END
    mov OriginalSize, eax
    ; rewind input file to beginning for subsequent reading
    INVOKE SetFilePointer, dword ptr InFileHandle, 0, 0, FILE_BEGIN

    ; write originalFileSize (DWORD) immediately after serialized tree
    INVOKE WriteFile, dword ptr OutFileHandle, ADDR OriginalSize, 4, ADDR BytesWritten, 0

    ; backpatch treeBytes at offset 4 (after Magic Number)
    INVOKE SetFilePointer, dword ptr OutFileHandle, 4, 0, FILE_BEGIN
    INVOKE WriteFile, dword ptr OutFileHandle, ADDR TreeBytes, 4, ADDR BytesWritten, 0

    ; move file pointer back to end to continue writing compressed data
    INVOKE SetFilePointer, dword ptr OutFileHandle, 0, 0, FILE_END

    INVOKE SetFilePointer, dword ptr InFileHandle, 0, 0, FILE_BEGIN

    ; write simple header to console for verification
    mov edx, OFFSET msg_header
    call WriteString
    ; iterate symbols and print symbol:len
  mov ecx, 256
 xor ebx, ebx ; index
PrintHeaderLoop:
    mov al, CodeLen[ebx]
cmp al, 0
  je nextSym
    mov eax, ebx
    call WriteDec
    mov edx, OFFSET msg_colon
    call WriteString
    movzx eax, byte ptr CodeLen[ebx]
    call WriteDec
    call Crlf
nextSym:
    inc ebx
    loop PrintHeaderLoop

  ; Now compress input file by reading chunks
  mov edx, OFFSET msg_compress
 call WriteString

    INVOKE SetFilePointer, dword ptr InFileHandle, 0, 0, FILE_CURRENT
    call WriteDec
    mov edx, OFFSET msg_colon
    call WriteString
    call Crlf

    mov eax, dword ptr InFileHandle
    cmp eax, INVALID_HANDLE_VALUE
    je open_in_err
    
ReadChunkLoop:
    ; ReadFile(InFileHandle, ReadBuf, 4096, &ReadCount, 0)
    INVOKE ReadFile, dword ptr InFileHandle, ADDR ReadBuf, 4096, ADDR ReadCount, 0
    
    mov eax, ReadCount
    call WriteDec
    mov edx, OFFSET msg_colon
call WriteString
    call Crlf
    
 ; check ReadCount
mov eax, ReadCount
    cmp eax, 0
  je flush
    ; process ReadCount bytes in ReadBuf
    mov ecx, eax
    xor ebx, ebx ; buffer index
ProcessByteLoop:
    mov al, ReadBuf[ebx]
    movzx edx, al; symbol in EDX
    movzx esi, byte ptr CodeLen[edx]
    cmp esi, 0
  je skipSym
    ; Code bits fetched inside loop (LSB-first), ESI = length
    push ecx
    xor ecx, ecx    ; bit index
WriteBitsLoop2:
 cmp ecx, esi
 jge nextByte
    push edx
    mov eax, dword ptr CodeBits[edx*4]
 push ecx
    mov cl, byte ptr [esp]
    shr eax, cl
    pop ecx
    and eax, 1
    push eax
    call BitBufferWriteBit
    pop edx
 inc ecx
    jmp WriteBitsLoop2
nextByte:
    pop ecx
skipSym:
    inc ebx
    dec ecx
    cmp ecx, 0
    jne ProcessByteLoop
    jmp ReadChunkLoop

open_in_err:
    mov edx, OFFSET msg_in_open_err
  call WriteString
    jmp cleanupAndReturn

open_out_err:
    mov edx, OFFSET msg_out_open_err
    call WriteString
    jmp cleanupAndReturn

cleanupAndReturn:
    ; attempt to close any open handles
    cmp dword ptr InFileHandle, 0
    je no_in
    INVOKE CloseHandle, InFileHandle
no_in:
    cmp dword ptr OutFileHandle, 0
  je no_out
 INVOKE CloseHandle, OutFileHandle
no_out:
    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
  ret 12 

flush:
call BitBufferFlush
    mov edx, OFFSET msg_done
    call WriteString
    ; Close handles
    INVOKE CloseHandle, InFileHandle
  INVOKE CloseHandle, OutFileHandle

    pop edi
    pop esi
    pop ebx
    mov esp, ebp
    pop ebp
    ret 12  
Pro2_EncodeHuffman ENDP


; ------------------------------------------------------------
; CompressFile(inputPathPtr, outputPathPtr)
; Calls BuildHuffmanTree (from HuffmanDataAnalyst), then EncodeHuffman
; If outputPathPtr is NULL, auto-generates output filename
; stdcall: caller pushes inputPathPtr and outputPathPtr; callee cleans stack
; ------------------------------------------------------------
Pro2_CompressFile PROC, inputPathPtr:PTR BYTE, outputPathPtr:PTR BYTE
push ebx
    push esi
  push edi

    mov edi, inputPathPtr
  mov esi, outputPathPtr

    ; Build Huffman tree from input file (use file-based wrapper)
 INVOKE BuildHuffmanTree_File, edi ; returns rootPtr in EAX
    mov ebx, eax          ; rootPtr

    ; Call EncodeHuffman(rootPtr, inputPathPtr, outputPathPtr)
  push esi ; outputPathPtr (third arg) - can be NULL
    push edi ; inputPathPtr (second arg)
    push ebx ; rootPtr (first arg)
    call Pro2_EncodeHuffman ; stdcall, will clean 12 bytes

    ; cleanup and return
    pop edi
    pop esi
    pop ebx
    ret
Pro2_CompressFile ENDP

end
