
BEGIN {
	use Config;
	if (! $Config{'useithreads'}) {
		print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
		exit(0);
	}
}

use Test::More tests => 3;
use Net::NfDump qw ':all';
use Data::Dumper;

open(STDOUT, ">&STDERR");

require "t/ds.pl";

# preapre dataset 
$floww = new Net::NfDump(OutputFile => "t/agg_dataset.tmp" );
my %row = %{$DS{'v4_txt'}};
for (my $i = 0; $i < 1000; $i++) {
	$floww->storerow_hashref( txt2flow(\%row) );
}
$floww->finish();


$flowr = new Net::NfDump(
		InputFiles => [ "t/agg_dataset.tmp" ], 
		Fields => "srcip,dstport,bytes,duration,inif,outif,bps,pps,pkts", 
		Aggreg => 1);
$flowr->query();
my $numrows = 0;
%row = %{$DS{'v4_txt'}};
while ( my $row = $flowr->fetchrow_hashref() )  {
	$row = flow2txt($row);
	$numrows++ if ($row->{'srcip'} eq '147.229.3.135' && $row->{'bytes'} eq '750000000000' 
	&& $row->{'outif'} eq '1' && $row->{'bps'} eq '100000000000');
#	diag Dumper($row);
}

ok($numrows == 1);


$flowr = new Net::NfDump(
		InputFiles => [ "t/agg_dataset.tmp" ], 
		Fields => "srcip/24/64,bytes,bps", 
		Aggreg => 1);
$flowr->query();
$numrows = 0;
while ( my $row = $flowr->fetchrow_hashref() )  {
	$row = flow2txt($row);
	$numrows++ if ($row->{'srcip'} eq '147.229.3.0' && $row->{'bytes'} eq '750000000000');
#	diag Dumper($row);
}

ok($numrows == 1);

my %row4 = %{$DS{'v4_txt'}};
my %row6 = %{$DS{'v6_txt'}};

$floww = new Net::NfDump(OutputFile => "t/agg_dataset2.tmp" );
for (my $i = 0; $i < 1000; $i++) {
	$row4{'srcip'} = sprintf("147.229.%d.10", $i % 10);
	$row4{'bytes'} = $i * 2;
	$row6{'srcip'} = sprintf("2001:67c:1220:%d::10", $i % 10);
	$row6{'bytes'} = $i * 6;
	delete($row4{'ip'});
	delete($row6{'ip'});
	$floww->storerow_hashref( txt2flow(\%row4) );
	$floww->storerow_hashref( txt2flow(\%row6) );
}
$floww->finish();

$flowr = new Net::NfDump(InputFiles => [ "t/agg_dataset2.tmp" ], Fields => "srcip/24/64,bytes", 
			Aggreg => 1, OrderBy => "bytes");
$flowr->query();
$numrows = 0;
while ( my $row = $flowr->fetchrow_hashref() )  {
	$row = flow2txt($row);
	$numrows++;
#	diag Dumper($row);
#	printf "NUMROWS: $numrows\n";
}

ok($numrows == 20);

