#[starknet::interface]
trait IInternalCustomURI<TComponentState> {
    fn get_base_uri(self: @TComponentState) -> Array<felt252>;
    fn get_uri(self: @TComponentState, value: u128) -> Array<felt252>;
    fn get_uri_u256(self: @TComponentState, value: u256) -> Array<felt252>;
    fn set_base_uri(ref self: TComponentState, base_uri: Span<felt252>);
}
