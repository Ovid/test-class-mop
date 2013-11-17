use mop;
class PersonTest {
    use strict;
    use warnings;
    has $!first_name = die 'first_name required';
    has $!last_name  = die 'last_name required';

    method full_name {
        return join ' ' => $self->first_name, $self->last_name;
    }
}
