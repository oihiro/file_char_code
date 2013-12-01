#
# 日本語文字コードの判定（ファイルはディレクトリ再帰で発見）
#
# 2013/12/01
# Oi Hirokazu
#
# 複数の文字コードが混ざったテキストファイルも判定できるよう，一行ずつ判定する。
#
# 参考：
# 404 Blog Not Found:ruby|perl - 文字コードのちょっと高度な判定 : http://blog.livedoor.jp/dankogai/archives/50737353.html
# 再帰的にすべてのファイルを処理する - File::Find::find() - サンプルコードによるPerl入門 : http://d.hatena.ne.jp/perlcodesample/20080530/1212291182
#
use strict;
use warnings;
use utf8;
use Encode 'encode';
use Encode::Guess;
use File::Path;
use Fcntl;
use File::Find;
use Getopt::Long;

sub print_ascii_1 {
    my $fh = shift;
    for (my $i = 0; $i < 5; $i++) {
	print $fh "abcde\n";
    }
}

sub print_utf8_1 {
    my $fh = shift;
    for (my $i = 0; $i < 5; $i++) {
	print $fh "こんにちは\n";
    }
}

sub print_utf8_2 {
    my $fh = shift;
    print $fh "≫\n";
    print $fh "損\n";
    print $fh "≫損\n";
    print $fh "≫Son\n";
}

sub print_eucjp_1 {
    my $fh = shift;
    my $str = encode('EUC-JP', 'こんにちは');
    for (my $i = 0; $i < 5; $i++) {
	print $fh "$str\n";
    }
}

sub print_sjis_1 {
    my $fh = shift;
    my $str = encode('Shift_JIS', 'こんにちは');
    for (my $i = 0; $i < 5; $i++) {
	print $fh "$str\n";
    }
}

sub print_u8_eu_1 {
    my $fh = shift;
    for (my $i = 0; $i < 3; $i++) {
	print $fh "こんにちは\n";
    }
    my $str = encode('EUC-JP', 'こんにちは');
    for (my $i = 0; $i < 3; $i++) {
	print $fh "$str\n";
    }
}

sub print_eu_sj_1 {
    my $fh = shift;
    my $str = encode('EUC-JP', 'こんにちは');
    for (my $i = 0; $i < 3; $i++) {
	print $fh "$str\n";
    }
    $str = encode('Shift_JIS', 'こんにちは');
    for (my $i = 0; $i < 3; $i++) {
	print $fh "$str\n";
    }
}

sub print_sj_u8_1 {
    my $fh = shift;
    my $str = encode('Shift_JIS', 'こんにちは');
    for (my $i = 0; $i < 3; $i++) {
	print $fh "$str\n";
    }
    for (my $i = 0; $i < 3; $i++) {
	print $fh "こんにちは\n";
    }
}

sub print_u8_eu_sj_1 {
    my $fh = shift;
    for (my $i = 0; $i < 3; $i++) {
	print $fh "こんにちは\n";
    }
    my $str = encode('EUC-JP', 'こんにちは');
    for (my $i = 0; $i < 3; $i++) {
	print $fh "$str\n";
    }
    $str = encode('Shift_JIS', 'こんにちは');
    for (my $i = 0; $i < 3; $i++) {
	print $fh "$str\n";
    }
}

# テスト準備：ディレクトリとファイルの作成
sub create_testfiles {
    my $top_dir = shift;
    my @dirs = (
	"$top_dir/ascii", "$top_dir/utf8", "$top_dir/eucjp",
	"$top_dir/sjis", "$top_dir/mixed"
	);

    for my $dir (@dirs) {
	eval { mkpath $dir };
	if (@!) { die "@!" }
    }

    my %files = (
	"$top_dir/ascii/ascii.txt" => \&print_ascii_1,
	"$top_dir/utf8/utf8_1.txt" => \&print_utf8_1,
	"$top_dir/utf8/utf8_2.txt" => \&print_utf8_2,
	"$top_dir/eucjp/eucjp_1.txt" => \&print_eucjp_1,
	"$top_dir/sjis/sjis_1.txt" => \&print_sjis_1,
	"$top_dir/mixed/u8_eu_1.txt" => \&print_u8_eu_1,
	"$top_dir/mixed/eu_sj_1.txt" => \&print_eu_sj_1,
	"$top_dir/mixed/sj_u8_1.txt" => \&print_sj_u8_1,
	"$top_dir/mixed/u8_eu_sj_1.txt" => \&print_u8_eu_sj_1,
	);

    for my $file (keys %files) {
	sysopen( my $fh, $file, O_WRONLY | O_CREAT | O_EXCL )
	    or die "$file を作成することができません。: $!";
	&{$files{$file}}($fh);
	close $fh;
    }
    print "created $top_dir\n\n";
}

#
# main routine
#
my $create_testfiles_f;
my $top_dir = ".";
my $top_testdir = $top_dir . "/testfiles";
GetOptions("testfiles" => \$create_testfiles_f);
create_testfiles($top_testdir) if $create_testfiles_f;

# 再帰下降して日本語文字コードを判定
#$\ = "\n";
find(\&determine_char_code, $top_dir);

# 日本語文字コード判定処理                                   
sub determine_char_code {
    return if $File::Find::name !~ /\.([hc]|java|txt|cpp)$/;
    my %hash = ();
    print "$File::Find::name\n";
    open(my $fh, $_) or die "Can't open $File::Find::name : $!";
    while (my $line = <$fh>) {
	chomp $line;
	my $enc = guess_encoding($line, qw/euc-jp shiftjis 7bit-jis/);
	my $enc_str = ref $enc ? $enc->name : $enc;
	unless ($hash{$enc_str}) {
	    print "$enc_str\n";
	    $hash{$enc_str} = 1;
	}
    }
    close $fh;
}



