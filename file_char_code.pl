#
# 日本語文字コードの判定（ファイルはディレクトリ再帰で発見）
#
# 2013/12/01
# Oi Hirokazu
#
# 参考：
# 404 Blog Not Found:ruby|perl - 文字コードのちょっと高度な判定 : http://blog.livedoor.jp/dankogai/archives/50737353.html
# 再帰的にすべてのファイルを処理する - File::Find::find() - サンプルコードによるPerl入門 : http://d.hatena.ne.jp/perlcodesample/20080530/1212291182
#
use strict;
use warnings;
use Encode::Guess;
use File::Path;
use Fcntl;
use File::Find;

# テスト準備：ディレクトリとファイルの作成
my $top_dir = "dir_20080530_$$";
my @dirs = (
  "$top_dir/dir1", "$top_dir/dir1/dir1_1", "$top_dir/dir1/dir1_2",
  "$top_dir/dir2",
);
for my $dir (@dirs) {
  eval { mkpath $dir };
  if (@!) { die "@!" }
}

my @files = (
  "$top_dir/top.txt", "$top_dir/dir1/1.txt",
  "$top_dir/dir1/dir1_1/1_1.txt", "$top_dir/dir1/dir1_2/1_2.txt",
  "$top_dir/dir2/2.txt"
);
for my $file (@files) {
  sysopen( my $fh, $file, O_WRONLY | O_CREAT | O_EXCL )
    or die "$file を作成することができません。: $!";
  close $fh;
}
print "準備: $top_dir を作成\n\n";

# 再帰下降
print "再帰的に日本語文字コードを判定\n";
$\ = "\n";
find( \&determine_char_code, $top_dir );

# 日本語文字コード判定処理                                   
sub determine_char_code {
    return if $File::Find::name !~ /\.([hc]|java|txt|cpp)$/;
    my %hash = ();
    open(my $fh, "<",  $File::Find::name) or die "Can't open $File::Find::name : $!";
    print "$File::Find::name\n";
    while (my $line = readline $fh) {
	chomp $line;
	my $enc = guess_encoding($line, qw/euc-jp shiftjis 7bit-jis/);
	$enc_str = ref $enc ? $enc->name : $enc;
	unless $hash{$enc_str} {
	    print "$enc_str\n";
	    $hash{$enc_str} = 1;
	}
    }
    close $fh;
}



