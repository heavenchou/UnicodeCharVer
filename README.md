# UnicodeCharVer

由 Unicode 公開資料取得 Unicode 字元的版本

# 說明

原始資料來源是 https://unicode.org/Public/UCD/latest/ucdxml/ucd.all.flat.zip

這個也可以 https://unicode.org/Public/UCD/latest/ucdxml/ucd.nounihan.flat.zip

二種格式大同小異, nounihan 檔案較小, 應該是沒有 unihan 資料, 不少文字是用範圍表示.

二份資料解壓縮後放在同一層目錄中.

# 執行

直接執行 perl GetUniCharVer.pl 

# 結果

執行後會產生二種檔案, 第一種是每個字或每個區間的版本, 這是依原始檔內容產生的.

第二種檔案是找出同一版本的區間, 以簡省檔案空間及方便其他程式使用.

# 範例

第一種檔案例子, 內容分別是 總類 : 編碼或區間 : 版本(或未分配)

C: 10C4 : 1.1<br>
C: 10C5 : 1.1<br>
R: 10C6 : unassigned<br>
C: 10C7 : 6.1<br>
R: 10C8 - 10CC : unassigned<br>
C: 10CD : 6.1<br>
R: 10CE - 10CF : unassigned

第二種檔案例子:

總類,起始,結束,版本<br>
C,037A,037A,1.1<br>
C,037B,037D,5.0<br>
C,037E,037E,1.1<br>
C,037F,037F,7.0<br>
R,0380,0383,0<br>
C,0384,038A,1.1<br>
R,038B,038B,0<br>

總類有 C, R, S, N 對應原始資料的四種標記, 說明是我自己的理解, 不一定正確.

* C:char , 一般字元.
* R:reserved , 保留字, 未分配.
* S:surrogate , 代理字 , UTF16 使用, 即 D800 - DFFF
* N:noncharacter , 非字元

版本為 0 表示原始資料為 unassigned.