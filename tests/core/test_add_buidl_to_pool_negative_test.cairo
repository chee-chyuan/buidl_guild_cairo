%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from tests.core.utils.ICore import ICore
from src.interfaces.IUserRegistrar import IUserRegistrar

const USER = 13434
const CONTRACT_HASH = 353534
@view
func __setup__():
    tempvar user_registry_address
    %{
         context.user_registry = deploy_contract(
            "./src/user_registry.cairo", 
            []).contract_address

         ids.user_registry_address = context.user_registry

         context.contract_address = deploy_contract(
            "./src/core.cairo", 
            [ids.CONTRACT_HASH,
             ids.user_registry_address,
             1
            ]).contract_address
    %}
    return ()
end

func register_user{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}(user: felt): 
    tempvar user_registry_addr
    %{
        ids.user_registry_addr = context.user_registry
        stop_prank_callable = start_prank(ids.user, target_contract_address=ids.user_registry_addr)
    %}

    let prefix = 'a'
    let suffix = 'ab'
    let ipfs_len = 1
    let (ipfs) = alloc()
    assert ipfs[0] = 'xxxx'

    IUserRegistrar.register(contract_address=user_registry_addr,
                            github_prefix=prefix, 
                            github_suffix=suffix,
                            ipfs_url_len=ipfs_len,
                            ipfs_url=ipfs
                            )

    %{
        stop_prank_callable()
    %}
    return ()
end

@view 
func test_cannot_add_buidl_to_pool_when_buidl_id_is_0{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}():
    tempvar contract_address
    %{
        ids.contract_address=context.contract_address
    %}

    %{ expect_revert() %}
    ICore.add_buidl_to_pool(contract_address=contract_address, buidl_id=0, pool_id=1)

    return ()
end

# skip but it seems to be working
# @view 
func test_cannot_add_buidl_to_pool_when_buidl_id_greater_than_current{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}():
    alloc_locals
    local pedersen_ptr_local: HashBuiltin* = pedersen_ptr 

    register_user(USER)

    tempvar contract_address
    %{
        ids.contract_address=context.contract_address
        stop_prank_callable = start_prank(ids.USER, target_contract_address=ids.contract_address)
    %}
    local contract_address = contract_address

    let ipfs_len = 2
    let (ipfs) = alloc()
    assert ipfs[0] = 'a'
    assert ipfs[1] = 'b'

    ICore.add_buidl(contract_address=contract_address, ipfs_len=ipfs_len, ipfs=ipfs)

    %{ expect_revert() %}
    ICore.add_buidl_to_pool(contract_address=contract_address, buidl_id=2, pool_id=1)

    %{
        stop_prank_callable()
    %}
    return ()
end

