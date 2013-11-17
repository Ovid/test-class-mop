use mop;
class PersonTest {
    use strict;
    use warnings;
    has $!first_name is ro = die 'first_name required';
    has $!last_name  is ro = die 'last_name required';

    method full_name {
        return join ' ' => $self->first_name, $self->last_name;
    }
}
