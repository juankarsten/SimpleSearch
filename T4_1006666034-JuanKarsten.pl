#!/usr/bin/perl

%modelbool = {};
%titleofdoc = {};

sub readfile{
	open FILEHANDLE, $_[0] or die $!;
	my $string = do { local $/; <FILEHANDLE> };
	close FILEHANDLE;
	$string=~s/[\r,\n]//gi;
	$string=~tr/A-Z/a-z/;
	return $string;
}



sub gettagcontent{
	my $str,$variation,$word,$length_str;
	$str = $_[0];
	$length_str = length($str);
	$variation = $_[1];
	
	my $front = 0;
	my $content = "";
	my $rest = $str;
	
	foreach my $ii (2 .. $variation+2){
		$word = $_[$ii];
		my $tag = "<".$word.">";
		my $a = index($str,$tag);
		if ($a == -1) {
			next;
		}
		
		my $untag = "</".$word.">";
		my $b = index($str,$untag);
		if ($b == -1) {
			next;
		}
		
		if($a <= $front or $content eq ""){
			($content,$rest) = ( substr($str,$a+length($tag),$b-($a+length($tag))), substr($str,$b+length($untag),$length_str-($b+length($untag))) );
		}
	}
	return ($content,$rest);
}

sub process_doc{
	my $str;
	$str= $_[0];
	($content,$rest)=gettagcontent($str,2,"dok","doc");
	while ($rest ne ""){
		($no,$content)=gettagcontent($content,1,"no");
		($judul,$content)=gettagcontent($content,1,"judul");
		($teks,$content)=gettagcontent($content,1,"teks");
		
		$titleofdoc{$no}=$judul;
		@words = split(/\s+/,$judul);
		for $word(@words){
			$modelbool{$word}{$no}=1;
		}
		@words = split(/\s+/,$teks);
		for $word(@words){
			$modelbool{$word}{$no}=1;
		}
		
		($content,$rest)=gettagcontent($rest,2,"dok","doc");
	}
}

sub searchquery{
	open hasil , ">hasil.txt";
	
	my $queries = readfile("kueri.txt");
	@queries = split(/\s+/,$queries);
	for $query(@queries){
		print hasil $query."\n";
		if (substr($query,0,1) eq "#" ){	
			$query1 = substr($query,1,length($query)-1);
			print $query1;
			%doks=%{$modelbool{$query1}};
			my $ii = 0;
			for $no(keys %doks){
				#print hasil $no."\n";
				print hasil "    - ".$titleofdoc{$no}."\n";
				$ii = $ii+1;
				if($ii>=10){
					last;
				}
			}
		}
	}
	
	close(hasil);
}

# count time
$start = time;

print "read doc...\n";
$file = readfile("korpus.txt");

print "build model...\n";
process_doc($file);

print "query...\n";
searchquery();

# finish
$end = time;
print "elapsed times: ".($end-$start)."\n";
