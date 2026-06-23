# NCKU 1142 編譯系統（Compiler Construction）作業集合

本儲存庫包含國立成功大學 114 年度 1142 編譯系統課程的所有作業實作。

## 項目結構

```
Compiler/
├── NCKU_Compiler_HW1/     # 作業一：詞法分析器（Lexical Analyzer）
├── NCKU_Compiler_HW2/     # 作業二：語法分析與編譯器（Parser & LLVM Compiler）
├── backup/                # 備份檔案
└── README.md              # 本檔案
```

## 各作業說明

### 作業一 - 詞法分析器（HW1）

**目標**：實作文言文（Wenyan）編程語言的詞法分析器

- **主要文件**：`src/compiler.l`（Flex 詞法規則）
- **輸入**：文言文源代碼（`.wy` 文件）
- **輸出**：Token 序列
- **技術**：Flex（詞法分析生成器）

**詳見**：[NCKU_Compiler_HW1/README.md](NCKU_Compiler_HW1/README.md)

### 作業二 - 編譯器（HW2）

**目標**：在 HW1 基礎上實作完整的編譯器，包括語法分析、語義分析和 LLVM IR 代碼生成

- **主要文件**：

  - `src/compiler.y`：Yacc 語法規則
  - `src/scope.c`：符號表管理
  - `src/object.c` 和 `value_data.c`：物件系統
  - `src/control/`：控制流結構（if、for、while、function）
- **輸出**：LLVM IR 代碼，進而編譯為執行檔
- **技術**：Yacc/Bison（語法分析生成器）、LLVM（中間語言生成）

**詳見**：[NCKU_Compiler_HW2/README.md](NCKU_Compiler_HW2/README.md)

## 快速開始

### 環境需求

- **CMake** ≥ 3.10
- **Flex** ≥ 2.6（詞法分析生成器）
- **Bison** ≥ 3.6（語法分析生成器）
- **GCC** 或 **Clang**（支援 C11）
- **LLVM** ≥ 14（HW2 需要）

### 編譯與測試

#### HW1

```bash
cd NCKU_Compiler_HW1
mkdir build && cd build
cmake ..
make
./test.sh  # 或 test.ps1（Windows）
```

#### HW2

```bash
cd NCKU_Compiler_HW2
mkdir build && cd build
cmake ..
make
./test.sh  # 或 test.ps1（Windows）
```

## 文件資源

### HW1 相關

- [作業規劃與說明（HackMD）](https://hackmd.io/@WavJaby/NCKU_1142_COMPILER_HW)

### HW2 相關

- [作業說明（HackMD）](https://hackmd.io/@WavJaby/NCKU_1142_COMPILER_HW2)
- [YACC 速查表](NCKU_Compiler_HW2/YACC_CHEATSHEET.md)
- [LLVM IR 速查表](NCKU_Compiler_HW2/LLVM_IR_CHEATSHEET.md)

## 學習重點

本系列作業涵蓋編譯器開發的完整流程：

1. **詞法分析**（HW1）：正規表達式 → Token
2. **語法分析**（HW2）：Context-Free Grammar → 抽象語法樹（AST）
3. **語義分析**（HW2）：符號表、型別檢查、作用域管理
4. **中間代碼生成**（HW2）：AST → LLVM IR
5. **代碼優化與執行**（HW2）：LLVM IR → 機器代碼

## 測試檔案

- **策問（入門題）**：基礎功能測試
- **殿試（進階題）**：複雜功能測試
- **對勘（對照題）**：輸出比較測試

## 相關資源

- [文言文編程語言文檔](https://wy-lang.org/)
- [LLVM 官方文檔](https://llvm.org/docs/)
- [Flex &amp; Bison 教程](https://www.gnu.org/software/bison/manual/)

---

**作者**：NCKU 學生
**課程**：編譯系統（NCKU 114-2）
**最後更新**：2026年6月
