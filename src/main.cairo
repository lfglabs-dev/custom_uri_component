#[starknet::component]
mod custom_uri_component {
    use core::traits::AddEq;
    use core::option::OptionTrait;
    use core::traits::TryInto;
    use core::array::ArrayTrait;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use custom_uri::interface::IInternalCustomURI;
    use super::{append_to_str, div_rec};

    #[storage]
    struct Storage {
        uri: LegacyMap<felt252, felt252>
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {}


    impl InternalImpl<T, +HasComponent<T>> of IInternalCustomURI<ComponentState<T>> {
        fn get_base_uri(self: @ComponentState<T>) -> Array<felt252> {
            let mut output = ArrayTrait::new();
            let mut i = 0;
            loop {
                let value = self.uri.read(i);
                if value == 0 {
                    break;
                };
                output.append(value);
                i += 1;
            };
            output
        }

        fn get_uri(self: @ComponentState<T>, mut value: u256) -> Array<felt252> {
            let mut base = self.get_base_uri();
            let ten: NonZero<u256> = 10_u256.try_into().unwrap();
            let to_add = div_rec(value, ten);

            let mut output = ArrayTrait::new();
            let mut last_i = base.len() - 1;
            let last = *base.at(last_i);
            let mut i = 0;
            loop {
                if i == last_i {
                    break;
                }
                output.append(*base.at(i));
                i += 1;
            };
            append_to_str(ref output, last.into(), to_add.span());
            output
        }

        fn set_base_uri(ref self: ComponentState<T>, mut base_uri: Span<felt252>) {
            // writing end of text
            self.uri.write(base_uri.len().into(), 0);
            loop {
                match base_uri.pop_back() {
                    Option::Some(value) => { self.uri.write(base_uri.len().into(), *value); },
                    Option::None => { break; }
                }
            };
        }
    }
}

fn div_rec(value: u256, divider: NonZero<u256>) -> Array<felt252> {
    let (value, digit) = DivRem::div_rem(value, divider);
    let mut output = if value == 0 {
        Default::default()
    } else {
        div_rec(value, divider)
    };
    output.append(48 + digit.try_into().unwrap());
    output
}

fn append_to_str(ref str: Array<felt252>, last_field: u256, to_add: Span<felt252>) {
    let mut free_space: usize = 0;
    let ascii_length: NonZero<u256> = 256_u256.try_into().unwrap();
    let mut i = 0;
    let mut shifted_field = last_field;
    loop {
        let (_shifted_field, char) = DivRem::div_rem(shifted_field, ascii_length);
        shifted_field = _shifted_field;
        if char == 0 {
            free_space += 1;
        } else {
            free_space = 0;
        };
        i += 1;
        if i == 31 {
            break;
        }
    };

    let mut new_field = 0;
    let mut shift = 1;
    let mut i = free_space;

    loop {
        if free_space == 0 {
            break;
        }
        free_space -= 1;
        match to_add.get(free_space) {
            Option::Some(c) => {
                new_field += shift * *c.unbox();
                shift *= 256;
            },
            Option::None => {}
        };
    };
    new_field += last_field.try_into().expect('invalid string') * shift;
    str.append(new_field);
    if i >= to_add.len() {
        return;
    }

    let mut new_field_shift = 1;
    let mut new_field = 0;
    let mut j = i + 30;

    loop {
        match to_add.get(j) {
            Option::Some(char) => {
                new_field += new_field_shift * *char.unbox();
                if new_field_shift == 0x100000000000000000000000000000000000000000000000000000000000000 {
                    str.append(new_field);
                    new_field_shift = 1;
                    new_field = 0;
                } else {
                    new_field_shift *= 256;
                }
            },
            Option::None => {},
        }
        if j == i {
            i += 31;
            j = i + 30;
            str.append(new_field);
            if i >= to_add.len() {
                break;
            }
            new_field_shift = 1;
            new_field = 0;
        } else {
            j -= 1;
        };
    };
}
