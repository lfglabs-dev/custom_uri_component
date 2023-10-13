use custom_uri::main::custom_uri_component::{InternalImpl, component_state_for_testing};
use custom_uri::main::custom_uri_component;

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
#[available_gas(200000)]
fn test_ownable_initializer() {
    let mut uri_component: TestingState = Default::default();
    let base_uri = array!['https://api.starknet.id/uri?id='];
    uri_component.set_base_uri(base_uri.span());
}
