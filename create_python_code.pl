# 由 ucd.nounihan.flat.range.txt 的資料產生 perl 使用的程式碼
# 例:
# C,0218,021F,3.0
# C,0220,0220,3.2
# 產生
# if(uni >= 0x0218 and uni <= 0x021F) :	return "3.0"
# if(uni == 0x0220) :					return "3.2"
use utf8;

open IN, "<:utf8", "ucd.nounihan.flat.range.txt";
open OUT, ">:utf8", "python_code.py";
print OUT "def get_unicode_ver(uni):

\t# 常用的先放前面
\tif(uni >= 0x4E00 and uni <= 0x9FA5) : return \"1.1\"
\t# 符號和標點符號
\tif(uni >= 0x3000 and uni <= 0x3037) : return \"1.1\"
\tif(uni <= 0x01F5) : return \"1.1\"
\tif(uni >= 0x3400 and uni <= 0x4DB5) : return \"3.0\"
\tif(uni >= 0x20000 and uni <= 0x2A6D6) : return \"3.1\"
\t# 相容表意字補充 - 台灣的相容漢字
\tif(uni >= 0x2F800 and uni <= 0x2FA1D) : return \"3.1\"
\tif(uni >= 0x2A700 and uni <= 0x2B734) : return \"5.2\"
\tif(uni >= 0x2B740 and uni <= 0x2B81D) : return \"6.0\"
\tif(uni >= 0x2B820 and uni <= 0x2CEA1) : return \"8.0\"
\tif(uni >= 0x2CEB0 and uni <= 0x2EBE0) : return \"10.0\"

";
while(<IN>)
{
    chomp;
    my @dim = split(/,/,$_);
    next if($dim[0] eq "總類");

    if($dim[3] ne "0")
    {
        if($dim[1] eq $dim[2])
        {
            print OUT "\tif(uni == 0x" . $dim[1]. ") : return \"" . $dim[3] . "\"\n";
        }
        else
        {
            print OUT "\tif(uni >= 0x" . $dim[1]. " and uni <= 0x" . $dim[2] . ") : return \"" . $dim[3] . "\"\n";
        }
    }
}
print OUT "\n\treturn \"999\"";
close IN;
close OUT;