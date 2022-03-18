- WORDLE2 https://www.wordle2.in 何故か本家とdom構成などが同じでコードを流用できるので対応してる

## 答えに同じ文字が複数含まれてる時の挙動
（一回のトライにつき）**「🟩+🟨」の合計は実際に答えに含まれているその文字の合計を超えない**らしい。例えば`E`が3つ含まれる単語（"melee"とか）を試した結果、`E`のタイル表示が「🟩1 + 🟨1 + ⬛️1」或いは「🟨2 + ⬛️1」となった場合、答えに含まれる`E`の数は2個と確定するので、その時点で候補となる単語群の中から`E`の登場回数が2でない単語は全て除外できる。

今のところこれで合ってるはず。

## todo
- 残りの全候補がアナグラム一致の時、正解に辿り着けない

