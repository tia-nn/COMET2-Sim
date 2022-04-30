# COMET2-Sim
[wip] COMET-Ⅱ シミュレータ　（そのうち OS 実装用に拡張する）

参考: [情報処理技術者試験 試験で仕様する情報技術に関する用語・プログラム言語など](https://www.jitec.ipa.go.jp/1_13download/shiken_yougo_ver4_3.pdf) 別紙2

## 仕様

- ラベルは大文字・小文字の区別あり
- 命令名(ニーモニック)、GR[0-7]、16進数の[a-f]は大文字・小文字の区別無し
- トークン間のスペースは問題ない
- アセンブリのソースは UTF-8
  - 文字列定数・文字列リテラルは中で sjis (jis x 0201) に変換

## 検討中の仕様

- START、END の制約の緩和
  - 1ファイル中に複数 START-END できる
  - START につけたラベルがいわゆる .global になる
  - 1つの START-END の中に他の START-END は挟めない
- マクロ定義

### マクロ

```
MACRO_NAME MACRO $arg1, $arg2, $hoge, ...
    push 0, $arg1
    push 0, $arg2
    pop $hoge
    ENDMACRO
```

- マクロ内のラベルは展開時にいい感じにする
- トークナイズとパースの間に展開

### OS 実装向け拡張

- int addr, x 割り込み命令
- EI / DI 割り込み許可/禁止命令
- RETI 割り込み処理からのリターン
- LDM, STM 割り込みマスク書き込み・読み込み

- メモリマップ
  - 0x0000 - 0x1fff (length 0x2000) : カーネルプログラム (余ったら自由に)
  - 0x2000 - 0x200f (length 0x10) : 割り込みベクタ
  - 0x2010 - 0x21ff (length 0x190) : フレームバッファ

- 割り込み要因
  - 0-7 ハードウェア
    - 0: 0除算
    - 1: 不正な命令
    - 4: タイマー
  - 8-15 ソフトウェア
    - 8: bios call

- bios call
- GR7 の値によって機能を呼び出す
  - 0xf000: シャットダウン

(シミュレータ仕様)

- 起動時にディレクトリパスを一つ渡し、COMET2 のサブ記憶とする
- サブ記憶は一つのみとする
- サブ記憶の /kernel.bin をメモリの 0 番地に読み込み、その他初期化をし、kernel.bin に制御を移す (0 番地に飛ぶ)

- 起動時にファイルパスを一つ渡し、ディスプレイとする
- ディスプレイは 縦20 * 横40 文字サイズ


## TODO

### ベーシック COMET2,CASL2

- ビジュアライザ
- 丁寧な文法エラー報告

### 一般向け拡張

-  マクロ定義

### OS 実装向け拡張

- All.

参考: [COMET-II互換プロセッサによるCPU設計演習環境の開発](https://www.ieice.org/publications/conference-FIT-DVDs/FIT2002/pdf/C/C_1.PDF)
