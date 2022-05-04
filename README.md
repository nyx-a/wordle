## 対象
- WORDLE https://www.nytimes.com/games/wordle
- WordHurdle https://www.wordhurdle.in

## 答えに同じ文字が複数含まれてる時の挙動メモ
各トライごと、**ある文字の「🟩+🟨」の合計は実際に答えに含まれているその文字の合計を超えない**。

例えば`E`が3つ含まれる単語（"melee"とか）を試した結果、`E`のタイル表示が「🟩×1 + 🟨×1 + ⬛️×1」或いは「🟨×2 + ⬛️×1」となった場合、答えに含まれる`E`の数は2個と確定するので、その時点で候補となる単語群の中から`E`の登場回数が2でない単語は全て除外できる。

1枚の場合も同様、試した単語に文字`x`が2枚含まれるのに片方が🟩、片方が⬛️となった場合、答えの中に`x`はその1枚のみなのでそれ以外の場所には存在しない。

## todo
- 残りの全候補がアナグラム一致の場合絞り込めなくなる -> 文字の出現位置を考慮するように変更する
- その前に平均何回で解答できるか調べたい

