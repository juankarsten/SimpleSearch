#!/usr/bin/perl

%modelbool;
%modelbool_stem;
%titleofdoc;

#trim word
sub trim{
	my $str;
	$str = $_[0];
	$str =~ s/^\s+//;
	$str =~ s/\s+$//;
	return $str;
}

#read whole file
sub readfile{
	open FILEHANDLE, $_[0] or die $!;
	my $string = do { local $/; <FILEHANDLE> };
	close FILEHANDLE;
	$string=~s/[\r,\n]//gi;
	$string=~tr/A-Z/a-z/;
	return $string;
}


# take content of a tag
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

#clean sentence from bad char
sub clean_sentence{
	$result = $_[0];
	
	# remove word which contains number
	$result=~s/[a-z]*[0-9]+[a-z]*/ /g;
	
	# temp remove dash
	$result=~s/-/ /g;
	
	# temp remove boundary
	$result=~s/\b/ /g;
	
	# remove non alphabet
	$result=~s/[^a-z]/ /g;
	
	return $result;
}

# process doc 
# get tag of dokno, judul, and tag
# create boolean model of unstem and stem word
sub process_doc{
	my $str; my $content; my $rest;
	$str= $_[0];
	($content,$rest)=gettagcontent($str,2,"dok","doc");
	while (1){
		# jika udah habis
		if($content eq "" and $rest eq ""){
			last;
		}
		
		($no,$content)=gettagcontent($content,1,"no");
		($judul,$content)=gettagcontent($content,1,"judul");
		($teks,$content)=gettagcontent($content,1,"teks");
		
		#clean sentence
		$judul_prev = $judul;
		$judul = clean_sentence($judul);
		$teks = clean_sentence($teks);
		
		#trim number doc and title
		$no =~ s/^\s+//;
		$no =~ s/\s+$//;
		$judul =~ s/^\s+//;
		$judul =~ s/\s+$//;
		#print $no;
		
		# buat model booleannya untuk stem and unstem
		$titleofdoc{$no}=$judul_prev;
		@words = split(/\s+/,$judul);
		for $word(@words){
			if($word  ne ""){
				#$modelbool{$word}{$no}=1;
				$modelbool{$no}{$word}=1;
			}
			
			$stem_result = stemming($word);
			if($stem_result ne ""){
				#$modelbool_stem{$stem_result}{$no}=1;
				$modelbool_stem{$no}{$stem_result}=1;
			}
			
		}
		@words = split(/\s+/,$teks);
		for $word(@words){
			if($word  ne ""){
				#$modelbool{$word}{$no}=1;
				$modelbool{$no}{$word}=1;
			}
			
			$stem_result = stemming($word);
			if($stem_result  ne ""){
				#$modelbool_stem{$stem_result}{$no}=1;
				$modelbool_stem{$no}{$stem_result}=1;
			}
		}
		
		
		($content,$rest)=gettagcontent($rest,2,"dok","doc");
	}
}

# cari query dari file kueri.txt
sub searchquery{
	open hasil , ">hasil.txt";
	
	# read file and search all query
	open(kueris,"kueri.txt");
	while (my $query=<kueris>){
		$query=~s/[\n,\r]*//gi;
		print hasil $query."\n";
		
		
		# without stem
		if (substr($query,0,1) eq "#" ){	
			$query1 = substr($query,1,length($query)-1);
			#print $query1."my query\n";
			my $ii = 0;
			for $no(sort keys %modelbool){
				# gunakan metod parse tree utk parse bool exp
				@query_letter = split(//,$query1);
				# jika ada print ke file
				if(parsetree(0,length($query1)-1, length($query1),$no, \@query_letter,\%modelbool,$NOSTEM)){
					print hasil "    - ".$titleofdoc{$no}."\n";
					$ii = $ii+1;
					if($ii>=10){
						last;
					}
				}
			}
		# with stemming
		}else{
			
			$query1 = $query;
			my $ii = 0;
			for $no(sort keys %modelbool_stem){
				# gunakan metod parse tree utk parse bool exp
				@query_letter = split(//,$query1);
				# jika ada print ke file
				if(parsetree(0,length($query1)-1, length($query1),$no, \@query_letter,\%modelbool_stem,$STEM)){
					#print hasil $no."\n";
					print hasil "    - ".$titleofdoc{$no}."\n";
					$ii = $ii+1;
					if($ii>=10){
						last;
					}
				}
			}
		}
	}
	
	close(hasil);
}

sub searchquery1{
	open hasil , ">hasil.txt";
	
	# read file and search all query
	my $queries = readfile("kueri.txt");
	@queries = split(/\s+/,$queries);
	for $query(@queries){
		print hasil $query."\n";
		
		# without stem
		if (substr($query,0,1) eq "#" ){	
			$query1 = substr($query,1,length($query)-1);
			#print $query1;
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
		# with stemming
		}else{
			$query1 = stemming($query);
			#print $query1;
			%doks=%{$modelbool_stem{$query1}};
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

#is prefix allowed
sub is_allowed{
	my $affix,$suffix;
	$affix=@_[0];
	$suffix=@_[1];

	# beberapa awalan akhiran yang tidak diperbolehkan
	# jika tidak boleh return 0
	if($affix=~/^be-$/ and $suffix eq "-i"){
		return 0;
	}elsif($affix=~/^di-$/ and $suffix eq "-an"){
		return 0;
	}elsif($affix=~/^ke-$/ and ( $suffix eq "-i" or $suffix eq "-kan" )){
		return 0;
	}elsif($affix=~/^me-$/ and $suffix eq "-an"){
		return 0;
	}elsif($affix=~/^se-$/ and ( $suffix eq "-i" or $suffix eq "-kan" )){
		return 0;
	}
	
	return 1;
}

#global variable
#%imbuhan;
#%root_words;
#%prev_words;

# stemming word
sub stemming{
	my $word,$finish,$root1,@suffix1,$root2,@suffix2,$root3,$affix;
	my $all_affix,$all_suffix,$finish,$ii;
	
	#init
	$all_affix="";
	$all_suffix="";
	$finish=0;
	$word=@_[0];
	
	$ii=0;
	
	#get suffix inflectional and derivation first
	($root1,@suffix1)=inflectional_suffix($word);
	($root2,$suffix2)=derivation_suffix($root1);
	$word=$root2;
	
	# minimal 4 huruf
	while($word=~/^[a-z]{4,}/ and $finish==0 and $ii<=3){
		
		# handle prefix
		# handle di ke se be me pe te
		if($affix eq ""){
			($root3,$affix)=handle_di_ke_se($word);
		}
		if($affix eq ""){
			($root3,$affix)=handle_be($word);
		}
		if($affix eq ""){
			($root3,$affix)=handle_me($word);
		}
		if($affix eq ""){
			($root3,$affix)=handle_pe($word);
		}
		if($affix eq ""){
			($root3,$affix)=handle_te($word);
		}
		
		
		# is prefix and suffix allowed?
		# jika tidak diperbolehkan, concat suffix lagi ke kata
		unless(is_allowed($affix,$suffix2)){
			$root3=$root3.substr($suffix2,1,length($suffix2));
			$suffix2="";
			$finish=1;
		}
		
		# update root,affix
		$word=$root3;
		$all_affix=$all_affix.$affix;
		
		# if no affix break loop
		if($affix eq ""){
			$finish=1;
		}
		
		# clear variable
		$affix="";
		
		# increment to stop infinite loop
		$ii++;
	}
	$all_suffix=$suffix2.(join "", @suffix1).$all_suffix;
	
	return $word;
}


# param word
# output (root word, suffix)
# assume length of root word > 2
sub inflectional_suffix{
	my $root,@suffix;
	$root = $_[0];
	@suffix=();
	
	# Jika berupa particles (ku mu nya) maka hapus dan return 
	if($root=~/^[a-z]{3,}ku$/){
		push @suffix,"-ku";
		$root=~s/ku$//;
		return ($root,@suffix);
	}elsif($root=~/^[a-z]{3,}mu$/){
		push @suffix,"-mu";
		$root=~s/mu$//;
		return ($root,@suffix);
	}elsif($root=~/^[a-z]{3,}nya$/){
		push @suffix,"-nya";
		$root=~s/nya$//;
		return ($root,@suffix);
	}
	
	# Jika berupa particles (“-lah”, “-kah”, “-tah”) maka langkah ini diulangi lagi untuk menghapus 
	# Possesive Pronouns (“-ku”, “-mu”, atau “-nya”), jika ada.
	if($root=~/^[a-z]{3,}lah$/){
		push @suffix,"-lah";
		$root=~s/lah$//;
	}elsif($root=~/^[a-z]{3,}kah$/){
		push @suffix,"-kah";
		$root=~s/kah$//;
	}elsif($root=~/^[a-z]{3,}tah$/){
		push @suffix,"-tah";
		$root=~s/tah$//;
	}
		
	# hapus -ku -mu -nya
	if($root=~/^[a-z]{3,}ku$/){
		push @suffix,"-ku";
		$root=~s/ku$//;
	}elsif($root=~/^[a-z]{3,}mu$/){
		push @suffix,"-mu";
		$root=~s/mu$//;
	}elsif($root=~/^[a-z]{3,}nya$/){
		push @suffix,"-nya";
		$root=~s/nya$//;
	}
	
	return ($root,reverse @suffix);
}

#Hapus Derivation Suffixes (“-i”, “-an” atau “-kan”)
sub derivation_suffix{
	my $root,$suffix;
	
	$root=$_[0];
	$suffix="";
	
	if($root=~/^[a-z]{3,}i$/){
		$suffix="-i";
		$root=~s/i$//;
	}elsif($root=~/^[a-z]{3,}kan$/){
		$suffix="-kan";
		$root=~s/kan$//;
	}elsif($root=~/^[a-z]{3,}an$/){
		$suffix="-an";
		$root=~s/an$//;
	}
	
	return ($root,$suffix)
}

# hapus di ke se
sub handle_di_ke_se{
	my $word;
	
	$word=$_[0];
	if($word=~/^di[a-z]{3,}$/){
		$word=~s/^di//;
		return ($word,"di-");
	}
	
	if($word=~/^ke[a-z]{3,}$/){
		$word=~s/^ke//;
		return ($word,"ke-");
	}
	
	if($word=~/^se[a-z]{3,}$/){
		$word=~s/^se//;
		return ($word,"se-");
	}
}

sub handle_me{
	my $root,$affix;
	$root=$_[0];
	$affix="me-";
		
	
	# hapus meng- untuk root dengan depan vokal dan g h
	if($root=~/^meng[a-z]{3,}$/){
		$root=~s/^meng//;
		return ($root,$affix);
	}
	
	
	# ubah meny menjadi s
	# contoh: menyapu jadi sapu
	if($root=~/^meny[a-z]{3,}$/){
		$root=~s/^meny//;
		return ("s".$root,$affix);
	}
	
	# jika men-[c,d,j] hapus saja men
	# jika men-vokal hapus men ganti t contoh: menampar jadi tampar
	# else hapus men
	if($root=~/^men[a-z]{3,}$/){
		$root=~s/^men//;
			
		if($root=~/^[c,d,j]{1}/){
			return ($root,$affix);
		}elsif($root=~/^[a,i,u,e,o]/){
			return ("t".$root,$affix);
		}else{
			return ($root,$affix);
		}
	}
	
	# jika mem[b,f,v] hapus mem
	# else jika mem[vokal] hapus mem dan tambahkan p contoh memakai jadi pakai
	#
	if($root=~/^mem[a-z]{3,}$/){
		$root=~s/^mem//;
		if($root=~/^[b,f,v]/){
			return ($root,$affix);
		}elsif($root=~/^[a,i,u,e,o]/){
			return ("p".$root,$affix);
		}else{
			return ($root,$affix);
		}
	}
	
	# hapus me
	if($root=~/^me[l,m,n,q,r,w]{1}[a-z]{2,}$/){
		$root=~s/^me//;
		return ($root,$affix);
	}
	
	return ($root,"");
}

# hapus pe
sub handle_pe{
	my $root,$affix;
	
	$root=$_[0];
	$affix="pe-";
	
	# special case
	if($root=~/^pelajar/){
		$root=~s/^pel//;
		return ($root,$affix);
	}
	
	# special case
	if($root=~/^pekerja/){
		$root=~s/^pe//;
		return ($root,$affix);
	}
	
	# hapus per
	if($root=~/^per[a-z]{3,}$/){
		$root=~s/^per//;
		return ($root,$affix);
	}
	
	# awalan peng
	if($root=~/^peng[a-z]{3,}$/){
		$root=~s/^peng//;
		return ($root,$affix);
	}
	
	# hapus pen
	# jika peny jadi s contoh penyapu jadi sapu
	# jika pen[vokal] jadi t contoh penampar jadi tampar
	if($root=~/^pen[a-z]{3,}$/){
		$root=~s/^pen//;
		if($root=~/^[j,d,c,z]{1}[a-z]{2,}/){
			return ($root,$affix);
		}elsif($root=~/^y[a-z]{2,}/){
			$root=~s/^y//;
			return ("s".$root,$affix);
		}elsif($root=~/^[a,i,u,e,o]/){
			return ("t".$root,$affix);
		}else{
			return ($root,$affix);
		}
	}
	
	# jika pem[b,f,v] hapus pem
	# else 
	if($root=~/^pem[a-z]{3,}$/){
		$root=~s/^pem//;
		if($root=~/^[b,f,v]{1}[a-z]{2,}/){
			return ($root,$affix);
		}elsif($root=~/^[a,i,u,e,o]/){
			return ("p".$root,$affix);
		}else{
			return ($root,$affix);
		}
	}

		# hapus pe
	if($root=~/^pe[l,r,w,g]{1}[a-z]{2,}/){
		$root=~s/^pe//;
		return ($root,$affix);
	}
	
	return ($root,"");
}


sub handle_be{
	my $root,$affix;
	$root=$_[0];
	$affix="be-";
	
	if($root=~/^ber[a-z]{3,}$/){
		$root=~s/ber//;
		return ($root,$affix);
	}
		
	# potong ber-
	# potong be.er contoh bekerja jadi kerja
	if($root=~/^ber[a-z]{2,}$/ or $root=~/^be[a-z]er[a-z]{1,}$/){
		$root=~s/^be//;
		return ($root,$affix);
	}
	
	
	if($root=~/^belajar$/){
		$root=~s/^bel//;
		return ("ajar",$affix);
	} 
	
	return ($root,"");
}

sub handle_te{
	my $root,$affix;
	
	$root=$_[0];
	$affix="te-";
		
	# hapus ter
	if($root=~/^ter[a-z]{3,}$/){
		$root=~s/^ter//;
		return ($root,$affix);		
	}

	return ($root,"");
}

$STEM = 0;
$NOSTEM = 1;

# parse tree input boolean expression string
# 
sub parsetree{
	my $start;	my $end;my $len;my $doknum; my @letters; my %model; my $type;
	$start = $_[0];
	$end = $_[1];
	$len = $_[2];
	$dok_num = $_[3];
	@letters = @{$_[4]};
	%model = %{$_[5]};
	$type = $_[6];
	
	# trim front and rear space
	for $ii($start..$end){
		if($letters[$ii] ne " "){
			$start = $ii;
			last;
		}
	}
	for(my $ii = $end; $ii>=$start; $ii--){
		if($letters[$ii] ne " "){
			$end = $ii;
			last;
		}
	}
	
	
	# remove ( and )
	if($letters[$start] eq "(" and $letters[$end] eq ")"){
		$start = $start + 1;
		$end = $end - 1;
		#print $start." ".$end;
	}
	
	my $nokurung = 1;	my $kurung = 0;
	my $first = 0;	my $left=1; my $right=1;
	for $ii($start..$end){
		if ($letters[$ii] eq "("){
			$kurung = $kurung + 1;
			$nokurung = 0;
		}elsif ($letters[$ii] eq ")"){
			$kurung = $kurung - 1;
		}else{
			if($kurung == 0){
				# check and
				# jika ada and, manggil method scr rekursif
				if($ii <= $end-2 and $letters[$ii] eq "A" and $letters[$ii+1] eq "N" and $letters[$ii+2] eq "D" ){
					#print "AND -->".$start." ".($ii-1)." --- ".($ii+3)." ".$end."\n";
					my $left = parsetree($start,$ii-1,$len,$dok_num,\@letters,\%model,$type);
					my $right = parsetree($ii+3,$end,$len,$dok_num,\@letters,\%model,$type);
					return ($left and $right);
				}
				# check or
				# jika ada or, manggil method scr rekursif
				elsif($ii <= $end-1 and $letters[$ii] eq "O" and $letters[$ii+1] eq "R" ){
					#print "OR -->".$start." ".($ii-1)." --- ".($ii+2)." ".$end."\n";
					my $left = parsetree($start,$ii-1,$len,$dok_num,\@letters,\%model,$type);
					my $right = parsetree($ii+2,$end,$len,$dok_num,\@letters,\%model,$type);
					return ($left or $right);
				}
				# check not
				# jika ada not, manggil method scr rekursif
				elsif($ii <= $end-2 and $letters[$ii] eq "N" and $letters[$ii+1] eq "O" and $letters[$ii+2] eq "T" ){
					#print "NOT -->".($ii+3)." ".$end."\n";
					my $left = parsetree($ii+3,$end,$len,$dok_num,\@letters,\%model,$type);
					return (not $left);
				}
			}
		}
	}
	
	# base case 
	if($nokurung){
		# trim space
		#print "\nno kurung".$start." ".$end."\n";
		my $str="";
		for $ii($start..$end){
			if($letters[$ii] ne " "){
				$start = $ii;
				last;
			}
		}
		for(my $ii = $end; $ii>=$start; $ii--){
			if($letters[$ii] ne " "){
				$end = $ii;
				last;
			}
		}
		for $ii($start..$end){
			$str = $str.$letters[$ii];
		}
		
		# do stemming if asked
		if($type == $STEM){
			$str = stemming($str);
		}
		#print "base case " .$str."\n";
		return $model{$dok_num}{$str};
	}
	
	
	#print "masuk".$start.$end;
	return parsetree($start,$end,$len,$dok_num,\@letters,\%model,$type);
}

#print clean_sentence("abc-abc. dajskdjf;'f;'g'fd ahdj6jdkjdks asdsadasd asdasds");


# count time
$start = time;

# baca seluruh file
print "read doc...\n";
$file = readfile("korpus.txt");

# proses file dan hasilkan model boolean
print "build model...\n";
process_doc($file);

# process query
print "query...\n";
searchquery();

$end = time;

print "elapsed times: ".($end-$start)." seconds\n";

