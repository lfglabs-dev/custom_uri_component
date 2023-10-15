use custom_uri::main::custom_uri_component::{InternalImpl, component_state_for_testing};
use custom_uri::main::custom_uri_component;
use custom_uri::main::append_to_str;

#[starknet::contract]
mod DummyContract {
    use starknet::ContractAddress;
    use custom_uri::main::custom_uri_component;

    component!(path: super::custom_uri_component, storage: custom_uri, event: CustomUriEvent);

    impl URIComponent = custom_uri_component::InternalImpl<ContractState>;

    #[storage]
    struct Storage {
        #[substorage(v0)]
        custom_uri: custom_uri_component::Storage
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        CustomUriEvent: custom_uri_component::Event
    }
}


type TestingState =
    custom_uri::main::custom_uri_component::ComponentState<DummyContract::ContractState>;

impl TestingStateDefault of Default<TestingState> {
    fn default() -> TestingState {
        component_state_for_testing()
    }
}

#[test]
#[available_gas(2000000)]
fn test_base_uri() {
    let mut uri_component: TestingState = Default::default();

    let base_uri = array!['a', 'b', 'c'];
    uri_component.set_base_uri(base_uri.span());
    let read_base_uri = uri_component.get_base_uri();
    assert(base_uri == read_base_uri, 'unexpected base_uri 1');

    // make sure the 0 is written at the end
    let base_uri = array!['https://api.starknet.id/uri?id='];
    uri_component.set_base_uri(base_uri.span());
    let read_base_uri = uri_component.get_base_uri();
    assert(base_uri == read_base_uri, 'unexpected base_uri 2');
}


#[test]
#[available_gas(40000000)]
fn test_appending_id() {
    let mut uri_component: TestingState = Default::default();

    // basic test
    let base_uri = array!['https://api.starknet.id/uri?id='];
    uri_component.set_base_uri(base_uri.span());
    let uri = uri_component.get_uri(12345);
    assert(uri == array!['https://api.starknet.id/uri?id=', '12345'], 'wrong output uri');

    // low/high test
    let base_uri = array!['https://api.starknet.id/uri?id='];
    uri_component.set_base_uri(base_uri.span());
    let uri = uri_component.get_uri(3331111111111111111);
    assert(
        uri == array!['https://api.starknet.id/uri?id=', '3331111111111111111'],
        'wrong output uri 2'
    );

    // 31 chars test
    let base_uri = array!['https://api.starknet.id/uri?id='];
    uri_component.set_base_uri(base_uri.span());
    let uri = uri_component.get_uri(1000000000000000000000000000000);
    assert(
        uri == array!['https://api.starknet.id/uri?id=', '1000000000000000000000000000000'],
        'wrong output uri 3'
    );
    // 31+ chars test
    let base_uri = array!['https://api.starknet.id/uri?id='];
    uri_component.set_base_uri(base_uri.span());
    let uri = uri_component.get_uri(1000000000000000000000000000000234);
    assert(
        uri == array!['https://api.starknet.id/uri?id=', '1000000000000000000000000000000', '234'],
        'wrong output uri'
    );
}


#[test]
#[available_gas(8000000)]
fn test_appending_chars() {
    // not many digits to add
    let mut output = Default::default();
    append_to_str(ref output, 'abcd', array!['e', 'f', 'g'].span());
    assert(output == array!['abcdefg'], 'wrong string sum');

    // 31 initially
    let mut output = Default::default();
    append_to_str(ref output, 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', array!['e', 'f', 'g'].span());
    assert(output == array!['aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 'efg'], 'wrong string sum');

    // more than 31 to add
    let mut output = Default::default();
    append_to_str(ref output, 'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', array!['e', 'f', 'g'].span());
    assert(output == array!['aaaaaaaaaaaaaaaaaaaaaaaaaaaaaae', 'fg'], 'wrong string sum');

    // adding 31 b
    let mut output = Default::default();
    append_to_str(
        ref output,
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        array![
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
        ]
            .span()
    );
    assert(
        output == array!['aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb'],
        'wrong string sum aza'
    );

    // adding 32 b
    let mut output = Default::default();
    append_to_str(
        ref output,
        'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        array![
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b',
            'b'
        ]
            .span()
    );
    assert(
        output == array!['aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa', 'bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb', 'b'],
        'wrong string sum'
    );
}
