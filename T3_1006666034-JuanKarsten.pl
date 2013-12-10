#!/usr/bin/perl

# GLOBAL VARIABLE
# semua kata
%all_words;
@words_aja;
# daftar query
@queries;
# daftar soundex
%soundexes;

# param 3 angka $_[0],$_[1],$_[2]
# mencari manakah yang paling minimum dari ketiga angka tsb
sub min3{
	my $min;
	if($_[0]<$_[1]){
		$min=$_[0];
	}else{
		$min=$_[1];
	}
	
	if($min<$_[2]){
		return $min;
	}
	return $_[2];
	
}

# param array
# print array hanya untuk debug
sub print_array{
	my @ar;
	@ar=@_;
	print "print array: \n";
	foreach $ii(@ar){
		print join ",",@$ii;
		print "\n";
	}
	print "\n";
}

sub words_to_file{
	my $word;
	
	open(infile,"words.txt");
	for $word(sort keys %all_words){
		print infile "$word\n";
	}
	close(infile);
}

# param katanya dan posisi karakter yang ingin dicari
# param 1 kata; param 2 posisi karakter
# return karakter di kata tsb
# conoth char_at('abcde',3)=d
sub char_at{
	
	if($_[0] eq ""){
		return "";
	}
	if($_[1] < 0){
		return "";
	}
	
	my $word,$pos,@letters;
	$word=$_[0];
	$pos=$_[1];
	my @letters=split(//,$word);
	return $letters[$pos];
}

# param1 word1 param2 word2
# mengembalikan levenshtein_distance(word1,word2)
sub levenshtein_distance{
	my $word1, $word2,$word1len, $word2len, $ii, $jj;
	
	# get param word0 and word1 and their length
	$word1=$_[0];
	$word2=$_[1];
	$word1len=length($word1);
	$word2len=length($word2);
	
	# array of array
	my @distance=();
	
	# split word
	my @letters1=split(//,$word1);
	my @letters2=split(//,$word2);
	
	#initialize array
	for $ii(0 .. $word1len){
		$distance[$ii]=[($ii)];
	}
	for $ii(0 .. $word2len){
		$distance[0][$ii]=$ii;
	}
	
	
	for $ii(1 .. $word1len){
		for $jj(1 .. $word2len){
			my $inc;
			
			# jika char sama inc=0 else inc=1
			#if(char_at($word1,$ii-1) eq char_at($word2,$jj-1)){
			if($letters1[$ii-1] eq $letters2[$jj-1]){
				$inc=0;
			}else{
				$inc=1;
			}
			
			# find minimum between three choice	
			$distance[$ii][$jj]=min3($distance[$ii-1][$jj-1]+$inc,$distance[$ii-1][$jj]+1,$distance[$ii][$jj-1]+1);
		}
	}
	
	return $distance[$word1len][$word2len];
}



# param1 kata
# return string soundex
sub soundex{
	my $word, $front,$rear,$result;
	$word=$_[0];
		
	$front=char_at($word,0);
	$rear = substr $word,1,length($word);
	
	$rear=~tr/A-Z/a-z/;
	
	#1. menghilangkan h dan w
	$rear=~s/[h,w]//gi;
	
	
	$rear=$front.$rear;
	
	#2a. mengubah bfvp menjadi 1
	$rear=~s/[b,f,v,p]/1/gi;
	#2b. mengubah cgjkqsxz menjadi 2
	$rear=~s/[c,g,j,k,q,s,x,z]/2/gi;
	#2c. mengubah dt menjadi 3
	$rear=~s/[d,t]/3/gi;
	#2d. mengubah l menjadi 4
	$rear=~s/[l]/4/gi;
	#2e. mengubah mn menjadi 5
	$rear=~s/[m,n]/5/gi;
	#2f. mengubah r menjadi 6
	$rear=~s/[r]/6/gi;
	

	#3. menggabungkan angka
	$result='';
	my $last='';
	my @read_letters=split(//,$rear);
	for ($ii=0; $ii<length($rear);$ii++){
		#unless(char_at($result,length($result)-1) eq  char_at($rear,$ii)){
		unless($last eq  $read_letters[$ii]){
			#$result=$result.char_at($rear,$ii);
			#$last=char_at($rear,$ii);
			$result=$result.$read_letters[$ii];
			$last=$read_letters[$ii];
		}
	}
	$result=substr $result, 1,length($result);
	
	#4 buang aiueoy 
	$result=~s/[a,i,u,e,o,y]//gi;
	$result=$front.$result;
	
	#5. add trailing zero if length < 4
	$result=substr $result, 0,4;
	while (length($result)<4){
		$result=$result."0";
	}
	return $result;
}

# hitung soundex
sub count_soundex{
	my $word, $sd, $len;
	foreach $word(@words_aja){
		$sd=soundex($word);
		$len=@{$soundexes{$sd}};
		$soundexes{$sd}[$len]=$word;
	}
}

# param1 nama file
# membaca korpus dan membersihkan korpus dari tag dan karakter aneh
# return semua isi korpus
sub read_corpus{
	my $line,$korpus;
	
	open(IN,$_[0]);
	$korpus='';
	
	while($line=<IN>){
		#$korpus=$korpus.$line;
		$korpus=$line;
		
		# lower case	
		$korpus=~tr/A-Z/a-z/;
		
		# hapus tag <no> dengan karakter didalamnya
		#$korpus=~s/<[n,o]{2}>[^<]{1,10}<\/[n,o]{2}>//gi;
		$korpus=~s/<[n,o]{2}>[^<]{1,10}//gi;
		
		#remove any tag
		$korpus=~s/<[^<]{2,6}>//g;
		$korpus=~s/<\/[^<]{2,6}>//g;	

		# remove word which contains number
		$korpus=~s/[a-z]*[0-9]+[a-z]*/ /g;
		
		# remove non alphabet
		$korpus=~s/[^a-z]/ /g;
		
		get_words($korpus);
	}
	close(IN);
	
	@words_aja=keys %all_words;
	# return $korpus;
}

# param string panjang dari subroutine read_corpus
# memisahkan dan menyimpan kata di korpus
sub get_words{
	my $input,@words;
	$input=$_[0];
	
	@words=split(/\s+/,$input);
	
	foreach $word(@words){
		if($word eq ''){
			next;
		}
		$all_words{$word}++;
	}
	
	
}

# param1 membaca file query
# menuliskan isi query ke variable global @queries
sub read_query{
	my $line;
	@queries=();
	open(IN,$_[0]);
	while($line=<IN>){
		$line=~s/\s+//;
		# jika kosong, continue
		if($line eq ""){
			next;
		}
		push @queries , [split(/_/,$line)];
	}
	close(IN);
}

sub answer_question{
	
	print "start reading corpus.........................\n";
	# pre process
	#get_words(read_corpus("korpus.txt"));
	read_corpus("korpus.txt");
	
	
	# Levenshtein Distance
	print "start LD.........................\n";
	open(OUT,">hasil_LD.txt");
	# baca query
	read_query('kueri_LD.txt');
	
	my @hasil_query=();
	my @nilai_query=();
	my @total_found=();
	
	# utk tiap query
	foreach $word(@words_aja){
		my $ii=-1,$finish=1;
		foreach $query(@queries){
			
			$ii++;
			
			# jika sudah selesai
			if($total_found[$ii]>=10){
				next;
			}else{
				$finish=0;
			}
			
			# get word and distance
			$query_word=$query->[0];
			$query_n=$query->[1];
			
			# cari Levenshtein Distance dengan setiap kata
			$distance=levenshtein_distance($query_word,$word);
			
			# jika distance <= query tulis ke output
			if($distance<=$query_n){
				$hasil_query[$ii]=$hasil_query[$ii].$word."(".$distance."), ";
				$total_found[$ii]++;
			}
			
		}
		
		if($finish==1){
			last;
		}
	}
	
	my $ii=0;
	foreach $query(@queries){
		# get word and distance
		$query_word=$query->[0];
		$query_n=$query->[1];
		print OUT "$query_word\_$query_n : ";
		print OUT substr $hasil_query[$ii],0, -2;
		print OUT "\n";
		$ii++;
	}
	close(OUT);
	
	print "start soundex.........................\n";
	# SOUNDEX
	count_soundex();
	
	open(OUT,">hasil_Soundex.txt");
	# baca query
	read_query('kueri_Soundex.txt');
	foreach $query(@queries){
		
		#jika query kosong, continue
		if($query eq ""){
			next;
		}
		
		$query_word=$query->[0];
		$sd1=soundex($query_word);
		$sd1temp=$sd1;
		$sd1temp=~tr/a-z/A-Z/;
		print OUT $query_word."($sd1temp) : ";
		$first=1;
		$total=0;
		
		# bandingkan  soundex dengan setiap kata
		for $word(@{$soundexes{$sd1}}){
			$total++;
			if($first==1){
				$first=0;
			}else{
				print OUT ", ";
			}
			
			#print kata
			print OUT $word;
			
			# sudah 10 kata hasil exit
			if($total>=10){
				last;
			}
		}
		print OUT "\n";
		
	}
	close(OUT);
	
	
}

my $start=time;
answer_question();
my $end=time;
my $elapsed=$end-$start;
print "Elapsed time: $elapsed seconds";
#words_to_file();
