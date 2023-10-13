#[starknet::component]
mod custom_uri_component {
    use core::array::ArrayTrait;
    use starknet::ContractAddress;
    use starknet::get_caller_address;
    use custom_uri::interface::IInternalCustomURI;

    #[storage]
    struct Storage {
        uri: LegacyMap<felt252, felt252>
    }

    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {}


    impl InternalImpl<T, +HasComponent<T>> of IInternalCustomURI<ComponentState<T>> {
        fn get_base_uri(self: @ComponentState<T>) -> Array<felt252> {
            Default::default()
        }

        fn get_uri(self: @ComponentState<T>, value: u128) -> Array<felt252> {
            Default::default()
        }

        fn get_uri_u256(self: @ComponentState<T>, value: u256) -> Array<felt252> {
            Default::default()
        }

        fn set_base_uri(ref self: ComponentState<T>, mut base_uri: Span<felt252>) {
            match base_uri.pop_front() {
                Option::Some(value) => {},
                Option::None => {}
            }
        }
    }
}
