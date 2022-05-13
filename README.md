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

- FR に特権レベル PL を追加 (0: スーパーバイザ 1: ユーザ)
- FR に割り込み許可状態 IE を追加 (0: 禁止 1: 許可)
- 割り込み要因マスクレジスタ IM を追加 (内部レジスタ)

- TODO: メモリ保護機構

- メモリマップ
  - 0x0000 - 0x1fff (length 0x2000) : カーネルプログラム (余ったら自由に)
  - 0x2000 - 0x200f (length 0x10) : 割り込みベクタ
  - 0x2010 - 0x21ff (length 0x190) : フレームバッファ

- 割り込み要因
  - 0 - 3 プロセッサ例外
    - 0: 0除算
    - 1: 不正な命令
    - 2: 一般保護
    - 3: bios call
  - 4 - 7 外部要因割り込み
    - 4: タイマー
  - 8-15: ユーザ定義割り込み

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

- マクロ定義
- ELF 形式対応

### OS 実装向け拡張

- タイマー割り込み
- メモリ保護

参考: [COMET-II互換プロセッサによるCPU設計演習環境の開発](https://www.ieice.org/publications/conference-FIT-DVDs/FIT2002/pdf/C/C_1.PDF)
