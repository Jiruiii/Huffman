# README additions: Header spec, flow, and team summary

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
