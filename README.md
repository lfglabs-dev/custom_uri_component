# Custom URI component

This Cairo component allows you to efficiently create a dynamic token_uri. The concept is simple, you
just have to call  `set_base_uri(your_uri)` where `your_uri` is an array of utf-8 felt encoded strings.
A felt can contain 31 ascii chars, so if your uri is something like "https://my.example.api/get_token_uri?uri=",
you should pass `[ 'https://my.example.api/get_toke', 'n_uri?uri=' ]`.
You can then get a URL with a dynamically appended number at the end with `get_uri(number)`, for example
with `get_uri(12345)`, you should get `[ 'https://my.example.api/get_toke', 'n_uri?uri=12345' ]` in a 
minimal amount of steps.

## How to install

Install the component through scarb by specifying it in your dependencies. I recommend to specify a commit with rev.
```toml
[dependencies]
custom_uri = { git = "https://github.com/starknet-id/custom_uri_component", rev = "abb2f3d43c7be56dd5cd9f93c33af40b272c2245" }
```

Add it to your cairo code:
```cairo
    use custom_uri::{interface::IInternalCustomURI, main::custom_uri_component};
    // load component
    component!(path: custom_uri_component, storage: custom_uri, event: CustomUriEvent);

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
```

You can now set your URI in your constructor (for example):
```cairo
    self.custom_uri.set_base_uri(token_uri_base);
```

To add the standard ERC721 token_uri function while using OZ ERC721 component, I suggest 
to define a new impl (and implement it with #[abi(embed_v0)]) like:
```cairo
use openzeppelin::{
    token::erc721::{ERC721Component::{ERC721Metadata, HasComponent}},
    introspection::src5::SRC5Component,
};
use custom_uri::{main::custom_uri_component::InternalImpl, main::custom_uri_component};


#[starknet::interface]
trait IERC721Metadata<TState> {
    fn name(self: @TState) -> felt252;
    fn symbol(self: @TState) -> felt252;
    fn token_uri(self: @TState, tokenId: u256) -> Array<felt252>;
    fn tokenURI(self: @TState, tokenId: u256) -> Array<felt252>;
}

#[starknet::embeddable]
impl IERC721MetadataImpl<
    TContractState,
    +HasComponent<TContractState>,
    +SRC5Component::HasComponent<TContractState>,
    +custom_uri_component::HasComponent<TContractState>,
    +Drop<TContractState>
> of IERC721Metadata<TContractState> {
    fn name(self: @TContractState) -> felt252 {
        let component = HasComponent::get_component(self);
        ERC721Metadata::name(component)
    }

    fn symbol(self: @TContractState) -> felt252 {
        let component = HasComponent::get_component(self);
        ERC721Metadata::symbol(component)
    }

    fn token_uri(self: @TContractState, tokenId: u256) -> Array<felt252> {
        let component = custom_uri_component::HasComponent::get_component(self);
        component.get_uri(tokenId)
    }

    fn tokenURI(self: @TContractState, tokenId: u256) -> Array<felt252> {
        self.token_uri(tokenId)
    }
}
```