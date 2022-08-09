%lang starknet

from starkware.cairo.common.cairo_builtins import HashBuiltin
from starkware.cairo.common.alloc import alloc
from tests.core.utils.ICore import ICore
from src.interfaces.IUserRegistrar import IUserRegistrar

const ADMIN = 343252342
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
             1,
             ids.ADMIN
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
func test_fail_to_add_user_not_registered{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}():
    tempvar contract_address
    %{
        ids.contract_address = context.contract_address
    %}

    let ipfs_len = 1
    let (ipfs) = alloc()
    assert ipfs[0] = 'a'

    %{ expect_revert(error_message="User not registered") %}
    ICore.add_buidl(contract_address=contract_address, ipfs_len=1, ipfs=ipfs)

    return ()
end

@view
func test_add_buidl{
    syscall_ptr : felt*,
    pedersen_ptr : HashBuiltin*,
    range_check_ptr,
}():
    alloc_locals
    local pedersen_ptr_temp :HashBuiltin* = pedersen_ptr

    register_user(USER)

    tempvar contract_address
    tempvar user_registry
    %{
        ids.user_registry = context.user_registry
        ids.contract_address = context.contract_address
        stop_prank_callable = start_prank(ids.USER, target_contract_address=ids.contract_address)
    %}

    local contract_address = contract_address

    # state before
    let (id_before) = ICore.get_user_current_buidl_id(contract_address=contract_address, user_addr=USER)
    assert id_before = 0

    let ipfs_len = 2
    let (ipfs) = alloc()
    assert ipfs[0] = 'a'
    assert ipfs[1] = 'b'

    ICore.add_buidl(contract_address=contract_address, ipfs_len=ipfs_len, ipfs=ipfs)

    let (id_after) = ICore.get_user_current_buidl_id(contract_address=contract_address, user_addr=USER)
    assert id_after = 1

    let (link) = alloc()
    let (ipfs_len, ipfs) = ICore.get_user_buidl_ipfs(
                            contract_address=contract_address,
                            user_addr=USER,
                            buidl_id=1,
                            current_index=0,
                            ipfs_len=2,
                            link_len=0,
                            link=link
                            )
    
    assert ipfs_len = 2
    assert ipfs[0] = 'a'
    assert ipfs[1] = 'b'

    let (buidl_len, buidl) = ICore.get_all_user_buidl(contract_address=contract_address, user_addr=USER)
    assert buidl_len = 1
    assert buidl.ipfs_link_len = 2

    %{
        stop_prank_callable()
    %}
    return ()
end