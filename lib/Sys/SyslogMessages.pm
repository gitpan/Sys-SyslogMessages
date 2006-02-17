package Sys::SyslogMessages;

our $VERSION = '0.01';

my %logger_types = ( 'syslog'   => '/var/run/syslogd.pid',
                     'syslogng' => '/var/run/syslog-ng.pid'
                   ); 

sub new{
    my $package = shift;
    my $options = shift;
    my $self = {};
    bless $self, $package;
    foreach my $option (keys %{$options}){
        $self->{$option} = $options->{$option};
    }
    $self->_check_logger();
    return $self;
}


sub tail {
    my $self = shift;
    my $options = shift;
    $self->{'number_lines'} = 50;
    foreach my $option (keys %{$options}){
	$self->{$option} = $options->{$option};
    }
    $self->_parse_config();
    if ( $self->{'output_file'}){
        system("tail -n$self->{'number_lines'} $self->{'syslog_file'} > $self->{'output_file'}");
    } else {
        system("tail -n$self->{'number_lines'} $self->{'syslog_file'}");
    }
    if ( $? == 0 ){
        return 1;
    }
}

sub copy {
    my $self = shift;
    my $options = shift;
    $self->_parse_config();
    foreach my $option (keys %{$options}){
	$self->{$option} = $options->{$option};
    }
    unless ($self->{'output_file'}) {$self->{'output_file'} = 'syslog.txt';}
    system("cp $self->{'syslog_file'} $self->{'output_file'}");
    if ( $? == 0 ){
        return 1;
    }
}

sub _check_logger{
    my $self = shift;
    foreach $key (keys %logger_types){
        if ( -e $logger_types{$key}){
            my $pkg = 'Sys::SyslogMessages::' . $key;
            bless $self, $pkg; 
            $self->{ 'logger' } = $key;
            return;
        }
    }
}


package Sys::SyslogMessages::syslog;
use base Sys::SyslogMessages;

sub _parse_config{
     my $self = shift;
     $self->{'syslog_config'} = '/etc/syslog.conf';
     open FH, $self->{'syslog_config'};
     while (<FH>){
         next if $_ =~ m/^#/;
         next if $_ =~ m/^\n$/;
         chomp $_;
         if ($_ =~ m/\*\.(\*|info)/){
	     ($self->{'syslog_file'}) = $_ =~ m/\*\.\*.*\s+\-?(\/.*)/;
	     close FH;
             return;
         }

     }
     close FH;
}




package Sys::SyslogMessages::syslogng;
use base Sys::SyslogMessages;

sub _parse_config{
     my $self = shift;
     $self->{'syslog_config'} = '/etc/syslog-ng/syslog-ng.conf';
     open FH, $self->{'syslog_config'};
     while (<FH>){
         next if $_ =~ m/^#/;
         next if $_ =~ m/^\n$/;
         chomp $_;
         if ($_ =~ m/destination\s+messages.*file/){
             ($self->{'syslog_file'}) = $_ =~ m/destination\s+messages.*file\(\s*(?:\'|\")(.*)(?:\'|\")/;
         }
     }
     close FH;
}

1;

__END__


=head1 NAME

Sys::SyslogMessages - Figure out where syslog is and copy or tail it.(on Linux)

=head1 SYNOPSIS

    use Sys::SyslogMessages;

    $linux = new Sys::SyslogMessages({'output_file' => 'syslog.tail'});
    $linux->tail({'number_lines' => '500'});
    $linux->copy({'output_file' => 'syslog.log'});

=head1 DESCRIPTION
	
This is a simple module that finds the system logfile on Linux is and can copy 
it or tail it to a file.  It works for syslogd or syslog-ng.

=head1 TODO

Be able to save various categories of logs, i.e. kern.* mail.*.
Add copy dmsg support.
Tail syslog from a particular time or since last reboot.
Check for any other sys-logger options besides syslogd or syslog-ng.

=head1 AUTHORS

Judith Lebzelter, E<lt>judith@osdl.orgE<gt>

=head1 COPYRIGHT AND LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut

