# COMET II Core Spec

## メモリ空間

0x0000 ~ 0xffff (65536)

## Register

- GR[0-7]
- SP
- PR
- FR
  - OF
  - SF
  - ZF

### 追加命令

- LD.SP r
- ST.SP r

## 特権

- 特権命令のチェック
- メモリアクセスのチェック
<!-- - 特権レジスタアクセスのチェック -->

## 仮想メモリ

- 1段ページテーブル
- ページサイズ 256byte (オフセット 8 bit)
- \* 256 ページ

### レジスタ (CSR)

- ptr (Page Table Register)
  - PTA (Page Table Addr)
  - E (Enabled)

| 15 - 1 | 0   |
| ------ | --- |
| PTA    | E   |

#### 追加命令

- LD.PTR r
- ST.PTR r

### ページテーブルエントリ

- PPN (Phisical Page Number)
- U (User)
- X (eXecutable)
- W (Writable)
- R (Readable)
- V (Valid)

| 15 - 8 | 7 - 5 | 4   | 3   | 2   | 1   | 0   |
| ------ | ----- | --- | --- | --- | --- | --- |
| PPN    | ----  | U   | X   | W   | R   | V   |

### 仮想アドレス

| 15 - 8 | 7 - 0  |
| ------ | ------ |
| VPN    | Offset |

## 割り込み

### 割り込み原因

| 割り込み | 例外コード | 原因                           |
| -------- | ---------- | ------------------------------ |
| 1        | 1          | マシン ソフトウェア割り込み    | <!-- | 1 | 2 | ユーザ ソフトウェア割り込み | --> |
| 1        | 3          | マシン タイマー割り込み        | <!-- | 1 | 4 | ユーザ タイマー割り込み     | --> |
| 1        | 5          | マシン 外部割り込み            | <!-- | 1 | 6 | ユーザ 外部割り込み         | --> |
| 0        | 0          | 命令アクセスフォールト         |
| 0        | 1          | 不正命令                       |
| 0        | 2          | ブレークポイント               |
| 0        | 3          | ロードアクセスフォールト       |
| 0        | 4          | ストアアクセスフォールト       |
| 0        | 5          | ユーザモードからの環境呼び出し |
| 0        | 6          | マシンモードからの環境呼び出し |
| 0        | 7          | 命令ページフォールト           |
| 0        | 8          | ロードページフォールト         |
| 0        | 9          | ストアページフォールト         |

### register (CSR)

- ie (Interrupt Enabled)

| 15 - 6 | 5   | 4   | 3   | 2   | 1   | 0   |
| ------ | --- | --- | --- | --- | --- | --- |
| ------ | E   | -   | T   | -   | S   | -   |

- iw (Interrupt Waiting)

| 15 - 6 | 5   | 4   | 3   | 2   | 1   | 0   |
| ------ | --- | --- | --- | --- | --- | --- |
| ------ | E   | -   | T   | -   | S   | -   |

- cause 原因

| 15       | 14 - 0     |
| -------- | ---------- |
| 割り込み | 例外コード |

- status 状態

| 15 - 7 | 6   | 5   | 4   | 3   | 2   | 1   | 0   |
| ------ | --- | --- | --- | --- | --- | --- | --- |
| ------ | PPL | PL  | -   | PIE | -   | IE  | -   |

- tval (Trap VALue)
  - アドレス例外を起こしたアドレス、または不正命令例外を起こした命令
- tvec (Trap VECtor)
  - 例外ハンドラのベクトルのベースアドレス

- epr (Exception Program Register)
  - 例外が起こったPRの値
- scratch
  - ハンドラが自由に使える

#### 追加命令

- LD.IE
- LD.IW
- LD.CAUSE
- LD.STATUS

- ST.IE
- ST.STATUS

### 動作

<!-- TODO: 環境呼び出し時の SP について考える -->

STATUS.IE && IE.* && IW.* の時、

- EPR <- 例外が起きたPR (割り込みの時はハンドラが戻るべきPR)
- CAUSE <- 例外コード
- TVAL <- アドレス例外を起こしたアドレス、または不正命令例外を起こした命令　それ以外は0
- STATUS.PIE <- STATUS.IE; STATUS.IE = 0
- STATUS.PPL <- STATUS.PL; STATUS.PL = 0

IRET

- STATUS.PL <- STATUS.PPL
- STATUS.IE <- STATUS.PIE
- PR <- EPR
