# 由 unicode ucd 的資料找出每一個 unicode 字元的版本        by heaven 2019/07/10
#
# 原始資料來源是 https://unicode.org/Public/UCD/latest/ucdxml/ucd.all.flat.zip
# 這個也可以 https://unicode.org/Public/UCD/latest/ucdxml/ucd.nounihan.flat.zip
# 二種格式大同小異, nounihan 檔案較小, 應該是沒有 unihan 資料, 不少文字是用範圍表示.
# 二份資料解壓縮後放在同一層目錄中.
#
# 直接執行 perl GetUniCharVer.pl 會產生二種檔案, 
# 一種是每個字或每個區間的版本, 這是依原始檔內容產生的.
# 另一種檔案是找出同一版本的區間, 以簡省檔案空間及方便其他程式使用.

use utf8;

my @type = ();      # 種類 C:char, R:reserved, S:surrogate, N:noncharacter
my @cp = ();        # unicode 碼
my @age = ();       # 版本
my @errlog = ();    # 錯誤記錄

Get_ucd_flat("ucd.all.flat");
Get_ucd_flat("ucd.nounihan.flat");

###################################

sub Get_ucd_flat {
    local $_;
    my $filename = shift;

    @type = (); # 總類
    @cp = ();   # unicode 碼
    @age = ();  # 版本
    @errlog = ();
      
    open IN, "<:utf8", "$filename.xml";
    my $precp = -1;
    while(<IN>) {
        # 原始檔內容說明

        # 一般文字
        # <char cp="0000" age="1.1" 
        # <char cp="2FA1D" age="3.1" na="CJK COMPATIBILITY IDEOGRAPH-#" 

        # 有範圍的一般文字 (此三者是造字區)
        # <char first-cp="E000" last-cp="F8FF" age="1.1"  --- 造字區
        # <char first-cp="F0000" last-cp="FFFFD" age="2.0"   --- 造字區
        # <char first-cp="100000" last-cp="10FFFD" age="2.0"   --- 造字區

        # 未定義文字及範圍
        # <reserved cp="038B" age="unassigned"
        # <reserved first-cp="0380" last-cp="0383" age="unassigned"

        # utf16 專用的區域
        # <surrogate first-cp="D800" last-cp="DB7F" age="2.0"

        # 應該不是文字的區域
        # <noncharacter first-cp="FDD0" last-cp="FDEF" age="3.1"

        if(/<char cp="(.*?)" age="(.*?)"/) {
            pushdata("C", $1, $2);
            my $cp = hex($1);
            CheckCharRange($precp,$cp,1);
            $precp = $cp;
        } elsif(/<reserved cp="(.*?)" age="(.*?)"/) {
            pushdata("R", $1, $2);
            my $cp = hex($1);
            CheckCharRange($precp,$cp,1);
            $precp = $cp;
        } elsif (/<([crsn])\D+? first-cp="(.*?)" last-cp="(.*?)" age="(.*?)"/) {
            # 標記有四種可能 char , reserved , surrogate, noncharacter
            my $type = uc($1);
            pushdata("${type}1", $2, $4);
            pushdata("${type}2", $3, $4);
            my $cp1 = hex($2);
            my $cp2 = hex($3);
            CheckCharRange($precp,$cp1,1);
            CheckCharRange($cp1,$cp2,0);
            $precp = $cp2;
        }
    }
    close IN;

    Print_Range_Err($filename); # 印出有錯誤的範圍
    Print_cp_age($filename); # 印出 cp 與 age
    Print_cp_age_range($filename); # 印出 cp 與 age 的範圍
}

# 儲存資料
sub pushdata {
    my $type = shift;
    my $cp = shift;
    my $age = shift;

    push(@type, $type);
    push(@cp, $cp);
    push(@age, $age);
}

# 檢查 Char 範圍有沒有連續
sub CheckCharRange {
    my $pre = shift;
    my $now = shift;
    my $type = shift;   # 1 表示只能差 1, 0 表示只要後者大於前者

    if(($type == 1 && $pre != $now - 1) || ($type == 0 && $pre >= $now)) {
        push(@errlog, sprintf("%04X - %04X\n", $pre, $now));
    }
}

# 印出範圍有誤的地方
sub Print_Range_Err {
    return if($#errlog < 0);
    my $errfile = shift;
    open ERR, ">:utf8", "$errfile.err.txt";
    for my $line (@errlog) {
        print ERR $line;
    }
    close ERR;
    print "find range error!";
}

# 印出 cp 與 age
sub Print_cp_age {
    local $_;
    my $outfile = shift;
    open OUT, ">:utf8", "$outfile.txt";
    for(my $i=0; $i<=$#cp; $i++) {
        # 一般文字 或 unassigned 單一
        if($type[$i] eq "C" || $type[$i] eq "R") {
            print OUT $type[$i] . ": " . $cp[$i] . " : " . $age[$i] . "\n";
        }
        # 有範圍的開頭 , C1, R1, S1, N1
        elsif($type[$i] =~ /^([CRSN])1$/) {
            print OUT $1 . ": " . $cp[$i] . " - ";
        }
        # 有範圍的結束
        elsif($type[$i] =~ /^([CRSN])2$/) {
            print OUT $cp[$i] . " : " . $age[$i] . "\n";
        }
    }
    close OUT;
}

# 印出 cp 與 age 的範圍
sub Print_cp_age_range {
    local $_;
    my $rangefile = shift;
    open OUT, ">:utf8", "$rangefile.range.txt";
    
    my $pretype = substr($type[0],0,1);
    my $precp = $cp[0];
    my $preage = $age[0];
    print OUT "總類,起始,結束,版本\n";
    # 底下用 $#cp + 1 是為了可以印出最後一筆
    for(my $i=1; $i<=$#cp+1; $i++) {
        my $type = substr($type[$i],0,1);
        if($type ne $pretype || $age[$i] ne $preage) {
            
            $preage = TransAge2Num($preage);
            print OUT "$pretype,$precp";
            print OUT "," . $cp[$i-1];  # if($precp ne $cp[$i-1]);
            print OUT ",$preage\n";

            $pretype = $type;
            $precp = $cp[$i];
            $preage = $age[$i];
        }
    }
    close OUT;
}

# 把版本的 unassigned 換成 0 , 順便檢查有沒有非 n.n 的版本
sub TransAge2Num {
    local $_ = shift;
    if($_ eq "unassigned") {
        $_ = "0";
    }
    elsif($_ !~ /^\d+\.\d+$/) {
        print "age error: $_ , any key continue ...";
        <>;
    }
    return $_;
}